pragma solidity 0.8.15;

import "ERC4626.sol";
import "IERC20.sol";
import "IERC4626.sol";
import "Ownable.sol";
import "PortfolioScore.sol";
import "SafeERC20.sol";
import "EnumerableSet.sol";

contract SingleAssetVault is ERC4626, Ownable {
    using SafeERC20 for IERC20;
    using SafeERC20 for IERC20Metadata;
    using EnumerableSet for EnumerableSet.AddressSet;

    event FeeHarvested(uint256 fee, uint256 at);
    event VaultAdded(address vault);
    event VaultRemoved(address vault);

    PortfolioScore public oracle;

    EnumerableSet.AddressSet private vaults;

    uint256 public lastPricePerShare;

    address public feeTreasury;

    uint256 public feeInPpm;

    uint8 private immutable _decimals;

    constructor(
        address portfolioScore,
        IERC20Metadata asset_,
        string memory name,
        string memory symbol,
        address addressForFees,
        uint256 _fee
    ) ERC4626(asset_) ERC20(name, symbol) {
        require(portfolioScore != address(0), "Zero address provided");
        require(addressForFees != address(0), "Zero address provided");
        require(_fee <= 1000, "Fee can't be more than 100%");

        oracle = PortfolioScore(portfolioScore);
        feeTreasury = addressForFees;
        feeInPpm = _fee;
        _decimals = asset_.decimals();
        lastPricePerShare = 10**decimals();
    }

    function addVault(address vault) external onlyOwner {
        require(!vaults.contains(vault), "this vault is already added");

        vaults.add(vault);
        if (IERC20(asset()).allowance(address(this), vault) == 0)
            IERC20(asset()).safeIncreaseAllowance(vault, type(uint256).max);

        emit VaultAdded(vault);
    }

    function removeVault(address vault) external onlyOwner {
        require(vaults.contains(vault), "vault does not exist");
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
            total += oracle.portfolioScore(vaults.at(i));
    }

    /**
		Recomputes stored price per share, and, if it has increased,
		withdeaws part of profit as fee 
	 */
    function recomputePricePerShareAndHarvestFee() public returns (uint256) {
        uint256 totalBalance = totalAssets();

        uint256 newPricePerShare = pricePerToken();

        if (newPricePerShare > lastPricePerShare) {
            uint256 oldTotalBalance = (totalSupply() * lastPricePerShare) /
                10**decimals();
            uint256 profit = totalBalance - oldTotalBalance;
            uint256 fee = (profit * feeInPpm) / 1000;
            //uint256 shares = convertToShares(fee);
            //_mint(feeTreasury, shares);
            /*lastPricePerShare = */
            newPricePerShare =
                ((totalBalance - fee) / totalSupply()) *
                10**decimals();
            _withdrawAssets(feeTreasury, fee);
            emit FeeHarvested(fee, block.timestamp);
        }

        lastPricePerShare = newPricePerShare;
        return lastPricePerShare;
    }

    function pricePerToken() public view returns (uint256) {
        return convertToAssets(10**decimals());
    }

    function totalAssets()
        public
        view
        virtual
        override
        returns (uint256 totalBalance)
    {
        for (uint256 i = 0; i < vaults.length(); i++) {
            IERC4626 vault = IERC4626(vaults.at(i));
            uint256 shares = vault.balanceOf(address(this));
            uint256 balanceAtVault = vault.convertToAssets(shares);
            totalBalance += balanceAtVault;
        }
    }

    function computeScoreDeviationInPpm(address vaultAddress)
        public
        view
        returns (int256)
    {
        IERC4626 vault = IERC4626(vaultAddress);
        uint256 portfolioScore = oracle.portfolioScore(address(vault));
        uint256 assetsInVault = vault.convertToAssets(
            vault.balanceOf(address(this))
        );
        uint256 shareOfVault = assetsInVault == 0
            ? 0
            : (1000 * assetsInVault) / totalAssets();
        return
            int256(shareOfVault) -
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

        recomputePricePerShareAndHarvestFee();

        int256 scoreDeviation1 = computeScoreDeviationInPpm(sourceVaultAddress);
        int256 scoreDeviation2 = computeScoreDeviationInPpm(
            destinationVaultAddress
        );

        require(scoreDeviation1 > 0);
        require(scoreDeviation2 < 0);

        uint256 previousBalance = IERC20(asset()).balanceOf(address(this));
        IERC4626(sourceVaultAddress).withdraw(
            assets,
            address(this),
            address(this)
        );
        uint256 value = IERC20(asset()).balanceOf(address(this)) -
            previousBalance;

        IERC4626(destinationVaultAddress).deposit(value, address(this));
    }

    function _convertToShares(uint256 assets, Math.Rounding rounding)
        internal
        view
        virtual
        override
        returns (uint256 shares)
    {
        uint256 balance = totalAssets();
        uint256 supply = totalSupply();
        return balance != 0 ? (assets * supply) / balance : assets; // divide by lastPricePerShare
    }

    function _convertToAssets(uint256 shares, Math.Rounding rounding)
        internal
        view
        virtual
        override
        returns (uint256 assets)
    {
        uint256 balance = totalAssets();
        uint256 supply = totalSupply();
        return supply != 0 ? (shares * balance) / supply : shares; // times by lastPricePerShare
    }

    function maxDeposit(address)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return type(uint256).max;
    }

    function decimals()
        public
        view
        virtual
        override(IERC20Metadata, ERC20)
        returns (uint8)
    {
        return _decimals;
    }

    function _deposit(
        address caller,
        address receiver,
        uint256 assets,
        uint256 shares
    ) internal virtual override {
        IERC20 token = IERC20(asset());
        token.safeTransferFrom(caller, address(this), assets);
        uint256 totalScore = totalPortfolioScore();
        for (uint256 i = 0; i < vaults.length(); i++) {
            IERC4626 vault = IERC4626(vaults.at(i));
            vault.deposit(
                (assets * oracle.portfolioScore(address(vault))) / totalScore,
                address(this)
            );
        }

        _mint(receiver, shares);

        recomputePricePerShareAndHarvestFee();

        emit Deposit(caller, receiver, assets, shares);
    }

    function _withdraw(
        address caller,
        address receiver,
        address owner,
        uint256 assets,
        uint256 shares
    ) internal virtual override {
        _burn(owner, shares);

        _withdrawAssets(receiver, assets);

        recomputePricePerShareAndHarvestFee();

        emit Withdraw(caller, receiver, owner, assets, shares);
    }

    function _withdrawAssets(address to, uint256 assets) private {
        uint256 _totalAssets = totalAssets();
        for (uint256 i = 0; i < vaults.length(); i++) {
            IERC4626 vault = IERC4626(vaults.at(i));
            vault.withdraw(
                ((assets *
                    vault.convertToAssets(vault.balanceOf(address(this)))) /
                    _totalAssets),
                to,
                address(this)
            );
        }
    }
}