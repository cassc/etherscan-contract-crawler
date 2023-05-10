// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "contracts/interfaces/IStakingNFT.sol";
import "contracts/libraries/lockup/AccessControlled.sol";
import "contracts/libraries/errors/LockupErrors.sol";
import "contracts/BonusPool.sol";
import "contracts/utils/EthSafeTransfer.sol";
import "contracts/utils/ERC20SafeTransfer.sol";

/**
 * @notice RewardPool holds all ether and ALCA that is part of reserved amount
 * of rewards on base positions.
 * @dev deployed by the lockup contract
 */
contract RewardPool is AccessControlled, EthSafeTransfer, ERC20SafeTransfer {
    address internal immutable _alca;
    address internal immutable _lockupContract;
    address internal immutable _bonusPool;
    uint256 internal _ethReserve;
    uint256 internal _tokenReserve;

    constructor(address alca_, address aliceNetFactory_, uint256 totalBonusAmount_) {
        _bonusPool = address(
            new BonusPool(aliceNetFactory_, msg.sender, address(this), totalBonusAmount_)
        );
        _lockupContract = msg.sender;
        _alca = alca_;
    }

    /// @notice function that receives ether and updates the token and ether reservers. The ALCA
    /// tokens has to be sent prior the call to this function.
    /// @dev can only be called by the bonusPool or lockup contracts
    /// @param numTokens_ number of ALCA tokens transferred to this contract before the call to this
    /// function
    function deposit(uint256 numTokens_) public payable onlyLockupOrBonus {
        _tokenReserve += numTokens_;
        _ethReserve += msg.value;
    }

    /// @notice function to pay a user after the lockup period. If a user is the last exiting the
    /// lockup it will receive any remainders kept by this contract by integer division errors.
    /// @dev only can be called by the lockup contract
    /// @param totalShares_ the total shares at the end of the lockup period
    /// @param userShares_ the user shares
    /// @param isLastPosition_ if the user is the last position exiting from the lockup contract
    function payout(
        uint256 totalShares_,
        uint256 userShares_,
        bool isLastPosition_
    ) public onlyLockup returns (uint256 proportionalEth, uint256 proportionalTokens) {
        if (totalShares_ == 0 || userShares_ > totalShares_) {
            revert LockupErrors.InvalidTotalSharesValue();
        }

        // last position gets any remainder left on this contract
        if (isLastPosition_) {
            proportionalEth = address(this).balance;
            proportionalTokens = IERC20(_alca).balanceOf(address(this));
        } else {
            (proportionalEth, proportionalTokens) = _computeProportions(totalShares_, userShares_);
        }
        _safeTransferERC20(IERC20Transferable(_alca), _lockupContract, proportionalTokens);
        _safeTransferEth(payable(_lockupContract), proportionalEth);
    }

    /// @notice gets the bonusPool contract address
    /// @return the bonusPool contract address
    function getBonusPoolAddress() public view returns (address) {
        return _getBonusPoolAddress();
    }

    /// @notice gets the lockup contract address
    /// @return the lockup contract address
    function getLockupContractAddress() public view returns (address) {
        return _getLockupContractAddress();
    }

    /// @notice get the ALCA reserve kept by this contract
    /// @return the ALCA reserve kept by this contract
    function getTokenReserve() public view returns (uint256) {
        return _tokenReserve;
    }

    /// @notice get the ether reserve kept by this contract
    /// @return the ether reserve kept by this contract
    function getEthReserve() public view returns (uint256) {
        return _ethReserve;
    }

    /// @notice estimates the final amount that a user will receive from the assets hold by this
    /// contract after end of the lockup period.
    /// @param totalShares_ total number of shares locked by the lockup contract
    /// @param userShares_ the user's shares
    /// @return proportionalEth The ether that a user will receive at the end of the lockup period
    /// @return proportionalTokens The ALCA that a user will receive at the end of the lockup period
    function estimateRewards(
        uint256 totalShares_,
        uint256 userShares_
    ) public view returns (uint256 proportionalEth, uint256 proportionalTokens) {
        if (totalShares_ == 0 || userShares_ > totalShares_) {
            revert LockupErrors.InvalidTotalSharesValue();
        }
        return _computeProportions(totalShares_, userShares_);
    }

    function _computeProportions(
        uint256 totalShares_,
        uint256 userShares_
    ) internal view returns (uint256 proportionalEth, uint256 proportionalTokens) {
        proportionalEth = (_ethReserve * userShares_) / totalShares_;
        proportionalTokens = (_tokenReserve * userShares_) / totalShares_;
    }

    function _getLockupContractAddress() internal view override returns (address) {
        return _lockupContract;
    }

    function _getBonusPoolAddress() internal view override returns (address) {
        return _bonusPool;
    }

    function _getRewardPoolAddress() internal view override returns (address) {
        return address(this);
    }
}