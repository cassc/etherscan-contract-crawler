/**
 *Submitted for verification at Etherscan.io on 2023-06-30
*/

pragma solidity 0.8.13;

abstract contract Setter {
    function addAuthorization(address) public virtual;

    function setDelay(uint256) public virtual;
}

contract EnableGovernance {
    Setter public constant GEB_PAUSE =
        Setter(0x1c8F291c08aBad6e0a5a6a458614f471817004fd);
    Setter public constant GEB_REWARD_DRIPPER =
        Setter(0x41860aFb5cfCaa24213E1047E8285F8261Be6056);           
    Setter public constant GEB_LIQUIDITY_REWARDS =
        Setter(0x27c3017C4d126b105533c8D4AF53052dfb4aA7Fe);     
    address public constant GEB_MULTISIG = 0x4fC49D0979fa0Ea7cE33C5cb98af01BbA5C48C6F;

    function run() external {
        GEB_PAUSE.setDelay(12 hours); 
        GEB_REWARD_DRIPPER.addAuthorization(GEB_MULTISIG);
        GEB_LIQUIDITY_REWARDS.addAuthorization(GEB_MULTISIG);
    }
}