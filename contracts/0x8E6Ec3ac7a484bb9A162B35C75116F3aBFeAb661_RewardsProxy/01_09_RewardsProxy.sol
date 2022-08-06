pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

interface ISTAKING {
    function claimRewardsAllFor(address user) external;
}

contract RewardsProxy is Context, Ownable {
    address private flowtysStaking;
    address private mlaStaking;
    address private morphysStaking;

    constructor () {}

    function setStakingAddress(address flowtys, address morphys, address mla) external onlyOwner {
        flowtysStaking = flowtys;
        morphysStaking = morphys;
        mlaStaking = mla;
    }

    function claimAll() external {
        ISTAKING(flowtysStaking).claimRewardsAllFor(msg.sender);
        ISTAKING(morphysStaking).claimRewardsAllFor(msg.sender);
        ISTAKING(mlaStaking).claimRewardsAllFor(msg.sender);
    }
}