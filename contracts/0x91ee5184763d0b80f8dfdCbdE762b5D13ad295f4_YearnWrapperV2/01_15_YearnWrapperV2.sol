// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.12;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

import "../../interfaces/adapters/yearn/IVaultWrapper.sol";
import {VaultAPI, IYearnRegistry} from "../../interfaces/adapters/yearn/VaultAPI.sol";
import "../../interfaces/IERC4626.sol";
import {FixedPointMathLib} from "../../lib/FixedPointMathLib.sol";

/**
 * @author RobAnon
 * @author 0xTraub
 * @author 0xTinder
 * @notice a contract for providing Yearn V2 contracts with an ERC-4626-compliant interface
 *         Developed for Resonate.
 *         This version uses getPricePerShare instead of free funds. This may make it more resilient to migrations
 *         However, it makes it significantly less precise for stablecoins
 * @dev The initial deposit to this contract should be made immediately following deployment
 */
contract YearnWrapperV2 is ERC20, IVaultWrapper, IERC4626, Ownable, ReentrancyGuard {

    using FixedPointMathLib for uint;
    using SafeERC20 for IERC20;

    /// NB: If this is deployed on non-Mainnet chains
    ///     Then this address may be different
    IYearnRegistry public registry = IYearnRegistry(0x50c1a2eA0a861A967D9d0FFE2AE4012c2E053804);

    VaultAPI public yVault;

    address public immutable token;
    /// Decimals for native token
    uint8 public immutable _decimals;

    /// Necessary to prevent precision manipulation
    uint private constant MIN_DEPOSIT = 1E3;

    constructor(VaultAPI _vault)
        ERC20(
            string(abi.encodePacked(_vault.name(), "-4646-Adapter")),
            string(abi.encodePacked(_vault.symbol(), "-4646"))
        )
    {
        yVault = _vault;
        token = yVault.token();
        _decimals = uint8(_vault.decimals());
    }

    function vault() external view returns (address) {
        return address(yVault);
    }

    /// @dev Verifies that the yearn registry has "_target" recorded as the asset's latest vault
    function migrate(address _target) external onlyOwner returns (address) {
        // verify _target is a valid address
        if(registry.latestVault(token) != _target) {
            revert InvalidMigrationTarget();
        }

        uint assets = yVault.withdraw(type(uint).max);
        yVault = VaultAPI(_target);

        // Redeposit want into target vault
        yVault.deposit(assets);

        return _target;
    }

    // NB: this number will be different from this token's totalSupply
    function vaultTotalSupply() external view returns (uint256) {
        return yVault.totalSupply();
    }

    /*//////////////////////////////////////////////////////////////
                      ERC20 compatibility
   //////////////////////////////////////////////////////////////*/

    function decimals() public view override(ERC20,IERC4626) returns (uint8) {
        return _decimals;
    }

    function asset() external view override returns (address) {
        return token;
    }

    /*//////////////////////////////////////////////////////////////
                      DEPOSIT/WITHDRAWAL LOGIC
  //////////////////////////////////////////////////////////////*/

    function deposit(
        uint256 assets, 
        address receiver
    ) public override nonReentrant returns (uint256 shares) {
        if(assets < MIN_DEPOSIT) {
            revert MinimumDepositNotMet();
        }

        (assets, shares) = _deposit(assets, receiver, msg.sender);

        emit Deposit(msg.sender, receiver, assets, shares);
    }

    function mint(
        uint256 shares, 
        address receiver
    ) public override nonReentrant returns (uint256 assets) {
        // No need to check for rounding error, previewMint rounds up.
        assets = previewMint(shares); 

        uint expectedShares = shares;
        (assets, shares) = _deposit(assets, receiver, msg.sender);

        if(assets < MIN_DEPOSIT) {
            revert MinimumDepositNotMet();
        }

        if(shares != expectedShares) {
            revert NotEnoughAvailableAssetsForAmount();
        }

        emit Deposit(msg.sender, receiver, assets, shares);
    }

    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) public override nonReentrant returns (uint256 shares) {
        
        if(assets == 0) {
            revert NonZeroArgumentExpected();
        }

        (assets, shares) = _withdraw(
            assets,
            receiver,
            owner
        );

        emit Withdraw(msg.sender, receiver, owner, assets, shares);
    }

    function redeem(
        uint256 shares,
        address receiver,
        address owner
    ) public override nonReentrant returns (uint256 assets) {
        
        if(shares == 0) {
            revert NonZeroArgumentExpected();
        }

        (assets, shares) = _redeem(
            shares,
            receiver,
            owner
        );

        emit Withdraw(msg.sender, receiver, owner, assets, shares);
    }

    /*//////////////////////////////////////////////////////////////
                          ACCOUNTING LOGIC
  //////////////////////////////////////////////////////////////*/

    function totalAssets() public view override returns (uint256) {
        return convertYearnSharesToAssets(yVault.balanceOf(address(this)));
    }

    function convertToShares(uint256 assets)
        public
        view
        override
        returns (uint256)
    {
        uint supply = totalSupply();
        uint localAssets = convertYearnSharesToAssets(yVault.balanceOf(address(this)));
        return supply == 0 ? assets : assets.mulDivDown(supply, localAssets); 
    }

    function convertToAssets(uint256 shares)
        public
        view
        override
        returns (uint assets)
    {
        uint supply = totalSupply();
        uint localAssets = convertYearnSharesToAssets(yVault.balanceOf(address(this)));
        return supply == 0 ? shares : shares.mulDivDown(localAssets, supply);
    }
    
    function previewDeposit(uint256 assets)
        public
        view
        override
        returns (uint256)
    {
        return convertToShares(assets);
    }

    function previewWithdraw(uint256 assets)
        public
        view
        override
        returns (uint256)
    {
        uint supply = totalSupply();
        uint localAssets = convertYearnSharesToAssets(yVault.balanceOf(address(this)));
        return supply == 0 ? assets : assets.mulDivUp(supply, localAssets); 
    }

    function previewMint(uint256 shares)
        public
        view
        override
        returns (uint256)
    {
        uint supply = totalSupply();
        uint localAssets = convertYearnSharesToAssets(yVault.balanceOf(address(this)));
        return supply == 0 ? shares : shares.mulDivUp(localAssets, supply);
    }

    function previewRedeem(uint256 shares)
        public
        view
        override
        returns (uint256)
    {
        return convertToAssets(shares);
    }

    /*//////////////////////////////////////////////////////////////
                    DEPOSIT/WITHDRAWAL LIMIT LOGIC
  //////////////////////////////////////////////////////////////*/

    function maxDeposit(address)
        public
        view
        override
        returns (uint256)
    {
        return yVault.availableDepositLimit();
    }

    function maxMint(address _account)
        external
        view
        override
        returns (uint256)
    {
        return maxDeposit(_account)/ yVault.pricePerShare();
    }

    function maxWithdraw(address owner)
        external
        view
        override
        returns (uint256)
    {
        return convertToAssets(this.balanceOf(owner));
    }

    function maxRedeem(address owner) external view override returns (uint256) {
        return this.balanceOf(owner);
    }

     function _deposit(
        uint256 amount,
        address receiver,
        address depositor
    ) internal returns (uint256 deposited, uint256 mintedShares) {
        VaultAPI _vault = yVault;
        IERC20 _token = IERC20(token);

        if (amount == type(uint256).max) {
            amount = Math.min(
                _token.balanceOf(depositor),
                _token.allowance(depositor, address(this))
            );
        }

        _token.safeTransferFrom(depositor, address(this), amount);


        _token.safeApprove(address(_vault), amount);

        uint256 beforeBal = _token.balanceOf(address(this));

        mintedShares = previewDeposit(amount);
        _vault.deposit(amount, address(this));

        uint256 afterBal = _token.balanceOf(address(this));
        deposited = beforeBal - afterBal;

        // afterDeposit custom logic
        _mint(receiver, mintedShares);
    }

    function _withdraw(
        uint256 amount,
        address receiver,
        address sender
    ) internal returns (uint256 assets, uint256 shares) {
        VaultAPI _vault = yVault;

        shares = previewWithdraw(amount); 
        uint yearnShares = convertAssetsToYearnShares(amount);

        assets = _doWithdrawal(shares, yearnShares, sender, receiver, _vault);

        if(assets < amount) {
            revert NotEnoughAvailableSharesForAmount();
        }
    }

    function _redeem(
        uint256 shares, 
        address receiver,
        address sender
    ) internal returns (uint256 assets, uint256 sharesBurnt) {
        VaultAPI _vault = yVault;
        uint yearnShares = convertSharesToYearnShares(shares);
        assets = _doWithdrawal(shares, yearnShares, sender, receiver, _vault);    
        sharesBurnt = shares;
    }

    function _doWithdrawal(
        uint shares,
        uint yearnShares,
        address sender,
        address receiver,
        VaultAPI _vault
    ) private returns (uint assets) {
        if (sender != msg.sender) {
            uint currentAllowance = allowance(sender, msg.sender);
            if(currentAllowance < shares) {
                revert SpenderDoesNotHaveApprovalToBurnShares();
            }
            _approve(sender, msg.sender, currentAllowance - shares);
        }

        if (shares > balanceOf(sender)) {
            revert NotEnoughAvailableSharesForAmount();
        }

        if(yearnShares == 0 || shares == 0) {
            revert NoAvailableShares();
        }

        _burn(sender, shares);
        // withdraw from vault and get total used shares
        assets = _vault.withdraw(yearnShares, receiver, 0);
    }

    ///
    /// VIEW METHODS
    ///

    function convertAssetsToYearnShares(uint assets) internal view returns (uint yShares) {
        uint256 supply = yVault.totalSupply();
        return supply == 0 ? assets : assets.mulDivUp(10**decimals(), yVault.pricePerShare());
    }

    function convertYearnSharesToAssets(uint yearnShares) internal view returns (uint assets) {
        uint supply = yVault.totalSupply();
        return supply == 0 ? yearnShares : yearnShares * yVault.pricePerShare() / 10**decimals();
    }

    function convertSharesToYearnShares(uint shares) internal view returns (uint yShares) {
        uint supply = totalSupply(); 
        return supply == 0 ? shares : shares.mulDivUp(yVault.balanceOf(address(this)), totalSupply());
    }

    function allowance(address owner, address spender) public view virtual override(ERC20,IERC4626) returns (uint256) {
        return super.allowance(owner,spender);
    }

    function balanceOf(address account) public view virtual override(ERC20,IERC4626) returns (uint256) {
        return super.balanceOf(account);
    }

    function name() public view virtual override(ERC20,IERC4626) returns (string memory) {
        return super.name();
    }

    function symbol() public view virtual override(ERC20,IERC4626) returns (string memory) {
        return super.symbol();
    }

    function totalSupply() public view virtual override(ERC20,IERC4626) returns (uint256) {
        return super.totalSupply();
    }

}