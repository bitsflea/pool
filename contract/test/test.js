const StakingPool = artifacts.require("StakingPool");
const ERC20 = artifacts.require("ERC20");

contract("pool test", async accounts => {
    var fmp;
    var lp1;
    var lp2;
    var pool;
    it("add lp pool", async () => {
        // 每执行一次必须换地址
        fmp = await ERC20.at("0xcBAA3f46E10BCdfBE0A4Cc0F7928c4eaecBD06e0");
        lp1 = await ERC20.at("0x9b666b2887424FD652109b63EA6e5a566ad7e9B0");
        lp2 = await ERC20.at("0xeC2AFA5a947a398a90bf0a6e6F57Ad568554ebD3");
        pool = await StakingPool.deployed();
        await fmp.mint(pool.address, "30000000000000000000000");
        await pool.addPool(lp1.address, "1614249667", "259200", "10000000000000000000000");
        await pool.addPool(lp2.address, "1614249667", "259200", "20000000000000000000000");

        let info = await pool.getMineInfo(lp1.address, accounts[0]);
        assert.equal(info['0'].valueOf(), 1614249667);
    });

    it("staking", async () => {
        let acc = accounts[4];
        await lp1.mint(acc, "10000000000000000000000");
        let balance = await lp1.balanceOf(acc);
        assert.equal(balance.toString(), "10000000000000000000000");

        await lp1.approve(pool.address, "10000000000000000000000", { "from": acc });
        let allow = await lp1.allowance(acc, pool.address);
        assert.equal(allow.toString(), "10000000000000000000000");

        await pool.staking(lp1.address, "5000000000000000000000", { "from": acc });
        let info = await pool.getMineInfo(lp1.address, acc);
        assert.equal(info['5'].toString(), "5000000000000000000000");
    });

});