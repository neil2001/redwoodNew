pragma solidity 0.5.3;

import './Exc.sol';
// import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/solc-0.6/contracts/math/SafeMath.sol";
import '../contracts/libraries/math/SafeMath.sol';

contract Pool {
    using SafeMath for uint;
    
    /// @notice some parameters for the pool to function correctly, feel free to add more as needed
    address private tokenP;
    address private token1;
    address private dex;
    bytes32 private tokenPT;
    bytes32 private token1T;
    
    // todo: create wallet data structures
    mapping(address => mapping(bytes32 => uint)) public traderBalances;
    uint private lastSellID;
    uint private lastBuyID;

    // todo: fill in the initialize method, which should simply set the parameters of the contract correctly. To be called once
    // upon deployment by the factory.
    function initialize(address _token0, address _token1, address _dex, uint whichP, bytes32 _tickerQ, bytes32 _tickerT)
    external {
        require(whichP == 1 || whichP == 2);
        dex = _dex;
        tokenPT = _tickerQ;
        token1T = _tickerT;
        lastSellID = 0;
        lastBuyID = 0;
        if (whichP == 1) {
            tokenP = _token0;
            token1 = _token1;
        } else {
            tokenP = _token1;
            token1 = _token0;
        }
        
    }
    
    function updatePrice() internal {
        
        uint256 pineAmount = IERC20(tokenP).balanceOf(address(this));
        uint256 tokenAmount = IERC20(token1).balanceOf(address(this));
        
        uint256 newPrice = SafeMath.div(pineAmount,tokenAmount);
        
        IExc(dex).deleteLimitOrder(lastSellID, token1T, IExc.Side.SELL);
        IExc(dex).deleteLimitOrder(lastBuyID, token1T, IExc.Side.BUY);
        
        IExc(dex).makeLimitOrder(token1T, tokenAmount, newPrice, IExc.Side.SELL);
        IExc(dex).makeLimitOrder(token1T, SafeMath.div(pineAmount, newPrice), newPrice, IExc.Side.BUY);
        
        // for (uint i = 0; i < orderBook[ticker][0].length; i++) {
        //     Order lmOrder = orderBook[ticker][0][i];
        //     Order newOrder = new Order(lmOrder.id, lmOrder.trader,lmOrder.side, lmOrder.ticker, lmOrder.amount, lmOrder.filled, newPrice, lmOrder.date);
        //     Exc(dex).deleteLimitOrder(lmOrder.id, lmOrder.ticker, lmOrder.side);
        //     Exc(dex).makeLimitOrder(newOrder.id, newOrder.amount, newOrder.price, newOrder.side);
        // }
        // for (uint i = 0; i < orderBook[ticker][1].length; i++) {
        //     Order lmOrder = orderBook[ticker][1][i];
        //     Order newOrder = new Order(lmOrder.id, lmOrder.trader,lmOrder.side, lmOrder.ticker, lmOrder.amount, lmOrder.filled, newPrice, lmOrder.date);
        //     Exc(dex).deleteLimitOrder(lmOrder.id, lmOrder.ticker, lmOrder.side);
        //     Exc(dex).makeLimitOrder(newOrder.id, newOrder.amount, newOrder.price, newOrder.side);
        // }
    }
    
    // todo: implement wallet functionality and trading functionality

    // todo: implement withdraw and deposit functions so that a single deposit and a single withdraw can unstake
    // both tokens at the same time
    function deposit(
        uint tokenAmount, 
        uint pineAmount)
        external {
            if (tokenAmount > 0) {
                IERC20(token1).transferFrom(msg.sender, address(this), tokenAmount);
                IExc(dex).deposit(tokenAmount, token1T);
                traderBalances[msg.sender][token1T] = traderBalances[msg.sender][token1T].add(tokenAmount);
                // totalToken += tokenAmount;
            }
            if (pineAmount > 0) { 
                IERC20(tokenP).transferFrom(msg.sender, address(this), pineAmount);
                IExc(dex).deposit(pineAmount, tokenPT);
                traderBalances[msg.sender][tokenPT] = traderBalances[msg.sender][tokenPT].add(pineAmount);
                // totalPine += pineAmount;
            }
            updatePrice();
        }


    function withdraw(
        uint tokenAmount, 
        uint pineAmount)
        external {
            require(traderBalances[msg.sender][tokenPT] >= pineAmount);
            require(traderBalances[msg.sender][token1T] >= tokenAmount);
            if (pineAmount > 0) {
                IExc(dex).withdraw(pineAmount, tokenPT);
                IERC20(tokenP).transfer(msg.sender, pineAmount);
                traderBalances[msg.sender][tokenPT] = traderBalances[msg.sender][tokenPT].sub(pineAmount);
            }
            if (tokenAmount > 0) {
                IExc(dex).withdraw(pineAmount, token1T);
                IERC20(token1).transfer(msg.sender, tokenAmount);
                traderBalances[msg.sender][token1T] = traderBalances[msg.sender][token1T].sub(tokenAmount);
            } 
            updatePrice();
        }

    function testing(uint testMe) public view returns (uint) {
        if (testMe == 1) {
            return 5;
        } else {
            return 3;
        }
    }
}
