const { expectRevert } = require('@openzeppelin/test-helpers');
const Pin = artifacts.require('dummy/Pin.sol');
const Zrx = artifacts.require('dummy/Zrx.sol');
const Exc = artifacts.require('Exc.sol');
const Fac = artifacts.require('Factory.sol')
const Pool = artifacts.require('Pool.sol')
const SIDE = {
    BUY: 0,
    SELL: 1
};
contract('Pool', (accounts) => {
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
        fac = await Fac.new()
    });
    
    it('pool deposit test: single deposit', async () => {
        let event = await fac.createPair(
            pin.address,
            zrx.address,
            pin.address,
            exc.address,
            PIN,
            ZRX
        );
        let log = event.logs[0];
        let poolAd = log.args.pair;
        const pool = await Pool.at(poolAd);
        
        await pin.mint(traderA, 1000);
        await pin.approve(pool.address, 1000, {from: traderA});
        await zrx.mint(traderA, 1000);
        await zrx.approve(pool.address, 1000, {from: traderA});
        await pool.deposit(1000, 1000, {from: traderA});
        
        const poolPIN = await exc.traderBalances.call(pool.address, PIN);
        const poolZRX = await exc.traderBalances.call(pool.address, ZRX);
        assert.equal(poolPin,1000);
        assert.equal(poolZRX,1000);
        
        const newBuy = await exc.getOrders(ZRX, 0);
        const newSell = await exc.getOrders(ZRX, 1)
        assert.equal(newBuy.length, 1);
        assert.equal(newSell.length, 1);
    });
    
    it('pool deposit test: multiple deposit', async () => {
        let event = await fac.createPair(
            pin.address,
            zrx.address,
            pin.address,
            exc.address,
            PIN,
            ZRX
        );
        let log = event.logs[0];
        let poolAd = log.args.pair;
        const pool = await Pool.at(poolAd);
        
        await pin.mint(traderA, 1000);
        await pin.approve(pool.address, 1000, {from: traderA});
        await zrx.mint(traderA, 1000);
        await zrx.approve(pool.address, 1000, {from: traderA});
        await pool.deposit(100, 100, {from: traderA});
        await pool.deposit(200, 200, {from: traderA});
        await pool.deposit(300, 300, {from: traderA});
        await pool.deposit(400, 400, {from: traderA});
        
        const poolPIN = await exc.traderBalances.call(pool.address, PIN);
        const poolZRX = await exc.traderBalances.call(pool.address, ZRX);
        assert.equal(poolPin,1000);
        assert.equal(poolZRX,1000);
        
        const traderPIN = await exc.traderBalances.call(traderA, PIN);
        const traderZRX = await exc.traderBalances.call(traderA, ZRX);
        assert.equal(traderPIN,0);
        assert.equal(traderPIN,0);
        
        const newBuy = await exc.getOrders(ZRX, 0);
        const newSell = await exc.getOrders(ZRX, 1)
        assert.equal(newBuy.length, 4);
        assert.equal(newSell.length, 4);
    });
    
    it('pool withdraw test: withdraw once', async () => {
        let event = await fac.createPair(
            pin.address,
            zrx.address,
            pin.address,
            exc.address,
            PIN,
            ZRX
        );
        let log = event.logs[0];
        let poolAd = log.args.pair;
        const pool = await Pool.at(poolAd);
        
        await pin.mint(traderA, 1000);
        await pin.approve(pool.address, 1000, {from: traderA});
        await zrx.mint(traderA, 1000);
        await zrx.approve(pool.address, 1000, {from: traderA});
        await pool.deposit(500, 500, {from: traderA});
        
        await pool.withdraw(50,50, {from: traderA});
        
        const poolPIN = await exc.traderBalances.call(pool.address, PIN);
        const poolZRX = await exc.traderBalances.call(pool.address, ZRX);
        assert.equal(poolPin,500);
        assert.equal(poolZRX,500);
    });
    
    it('pool withdraw test: withdraw multiple times', async () => {
        let event = await fac.createPair(
            pin.address,
            zrx.address,
            pin.address,
            exc.address,
            PIN,
            ZRX
        );
        let log = event.logs[0];
        let poolAd = log.args.pair;
        const pool = await Pool.at(poolAd);
        
        await pin.mint(traderA, 1000);
        await pin.approve(pool.address, 1000, {from: traderA});
        await zrx.mint(traderA, 1000);
        await zrx.approve(pool.address, 1000, {from: traderA});
        await pool.deposit(500, 500, {from: traderA});
        
        await pool.withdraw(50,50, {from: traderA});
        await pool.withdraw(50,50, {from: traderA});
        await pool.withdraw(50,50, {from: traderA});
        await pool.withdraw(50,50, {from: traderA});
        
        const poolPIN = await exc.traderBalances.call(pool.address, PIN);
        const poolZRX = await exc.traderBalances.call(pool.address, ZRX);
        assert.equal(poolPin,300);
        assert.equal(poolZRX,300);
        
        const traderPIN = await exc.traderBalances.call(traderA, PIN);
        const traderZRX = await exc.traderBalances.call(traderA, ZRX);
        assert.equal(traderPIN,700);
        assert.equal(traderPIN,700);
    });
});