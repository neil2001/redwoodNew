pragma solidity 0.5.3;

import './Exc.sol';
// import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/solc-0.6/contracts/math/SafeMath.sol";
import '../contracts/libraries/math/SafeMath.sol';

contract Pool {
    
    /// @notice some parameters for the pool to function correctly, feel free to add more as needed
    address private tokenP;
    address private token1;
    address private dex;
    bytes32 private tokenPT;
    bytes32 private token1T;
    
    // todo: create wallet data structures
    

    // todo: fill in the initialize method, which should simply set the parameters of the contract correctly. To be called once
    // upon deployment by the factory.
    function initialize(address _token0, address _token1, address _dex, uint whichP, bytes32 _tickerQ, bytes32 _tickerT)
    external {
        require(whichP == 1 || whichP == 2);
        dex = _dex;
        tokenPT = _tickerQ;
        token1T = _tickerT;
        lastTradeID = -1;
        if (whichP = 1) {
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
        
        for (uint i = 0; i < orderBook[ticker][0].length; i++) {
            Order lmOrder = orderBook[ticker][0][i];
            Order newOrder = new Order(lmOrder.id, lmOrder.trader,lmOrder.side, lmOrder.ticker, lmOrder.amount, lmOrder.filled, newPrice, lmOrder.date);
            Exc(dex).deleteLimitOrder(lmOrder.id, lmOrder.ticker, lmOrder.side);
            Exc(dex).makeLimitOrder(newOrder.id, newOrder.amount, newOrder.price, newOrder.side);
        }
        for (uint i = 0; i < orderBook[ticker][1].length; i++) {
            Order lmOrder = orderBook[ticker][1][i];
            Order newOrder = new Order(lmOrder.id, lmOrder.trader,lmOrder.side, lmOrder.ticker, lmOrder.amount, lmOrder.filled, newPrice, lmOrder.date);
            Exc(dex).deleteLimitOrder(lmOrder.id, lmOrder.ticker, lmOrder.side);
            Exc(dex).makeLimitOrder(newOrder.id, newOrder.amount, newOrder.price, newOrder.side);
        }
    }
    
    // todo: implement wallet functionality and trading functionality

    // todo: implement withdraw and deposit functions so that a single deposit and a single withdraw can unstake
    // both tokens at the same time
    function deposit(
        uint amount,
        bytes32 ticker)
        external {
            require(balances[msg.sender][ticker] >= amount);
            //maybe wrong
            IERC20(tokens[ticker].tokenAddress).transferFrom(msg.sender, address(this), amount);
            balances[address(this)][ticker] += amount;
            balances[msg.sender][ticker] -= amount;
            updatePrice();
        }


    function withdraw(
        uint amount,
        bytes32 ticker)
        external {
            require(balances[address(this)][ticker] >= amount);
            IERC20(tokens[ticker].tokenAddress).transfer(msg.sender, amount);
            balances[address(this)][ticker] -= amount;
            balances[msg.sender][ticker] += amount;
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
}