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

    event VaultAdded(address vault);
    event VaultRemoved(address vault);

    event SetNewFeeDestination(address destination, uint256 block);

    event SetNewFeeValue(uint256 value, uint256 block);

    event FeeHarvested(uint256 fee, uint256 at);

    EnumerableSet.AddressSet private vaults;

    AssetConverter public immutable assetConverter;

    uint256 public lastPricePerToken;
    uint256 public allowedDeviationInPpm = 50;

    address public feeTreasury;

	uint256 public feeInPpm;

    constructor(address _converter, address _feeDestination, uint256 _feeValue) ERC20("ApyFlow", "APYFLW") {
        require(_converter != address(0), "Zero address provided");
        assetConverter = AssetConverter(_converter);
        feeTreasury = _feeDestination;
        feeInPpm = _feeValue;
        lastPricePerToken = 10 ** decimals();
    }

    function setNewFeeDestination(address newFeeDestination) onlyOwner external
    {
        feeTreasury = newFeeDestination;

        emit SetNewFeeDestination(newFeeDestination, block.number);
    }

    function setNewFeeValue(uint256 newFeeValue) onlyOwner external
    {
        require(newFeeValue < 1000, "fee value incorrect");
        recomputePricePerTokenAndHarvestFee();
        feeInPpm = newFeeValue;

        emit SetNewFeeValue(newFeeValue, block.number);
    }

    /**
		Recomputes stored price per share, and, if it has increased,
		withdeaws part of profit as fee 
	 */
	function recomputePricePerTokenAndHarvestFee() public returns (uint256 actualPricePerToken)
	{
		uint256 _totalAssets = totalAssets();
        uint256 _totalSupply = totalSupply();

		uint256 newPricePerToken = pricePerToken();

		if (newPricePerToken > lastPricePerToken)
		{
			uint256 oldTotalAssets = _totalSupply * lastPricePerToken / 10 ** decimals();
			uint256 profit = _totalAssets - oldTotalAssets;
			uint256 fee = profit * feeInPpm / 1000;
			uint256 shares = _convertToShares(fee, _totalSupply, _totalAssets - fee);
			_mint(feeTreasury, shares);

			lastPricePerToken = pricePerToken();

			emit FeeHarvested(fee, block.timestamp);
		}

		return lastPricePerToken;
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

    function _convertToAssets(
        uint256 shares,
        uint256 _totalSupply,
        uint256 _totalAssets
    ) public pure returns (uint256) {
        return
            _totalSupply != 0 ? (shares * _totalAssets) / _totalSupply : shares;
    }

    function convertToAssets(uint256 shares) public view returns (uint256) {
        return _convertToAssets(shares, totalSupply(), totalAssets());
    }

    function _convertToShares(
        uint256 assets,
        uint256 _totalSupply,
        uint256 _totalAssets
    ) public pure returns (uint256) {
        return
            _totalAssets != 0 ? (assets * _totalSupply) / _totalAssets : assets;
    }

    function convertToShares(uint256 assets)
        public
        view
        returns (uint256 shares)
    {
        return _convertToShares(assets, totalSupply(), totalAssets());
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

    function _verifyAmounts(uint256[] memory amounts)
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
            expected =
                (totalAmount *
                    vault.totalPortfolioScore() *
                    10**(vault.decimals())) /
                (totalScore * (10**decimals()));
            if (amounts[i] > expected) deviation += amounts[i] - expected;
            else deviation += expected - amounts[i];
        }
        require((deviation * 100) / totalAmount <= 50, "Invalid amounts");
    }

    function deposit(uint256[] memory amounts, address receiver)
        external
        returns (uint256 shares)
    {
        _verifyAmounts(amounts);
        recomputePricePerTokenAndHarvestFee();
        uint256 _totalAssets = totalAssets();
        uint256 _totalSupply = totalSupply();
        for (uint256 i = 0; i < vaults.length(); i++) {
            if (amounts[i] == 0) continue;

            SingleAssetVault vault = SingleAssetVault(vaults.at(i));
            IERC20 token = IERC20(vault.asset());
            token.safeTransferFrom(msg.sender, address(this), amounts[i]);

            uint256 prevVaultTotalAssets = vault.totalAssets();
            vault.deposit(amounts[i], address(this));
            uint256 delta = ((vault.totalAssets() - prevVaultTotalAssets) *
                (10**decimals())) / (10**vault.decimals());
                
            shares += _convertToShares(
                delta,
                _totalSupply,
                _totalAssets
            );
        }
        _mint(receiver, shares);
    }

    function redeem(uint256 shares, address receiver)
        external
        returns (uint256[] memory amounts)
    {
        recomputePricePerTokenAndHarvestFee();
        amounts = new uint256[](vaults.length());
        uint256 _totalSupply = totalSupply();
        for (uint256 i = 0; i < vaults.length(); i++) {
            SingleAssetVault vault = SingleAssetVault(vaults.at(i));
            IERC20 token = IERC20(vault.asset());

            uint256 previousBalance = token.balanceOf(receiver);

            uint256 amountToRedeem = shares * vault.balanceOf(address(this)) / _totalSupply;
            if (amountToRedeem == 0) continue;
            vault.redeem(amountToRedeem, receiver, address(this));

            amounts[i] = token.balanceOf(receiver) - previousBalance;
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

        require(scoreDeviation1 >= 0);
        require(scoreDeviation2 * int256(1000 - allowedDeviationInPpm) / 1000 <= 0);
    }

    function feeInclusivePricePerToken() public view returns(uint256) {
        uint256 _pricePerToken = pricePerToken();
        if (_pricePerToken <= lastPricePerToken) {
            return _pricePerToken;
        } else {
            uint256 delta = _pricePerToken - lastPricePerToken;
            return lastPricePerToken + delta * (1000 - feeInPpm) / 1000;
        }
    }
}