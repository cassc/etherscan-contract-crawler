// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.6.12;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts/token/ERC20/SafeERC20.sol';
import '@openzeppelin/contracts/math/SafeMath.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import "./interfaces/IPool.sol";

/// @dev Ownable is used because solidity complain trying to deploy a contract whose code is too large when everything is added into Lord of Coin contract.
/// The only owner function is `init` which is to setup for the first time after deployment.
/// After init finished, owner will be renounced automatically. owner() function will return 0x0 address.
contract PoolTreasury is Ownable {

    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    /// @dev SDVD ETH pool address
    address public sdvdEthPool;

    /// @dev DVD pool address
    address public dvdPool;

    /// @dev SDVD contract address
    address public sdvd;

    /// @dev Distribute reward every 1 day to pool
    uint256 public releaseThreshold = 1 days;

    /// @dev Last release timestamp
    uint256 public releaseTime;

    /// @notice Swap reward distribution numerator when this time reached
    uint256 public numeratorSwapTime;

    /// @notice How long we should wait before swap numerator
    uint256 public NUMERATOR_SWAP_WAIT = 4383 days;  // 12 normal years + 3 leap days;

    constructor(address _sdvd) public {
        sdvd = _sdvd;
        releaseTime = block.timestamp;
        numeratorSwapTime = block.timestamp.add(NUMERATOR_SWAP_WAIT);
    }

    /* ========== Owner Only ========== */

    /// @notice Setup for the first time after deploy and renounce ownership immediately
    function init(address _sdvdEthPool, address _dvdPool) external onlyOwner {
        sdvdEthPool = _sdvdEthPool;
        dvdPool = _dvdPool;

        // Renounce ownership after init
        renounceOwnership();
    }

    /* ========== Mutative ========== */

    /// @notice Release pool treasury to pool and give rewards for farmers.
    function release() external {
        _release();
    }

    /* ========== Internal ========== */

    /// @notice Release pool treasury to pool
    function _release() internal {
        if (releaseTime.add(releaseThreshold) <= block.timestamp) {
            // Update release time
            releaseTime = block.timestamp;
            // Check balance
            uint256 balance = IERC20(sdvd).balanceOf(address(this));

            // If there is balance
            if (balance > 0) {
                // Get numerator
                uint256 numerator = block.timestamp <= numeratorSwapTime ? 4 : 6;

                // Distribute reward to pools
                uint dvdPoolReward = balance.div(10).mul(numerator);
                IERC20(sdvd).transfer(dvdPool, dvdPoolReward);
                IPool(dvdPool).distributeBonusRewards(dvdPoolReward);

                uint256 sdvdEthPoolReward = balance.sub(dvdPoolReward);
                IERC20(sdvd).transfer(sdvdEthPool, sdvdEthPoolReward);
                IPool(sdvdEthPool).distributeBonusRewards(sdvdEthPoolReward);
            }
        }
    }

}