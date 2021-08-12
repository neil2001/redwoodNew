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
    // mapping(address => mapping(bytes32 => uint)) public balances;
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
              returnTokens[i] = tokens[tokenList[i]];
          }
          return returnTokens;
    }
   
   
    // todo: implement addToken, which should add the token desired to the exchange by interacting with tokenList and tokens
    function addToken(
        bytes32 ticker,
        address tokenAddress)
        external {
            if (tokens[ticker].tokenAddress == address(0)){
            Token memory newToken = Token(ticker, tokenAddress);
            tokenList.push(ticker);
            tokens[ticker] = newToken;
            }
    }
   
   
    // todo: implement deposit, which should deposit a certain amount of tokens from a trader to their on-exchange wallet,
    // based on the wallet data structure you create and the IERC20 interface methods. Namely, you should transfer
    // tokens from the account of the trader on that token to this smart contract, and credit them appropriately
    function deposit(
        uint amount,
        bytes32 ticker)
        external {
            // require(balances[msg.sender][ticker] >= amount);
            IERC20(tokens[ticker].tokenAddress).transferFrom(msg.sender, address(this), amount);
            // balances[address(this)][ticker] = balances[address(this)][ticker].add(amount);
            traderBalances[msg.sender][ticker] = traderBalances[msg.sender][ticker].add(amount);
    }
   
   
    // todo: implement withdraw, which should do the opposite of deposit. The trader should not be able to withdraw more than
    // they have in the exchange.
    function withdraw(
         uint amount,
         bytes32 ticker)
        external {
            require(traderBalances[msg.sender][ticker] >= amount, "withdraw");
            IERC20(tokens[ticker].tokenAddress).transfer(msg.sender, amount);
            // balances[address(this)][ticker] = balances[address(this)][ticker].sub(amount);
            traderBalances[msg.sender][ticker] = traderBalances[msg.sender][ticker].sub(amount);
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
    tokenValid(ticker)
    external {
   
    require(ticker != 'PIN', "PIN");
    //require(traderBalances[msg.sender][ticker] >= amount, "hehe");
    if (side == Side.BUY){
        require(traderBalances[msg.sender]['PIN'] >= amount.mul(price), "side = buy, balance too low");
    }
    if (side == Side.SELL){
        require(traderBalances[msg.sender][ticker] >= amount, "side = sell, balance too low");
    }
    Order memory out = Order(nextOrderID, msg.sender, side, ticker, amount, 0, price, now);
    orderBook[ticker][uint(side)].push(out);
    nextOrderID ++;
    if (side == Side.BUY){
        buysort(orderBook[ticker][uint(side)]);
    } else{
        sellsort(orderBook[ticker][uint(side)]);
    }
       
    }

   
function buysort(Order[] storage arr)
    internal {
        if (arr.length > 0){
        for (uint i = 0; i < arr.length; i++){
            for (uint j = 0; j < arr.length - 1; j++){
                if (arr[j].price < arr[j+1].price){
                    Order memory temp = arr[j];
                    arr[j] = arr[j + 1];
                    arr[j + 1] = temp;
                }
            }
        }
        }
    }
function sellsort(Order[] storage arr)
    internal {
        if (arr.length > 0){
        for (uint i = 0; i < arr.length; i++){
            for (uint j = 0; j < arr.length - 1; j++){
                if (arr[j].price > arr[j+1].price){
                    Order memory temp = arr[j];
                    arr[j] = arr[j + 1];
                    arr[j + 1] = temp;
                }
            }
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
                if (orderBook[ticker][uint(side)][i].id == id) {
                    require(orderBook[ticker][uint(side)][i].trader == msg.sender, 'deleter was not maker');
                    if (i != orderBook[ticker][uint(side)].length - 1){
                        orderBook[ticker][uint(side)][i] = orderBook[ticker][uint(side)][orderBook[ticker][uint(side)].length-1];
                    }
                        orderBook[ticker][uint(side)].pop();
                    if (side == Side.BUY){
                        buysort(orderBook[ticker][uint(side)]);
                    } else{
                        sellsort(orderBook[ticker][uint(side)]);
                    }
                    return true;
                }
            }
            return false;
        }
       
       

       
   
    // todo: implement makeMarketOrder, which will execute a market order on the current orderbook. The market order need not be
    // added to the book explicitly, since it should execute against a limit order immediately. Make sure you are getting rid of
    // completely filled limit orders!
   
    //filling orders
    //updating balnces
    //removing filled orders
   
    function makeMarketOrder(
        bytes32 ticker,
        uint amount,
        Side side)
        external  
        tokenValid(ticker)
        checkCurrency(ticker){
        require(ticker != "PIN", "Cannot make market order for PIN");
        require(tokens[ticker].tokenAddress != address(0), "Token not in exchange");
        if (side == Side.SELL) {
            require(traderBalances[msg.sender][ticker] >= amount, "insufficient funds to sell");
            uint tofill = amount;
            uint counter = 0;
            while (tofill > 0) {
                Order storage currOrder = orderBook[ticker][uint(Side.BUY)][counter];
                if (currOrder.amount > tofill) {
                    currOrder.amount = currOrder.amount.sub(tofill);
                    currOrder.filled = currOrder.filled.add(tofill);
                   
                    traderBalances[currOrder.trader][ticker] = traderBalances[currOrder.trader][ticker].add(tofill);
                    traderBalances[msg.sender][ticker] = traderBalances[msg.sender][ticker].sub(tofill);
                   
                    uint totalPrice = tofill.mul(currOrder.price);
                    traderBalances[currOrder.trader][PIN] = traderBalances[currOrder.trader][PIN].sub(totalPrice);
                    traderBalances[msg.sender][PIN] = traderBalances[msg.sender][PIN].add(totalPrice);
                   
                    tofill = 0;
                    emit NewTrade(nextTradeID, currOrder.id, ticker, currOrder.trader, msg.sender, tofill, currOrder.price, now);
                    nextTradeID++;
                }
                else {
                    traderBalances[currOrder.trader][ticker] = traderBalances[currOrder.trader][ticker].add(currOrder.amount);
                    traderBalances[msg.sender][ticker] = traderBalances[msg.sender][ticker].sub(currOrder.amount);
                   
                    uint totalPrice = currOrder.amount.mul(currOrder.price);
                    traderBalances[currOrder.trader][PIN] = traderBalances[currOrder.trader][PIN].sub(totalPrice);
                    traderBalances[msg.sender][PIN] = traderBalances[msg.sender][PIN].add(totalPrice);
                   
                    tofill = tofill.sub(currOrder.amount);
                    counter = counter.add(1);
                    emit NewTrade(nextTradeID, currOrder.id, ticker, currOrder.trader, msg.sender, currOrder.amount, currOrder.price, now);
                    nextTradeID++;
                }
            }
            for (uint i = 0; i < counter; i++) {
                if (i != orderBook[ticker][uint(Side.BUY)].length - 1 && orderBook[ticker][uint(Side.BUY)].length > 1) {
                    Order memory temp = orderBook[ticker][uint(Side.BUY)][orderBook[ticker][uint(Side.BUY)].length - 1];
                    orderBook[ticker][uint(Side.BUY)][i] = temp;
                }
                orderBook[ticker][uint(Side.BUY)].pop();
            }
            buysort(orderBook[ticker][uint(Side.BUY)]);
        } else {
            uint tofill = amount;
            uint counter = 0;
            while (tofill > 0) {
                Order storage currOrder = orderBook[ticker][uint(Side.SELL)][counter];
                if (currOrder.amount > tofill) {
                    currOrder.amount = currOrder.amount.sub(tofill);
                    currOrder.filled = currOrder.filled.add(tofill);
                   
                    traderBalances[currOrder.trader][ticker] = traderBalances[currOrder.trader][ticker].sub(tofill);
                    traderBalances[msg.sender][ticker] = traderBalances[msg.sender][ticker].add(tofill);
                   
                    uint totalPrice = tofill.mul(currOrder.price);
                    traderBalances[currOrder.trader][PIN] = traderBalances[currOrder.trader][PIN].add(totalPrice);
                    traderBalances[msg.sender][PIN] = traderBalances[msg.sender][PIN].sub(totalPrice);
                   
                    tofill = 0;
                    emit NewTrade(nextTradeID, currOrder.id, ticker, currOrder.trader, msg.sender, tofill, currOrder.price, now);
                    nextTradeID++;
                }
                else {
                    traderBalances[currOrder.trader][ticker] = traderBalances[currOrder.trader][ticker].sub(currOrder.amount);
                    traderBalances[msg.sender][ticker] = traderBalances[msg.sender][ticker].add(currOrder.amount);
                   
                    uint totalPrice = currOrder.amount.mul(currOrder.price);
                    traderBalances[currOrder.trader][PIN] = traderBalances[currOrder.trader][PIN].add(totalPrice);
                    traderBalances[msg.sender][PIN] = traderBalances[msg.sender][PIN].sub(totalPrice);
                   
                    tofill = tofill.sub(currOrder.amount);
                    counter = counter.add(1);
                    emit NewTrade(nextTradeID, currOrder.id, ticker, currOrder.trader, msg.sender, currOrder.amount, currOrder.price, now);
                    nextTradeID++;
                }
            }
           
            for (uint i = 0; i < counter; i++) {
                if (i != orderBook[ticker][uint(Side.SELL)].length - 1 && orderBook[ticker][uint(Side.SELL)].length > 1) {
                    Order memory temp = orderBook[ticker][uint(Side.SELL)][orderBook[ticker][uint(Side.SELL)].length - 1];
                    orderBook[ticker][uint(Side.SELL)][i] = temp;
                }
                orderBook[ticker][uint(Side.SELL)].pop();
            }
            sellsort(orderBook[ticker][uint(Side.SELL)]);
        }
    }


    //todo: add modifiers for methods as detailed in handout
    modifier tokenValid(bytes32 tk) {
        require(tokens[tk].tokenAddress != address(0), "tokenValid");
        _;
    }
    modifier checkCurrency(bytes32 tk) {
        require(tk != 'PIN', "checkCurrency");
        // how do I know if it's pine or not?
        _;
    }
}