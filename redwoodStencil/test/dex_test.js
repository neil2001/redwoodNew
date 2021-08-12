const { expectRevert } = require('@openzeppelin/test-helpers');
const Pin = artifacts.require('dummy/Pin.sol');
const Zrx = artifacts.require('dummy/Zrx.sol');
const Exc = artifacts.require('Exc.sol');

const SIDE = {
    BUY: 0,
    SELL: 1
};


contract('Exc', (accounts) => {
    let pin, zrx, exc;
    const [traderA, traderB] = [accounts[1], accounts[2]];
    const [PIN, ZRX] = ['PIN', 'ZRX']
        .map(ticker => web3.utils.fromAscii(ticker));

    beforeEach(async() => {
        ([pin, zrx] = await Promise.all([
            Pin.new(),
            Zrx.new()
        ]));
        exc = await Exc.new();
    });
    
    it('test addToken: adding one token', async () => {
        await exc.addToken(PIN, pin.address);
        let tokens = await exc.getTokens();
        assert(tokens.length, 1);
        // await exc.addToken(ZRX, zrx.address);
        // let tokenUpdated = await exc.getTokens();
        // assert(tokensUpdated.length, 2);
    });
    
    it('test addToken: adding one token, then another', async () => {
        await exc.addToken(PIN, pin.address);
        await exc.addToken(ZRX, zrx.address);
        let tokens = await exc.getTokens();
        assert(tokens.length, 2);
    });
    
    it('test deposit: deposit one token', async () => {
        await exc.addToken(PIN, pin.address);
        await pin.mint(traderA, 100);
        await pin.approve(exc.address, 100, {from: traderA});
        await exc.deposit(100, PIN, {from: traderA});
        const newPine = await exc.traderBalances.call(traderA, PIN);
        assert.equal(parseInt(newPine), 100);
    });
    
    it('test deposit: deposit multiple tokens', async () => {
        await exc.addToken(PIN, pin.address);
        await exc.addToken(ZRX, zrx.address);
        
        await pin.mint(traderA, 100);
        await pin.approve(exc.address, 100, {from: traderA});
        await exc.deposit(100, PIN, {from: traderA});
        
        await zrx.mint(traderB, 100);
        await zrx.approve(exc.address, 100, {from: traderB});
        await exc.deposit(100, ZRX, {from: traderB});
        
        const pineAmount = await exc.traderBalances.call(traderA, PIN);
        const zrxAmount = await exc.traderBalances.call(traderB, ZRX);
        
        assert.equal(parseInt(pineAmount), 100);
        assert.equal(parseInt(zrxAmount), 100);
    });
    
    it('test withdraw: withdraw single token', async () => {
        await exc.addToken(PIN, pin.address);
        await pin.mint(traderA, 100);
        await pin.approve(exc.address, 100, {from: traderA});
        await exc.deposit(100, PIN, {from: traderA});
        await exc.withdraw(30, PIN, {from: traderA});
        const pineAmount = await exc.traderBalances.call(traderA, PIN);
        assert.equal(parseInt(pineAmount), 70);
    });
    
    it('test withdraw: withdraw multiple token', async () => {
        await exc.addToken(PIN, pin.address);
        await exc.addToken(ZRX, zrx.address);
        
        await pin.mint(traderA, 100);
        await pin.approve(exc.address, 100, {from: traderA});
        await exc.deposit(100, PIN, {from: traderA});
        
        await zrx.mint(traderB, 100);
        await zrx.approve(exc.address, 100, {from: traderB});
        await exc.deposit(100, ZRX, {from: traderB});
        
        await exc.withdraw(30, PIN, {from: traderA});
        await exc.withdraw(50, ZRX, {from: traderB});
        
        const pineAmount = await exc.traderBalances.call(traderA, PIN);
        const zrxAmount = await exc.traderBalances.call(traderB, ZRX);
        assert.equal(parseInt(pineAmount), 70);
        assert.equal(parseInt(zrxAmount), 50);
        
        
    });
    
    it('test makeLimitOrder: make one limit order', async () => {
        await exc.addToken(PIN, pin.address);
        await exc.addToken(ZRX, zrx.address);
        await pin.mint(traderA, 1000);
        await pin.approve(exc.address, 1000, {from: traderA});
        await exc.deposit(1000, PIN, {from: traderA});
        await exc.makeLimitOrder(ZRX, 10, 10, 0, {from: traderA});
        
        const ordersList = await exc.getOrders(ZRX, 0);
        assert.equal(ordersList.length, 1);
        assert.equal(ordersList[0].amount, 10);
    });
    
    it('test deleteLimitOrder: make a limit order and delete', async () => {
        await exc.addToken(PIN, pin.address);
        await exc.addToken(ZRX, zrx.address);
        await pin.mint(traderA, 1000);
        await pin.approve(exc.address, 1000, {from: traderA});
        await exc.deposit(1000, PIN, {from: traderA});
        await exc.makeLimitOrder(ZRX, 10, 10, 0, {from: traderA});
        await exc.deleteLimitOrder(0, ZRX, 0, {from: traderA});
        
        const ordersList = await exc.getOrders(ZRX, 0);
        assert.equal(ordersList.length, 0);
    });
    
    it('test makeLimitOrder: make multiple limit orders', async () => {
        await exc.addToken(PIN, pin.address);
        await exc.addToken(ZRX, zrx.address);
        
        await pin.mint(traderA, 1000);
        await pin.approve(exc.address, 1000, {from: traderA});
        await exc.deposit(1000, PIN, {from: traderA});
        
        await pin.mint(traderB, 1000);
        await pin.approve(exc.address, 1000, {from: traderB});
        await exc.deposit(1000, PIN, {from: traderB});
        
        await exc.makeLimitOrder(ZRX, 10, 10, 0, {from: traderA});
        await exc.makeLimitOrder(ZRX, 10, 10, 0, {from: traderB});
        
        const ordersList = await exc.getOrders(ZRX, 0);
        assert.equal(ordersList.length, 2);
    });
    
    it('test makeLimitOrder and deleteLimitOrder: make multiple limit orders then delete one', async () => {
        await exc.addToken(PIN, pin.address);
        await exc.addToken(ZRX, zrx.address);
        
        await pin.mint(traderA, 1000);
        await pin.approve(exc.address, 1000, {from: traderA});
        await exc.deposit(1000, PIN, {from: traderA});
        
        await pin.mint(traderB, 1000);
        await pin.approve(exc.address, 1000, {from: traderB});
        await exc.deposit(1000, PIN, {from: traderB});
        
        await exc.makeLimitOrder(ZRX, 10, 10, 0, {from: traderA});
        await exc.makeLimitOrder(ZRX, 5, 10, 0, {from: traderB});
        
        await exc.deleteLimitOrder(0, ZRX, 0, {from: traderA});
        
        const ordersList = await exc.getOrders(ZRX, 0);
        assert.equal(ordersList.length, 1);
        assert.equal(ordersList[0].amount, 5);
    });
    
    it('test make/deleteLimitOrder exceptions', async () => {
        await exc.addToken(PIN, pin.address);
        await exc.addToken(ZRX, zrx.address);
        await expectRevert(exc.makeLimitOrder(ZRX, 1, 1, 0, {from: traderA}), 'side = buy, balance too low');
        
        await pin.mint(traderA, 1000);
        await pin.approve(exc.address, 1000, {from: traderA});
        await exc.deposit(1000, PIN, {from: traderA});
        
        // await pin.mint(traderB, 1000);
        // await pin.approve(exc.address, 1000, {from: traderB});
        // await exc.deposit(1000, PIN, {from: traderB});
        
        await exc.makeLimitOrder(ZRX, 10, 10, 0, {from: traderA});
        
        await expectRevert(exc.deleteLimitOrder(0, ZRX, 0, {from: traderB}), 'deleter was not maker');
    });
   
    it('test makeMarketOrder: fulfilled by one', async () => {
        await exc.addToken(PIN, pin.address);
        await exc.addToken(ZRX, zrx.address);
        
        await pin.mint(traderA, 1000);
        await pin.approve(exc.address, 1000, {from: traderA});
        await exc.deposit(1000, PIN, {from: traderA});
        await exc.makeLimitOrder(ZRX, 10, 10, 0, {from: traderA});

        await zrx.mint(traderB, 1000);
        await zrx.approve(exc.address, 1000, {from: traderB});
        await exc.deposit(1000, ZRX, {from: traderB});
        await exc.makeMarketOrder(ZRX, 10, 1, {from: traderB});

        const traderAPine = await exc.traderBalances.call(traderA, PIN);
        const traderAZRX = await exc.traderBalances.call(traderA, ZRX);
        const traderBZRX = await exc.traderBalances.call(traderB, ZRX);
        
        assert.equal(traderAPine, 900);
        assert.equal(traderAZRX, 10);
        assert.equal(traderBZRX, 990);
    });
    
    it('test makeMarketOrder: fulfilled by several', async () => {
        await exc.addToken(PIN, pin.address);
        await exc.addToken(ZRX, zrx.address);
        
        await pin.mint(traderA, 9000);
        await pin.approve(exc.address, 9000, {from: traderA});
        await exc.deposit(9000, PIN, {from: traderA});
        await exc.makeLimitOrder(ZRX, 50, 10, 0, {from: traderA});
        await exc.makeLimitOrder(ZRX, 100, 10, 0, {from: traderA});
        await exc.makeLimitOrder(ZRX, 50, 10, 0, {from: traderA});
        
        await zrx.mint(traderB, 9000);
        await zrx.approve(exc.address, 9000, {from: traderB});
        await exc.deposit(9000, ZRX, {from: traderB});
        await exc.makeMarketOrder(ZRX, 200, 1, {from: traderB});
        
        const existingOrders = await exc.getOrders(ZRX, 0);
        assert.equal(existingOrders.length, 0);
        
        const traderAPine = await exc.traderBalances.call(traderA, PIN);
        const traderAZRX = await exc.traderBalances.call(traderA, ZRX);
        const traderBZRX = await exc.traderBalances.call(traderB, ZRX);
        
        assert.equal(traderAPine, 7000);
        assert.equal(traderAZRX, 200);
        assert.equal(traderBZRX, 8800);
    });
   
});