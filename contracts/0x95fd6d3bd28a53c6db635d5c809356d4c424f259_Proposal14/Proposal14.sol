/**
 *Submitted for verification at Etherscan.io on 2022-10-05
*/

pragma solidity 0.6.7;

abstract contract Setter {
    function changePriceSource(address) external virtual;
    function removeAuthorization(address) external virtual;
    function modifyParameters(bytes32, address) external virtual;
}

contract Proposal14 {
    Setter public constant FEED_SECURITY_MODULE_ETH = Setter(0xD4A0E3EC2A937E7CCa4A192756a8439A8BF4bA91);
    Setter public constant DEBT_FLOOR_ADJUSTER_OVERLAY = Setter(0xC6141Cbe06c4f0FA296C23308fDac9Da9bb7777a);
    Setter public constant GEB_FIXED_REWARDS_ADJUSTER = Setter(0xE64575f62d4802C432E2bD9c1b6692A8bACbDFB9);
    Setter public constant GEB_MINMAX_REWARDS_ADJUSTER = Setter(0x86EBA7b7dAaFEC537A2357f8A3a46026AF5Cb7bA);
    address public constant GEB_PAUSE_PROXY = 0xa57A4e6170930ac547C147CdF26aE4682FA8262E;
    address public constant ETH_ORACLE_OVERLAY = 0xBf26309B0BA639ABE651dd1e1042Eb3C57c3e100;

    function execute() public {
        FEED_SECURITY_MODULE_ETH.changePriceSource(ETH_ORACLE_OVERLAY);
        FEED_SECURITY_MODULE_ETH.removeAuthorization(GEB_PAUSE_PROXY);
        DEBT_FLOOR_ADJUSTER_OVERLAY.modifyParameters("ethPriceOracle", ETH_ORACLE_OVERLAY);
        GEB_FIXED_REWARDS_ADJUSTER.modifyParameters("ethPriceOracle", ETH_ORACLE_OVERLAY);
        GEB_MINMAX_REWARDS_ADJUSTER.modifyParameters("ethPriceOracle", ETH_ORACLE_OVERLAY);
    }
}