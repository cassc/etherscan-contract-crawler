// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC4626.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "./AssetConverter.sol";
import "./SingleAssetVault.sol";
import "./ChainlinkPriceFeedAggregator.sol";
import "./libraries/PricesLibrary.sol";
import "./libraries/SafeAssetConverter.sol";
import "./libraries/Utils.sol";
import "contracts/interfaces/IRootVault.sol";
import "contracts/SuperAdminControl.sol";

// see https://apyflow.notion.site/Processes-of-ApyFlow-root-vault-84537a0a824043a2bfbcd84ab9ff0ea6
/// @author YLDR <[email protected]>
contract RootVault is IRootVault, ERC20("YLDR Root Vault", "YLDR"), SuperAdminControl {
    using SafeERC20 for IERC20;
    using SafeERC20 for IERC20Metadata;
    using EnumerableSet for EnumerableSet.AddressSet;
    using SafeAssetConverter for IAssetConverter;
    using PricesLibrary for ChainlinkPriceFeedAggregator;

    event VaultAdded(address vault);
    event VaultRemoved(address vault);

    event SetNewFeeDestination(address destination, uint256 block);

    event SetNewFeeValue(uint256 value, uint256 block);

    event FeeHarvested(uint256 fee, uint256 at);

    EnumerableSet.AddressSet private vaults;

    IAssetConverter public immutable assetConverter;
    ChainlinkPriceFeedAggregator public immutable pricesOracle;

    uint256 public lastPricePerToken;
    uint256 public allowedDeviationInPpm = 50;

    address public feeTreasury;
    uint256 public feeInPpm;

    IERC20Metadata private immutable _asset;

    mapping(address => bool) public allowedTokens;

    uint8 private _decimals;

    function decimals() public view override(ERC20, IERC20Metadata) returns (uint8) {
        return _decimals;
    }

    function asset() public view returns (address) {
        return address(_asset);
    }

    constructor(
        IAssetConverter _assetConverter,
        ChainlinkPriceFeedAggregator _pricesOracle,
        address _feeDestination,
        uint256 _feeValue,
        IERC20Metadata asset_
    ) {
        require(address(_assetConverter) != address(0), "Zero address provided");
        assetConverter = _assetConverter;
        feeTreasury = _feeDestination;
        feeInPpm = _feeValue;
        _asset = asset_;
        pricesOracle = _pricesOracle;
        _decimals = _asset.decimals();

        lastPricePerToken = 10 ** decimals();
    }

    function setNewFeeDestination(address newFeeDestination) external onlyOwner {
        feeTreasury = newFeeDestination;

        emit SetNewFeeDestination(newFeeDestination, block.number);
    }

    function setNewFeeValue(uint256 newFeeValue) external onlyOwner {
        require(newFeeValue < 1000, "fee value incorrect");
        recomputePricePerTokenAndHarvestFee();
        feeInPpm = newFeeValue;

        emit SetNewFeeValue(newFeeValue, block.number);
    }

    /**
     * Recomputes stored price per share, and, if it has increased,
     * 		withdraws part of profit as fee
     */
    function recomputePricePerTokenAndHarvestFee() public {
        uint256 _totalAssets = totalAssets();
        uint256 _totalSupply = totalSupply();

        uint256 newPricePerToken = pricePerToken();
        if (newPricePerToken > lastPricePerToken) {
            uint256 oldTotalAssets = (_totalSupply * lastPricePerToken) / 10 ** decimals();
            uint256 profit = _totalAssets - oldTotalAssets;
            uint256 fee = (profit * feeInPpm) / 1000;
            uint256 shares = _convertToShares(fee, _totalAssets - fee, _totalSupply);
            _mint(feeTreasury, shares);

            lastPricePerToken = pricePerToken();
            emit FeeHarvested(fee, block.timestamp);
        }
    }

    function totalAssets() public view returns (uint256 total) {
        total = _asset.balanceOf(address(this));
        uint256 valueInUSD;
        for (uint256 i = 0; i < vaults.length(); i++) {
            SingleAssetVault vault = SingleAssetVault(vaults.at(i));
            uint256 balanceAtVault = vault.balanceOf(address(this));
            if (balanceAtVault == 0) continue;
            address vaultAsset = vault.asset();
            valueInUSD += pricesOracle.convertToUSD(vaultAsset, vault.convertToAssets(balanceAtVault));
        }
        total += pricesOracle.convertFromUSD(valueInUSD, address(_asset));
    }

    function _convertToAssets(uint256 shares, uint256 totalAssets_, uint256 totalSupply_)
        internal
        pure
        returns (uint256 assets)
    {
        return ((totalSupply_ == 0) || (totalAssets_ == 0)) ? shares : (shares * totalAssets_) / totalSupply_;
    }

    function convertToAssets(uint256 shares) public view returns (uint256) {
        return _convertToAssets(shares, totalAssets(), totalSupply());
    }

    function _convertToShares(uint256 assets, uint256 totalAssets_, uint256 totalSupply_)
        internal
        pure
        returns (uint256 shares)
    {
        return ((totalSupply_ == 0) || (totalAssets_ == 0)) ? assets : (assets * totalSupply_) / totalAssets_;
    }

    function convertToShares(uint256 assets) public view returns (uint256 shares) {
        return _convertToShares(assets, totalAssets(), totalSupply());
    }

    function pricePerToken() public view returns (uint256) {
        return convertToAssets(10 ** decimals());
    }

    function feeInclusivePricePerToken() public view returns (uint256) {
        uint256 _pricePerToken = pricePerToken();
        if (_pricePerToken <= lastPricePerToken) {
            return _pricePerToken;
        } else {
            uint256 delta = _pricePerToken - lastPricePerToken;
            return lastPricePerToken + (delta * (1000 - feeInPpm)) / 1000;
        }
    }

    function addVault(address vault) external onlyOwner {
        require(!(vaults.contains(vault)), "The vault is already added");
        require(vault != address(0), "Zero address provided");

        vaults.add(vault);

        address token = SingleAssetVault(vault).asset();
        Utils.approveIfZeroAllowance(token, vault);
        Utils.approveIfZeroAllowance(token, address(assetConverter));

        emit VaultAdded(vault);
    }

    function removeVault(address vault) external onlyOwner {
        require(vaults.contains(vault), "The vault is not added");
        vaults.remove(vault);

        address token = SingleAssetVault(vault).asset();
        Utils.revokeAllowance(token, vault);

        emit VaultRemoved(vault);
    }

    function vaultsLength() external view returns (uint256) {
        return vaults.length();
    }

    function getVault(uint256 index) external view returns (address) {
        return vaults.at(index);
    }

    function totalPortfolioScore() public view returns (uint256 total) {
        for (uint256 i = 0; i < vaults.length(); i++) {
            total += SingleAssetVault(vaults.at(i)).totalPortfolioScore();
        }
    }

    function deposit(uint256 assets, address receiver) external returns (uint256 shares) {
        recomputePricePerTokenAndHarvestFee();

        uint256 deposited = 0;
        uint256 totalScore = totalPortfolioScore();
        _asset.safeTransferFrom(msg.sender, address(this), assets);

        uint256 leftAssets = assets;

        for (uint256 i = 0; i < vaults.length(); i++) {
            SingleAssetVault vault = SingleAssetVault(vaults.at(i));
            address vaultAsset = vault.asset();
            uint256 amountToSwap = assets * vault.totalPortfolioScore() / totalScore;
            uint256 amount = assetConverter.safeSwap(address(_asset), vaultAsset, amountToSwap);
            leftAssets -= amountToSwap;
            if (amount == 0) continue;
            uint256 _deposited = vault.convertToAssets(vault.deposit(amount, address(this)));
            deposited += pricesOracle.convert(vaultAsset, address(_asset), _deposited);
        }

        deposited += leftAssets;

        shares = _convertToShares(deposited, totalAssets() - deposited, totalSupply());
        _mint(receiver, shares);
    }

    /// @dev avoids stack too deep error
    struct RedeemCalculationsVars {
        uint256 dustToRedeem;
        uint256 valueInUSD;
        uint256 valueInAsset;
        uint256 processedPricePerToken;
        uint256 adjustedPricePerToken;
        uint256 fee;
    }

    function _redeem(uint256 shares) internal returns (uint256 assets) {
        if (shares == 0) {
            return 0;
        }

        RedeemCalculationsVars memory vars;

        vars.dustToRedeem = shares * _asset.balanceOf(address(this)) / totalSupply();
        assets = vars.dustToRedeem;

        for (uint256 i = 0; i < vaults.length(); i++) {
            SingleAssetVault vault = SingleAssetVault(vaults.at(i));
            uint256 amountToRedeem = (shares * vault.balanceOf(address(this))) / totalSupply();
            if (amountToRedeem == 0) continue;
            {
                address token = vault.asset();
                uint256 amount = vault.redeem(amountToRedeem, address(this), address(this));
                vars.valueInUSD += pricesOracle.convertToUSD(
                    token,
                    vault.convertToAssets(amountToRedeem) // this already includes harvested rewards
                );
                assets += assetConverter.safeSwap(token, address(_asset), amount);
            }
        }

        vars.valueInAsset = pricesOracle.convertFromUSD(vars.valueInUSD, address(_asset)) + vars.dustToRedeem;
        vars.processedPricePerToken = (vars.valueInAsset * (10 ** decimals())) / shares;
        vars.adjustedPricePerToken = vars.processedPricePerToken;

        if (vars.processedPricePerToken > lastPricePerToken) {
            vars.adjustedPricePerToken =
                lastPricePerToken + ((vars.processedPricePerToken - lastPricePerToken) * (1000 - feeInPpm)) / 1000;
        }

        vars.fee = (assets * (vars.processedPricePerToken - vars.adjustedPricePerToken)) / vars.processedPricePerToken;
        if (vars.fee > 0) {
            _asset.safeTransfer(feeTreasury, vars.fee);
            assets -= vars.fee;
        }
    }

    function redeem(uint256 shares, address receiver) external returns (uint256 assets) {
        assets = _redeem(shares);
        _burn(_msgSender(), shares);
        if (assets > 0) {
            _asset.safeTransfer(receiver, assets);
        }
    }

    function computeScoreDeviationInPpm(address vaultAddress) public view returns (int256) {
        SingleAssetVault vault = SingleAssetVault(vaultAddress);
        uint256 portfolioScore = vault.totalPortfolioScore();
        uint256 shares = vault.balanceOf(address(this));
        uint256 assetsAtVault = pricesOracle.convert(vault.asset(), address(_asset), vault.convertToAssets(shares));
        return int256((1000 * assetsAtVault) / totalAssets()) - int256((1000 * portfolioScore) / totalPortfolioScore());
    }

    /**
     * Perform rebalancing from sourceToken vault to destinationToken vault
     * 	 Checks the rebalancing conditions mentioned in whitepaper
     *
     * 	 @param sourceVaultAddress Describes from which SingleAssetVault to take funds
     * 	 @param destinationVaultAddress Describes to which SingleAssetVault to put funds
     * 	 @param shares Amount of shares to redeem from source vault
     */
    function rebalance(address sourceVaultAddress, address destinationVaultAddress, uint256 shares) external {
        require(vaults.contains(sourceVaultAddress));
        require(vaults.contains(destinationVaultAddress));

        int256 scoreDeviation1 = computeScoreDeviationInPpm(sourceVaultAddress);
        int256 scoreDeviation2 = computeScoreDeviationInPpm(destinationVaultAddress);

        // this one check is strict (not <=) because we don't want
        // attackers to rebalance small portions infinite times burning
        // funds on deposit/swap fees
        require(scoreDeviation1 > 0);
        require(scoreDeviation2 <= 0);

        SingleAssetVault sourceVault = SingleAssetVault(sourceVaultAddress);
        SingleAssetVault destinationVault = SingleAssetVault(destinationVaultAddress);

        uint256 assets = sourceVault.redeem(shares, address(this), address(this));

        assets = assetConverter.safeSwap(sourceVault.asset(), destinationVault.asset(), assets);
        destinationVault.deposit(assets, address(this));

        scoreDeviation1 = computeScoreDeviationInPpm(sourceVaultAddress);
        scoreDeviation2 = computeScoreDeviationInPpm(destinationVaultAddress);

        require(scoreDeviation1 >= 0);
        require((scoreDeviation2 * int256(1000 - allowedDeviationInPpm)) / 1000 <= 0);
    }

    function previewRedeemHelper(uint256 shares) external {
        require(msg.sender == address(this));
        uint256 assets = _redeem(shares);
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, assets)
            revert(ptr, 32)
        }
    }

    function previewRedeem(uint256 shares) external returns (uint256 assets) {
        try this.previewRedeemHelper(shares) {}
        catch (bytes memory reason) {
            if (reason.length != 32) {
                if (reason.length < 68) revert("Unexpected error");
                assembly {
                    reason := add(reason, 0x04)
                }
                revert(abi.decode(reason, (string)));
            }
            return abi.decode(reason, (uint256));
        }
    }
}