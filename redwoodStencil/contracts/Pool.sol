pragma solidity 0.5.3;
import './Exc.sol';
// import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/solc-0.6/contracts/math/SafeMath.sol";
import '../contracts/libraries/math/SafeMath.sol';

contract Pool {
    using SafeMath for uint;

    /// @notice some parameters for the pool to function correctly
    address private factory;
    address private tokenP;
    address private token1;
    address private dex;
    bytes32 private tokenPT;
    bytes32 private token1T;
    uint private callTime;
    // todo: create wallet data structures
    mapping(address => mapping(bytes32 => uint)) public traderBalances;
    mapping(bytes32 => uint) public numToken;
    int lastTradeIDSELL;
    int lastTradeIDBUY;
    // todo: fill in the initialize method, which should simply set the parameters of the contract correctly. To be called once
    // upon deployment by the factory.
    function initialize(address _token0, address _token1, address _dex, uint whichP, bytes32 _tickerQ, bytes32 _tickerT)
    external {
        require(whichP == 1 || whichP == 2);
        require(callTime == 0);
        lastTradeIDSELL = -1;
        lastTradeIDBUY = -1;
        if (whichP == 1) {
            tokenP = _token0;
            token1 = _token1;
        } else {
            tokenP = _token1;
            token1 = _token0;
        }
        dex = _dex;
        tokenPT = _tickerQ;
        token1T = _tickerT;
        callTime.add(1);
    }

    // todo: implement wallet functionality and trading functionality
    function deposit(uint tokenAmount, uint pineAmount) external {
        require(SafeMath.mod(pineAmount, tokenAmount) == 0, 'Amount of token currency and quote currency must be proportional');
        uint amountPine = traderBalances[msg.sender][tokenPT];
        uint amountT = traderBalances[msg.sender][token1T];
        if (tokenAmount > 0) {
            IERC20(token1).transferFrom(msg.sender, address(this), tokenAmount);
            traderBalances[msg.sender][token1T];
            traderBalances[msg.sender][token1T] = traderBalances[msg.sender][token1T].add(tokenAmount);
            numToken[token1T] = numToken[token1T].add(tokenAmount);
        }
        if (pineAmount > 0) {
            IERC20(tokenP).transferFrom(msg.sender, address(this), pineAmount);
            amountPine = traderBalances[msg.sender][tokenPT];
            traderBalances[msg.sender][tokenPT] = traderBalances[msg.sender][tokenPT].add(pineAmount);
            numToken[tokenPT] = numToken[tokenPT].add(pineAmount);
        }
        
        if (lastTradeIDBUY != -1) {
            IExc(dex).deleteLimitOrder(uint(lastTradeIDBUY), token1T, IExc.Side.BUY);
            IExc(dex).withdraw(amountPine, tokenPT);
        }
        if (lastTradeIDSELL != -1) {
            IExc(dex).deleteLimitOrder(uint(lastTradeIDSELL), token1T, IExc.Side.SELL);
            IExc(dex).withdraw(amountT, token1T);
        }
        IERC20(token1).approve(dex, tokenAmount);
        IERC20(tokenP).approve(dex, pineAmount);

        IExc(dex).deposit(tokenAmount, token1T);
        IExc(dex).deposit(pineAmount, tokenPT);

        if (numToken[tokenPT] != 0) {
        lastTradeIDBUY = int(Exc(dex).nextOrderID());
        IExc(dex).makeLimitOrder(token1T, numToken[token1T], numToken[token1T].div(numToken[tokenPT]), IExc.Side.BUY);
        lastTradeIDSELL = int(Exc(dex).nextOrderID());
        IExc(dex).makeLimitOrder(token1T, numToken[token1T], numToken[token1T].div(numToken[tokenPT]), IExc.Side.SELL);
        }
    }

    function withdraw(uint tokenAmount, uint pineAmount) external {
        require(SafeMath.mod(pineAmount, tokenAmount) == 0, 'Amount of token currency and quote currency must be proportional');
        require(traderBalances[msg.sender][tokenPT] >= pineAmount);
        require(traderBalances[msg.sender][token1T] >= tokenAmount);
        
        uint amountPine = traderBalances[msg.sender][tokenPT];
        uint amountT = traderBalances[msg.sender][token1T];
        if (tokenAmount > 0) {
            IExc(dex).withdraw(amountT, token1T);
            IERC20(token1).transfer(msg.sender, tokenAmount);
        }
        if (pineAmount > 0) {
            IExc(dex).withdraw(amountPine, tokenPT);
            IERC20(tokenP).transfer(msg.sender, pineAmount);
        }

        traderBalances[msg.sender][tokenPT] = traderBalances[msg.sender][tokenPT].sub(pineAmount);
        traderBalances[msg.sender][token1T] = traderBalances[msg.sender][token1T].sub(tokenAmount);

        numToken[tokenPT] = numToken[tokenPT].sub(pineAmount);
        numToken[token1T] = numToken[token1T].sub(tokenAmount);
    }

    function testing(uint testMe) public view returns (uint) {
        if (testMe == 1) {
            return 5;
        } else {
            return 3;
        }
    }
}