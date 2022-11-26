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

    event VaultAdded(address vault);
    event VaultRemoved(address vault);

	PortfolioScore public immutable oracle;

    EnumerableSet.AddressSet private vaults;

    uint8 private immutable _decimals;

    constructor(
        address portfolioScore,
        IERC20Metadata asset_,
        string memory name,
        string memory symbol
    ) ERC4626(asset_) ERC20(name, symbol) {
        require(portfolioScore != address(0), "Zero address provided");

        oracle = PortfolioScore(portfolioScore);
        _decimals = asset_.decimals();
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

        require(scoreDeviation1 >= 0);
        require(scoreDeviation2 <= 0);
    }

    function _convertToAssets(uint256 shares, uint256 _totalSupply, uint256 _totalAssets) public pure returns(uint256) {
        return _totalSupply != 0 ? (shares * _totalAssets) / _totalSupply : shares;
    }

    function _convertToAssets(uint256 shares, Math.Rounding rounding) 
        internal
        view
        virtual
        override 
        returns (uint256) {
        return _convertToAssets(shares, totalSupply(), totalAssets());
    }

    function _convertToShares(uint256 assets, uint256 _totalSupply, uint256 _totalAssets) public pure returns(uint256) {
        return _totalAssets != 0 ? (assets * _totalSupply) / _totalAssets : assets;
    }

    function _convertToShares(uint256 assets, Math.Rounding rounding)
        internal
        view
        virtual
        override
        returns (uint256 shares)
    {
        return _convertToShares(assets, totalSupply(), totalAssets());
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
        uint256 _totalAssets = totalAssets();
        uint256 _totalSupply = totalSupply();
        uint256 _totalScore = totalPortfolioScore();
        IERC20 token = IERC20(asset());
        token.safeTransferFrom(caller, address(this), assets);
        for (uint256 i = 0; i < vaults.length(); i++) {
            IERC4626 vault = IERC4626(vaults.at(i));
            uint256 amount = (assets * oracle.portfolioScore(address(vault))) / _totalScore;
            if (amount == 0) continue;
            vault.deposit(
                amount,
                address(this)
            );
        }
        shares = _convertToShares(totalAssets() - _totalAssets, _totalSupply, _totalAssets);

        _mint(receiver, shares);

        emit Deposit(caller, receiver, assets, shares);
    }

    function _withdraw(
        address caller,
        address receiver,
        address owner,
        uint256 assets,
        uint256 shares
    ) internal virtual override {
        if (caller != owner) {
            _spendAllowance(owner, caller, shares);
        }
        
        _redeemShares(receiver, shares);

        _burn(owner, shares);

        emit Withdraw(caller, receiver, owner, assets, shares);
    }

    function _redeemShares(address to, uint256 shares) private {
        uint256 _totalSupply = totalSupply();
        for (uint256 i = 0; i < vaults.length(); i++) {
            IERC4626 vault = IERC4626(vaults.at(i));
            uint256 amountToRedeem = shares * vault.balanceOf(address(this)) / _totalSupply;
            if (amountToRedeem == 0) continue;
            vault.redeem(
                amountToRedeem,
                to,
                address(this)
            );
        }
    }
}