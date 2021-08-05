pragma solidity 0.5.3;
pragma experimental ABIEncoderV2;

/// @notice these commented segments will differ based on where you're deploying these contracts. If you're deploying
/// on remix, feel free to uncomment the github imports, otherwise, use the uncommented imports

// import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/solc-0.6/contracts/token/ERC20/IERC20.sol";
// import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/solc-0.6/contracts/math/SafeMath.sol";
import '../contracts/libraries/token/ERC20/ERC20.sol';
import '../contracts/libraries/math/SafeMath.sol';
import "./IExc.sol";

contract Exc is IExc{
    /// @notice simply notes that we are using SafeMath for uint, since Solidity's math is unsafe. For all the math
    /// you do, you must use the methods specified in SafeMath (found at the github link above), instead of Solidity's
    /// built-in operators.
    using SafeMath for uint;
    
    /// @notice these declarations are incomplete. You will still need a way to store the orderbook, the balances
    /// of the traders, and the IDs of the next trades and orders. Reference the NewTrade event and the IExc
    /// interface for more details about orders and sides.
    mapping(bytes32 => mapping(uint => Order[])) public orderBook;
    mapping(address => mapping(bytes32 => uint)) public balances;
    uint public nextTradeID;
    uint public nextOrderID;
    
    mapping(bytes32 => Token) public tokens;
    bytes32[] public tokenList;
    bytes32 constant PIN = bytes32('PIN');

    /// @notice, this is the more standardized form of the main wallet data structure, if you're using something a bit
    /// different, implementing a function that just takes in the address of the trader and then the ticker of a
    /// token instead would suffice
    mapping(address => mapping(bytes32 => uint)) public traderBalances;
    
    /// @notice an event representing all the needed info regarding a new trade on the exchange
    event NewTrade(
        uint tradeId,
        uint orderId,
        bytes32 indexed ticker,
        address indexed trader1,
        address indexed trader2,
        uint amount,
        uint price,
        uint date
    );
    
    // todo: implement getOrders, which simply returns the orders for a specific token on a specific side
    function getOrders(
      bytes32 ticker, 
      Side side) 
      external 
      view
      returns(Order[] memory) {
          return orderBook[ticker][uint(side)];
    }

    // todo: implement getTokens, which simply returns an array of the tokens currently traded on in the exchange
    function getTokens() 
      external 
      view 
      returns(Token[] memory) {
          Token[] memory returnTokens = new Token[](tokenList.length);
          for (uint i = 0; i < tokenList.length; i++) {
              returnTokens[i] = Token(tokens[tokenList[i]].ticker, tokens[tokenList[i]].tokenAddress);
          }
          return returnTokens;
    }
    
    // todo: implement addToken, which should add the token desired to the exchange by interacting with tokenList and tokens
    function addToken(
        bytes32 ticker,
        address tokenAddress)
        external {
            tokenList.length++;
            tokenList.push(ticker);
            // Token memory newToken = Token(ticker, tokenAddress);
            tokens[ticker] = Token(ticker, tokenAddress);
    }
    
    // todo: implement deposit, which should deposit a certain amount of tokens from a trader to their on-exchange wallet,
    // based on the wallet data structure you create and the IERC20 interface methods. Namely, you should transfer
    // tokens from the account of the trader on that token to this smart contract, and credit them appropriately
    function deposit(
        uint amount,
        bytes32 ticker)
        external {
            require(balances[msg.sender][ticker] >= amount);
            IERC20(tokens[ticker].tokenAddress).transferFrom(msg.sender, address(this), amount);
            balances[address(this)][ticker] = balances[address(this)][ticker].add(amount);
            balances[msg.sender][ticker] -= balances[msg.sender][ticker].sub(amount);
    }
    
    // todo: implement withdraw, which should do the opposite of deposit. The trader should not be able to withdraw more than
    // they have in the exchange.
    function withdraw(
         uint amount,
         bytes32 ticker)
        external {
            require(balances[address(this)][ticker] >= amount);
            IERC20(tokens[ticker].tokenAddress).transferFrom(address(this), msg.sender, amount);
            balances[address(this)][ticker] = balances[address(this)][ticker].sub(amount);
            balances[msg.sender][ticker] = balances[msg.sender][ticker].add(amount);
     }
     
     function sort(Order[] memory data) public returns(Order[] memory) {
       quickSort(data, uint(0), uint(data.length - 1));
       return data;
    }
    
    function quickSortHelp(Order[] memory arr, int left, int right) internal{
        int i = left;
        int j = right;
        if(i==j) return;
        uint pivot = arr[uint(left + (right - left) / 2)].price;
        while (i <= j) {
            while (arr[uint(i)].price < pivot) i++;
            while (pivot < arr[uint(j)].price) j--;
            if (i <= j) {
                (arr[uint(i)], arr[uint(j)]) = (arr[uint(j)], arr[uint(i)]);
                i++;
                j--;
            }
        }
        if (left < j)
            quickSortHelp(arr, left, j);
        if (i < right)
            quickSortHelp(arr, i, right);
    }
     
     function quickSort(Order[] memory arr, uint left, uint right) internal {
        uint pivot = arr.length/2;
        Order memory temp = arr[pivot];
        delete arr[pivot];
        arr[pivot] = arr[arr.length-1];
        arr[arr.length-1] = arr[pivot];
        bool done = false;
        while (!done) {
            uint256 leftItem = left;
            uint256 rightItem = right;
            while (arr[leftItem].price < arr[right].price) {
                left++;
            }
            while (arr[rightItem].price > arr[right].price) {
                right++;
            }
            if (left < right) {
                (arr[leftItem], arr[rightItem]) = (arr[rightItem], arr[leftItem]);
            } else {
                (arr[leftItem], arr[right]) = (arr[right], arr[leftItem]);
                done = true;
                quickSort(arr, left, leftItem - 1);
                quickSort(arr, leftItem + 1, right);
            }
        }
    }
    
    function reverseArray(Order[] memory toReverse) internal returns(Order[] memory){
        Order[] memory reversedOrders;
        uint last = toReverse.length - 1;
        for (uint i = 0; i < toReverse.length; i++) {
            if (i == last || i == (toReverse.length/2)){
                return reversedOrders;
            }
            reversedOrders[i] = toReverse[last];
            reversedOrders[last] = toReverse[i];
        }
    }

    
    // todo: implement makeLimitOrder, which creates a limit order based on the parameters provided. This method should only be
    // used when the token desired exists and is not pine. This method should not execute if the trader's token or pine balances
    // are too low, depending on side. This order should be saved in the orderBook
    
    // todo: implement a sorting algorithm for limit orders, based on best prices for market orders having the highest priority.
    // i.e., a limit buy order with a high price should have a higher priority in the orderbook.
    function makeLimitOrder(
        bytes32 ticker,
        uint amount,
        uint price,
        Side side)
        external {
            // is it msg.sender or address(this?)
            require(balances[address(this)][ticker] >= amount);
            require(ticker != 'PIN');
            
            if (ticker == "pine"){
                return;
            }
            
            bool is_in = false;
            for (uint i = 0; i < tokenList.length; i++){
                if (tokenList[i] == ticker){
                    is_in == true;
                }
            }
            
            if (is_in == false){
                return;
            }
            
            if (side == Side.BUY){
                if (balances[msg.sender]['PIN'] < amount.mul(price))
                // converts zrx to pine. Pine is quoting currency
                    return;
                } else {
                if (balances[msg.sender][ticker] < amount){
                    return;
                }
            }
           
           
            // update and sort orderbook
            // Order newLimitOrder = Order(nextOrderID, msg.sender, side, ticker, amount, 0, price, now);
            // orderBook[ticker].push(newLimitOrder);
            // orderSort(orderBook[ticker]);
            
            Order memory newLimitOrder = Order(nextOrderID, msg.sender, side, ticker, amount, 0, price, now);
            
            if (orderBook[ticker][uint(side)].length == 0){
                orderBook[ticker][uint(side)].length++;
                orderBook[ticker][uint(side)].push(newLimitOrder);
             }else {
                orderBook[ticker][uint(side)].length++;
                orderBook[ticker][uint(side)].push(newLimitOrder);
                if (side == Side.BUY) {
                // if buy, sort limit orders with highest prices as highest priority
                    quickSort(orderBook[ticker][uint(side)],0,orderBook[ticker][uint(side)].length-1);
                } else {
                // if sell, sort limit orders with
                quickSort(orderBook[ticker][uint(side)],0,orderBook[ticker][uint(side)].length-1);
                orderBook[ticker][uint(side)] = reverseArray(orderBook[ticker][uint(side)]);
                }
            }
            
    }
 
    
    // todo: implement deleteLimitOrder, which will delete a limit order from the orderBook as long as the same trader is deleting
    // it.
        function deleteLimitOrder(
        uint id,
        bytes32 ticker,
        Side side) external returns (bool) {
                
            if (orderBook[ticker][uint(side)].length == 0) {
                return false;
            }
            for (uint i = 0; i < orderBook[ticker][uint(side)].length; i++) {
                if (orderBook[ticker][uint(side)][i].id == id && orderBook[ticker][uint(side)][i].trader == msg.sender) {
                    //maybe not use delete
                    //maybe use .pop on an array
                    for (uint j = i; j < orderBook[ticker][uint(side)].length - 1; j++) {
                        // swap pairs until the thing to delete is at the end, then pop
                        orderBook[ticker][uint(side)][j] = orderBook[ticker][uint(side)][j+1];
                    }
                    orderBook[ticker][uint(side)].pop();
                    orderBook[ticker][uint(side)].length--;
                    return true;
                }
            }
            return false;
        }
        
        function deleteLimitOrderInternal(
        uint id,
        bytes32 ticker,
        Side side) internal returns (bool) {
                
            if (orderBook[ticker][uint(side)].length == 0) {
                return false;
            }
            for (uint i = 0; i < orderBook[ticker][uint(side)].length; i++) {
                if (orderBook[ticker][uint(side)][i].id == id && orderBook[ticker][uint(side)][i].trader == msg.sender) {
                    //maybe not use delete
                    //maybe use .pop on an array
                    for (uint j = i; j < orderBook[ticker][uint(side)].length - 1; j++) {
                        // swap pairs until the thing to delete is at the end, then pop
                        orderBook[ticker][uint(side)][j] = orderBook[ticker][uint(side)][j+1];
                    }
                    orderBook[ticker][uint(side)].pop();
                    orderBook[ticker][uint(side)].length--;
                    return true;
                }
            }
            return false;
        }
    
    // todo: implement makeMarketOrder, which will execute a market order on the current orderbook. The market order need not be
    // added to the book explicitly, since it should execute against a limit order immediately. Make sure you are getting rid of
    // completely filled limit orders!
    // function makeMarketOrder(
    //     bytes32 ticker,
    //     uint amount,
    //     Side side)
    //     external {
    //         // where the orders are always filled
    //         // only market orders can fill limit orders/where transferring happens
    //         require(balances[msg.sender][ticker] >= amount);
    //         uint amountLeft = amount;
    //         Order memory topOrder = orderBook[ticker][uint(side)][0];
    //         uint orderNum = 0;
    //         while (amountLeft > 0) {
    //             if (orderNum >= orderBook[ticker][uint(side)].length) {
    //                 return;
    //             }
    //             if (topOrder.filled.add(amountLeft) < topOrder.amount) {
    //                 topOrder.filled = topOrder.filled.add(amountLeft); // does this work?
    //                 // make market order works by using limit orders to fill the amount necessary to make the market order. We do this 
    //                 // by taking from the orders in orderbook. If the topOrder does not fill it, we should look at the next ones and 
    //                 // take their amounts as well.
                    
    //                 //should be in an if statement for the side a, also pin and token balance will change 4 statments use safemath
    //                 // Questions for TA: what exactlty should we be updating in balances? Should we be using amounts or filled? 
    //                 // how does an order being buy or selll affect what we do? 
                    
    //                 if ()
    //                 balances[msg.sender][ticker] =  balances[msg.sender][ticker].sub(amount);
    //                 //balances[][ticker] += amount;
    //                 emit NewTrade(nextTradeID, topOrder.id, ticker, msg.sender, address(this), amount, topOrder.price, now);
    //                 nextTradeID++;
    //                 return;
    //             } else {
    //                 orderNum++;
    //                 amountLeft = amountLeft.sub(topOrder.amount).add(topOrder.filled);
    //                 // IERC20(tokens[ticker].tokenAddress).transferFrom(topOrder.trader, msg.sender, topOrder.amount.sub(topOrder.filled));
    //                 // amount -= topOrder.amount;
    //                 // topOrder.amount = 0;
    //                 deleteLimitOrderInternal(topOrder.id, topOrder.ticker, topOrder.side);
    //                 topOrder = orderBook[ticker][uint(side)][orderNum]; // messy with indices here
    //                 emit NewTrade(nextTradeID, topOrder.id, ticker, msg.sender, address(this), amount, topOrder.price, now);
    //             }
    //             // emit NewTrade(uint(0), topOrder.id, ticker, msg.sender, address(this), amount, topOrder.price, now);
    //         }
    // }
    // function makeMarketOrder(
    //     bytes32 ticker,
    //     uint amount,
    //     Side side)
    //     external {
    //     uint tofill = amount;
    //     uint counter = 0;
        
    //     require(balances[msg.sender][ticker] >= amount);
    //         while (tofill > 0) {
    //             if (counter >= orderBook[ticker][uint(side)].length) {
    //                 return;
    //             }
    //             uint available = orderBook[ticker][uint(side)][counter].amount - orderBook[ticker][uint(side)][counter].filled;
    //             if (available > tofill){
    //                 orderBook[ticker][uint(side)][counter].filled += tofill;
    //                 IERC20(tokens[ticker].tokenAddress).transferFrom(msg.sender, orderBook[ticker][uint(side)][counter].trader, tofill);
    //                 emit NewTrade(nextTradeID, orderBook[ticker][uint(side)][counter].id, ticker, msg.sender, orderBook[ticker][uint(side)][counter].trader, tofill, orderBook[ticker][uint(side)][counter].price, now);
    //                 nextTradeID++;
    //                 tofill = 0;
    //                 if (side == side.SELL) {
    //                     if (ticker == "PIN") {
    //                         balances[msg.sender][ticker] =  balances[msg.sender][ticker].add(amount);
    //                         balances[orderBook[ticker][uint(side)][counter].trader][ticker] = balances[orderBook[ticker][uint(side)][counter].trader][ticker].sub(amount);
    //                     } else {
                            
    //                     }
    //                 } else {
    //                     balances[msg.sender][ticker] =  balances[msg.sender][ticker].sub(amount);
    //                 }
    //             }else{
    //                 tofill -= available;
    //                 IERC20(tokens[ticker].tokenAddress).transferFrom(msg.sender, orderBook[ticker][uint(side)][counter].trader, available);
    //                 emit NewTrade(nextTradeID, orderBook[ticker][uint(side)][counter].id, ticker, msg.sender, orderBook[ticker][uint(side)][counter].trader, available, orderBook[ticker][uint(side)][counter].price, now);
    //                 nextTradeID++;
    //                 delete orderBook[ticker][uint(side)][counter];
    //             }
    //             counter++;
    //         }
    // }
    
    function makeMarketOrder(
        bytes32 ticker,
        uint amount,
        Side side)
        // tokenExists(ticker)
        // tokenIsNotPine(ticker)
        external {
        if(side == Side.SELL) {
            require(
                traderBalances[msg.sender][ticker] >= amount,
                'token balance too low'
            );
        }
        
        uint tofill = amount;
        uint counter = 0;
            while (tofill > 0) {
                if (counter >= orderBook[ticker][uint(side)].length) {
                    return;
                }
                uint available = orderBook[ticker][uint(side)][counter].amount - orderBook[ticker][uint(side)][counter].filled;
                Order storage currOrder = orderBook[ticker][uint(side)][counter];
                if (available > tofill) {
                    currOrder.filled += tofill;
                    IERC20(tokens[ticker].tokenAddress).transferFrom(msg.sender, currOrder.trader, tofill);
                    emit NewTrade(nextTradeID, currOrder.id, ticker, msg.sender, currOrder.trader, tofill, currOrder.price, now);
                    nextTradeID++;
                    tofill = 0;
                    
                }else{
                    tofill -= available;
                    IERC20(tokens[ticker].tokenAddress).transferFrom(msg.sender, currOrder.trader, available);
                    emit NewTrade(nextTradeID, currOrder.id, ticker, msg.sender, currOrder.trader, available, currOrder.price, now);
                    nextTradeID++;
                    deleteLimitOrderInternal(currOrder.id, ticker, side);
                    // delete orderBook[ticker][uint(side)][counter];
                }
                // are we setting balances correctly?
                if (side == Side.SELL) {
                        if (ticker == "PIN") {
                            balances[msg.sender][ticker] =  balances[msg.sender][ticker].add(SafeMath.mul(amount,currOrder.price));
                            balances[currOrder.trader][ticker] = balances[currOrder.trader][ticker].sub(SafeMath.mul(amount,currOrder.price));
                        } else {
                            balances[msg.sender][ticker] =  balances[msg.sender][ticker].add(amount);
                            balances[currOrder.trader][ticker] = balances[currOrder.trader][ticker].sub(amount);
                        }
                    } else {
                        if (ticker == "PIN") {
                            balances[msg.sender][ticker] =  balances[msg.sender][ticker].sub(SafeMath.mul(amount,currOrder.price));
                            balances[currOrder.trader][ticker] = balances[currOrder.trader][ticker].add(SafeMath.mul(amount,currOrder.price));
                        } else {
                            balances[msg.sender][ticker] =  balances[msg.sender][ticker].sub(amount);
                            balances[currOrder.trader][ticker] = balances[currOrder.trader][ticker].add(amount);
                        }
                    }
                counter++;
            }
    }
    
    //todo: add modifiers for methods as detailed in handout
    modifier tokenValid(bytes32 tk) {
        require(tokens[tk].tokenAddress != address(0));
        _;
    }
    modifier checkCurrency(Token memory tk) {
        require(tk.ticker != 'pine');
        // how do I know if it's pine or not?
        _;
    }
}