// SPDX-License-Identifier: Apache-2.0
// https://docs.soliditylang.org/en/v0.8.10/style-guide.html
pragma solidity 0.8.11;

import {MathUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";
import {ERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {SafeERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import {PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import {ImpactVaultManager} from "src/vaults/ImpactVaultManager.sol";

/**
 * @title ImpactVault
 * @author @douglasqian, @DaoDeCyrus
 * @notice This contract implements a new token vault standard inspired by
 *   ERC-4626. Key difference is that ImpactVault ERC20 tokens do not
 *   entitle depositors to a portion of the yield earned on the vault.
 *   Instead, shares of yield is tracked to mint a proportional amount of
 *   governance tokens to determine how the vault's yield will be deployed.
 *
 *   Note: this vault should always be initialized with an ERC20 token
 *   (ex: CELO) and a non-rebasing yield token (ex: stCELO).
 */
abstract contract ImpactVault is
    ERC20Upgradeable,
    PausableUpgradeable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable
{
    using MathUpgradeable for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    error NotYetImplemented();
    error ZeroDeposit();
    error ZeroWithdraw();

    event Deposit(
        uint256 _assetsDeposited,
        uint256 _sharesMinted,
        address _receiver
    );
    event WithdrawAsset(uint256 _amount, address _owner, address _receiver);
    event WithdrawYieldAsset(
        uint256 _amountYieldAsset,
        uint256 _amountAsset,
        address _owner,
        address _receiver
    );
    event TransferYieldToManager(
        address _owner,
        uint256 _amountYieldAsset,
        uint256 _amountCUSD
    );

    IERC20Upgradeable public asset;
    IERC20Upgradeable public yieldAsset;
    address public impactVaultManager;

    /**
     * @dev Data structure that allows us to keep track of how much yield
     * each depositor in the vault is generating. For every depositor, this
     * is updated on deposits & withdraws.
     *
     * yield{t, t-1} = total_value{t} - total_value{t-1}
     */
    struct YieldIndex {
        // Tracks the amount of yield assets held at last update.
        // This is important to track because yield generated is calculated
        // based on how much this share of the vault has appreciated.
        uint256 amountYieldAssetAtLastUpdate;
        // Tracks the total value of yield assets associated with a depositor
        // in the vault at last update. Denominated in "asset"
        uint256 totalAssetValueAtLastUpdate;
        // Tracks the total amount of yield accumulated into vault.
        // Denominated in "asset".
        uint256 accumulatedYield;
    }

    mapping(address => YieldIndex) public yieldIndexMap;

    /**
     * @dev Set the underlying asset contracts. Checks invariant:
     * convertToAsset(convertToYieldAsset(asset)) == asset
     */
    function __ImpactVault_init(
        IERC20Upgradeable _asset,
        IERC20Upgradeable _yieldAsset,
        address _impactVaultManager
    ) internal onlyInitializing {
        __ImpactVault_init_unchained(_asset, _yieldAsset, _impactVaultManager);
    }

    function __ImpactVault_init_unchained(
        IERC20Upgradeable _asset,
        IERC20Upgradeable _yieldAsset,
        address _impactVaultManager
    ) internal onlyInitializing {
        asset = _asset;
        yieldAsset = _yieldAsset;
        impactVaultManager = _impactVaultManager;
    }

    /**
     * @notice Returns total asset value of vault.
     */
    function totalAssets() public view virtual returns (uint256) {
        return
            asset.balanceOf(address(this)) +
            convertToAsset(yieldAsset.balanceOf(address(this)));
    }

    /**
     * DEPOSIT
     */

    /**
     * @notice After asset are deposited in the vault, we stake it in the
     * underlying staked asset and mint new vault tokens.
     */
    function deposit(uint256 _amount, address _receiver)
        public
        virtual
        whenNotPaused
        nonReentrant
    {
        if (_amount == 0) {
            revert ZeroDeposit();
        }
        // Using SafeERC20Upgradeable
        // slither-disable-next-line unchecked-transfer
        asset.transferFrom(_msgSender(), address(this), _amount);
        uint256 sharesToMint = _stake(_amount);
        _mint(_receiver, sharesToMint);

        emit Deposit(_amount, sharesToMint, _receiver);
    }

    /**
     * WITHDRAW
     */

    /**
     * @notice Withdraws underlying asset by converting equivalent value in
     * staked asset and transferring it to the receiver.
     * @dev Burn vault tokens before withdrawing.
     */
    function withdraw(
        uint256 _amount,
        address _receiver,
        address _owner
    ) public virtual whenNotPaused nonReentrant {
        // Capture assets associated with owner before burn.
        _beforeWithdraw(_amount, _owner);

        emit WithdrawAsset(_amount, _owner, _receiver);

        _withdraw(_receiver, _amount);
    }

    function withdrawAll(address _receiver, address _owner) external virtual {
        withdraw(balanceOf(_owner), _receiver, _owner);
    }

    /**
     * @notice Withdraws yield asset from owner balance to receiver.
     * @param _amountAsset Amount to withdraw, denominated in asset.
     */
    function withdrawYieldAsset(
        uint256 _amountAsset,
        address _receiver,
        address _owner
    ) public virtual whenNotPaused nonReentrant {
        // Capture assets associated with owner before burn.
        _beforeWithdraw(_amountAsset, _owner);
        uint256 amountYieldAssetToWithdraw = convertToYieldAsset(_amountAsset);

        emit WithdrawYieldAsset(
            amountYieldAssetToWithdraw,
            _amountAsset,
            _owner,
            _receiver
        );

        // slither-disable-next-line unchecked-transfer
        yieldAsset.transfer(_receiver, amountYieldAssetToWithdraw);
    }

    function withdrawAllYieldAsset(address _receiver, address _owner)
        external
        virtual
    {
        withdrawYieldAsset(balanceOf(_owner), _receiver, _owner);
    }

    /**
     * @notice Transfers yield associated with a given address to the
     * ImpactVaultManager and updates their yield index. This can only be
     * triggered on the vault manager by the owner of the underlying asset.
     * Returns the amount of yield assets withdrawn from the vault in USD.
     */
    function transferYieldToManager(address _address)
        external
        virtual
        whenNotPaused
        nonReentrant
        onlyVaultManager
        returns (uint256)
    {
        // Withdraw total yield value in USD to ImpactVaultManager
        uint256 amountToTransferAsset = getYield(_address);
        uint256 amountToTransferYieldAsset = convertToYieldAsset(
            amountToTransferAsset
        );
        uint256 amountToTransferUSD = convertToUSD(amountToTransferAsset);

        // Reset yield index
        YieldIndex storage yIndex = yieldIndexMap[_address];
        yIndex.accumulatedYield = 0;
        yIndex.amountYieldAssetAtLastUpdate = 0;
        yIndex.totalAssetValueAtLastUpdate = balanceOf(_address); // just assets

        emit TransferYieldToManager(
            _address,
            amountToTransferYieldAsset,
            amountToTransferUSD
        );

        // slither-disable-next-line unchecked-transfer
        yieldAsset.transfer(_msgSender(), amountToTransferYieldAsset);
        return amountToTransferUSD;
    }

    modifier onlyVaultManager() {
        require(_msgSender() == impactVaultManager);
        _;
    }

    /**
     * @dev Common hook called before all withdrawal flows.
     */
    function _beforeWithdraw(uint256 _amount, address _owner) internal virtual {
        if (_amount == 0) {
            revert ZeroWithdraw();
        }
        address caller = _msgSender();
        if (caller != _owner) {
            _spendAllowance(_owner, caller, _amount);
        }
        _burn(_owner, _amount);
    }

    /**
     * YIELD INDEX
     */

    /**
     * @notice Generic hook called on "mint", "burn", "transfer" and
     * for "transferFrom"  vault tokens.
     * @dev Important to update yield indices so that yield starts being
     * attributed to new "to" address. Ignores null address values
     * (from mint and burn).
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        if (from != address(0)) {
            _updateYieldIndexSinceLastUpdate(from, amount, false);
        }
        if (to != address(0)) {
            _updateYieldIndexSinceLastUpdate(to, amount, true);
        }
    }

    /**
     * @dev Updates the yield index for a given address on vault token balance
     * changes. Should only be called from "_afterTokenTransfer". Yield values
     * should not change before & after this (invariant).
     *
     * @param _address Address of the depositor
     * @param _amount Amount of asset being deposited/withdrawn
     * @param _isDeposit True if deposit otherwise withdraw
     */
    function _updateYieldIndexSinceLastUpdate(
        address _address,
        uint256 _amount,
        bool _isDeposit
    ) internal virtual {
        // Adjust the yield asset balance associated with this address.
        YieldIndex storage yIndex = yieldIndexMap[_address];

        // Update this first before making modifications
        yIndex.accumulatedYield = _calculateYield(yIndex);

        // caching here saves a load on line 301
        uint256 newAmount = yIndex.amountYieldAssetAtLastUpdate;
        unchecked {
            if (_isDeposit) {
                newAmount += convertToYieldAsset(_amount);
            } else {
                newAmount -= convertToYieldAsset(_amount);
            }
        }
        yIndex.amountYieldAssetAtLastUpdate = newAmount;
        // Update total value of yield asset (denominated in asset).
        yIndex.totalAssetValueAtLastUpdate = convertToAsset(newAmount);
    }

    /**
     * @notice Returns total yield generated on vault in the underlying asset.
     */
    function totalYield() public view virtual returns (uint256) {
        unchecked {
            return totalAssets() - totalSupply();
        }
    }

    function totalYieldUSD() public view virtual returns (uint256) {
        return convertToUSD(totalYield());
    }

    /**
     * @notice Returns yield in vault associated with a depositor in underlying asset.
     */
    function getYield(address _address) public view virtual returns (uint256) {
        YieldIndex storage yIndex = yieldIndexMap[_address];
        return _calculateYield(yIndex);
    }

    /*
     * @notice Returns yield in vault associated with a storage pointer to
     * a yield index entry.
     */
    function _calculateYield(YieldIndex storage _yIndex)
        internal
        view
        virtual
        returns (uint256)
    {
        unchecked {
            uint256 assetValueNow = convertToAsset(
                _yIndex.amountYieldAssetAtLastUpdate
            );
            uint256 yieldSinceLastUpdate = (assetValueNow -
                MathUpgradeable.min(
                    assetValueNow,
                    _yIndex.totalAssetValueAtLastUpdate
                ));
            return _yIndex.accumulatedYield + yieldSinceLastUpdate;
        }
    }

    /**
     * @notice Returns yield in vault associated with a depositor in USD.
     */
    function getYieldUSD(address _address)
        public
        view
        virtual
        returns (uint256)
    {
        return convertToUSD(getYield(_address));
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * TO BE IMPLEMENTED
     */

    /**
     * @notice Converts an amount of the underlying asset to its value in USD.
     */
    function convertToUSD(uint256 _assetAmount)
        public
        view
        virtual
        returns (uint256);

    /**
     * @dev Converts amount of yield asset to asset.
     */
    function convertToAsset(uint256 _amountYieldAsset)
        public
        view
        virtual
        returns (uint256);

    /**
     * @dev Converts amount of asset to yield asset.
     */
    function convertToYieldAsset(uint256 _amountAsset)
        public
        view
        virtual
        returns (uint256);

    /**
     * @dev Post-deposit hook to stake assets deposited and store in vault.
     */
    function _stake(uint256 _assets) internal virtual returns (uint256);

    /**
     * @dev Core logic for withdrawing from staked asset contract to
     * receive underlying asset that we send back to receiver.
     */
    function _withdraw(address _receiver, uint256 _amount) internal virtual;
}