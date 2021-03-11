const ERC20 = artifacts.require("ERC20");

module.exports = function (deployer, network, accounts) {
    var testLP3;
    deployer.deploy(ERC20, "test FMP/HUSD lp", "LP3", 18, "100000000000000000000000000").then(function (ins) { testLP3 = ins; });
};