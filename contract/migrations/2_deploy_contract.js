const ERC20 = artifacts.require("ERC20");
const Manager = artifacts.require("Manager");
const StakingPool = artifacts.require("StakingPool");

module.exports = function (deployer, network, accounts) {
    var fmp;
    var testLP;
    var testLP2;
    var manager;
    var pools;
    deployer.deploy(ERC20, "bitsflea points", "FMP", 18, "1000000000000000000000000000").then(function (ins) { fmp = ins; });
    deployer.deploy(ERC20, "test FMP/USDT lp", "LP", 18, "100000000000000000000000000").then(function (ins) { testLP = ins; });
    deployer.deploy(ERC20, "test FMP/HUSD lp", "LP2", 18, "100000000000000000000000000").then(function (ins) { testLP2 = ins; });
    deployer.deploy(StakingPool).then(function (ins) { pools = ins; });

    deployer.deploy(Manager).then(function (ins) {
        manager = ins;
        manager.setMember("token", fmp.address);
        //cashier
        manager.setMember("cashier", accounts[3]);
        //Admin permission
        manager.setPermit(accounts[0], "Admin", true);

        //manager
        pools.setManager(manager.address);
    });
};
