pragma solidity 0.8.15;

import "ERC20.sol";
import "IERC20Metadata.sol";
import "Ownable.sol";
import "IERC4626.sol";
import "SafeERC20.sol";
import "EnumerableSet.sol";
import "AssetConverter.sol";
import "SingleAssetVault.sol";
import "PortfolioScore.sol";

contract ApyFlow is ERC20, Ownable {
    using SafeERC20 for IERC20;
    using SafeERC20 for IERC20Metadata;
    using EnumerableSet for EnumerableSet.AddressSet;

    event Deposited(
        address indexed who,
        address indexed asset,
        uint256 numberOfAssets,
        uint256 numberOfShares
    );

    event Withdrawal(
        address indexed who,
        address indexed asset,
        uint256 numberOfAssets,
        uint256 numberOfShares
    );

    event VaultAdded(address vault);
    event VaultRemoved(address vault);

    EnumerableSet.AddressSet private vaults;

    AssetConverter public assetConverter;

    constructor(address _converter)
        ERC20("ApyFlow", "APYFLW")
    {
        require(_converter != address(0), "Zero address provided");
        assetConverter = AssetConverter(_converter);
    }

    function totalAssets() public view returns (uint256 total) {
        for (uint256 i = 0; i < vaults.length(); i++) {
            SingleAssetVault vault = SingleAssetVault(vaults.at(i));
            total +=
                (vault.convertToAssets(vault.balanceOf(address(this))) *
                    (10**decimals())) /
                (10**vault.decimals()); // todo: need tests for that
        }
    }

    function convertToAssets(uint256 shares) public view returns (uint256) {
        uint256 balance = totalAssets();
        uint256 supply = totalSupply();
        return supply != 0 ? (shares * balance) / supply : shares; // times by lastPricePerShare
    }

    function convertToShares(uint256 assets)
        public
        view
        returns (uint256 shares)
    {
        uint256 balance = totalAssets();
        uint256 supply = totalSupply();
        return balance != 0 ? (assets * supply) / balance : assets; // divide by lastPricePerShare
    }

    function pricePerToken() public view returns (uint256) {
        return convertToAssets(10**decimals());
    }

    function addVault(address vault) external onlyOwner {
        require(!(vaults.contains(vault)), "The vault is already added");
        require(vault != address(0), "Zero address provided");

        vaults.add(vault);
        IERC20 token = IERC20(SingleAssetVault(vault).asset());
        if (token.allowance(address(this), vault) == 0)
            token.safeIncreaseAllowance(vault, type(uint256).max);
        if (token.allowance(address(this), address(assetConverter)) == 0)
            token.safeIncreaseAllowance(
                address(assetConverter),
                type(uint256).max
            );

        emit VaultAdded(vault);
    }

    function removeVault(address vault) external onlyOwner {
        require(vaults.contains(vault), "The vault is not added");
        vaults.remove(vault);
        emit VaultRemoved(vault);
    }

    function vaultsLength() external view returns (uint256) {
        return vaults.length();
    }

    function getVault(uint256 index) external view returns (address) {
        return vaults.at(index);
    }

    function totalPortfolioScore() public view returns (uint256 total) {
        for (uint256 i = 0; i < vaults.length(); i++)
            total += SingleAssetVault(vaults.at(i)).totalPortfolioScore();
    }

    function _verifyAmounts(uint256[] memory amounts, bool withdrawal)
        internal
        view
    {
        require(amounts.length == vaults.length(), "Invalid amounts length");
        uint256 totalAmount;
        for (uint256 i = 0; i < amounts.length; i++)
            totalAmount +=
                (amounts[i] * (10**decimals())) /
                (10**SingleAssetVault(vaults.at(i)).decimals());
        uint256 totalScore = totalPortfolioScore();
        uint256 deviation = 0;
        for (uint256 i = 0; i < amounts.length; i++) {
            SingleAssetVault vault = SingleAssetVault(vaults.at(i));
            uint256 expected;
            if (!withdrawal) {
                expected =
                    (totalAmount *
                        vault.totalPortfolioScore() *
                        10**(vault.decimals())) /
                    (totalScore * (10**decimals()));
            } else {
                expected =
                    (totalAmount *
                        vault.convertToAssets(vault.balanceOf(address(this)))) /
                    totalAssets();
            }
            if (amounts[i] > expected) deviation += amounts[i] - expected;
            else deviation += expected - amounts[i];
        }
        require((deviation * 100) / totalAmount <= 50, "Invalid amounts");
    }

    function depositToVault(uint256 index, uint256 amount) external {
        SingleAssetVault vault = SingleAssetVault(vaults.at(index));
        IERC20 token = IERC20(vault.asset());
        token.safeTransferFrom(msg.sender, address(this), amount);
        vault.deposit(amount, address(this));
    }

    function deposit(uint256[] memory amounts, address receiver)
        external
        returns (uint256)
    {
        _verifyAmounts(amounts, false);
        uint256 totalShares;
        for (uint256 i = 0; i < vaults.length(); i++) {
            SingleAssetVault vault = SingleAssetVault(vaults.at(i));
            IERC20 token = IERC20(vault.asset());
            token.safeTransferFrom(msg.sender, address(this), amounts[i]);
            uint256 vaultAssets = vault.convertToAssets(
                vault.previewDeposit(amounts[i])
            );
            uint256 shares = convertToShares(
                (vaultAssets * (10**decimals())) / (10**vault.decimals())
            );
            totalShares += shares;
            vault.deposit(amounts[i], address(this));
            _mint(receiver, shares);
            emit Deposited(receiver, address(token), amounts[i], shares);
        }
        return totalShares;
    }

    function withdraw(uint256[] memory amounts, address receiver)
        external
        returns (uint256)
    {
        _verifyAmounts(amounts, true);
        uint256 totalShares;
        for (uint256 i = 0; i < amounts.length; i++) {
            SingleAssetVault vault = SingleAssetVault(vaults.at(i));
            uint256 shares = convertToShares(
                (amounts[i] * (10**decimals())) / (10**vault.decimals())
            );
            totalShares += shares;
            vault.withdraw(amounts[i], receiver, address(this));
            _burn(msg.sender, shares);
            emit Withdrawal(receiver, vault.asset(), amounts[i], shares);
        }
        return totalShares;
    }

    function redeem(uint256 shares, address receiver)
        external
        returns (uint256[] memory amounts)
    {
        amounts = new uint256[](vaults.length());
        uint256 _totalAssets = totalAssets();
        for (uint256 i = 0; i < vaults.length(); i++) {
            SingleAssetVault vault = SingleAssetVault(vaults.at(i));
            IERC20 token = IERC20(vault.asset());

            uint256 previousBalance = token.balanceOf(receiver);

            uint256 sharesToBurn = (shares *
                vault.convertToAssets(vault.balanceOf(address(this))) *
                (10**decimals())) / ((10**vault.decimals()) * _totalAssets);
            uint256 amountToWithdraw = (convertToAssets(sharesToBurn) *
                (10**vault.decimals())) / (10**decimals());
            vault.withdraw(amountToWithdraw, receiver, address(this));

            amounts[i] = token.balanceOf(receiver) - previousBalance;

            emit Withdrawal(receiver, vault.asset(), amounts[i], sharesToBurn);
        }
        _burn(msg.sender, shares);
    }

    function computeScoreDeviationInPpm(address vaultAddress)
        public
        view
        returns (int256)
    {
        SingleAssetVault vault = SingleAssetVault(vaultAddress);
        uint256 portfolioScore = vault.totalPortfolioScore();
        uint256 shares = vault.balanceOf(address(this));
        uint256 balanceAtVault = (vault.convertToAssets(shares) *
            (10**decimals())) / (10**vault.decimals());
        return
            int256((1000 * balanceAtVault) / totalAssets()) -
            int256((1000 * portfolioScore) / totalPortfolioScore());
    }

    /** 
	 Perform rebalancing from sourceToken vault to destinationToken vault
	 Checks the rebalancing conditions mentioned in whitepaper

	 @param sourceVaultAddress Describes from which SingleAssetVault to take funds
	 @param destinationVaultAddress Describes to which SingleAssetVault to put funds
	 @param assets Amount of assets to take from source vault
	 */
    function rebalance(
        address sourceVaultAddress,
        address destinationVaultAddress,
        uint256 assets
    ) external {
        require(vaults.contains(sourceVaultAddress));
        require(vaults.contains(destinationVaultAddress));

        int256 scoreDeviation1 = computeScoreDeviationInPpm(sourceVaultAddress);
        int256 scoreDeviation2 = computeScoreDeviationInPpm(
            destinationVaultAddress
        );

        require(scoreDeviation1 > 0);
        require(scoreDeviation2 < 0);

        SingleAssetVault sourceVault = SingleAssetVault(sourceVaultAddress);
        SingleAssetVault destinationVault = SingleAssetVault(
            destinationVaultAddress
        );

        IERC20 sourceAsset = IERC20(sourceVault.asset());
        uint256 previousBalance = sourceAsset.balanceOf(address(this));
        sourceVault.withdraw(
            (assets * (10**sourceVault.decimals())) / (10**decimals()),
            address(this),
            address(this)
        );
        uint256 value = sourceAsset.balanceOf(address(this)) - previousBalance;

        uint256 newValue = assetConverter.swap(
            sourceVault.asset(),
            destinationVault.asset(),
            value
        );
        destinationVault.deposit(newValue, address(this));
    }
}