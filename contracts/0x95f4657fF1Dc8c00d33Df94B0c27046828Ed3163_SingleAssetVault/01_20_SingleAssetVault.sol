// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IERC4626Minimal.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./PortfolioScoreOracle.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "./ApyFlowVault.sol";
import "./libraries/Utils.sol";

/// @author YLDR <[email protected]>
contract SingleAssetVault is ApyFlowVault {
    using SafeERC20 for IERC20;
    using SafeERC20 for IERC20Metadata;
    using EnumerableSet for EnumerableSet.AddressSet;

    event VaultAdded(address vault);
    event VaultRemoved(address vault);

    PortfolioScoreOracle public immutable oracle;

    EnumerableSet.AddressSet private vaults;

    constructor(PortfolioScoreOracle _oracle, IERC20Metadata _asset, string memory name, string memory symbol)
        ApyFlowVault(_asset)
        ERC20(name, symbol)
    {
        require(address(_oracle) != address(0), "Zero address provided");
        oracle = _oracle;
    }

    function addVault(address vault) external onlyOwner {
        require(!vaults.contains(vault), "this vault is already added");

        vaults.add(vault);
        Utils.approveIfZeroAllowance(asset(), vault);

        emit VaultAdded(vault);
    }

    function removeVault(address vault) external onlyOwner {
        require(vaults.contains(vault), "vault does not exist");
        vaults.remove(vault);
        Utils.revokeAllowance(asset(), vault);
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
            total += oracle.portfolioScore(vaults.at(i));
        }
    }

    function _totalAssets() internal view override returns (uint256 assets) {
        for (uint256 i = 0; i < vaults.length(); i++) {
            IERC4626Minimal vault = IERC4626Minimal(vaults.at(i));
            uint256 shares = vault.balanceOf(address(this));
            if (shares == 0) continue;
            assets += vault.convertToAssets(shares);
        }
    }

    function computeScoreDeviationInPpm(address vaultAddress) public view returns (int256) {
        IERC4626Minimal vault = IERC4626Minimal(vaultAddress);
        uint256 portfolioScore = oracle.portfolioScore(address(vault));
        uint256 balanceAtVault = vault.balanceOf(address(this));
        uint256 assetsInVault = balanceAtVault > 0 ? vault.convertToAssets(balanceAtVault) : 0;
        uint256 shareOfVault = assetsInVault == 0 ? 0 : (1000 * assetsInVault) / totalAssets();
        return int256(shareOfVault) - int256((1000 * portfolioScore) / totalPortfolioScore());
    }

    /**
     * Perform rebalancing from sourceToken vault to destinationToken vault
     * 	 Checks the rebalancing conditions mentioned in whitepaper
     *
     * 	 @param sourceVault Describes from which SingleAssetVault to take funds
     * 	 @param destinationVault Describes to which SingleAssetVault to put funds
     * 	 @param shares Amount of shares to redeem from source vault
     */
    function rebalance(IERC4626Minimal sourceVault, IERC4626Minimal destinationVault, uint256 shares) external {
        require(vaults.contains(address(sourceVault)));
        require(vaults.contains(address(destinationVault)));

        int256 scoreDeviation1 = computeScoreDeviationInPpm(address(sourceVault));
        int256 scoreDeviation2 = computeScoreDeviationInPpm(address(destinationVault));

        // this one check is strict (not <=) because we don't want
        // attackers to rebalance small portions infinite times burning
        // funds on deposit/swap fees
        require(scoreDeviation1 > 0);
        require(scoreDeviation2 <= 0);
        uint256 assets = sourceVault.redeem(shares, address(this), address(this));

        destinationVault.deposit(assets, address(this));

        scoreDeviation1 = computeScoreDeviationInPpm(address(sourceVault));
        scoreDeviation2 = computeScoreDeviationInPpm(address(destinationVault));

        require(scoreDeviation1 >= 0);
        require(scoreDeviation2 <= 0);
    }

    function _deposit(uint256 assets) internal override {}

    // overriding here because shares minting logic differs from base contract
    function deposit(uint256 assets, address receiver) public virtual override returns (uint256 shares) {
        IERC20(asset()).safeTransferFrom(_msgSender(), address(this), assets);
        uint256 _totalScore = totalPortfolioScore();
        uint256 deposited = 0;

        uint256 leftAssets = assets;

        for (uint256 i = 0; i < vaults.length(); i++) {
            IERC4626Minimal vault = IERC4626Minimal(vaults.at(i));
            uint256 amount = (assets * oracle.portfolioScore(address(vault))) / _totalScore;
            if (amount == 0) continue;
            deposited += vault.convertToAssets(vault.deposit(amount, address(this)));
            leftAssets -= amount;
        }

        deposited += leftAssets;
        uint256 totalAssetsAfter = totalAssets();

        // if rewards were harvested during deposit we shouldn't include them
        shares = _convertToShares(deposited, totalAssetsAfter - deposited, totalSupply());
        _mint(receiver, shares);

        emit Deposit(_msgSender(), receiver, assets, shares);
    }

    function _redeem(uint256 shares) internal override returns (uint256 assets) {
        for (uint256 i = 0; i < vaults.length(); i++) {
            IERC4626Minimal vault = IERC4626Minimal(vaults.at(i));
            uint256 amountToRedeem = (shares * vault.balanceOf(address(this))) / totalSupply();
            if (amountToRedeem == 0) continue;
            assets += vault.redeem(amountToRedeem, address(this), address(this));
        }
    }
}