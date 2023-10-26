// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {AddressUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import {IERC20, IERC20Metadata, ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {SafeERC20Upgradeable, IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import {SafeCastUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/math/SafeCastUpgradeable.sol";
import {IAlloyxVault} from "../../external/alloyx/IAlloyxVault.sol";
import {IDepository} from "../IDepository.sol";
import {IUXDController} from "../../core/IUXDController.sol";
import {MathLib} from "../../libraries/MathLib.sol";
import {AlloyxDepositoryStorage} from "./AlloyxDepositoryStorage.sol";

/// @title AlloyxDepository
/// @notice Manages interactions with Alloyx.
contract AlloyxDepository is
    UUPSUpgradeable,
    ReentrancyGuardUpgradeable,
    OwnableUpgradeable,
    AlloyxDepositoryStorage
{
    using MathLib for uint256;
    using AddressUpgradeable for address;
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using SafeERC20Upgradeable for ERC20;
    using SafeCastUpgradeable for uint256;
    using SafeCastUpgradeable for int256;

    error NoProfits(int256 pnl);
    error NotApproved(uint256 allowance, uint256 amount);
    error NotController(address caller);
    error NotContractAddress(address addr);
    error InvalidRedeemalbeAmount();
    error UnsupportedAsset(address asset);
    error RedeemableSoftCapHit(uint256 softcap, uint256 totalRedeemable);
    error TokenTransferFail(address token, address from, address to);

    ///////////////////////////////////////////////////////////////////
    ///                         Events
    ///////////////////////////////////////////////////////////////////
    event Deposited(
        address indexed caller,
        uint256 assets,
        uint256 redeemable,
        uint256 shares
    );
    event Withdrawn(
        address indexed caller,
        uint256 assets,
        uint256 redeemable,
        uint256 shares
    );
    event Redeemed(
        address indexed caller,
        uint256 assets,
        uint256 redeemable,
        uint256 shares
    );
    event RedeemableSoftCapUpdated(address indexed caller, uint256 newSoftCap);
    event ControllerSet(address indexed caller, address indexed controller);

    /// @notice Constructor
    /// @param _vault the address of the Alloyx vault
    /// @param _asset The asset to be deposited
    /// @param _controller the address of the UXDController
    function initialize(address _vault, address _asset, address _controller) external virtual initializer {
        __UUPSUpgradeable_init();
        __ReentrancyGuard_init();
        __Ownable_init();

        if (!_vault.isContract()) {
            revert NotContractAddress(_vault);
        }
        if (!_controller.isContract()) {
            revert NotContractAddress(_controller);
        }
        vault = IAlloyxVault(_vault);
        controller = IUXDController(_controller);
        assetToken = _asset;
        redeemable = address(controller.redeemable());
    }

    /// @dev restirct access to controller
    modifier onlyController() {
        if (msg.sender != address(controller)) {
            revert NotController(msg.sender);
        }
        _;
    }

    /// @notice Sets the redeemable soft cap
    /// @dev Can only be called by owner
    /// @param softCap The new redeemable soft cap
    function setRedeemableSoftCap(uint256 softCap) external onlyOwner {
        redeemableSoftCap = softCap;
        emit RedeemableSoftCapUpdated(msg.sender, softCap);
    }

    function setController(address _controller) external onlyOwner {
        controller = IUXDController(_controller);
        emit ControllerSet(msg.sender, _controller);
    }

    /// @notice Deposits assets
    /// @param assetAmount The amount of assets to deposit in assetToken.decimals()
    /// @return redeemableAmount the corresponding amount of redeemable for asset deposited
    function deposit(address asset, uint256 assetAmount)
        external
        onlyController
        returns (uint256)
    {
        if (asset != assetToken) {
            revert UnsupportedAsset(asset);
        }
        netAssetDeposits += assetAmount;
        IERC20(assetToken).approve(address(vault), assetAmount);
        uint256 sharesBefore = vault.vaultToken().balanceOf(address(this));
        vault.deposit(assetAmount);
        uint256 sharesAfter = vault.vaultToken().balanceOf(address(this));
        uint256 redeemableAmount = _assetsToRedeemable(assetAmount);
        redeemableUnderManagement += redeemableAmount;
        _checkSoftCap();
        emit Deposited(msg.sender, assetAmount, redeemableAmount, sharesAfter - sharesBefore);
        return redeemableAmount;
    }

    /// @notice Redeem a given amount.
    /// @param redeemableAmount The amount to redeem in redeemable.decimals()
    /// @return assetAmount The asset amount withdrawn by this redemption
    function redeem(address asset, uint256 redeemableAmount)
        external
        onlyController
        returns (uint256)
    {
        if (asset != assetToken) {
            revert UnsupportedAsset(asset);
        }
        // TODO: convert to shareAmount
        uint256 assetAmount = _redeemableToAssets(redeemableAmount); 
        if (assetAmount == 0) {
           revert InvalidRedeemalbeAmount(); 
        }
        redeemableUnderManagement -= redeemableAmount;
        netAssetDeposits -= assetAmount;
        uint256 assetBalance1 = IERC20Upgradeable(assetToken).balanceOf(address(this));
        uint256 tokenAmount = vault.usdcToAlloyxDura(assetAmount);
        vault.withdraw(tokenAmount);
        uint256 assetBalance2 = IERC20Upgradeable(assetToken).balanceOf(address(this));
        uint256 assetReceived = assetBalance2 - assetBalance1;

        _setControllerApproval(assetReceived);
        emit Withdrawn(msg.sender, assetAmount, redeemableAmount, assetReceived);
        return assetReceived;
    }

    /// @dev approves the controller to spend the given `amount` of asset.
    function _setControllerApproval(uint256 amount) private {
        // approve controller to spend asset amount received.
        IERC20(assetToken).approve(address(controller), 0);
        IERC20(assetToken).approve(address(controller), amount);
    }

    /// @dev returns assets deposited. IDepository required.
    function assetsDeposited() external view returns (uint256) {
        return netAssetDeposits;
    }

    /// @dev returns the shares currently owned by this depository
    function getDepositoryShares() public view returns (uint256) {
        return vault.vaultToken().balanceOf(address(this));
    }

    /// @dev returns the assets currently owned by this depository.
    function getDepositoryAssets() public view returns (uint256) {
        return vault.alloyxDuraToUsdc(getDepositoryShares());
    }

    /// @dev the difference between curent vault assets and amount deposited
    function getUnrealizedPnl() public view returns (int256) {
        uint256 depositoryAssets = getDepositoryAssets();
        if (netAssetDeposits > depositoryAssets) {
            return 0;
        }
        return depositoryAssets.toInt256() - netAssetDeposits.toInt256();
    }

    /// @dev Withdraw profits. Ensure redeemable is still fully backed by asset balance after this is run.
    /// TODO: Remove this function. Code profit access and use in contracts
    function withdrawProfits(address receiver) external onlyOwner nonReentrant {
        int256 pnl = getUnrealizedPnl();
        if (pnl <= 0) {
            revert NoProfits(pnl);
        }
        uint256 profits = pnl.toUint256();
        uint256 tokenAmount = vault.usdcToAlloyxDura(profits);
        uint256 assetBalanceBefore = vault.vaultToken().balanceOf(address(this));
        vault.withdraw(tokenAmount);
        uint256 assetBalanceAfter = vault.vaultToken().balanceOf(address(this));
        uint256 assetProfitReceived = assetBalanceAfter - assetBalanceBefore;
        IERC20Upgradeable(assetToken).safeTransfer(receiver, assetProfitReceived);
        realizedPnl += profits;
    }

    function supportedAssets() external override view returns (address[] memory) {
        address[] memory assetList = new address[](1);
        assetList[0] = assetToken;
        return assetList;
    }

    function _assetsToRedeemable(uint256 assetAmount)
        private
        view
        returns (uint256)
    {
        return
            assetAmount.fromDecimalToDecimal(
                IERC20Metadata(assetToken).decimals(),
                IERC20Metadata(redeemable).decimals()
            );
    }

    function _redeemableToAssets(uint256 redeemableAmount)
        private
        view
        returns (uint256)
    {
        return
            redeemableAmount.fromDecimalToDecimal(
                IERC20Metadata(redeemable).decimals(),
                IERC20Metadata(assetToken).decimals()
            );
    }

    function _checkSoftCap() private view {
        if (redeemableUnderManagement > redeemableSoftCap) {
            revert RedeemableSoftCapHit(
                redeemableSoftCap,
                redeemableUnderManagement
            );
        }
    }

    /// @notice Transfers contract ownership to a new address
    /// @dev This can only be called by the current owner.
    /// @param newOwner The address of the new owner.
    function transferOwnership(address newOwner)
        public
        override(IDepository, OwnableUpgradeable)
        onlyOwner
    {
        super.transferOwnership(newOwner);
    }

    ///////////////////////////////////////////////////////////////////////
    ///                         Upgrades
    ///////////////////////////////////////////////////////////////////////

    /// @dev Returns the current version of this contract
    // solhint-disable-next-line func-name-mixedcase
    function VERSION() external pure virtual returns (uint8) {
        return 3;
    }

    /// @dev called on upgrade. only owner can call upgrade function
    function _authorizeUpgrade(address)
        internal
        virtual
        override
        onlyOwner
    // solhint-disable-next-line no-empty-blocks
    {

    }
}