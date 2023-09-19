// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

import {ERC20PermitSignature, PermitHelper} from "@tempusfinance/tempus-utils/contracts/utils/PermitHelper.sol";
import {SafeERC20} from "openzeppelin/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "openzeppelin/token/ERC20/IERC20.sol";
import {ERC4626} from "openzeppelin/token/ERC20/extensions/ERC4626.sol";
import {ERC20} from "openzeppelin/token/ERC20/ERC20.sol";
import {Ownable2Step} from "openzeppelin/access/Ownable2Step.sol";
import {Math} from "openzeppelin/utils/math/Math.sol";

/**
 * @title Fixed Income ERC4626 Capped
 * @dev This contract extends the ERC4626 with the following added features:
 * 1) The vault interest is fixed, and set by the contract owner. Interest is distributed until
 *    the configured `vestingPeriodFinish`, or until the contract runs out of tokens to distribute.
 * 2) Total assets cap functionality.
 */
contract FixedIncomeERC4626Capped is Ownable2Step, ERC4626 {
    using SafeERC20 for IERC20;

    /// @dev Thrown when the total supply is zero a `updateEmissionParams` call.
    error ZeroSupply();

    /// @dev Thrown when there's an attempt to recover tokens that are still pledged or locked.
    error CannotRecoverPledgedTokens();

    /// @dev Emitted when tokens are successfully recovered.
    event Recovered(address token, uint256 amount);

    /// @dev Emitted when issuance and vestingPeriod parameters are updated.
    event EmissionParamsUpdated(uint256 issuanceRate, uint256 vestingPeriodFinish);

    /// @dev Emitted on every `totalAssetsStored` update.
    event TotalAssetsStoredUpdated(uint256 value);

    uint256 public cap;
    uint256 public totalAssetsStored;
    uint256 public issuanceRate; // asset/second, for each deposited token
    uint256 public lastUpdated; // last timestamp of when totalAssetsStored last updated.
    uint256 public vestingPeriodFinish; // Timestamp when current vesting schedule ends.

    constructor(string memory name_, string memory symbol_, IERC20 asset_, uint256 cap_)
        ERC20(name_, symbol_)
        ERC4626(asset_)
    {
        cap = cap_;
    }

    function setCap(uint256 cap_) external onlyOwner {
        cap = cap_;
    }

    function depositWithPermit(uint256 assets, address receiver, ERC20PermitSignature calldata permitSignature)
        public
        returns (uint256)
    {
        if (address(permitSignature.token) == asset()) {
            PermitHelper.applyPermit(permitSignature, msg.sender, address(this));
        }

        return ERC4626.deposit(assets, receiver);
    }

    function mintWithPermit(uint256 shares, address receiver, ERC20PermitSignature calldata permitSignature)
        public
        returns (uint256)
    {
        if (address(permitSignature.token) == asset()) {
            PermitHelper.applyPermit(permitSignature, msg.sender, address(this));
        }

        return ERC4626.mint(shares, receiver);
    }

    function _deposit(address caller, address receiver, uint256 assets, uint256 shares) internal override {
        _setTotalAssetsStored(totalAssets() + assets);
        ERC4626._deposit(caller, receiver, assets, shares);
    }

    function _withdraw(address caller, address receiver, address owner, uint256 assets, uint256 shares)
        internal
        override
    {
        _setTotalAssetsStored(totalAssets() - assets);
        ERC4626._withdraw(caller, receiver, owner, assets, shares);
    }

    function updateEmissionParams(uint256 vestingPeriod_, uint256 issuanceRate_) external onlyOwner {
        if (totalSupply() == 0) {
            revert ZeroSupply();
        }

        _setTotalAssetsStored(totalAssets());
        issuanceRate = issuanceRate_;
        vestingPeriodFinish = block.timestamp + vestingPeriod_;

        emit EmissionParamsUpdated(issuanceRate, vestingPeriodFinish);
    }

    function recoverERC20(address tokenAddress, uint256 tokenAmount) external onlyOwner {
        if (tokenAddress == asset()) {
            _setTotalAssetsStored(totalAssets());
            if (tokenAmount > IERC20(asset()).balanceOf(address(this)) - totalAssetsStored) {
                revert CannotRecoverPledgedTokens();
            }
        }

        IERC20(tokenAddress).safeTransfer(owner(), tokenAmount);
        emit Recovered(tokenAddress, tokenAmount);
    }

    function totalAssets() public view virtual override returns (uint256) {
        uint256 issuanceRate_ = issuanceRate;
        uint256 totalAssetsStored_ = totalAssetsStored;

        if (issuanceRate_ == 0) return totalAssetsStored_;

        uint256 vestingPeriodFinish_ = vestingPeriodFinish;
        uint256 lastUpdated_ = lastUpdated;

        uint256 vestingTimePassed = block.timestamp > vestingPeriodFinish_
            ? vestingPeriodFinish_ - lastUpdated_
            : block.timestamp - lastUpdated_;

        uint256 totalAssets_ = ((issuanceRate_ * vestingTimePassed * totalAssetsStored_) / (1e18)) + totalAssetsStored_;

        /// If the acrrued interest exceeds the contract balance, hard-stop interest accrual.
        return Math.min(totalAssets_, IERC20(asset()).balanceOf(address(this)));
    }

    function maxDeposit(address) public view override returns (uint256) {
        uint256 totalAssets_ = totalAssets();
        return totalAssets_ >= cap ? 0 : cap - totalAssets_;
    }

    function maxMint(address) public view override returns (uint256) {
        return convertToShares(maxDeposit(address(0)));
    }
    
    function _setTotalAssetsStored(uint256 value) private {
        totalAssetsStored = value;
        lastUpdated = block.timestamp;

        emit TotalAssetsStoredUpdated(value);
    }
}