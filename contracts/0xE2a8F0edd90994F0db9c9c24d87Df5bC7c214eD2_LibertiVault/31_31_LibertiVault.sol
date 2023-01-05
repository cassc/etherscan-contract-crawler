//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/interfaces/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC4626Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/draft-ERC20PermitUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";
import "@sushiswap/core/contracts/uniswapv2/interfaces/IUniswapV2Router02.sol";

import "./interfaces/ILibertiPriceFeed.sol";
import "./interfaces/ISanctionsList.sol";
import "./LibertiSwap.sol";

contract LibertiVault is
    LibertiSwap,
    Initializable,
    ERC4626Upgradeable,
    ERC20PermitUpgradeable,
    OwnableUpgradeable
{
    using MathUpgradeable for uint256;

    IUniswapV2Router02 internal immutable router;
    ILibertiPriceFeed internal immutable priceFeed;
    ISanctionsList internal constant SANCTIONS_LIST =
        ISanctionsList(0x40C57923924B5c5c5455c48D93317139ADDaC8fb);

    // Typed `address` to match public function ERC4626.asset()
    address public other;

    // Vault target allocation coefficient, in basis point
    uint256 public invariant; //FIXME: rename to Kp

    uint256 public maxDepositAmount;
    uint256 public entryFeeValue;
    uint256 public exitFeeValue;

    constructor(address _router, address _delegatedPriceFeed) {
        _disableInitializers();
        router = IUniswapV2Router02(_router);
        priceFeed = ILibertiPriceFeed(_delegatedPriceFeed);
        maxDepositAmount = 0; // block deposit to implementation contract
    }

    /// @notice Initialize the vault instance
    /// @dev Vault instance is an EIP-1167 minimal clone
    /// @dev The asset must be an ERC-20 supporting Metadata extension
    /// @dev The initialize function must not be callable on implementation contract
    /// @param _asset The asset of the vault
    /// @param _name The name of the vault
    /// @param _symbol The symbol of the vault
    /// @param _other The other asset
    /// @param _owner The wallet which can rebalance the vault
    /// @param _maxDepositAmount The maximum depositable amount of asset in one transaction
    function initialize(
        address _asset,
        string memory _name,
        string memory _symbol,
        address _other,
        address _owner,
        uint256 _maxDepositAmount,
        uint256 _entryFeeValue,
        uint256 _exitFeeValue
    ) public initializer {
        __ERC4626_init(IERC20Upgradeable(_asset));
        __ERC20_init(_name, _symbol);
        __ERC20Permit_init(_name);
        __Ownable_init(); //UNUSED: overriden by _transferOwnership below

        _transferOwnership(_owner);
        invariant = 10_000;
        other = _other;
        maxDepositAmount = _maxDepositAmount;
        entryFeeValue = _entryFeeValue;
        exitFeeValue = _exitFeeValue;
    }

    function setMaxDepositAmount(uint256 assets) public onlyOwner {
        maxDepositAmount = assets;
    }

    function getAmountsOut(
        uint256 amountIn,
        address token0,
        address token1
    ) internal view returns (uint256[] memory) {
        address[] memory path = new address[](2);
        path[0] = token0;
        path[1] = token1;
        return router.getAmountsOut(amountIn, path);
    }

    function swapExactTokensForTokens(
        uint256 amount,
        address token0,
        address token1,
        address receiver
    ) internal {
        SafeERC20.safeIncreaseAllowance(IERC20(token0), address(router), amount);
        address[] memory path = new address[](2);
        path[0] = token0;
        path[1] = token1;
        //FIXME: slither: unused-return
        router.swapExactTokensForTokens(
            amount,
            0,
            path,
            receiver,
            // solhint-disable-next-line not-rely-on-time
            block.timestamp
        );
    }

    /// @notice Rebalance the vault according to swap description from 1Inch API
    /// @dev Delegated call to a helper contract
    /// @param minOut The minimum amount to return to not revert the swap
    /// @param data The 1Inch calldata inclusing the swap description
    /// @param newInvariant The target allocation of the vault in basis point of asset
    function rebalance(
        uint256 minOut,
        bytes calldata data,
        uint256 newInvariant
    ) external onlyOwner returns (bytes memory) {
        require(newInvariant <= 10_000, "!invariant"); //FIXME: Replace with off-chain check (usecase for Openzeppelin Defender?)
        invariant = newInvariant; // For subsequent deposits
        return swap(minOut, data);
    }

    //
    // ERC-20 functions
    //

    function _beforeTokenTransfer(address from, address to, uint256) internal virtual override {
        require(
            !SANCTIONS_LIST.isSanctioned(from) && !SANCTIONS_LIST.isSanctioned(to),
            "!sanction"
        );
    }

    //
    // ERC-4626 functions
    //

    function decimals() public pure override(ERC4626Upgradeable, ERC20Upgradeable) returns (uint8) {
        return 18;
    }

    function maxDeposit(address) public view override returns (uint256) {
        return maxDepositAmount;
    }

    /// @notice Internal logic for the previewDeposit function
    /// @dev Round-down the value of the user deposit and round-up the tvl of the vault
    /// @dev Price feeds of assets and other token must have the same number of decimals
    /// @param assets A number of asset to deposit
    /// @return The exact amount of lp tokens returned
    /// @return The amount of asset exchanged for vault's other asset
    function _previewDeposit(uint256 assets) internal view returns (uint256, uint256, uint256) {
        uint256 supply = totalSupply();
        if (0 == assets || 0 == supply) {
            uint256 shares0 = assets.mulDiv(
                10_000 - entryFeeValue,
                10_000,
                MathUpgradeable.Rounding.Down
            );
            return (shares0, 0, assets - shares0);
        }
        address token0 = asset();
        uint256 decimalsToken0 = 10 ** IERC20Metadata(token0).decimals();
        uint256 decimalsToken1 = 10 ** IERC20Metadata(other).decimals();
        uint256 keepToken0 = assets.mulDiv(invariant, 10_000);
        uint256 sellToken0 = assets - keepToken0;
        uint256 priceToken0 = priceFeed.getPrice(token0);
        uint256 valueToken0 = priceToken0.mulDiv(
            keepToken0,
            decimalsToken0,
            MathUpgradeable.Rounding.Down
        );
        uint256 valueToken1 = 0;
        uint256 priceToken1 = priceFeed.getPrice(other);
        if (0 < sellToken0) {
            uint256[] memory amountsOut = getAmountsOut(sellToken0, token0, other);
            valueToken1 = priceToken1.mulDiv(
                amountsOut[1],
                decimalsToken1,
                MathUpgradeable.Rounding.Down
            );
        }
        uint256 nav = priceToken0.mulDiv(
            IERC20Metadata(token0).balanceOf(address(this)),
            decimalsToken0,
            MathUpgradeable.Rounding.Up
        );
        nav += priceToken1.mulDiv(
            IERC20Metadata(other).balanceOf(address(this)),
            decimalsToken1,
            MathUpgradeable.Rounding.Up
        );
        uint256 shares = supply.mulDiv(
            valueToken0 + valueToken1,
            nav,
            MathUpgradeable.Rounding.Down
        );
        uint256 entryFeeAmount = shares.mulDiv(
            entryFeeValue,
            10_000,
            MathUpgradeable.Rounding.Down
        );
        return (shares - entryFeeAmount, sellToken0, entryFeeAmount);
    }

    function previewDeposit(uint256 assets) public view override returns (uint256) {
        (uint256 shares, , ) = _previewDeposit(assets);
        return shares;
    }

    function deposit(uint256 assets, address receiver) public virtual override returns (uint256) {
        return deposit(assets, receiver, 0);
    }

    /// @notice Safely deposit assets into vault
    /// @dev Revert if returned amount of shares is below minimum
    /// @param assets The number of asset to deposit
    /// @param receiver The address receiving the shares
    /// @param amountOutMin The minimum amount of shares to mint
    /// @return The number of shares minted
    function deposit(
        uint256 assets,
        address receiver,
        uint256 amountOutMin
    ) public returns (uint256) {
        require(!SANCTIONS_LIST.isSanctioned(_msgSender()), "!sanction");
        require(assets <= maxDeposit(receiver), "ERC4626: deposit more than max");
        (uint256 shares, uint256 sellToken0, uint256 entryFeeAmount) = _previewDeposit(assets);
        require(shares >= amountOutMin, "!min");
        _deposit(_msgSender(), receiver, assets, shares);
        if (0 < sellToken0) {
            swapExactTokensForTokens(sellToken0, asset(), other, address(this));
        }
        _mint(owner(), entryFeeAmount);
        return shares;
    }

    /// @notice Internal logic for the previewRedeem function
    /// @dev May swap on Uniswap an amount of asset for the other asset
    /// @param shares A number of share to redeem
    /// @return The exact amount of assets returned
    /// @return The amount of asset transfered from contract's holdings
    /// @return The amount of other asset exchanged for vault's asset
    function _previewRedeem(
        uint256 shares
    ) private view returns (uint256, uint256, uint256, uint256) {
        uint256 supply = totalSupply();
        uint256 exitFeeAmount = shares.mulDiv(exitFeeValue, 10_000, MathUpgradeable.Rounding.Down);
        shares -= exitFeeAmount;
        if (0 == shares || 0 == supply) {
            return (shares, shares, 0, exitFeeAmount);
        }
        address token0 = asset();
        uint256 totalToken0 = IERC20Metadata(token0).balanceOf(address(this));
        uint256 amountToken0 = totalToken0.mulDiv(shares, supply, MathUpgradeable.Rounding.Down);
        uint256 totalToken1 = IERC20Metadata(other).balanceOf(address(this));
        if (0 < totalToken1) {
            uint256 amountToken1 = totalToken1.mulDiv(
                shares,
                supply,
                MathUpgradeable.Rounding.Down
            );
            uint256[] memory amountsOut = getAmountsOut(amountToken1, other, token0);
            return (amountToken0 + amountsOut[1], amountToken0, amountToken1, exitFeeAmount);
        }
        return (amountToken0, amountToken0, 0, exitFeeAmount);
    }

    function previewRedeem(uint256 shares) public view override returns (uint256) {
        (uint256 assets, , , ) = _previewRedeem(shares);
        return assets;
    }

    function _redeem0(
        uint256 shares,
        address receiver,
        uint256 amountOutMin
    ) internal returns (uint256, uint256, uint256) {
        (
            uint256 assets,
            uint256 amountToken0,
            uint256 amountToken1,
            uint256 exitFeeAmount
        ) = _previewRedeem(shares);
        require(assets >= amountOutMin, "!min"); // error: INSUFFICIENT_OUTPUT_AMOUNT
        if (0 < amountToken1) {
            swapExactTokensForTokens(amountToken1, other, asset(), receiver);
        }
        return (assets, amountToken0, exitFeeAmount);
    }

    function redeem(
        uint256 shares,
        address receiver,
        address owner_
    ) public virtual override returns (uint256) {
        return redeem(shares, receiver, owner_, 0);
    }

    function redeem(
        uint256 shares,
        address receiver,
        address owner_,
        uint256 amountOutMin
    ) public returns (uint256) {
        require(shares <= maxRedeem(owner_), "ERC4626: redeem more than max");
        (uint256 assets, uint256 amountToken0, uint256 exitFeeAmount) = _redeem0(
            shares,
            receiver,
            amountOutMin
        );
        if (_msgSender() != owner_) {
            _spendAllowance(owner_, _msgSender(), shares);
        }
        _burn(owner_, shares - exitFeeAmount);
        _transfer(owner_, owner(), exitFeeAmount);
        SafeERC20Upgradeable.safeTransfer(IERC20Upgradeable(asset()), receiver, amountToken0);
        //emit Withdraw(caller, receiver, owner, assets, shares);
        return assets;
    }

    function totalAssets() public pure override returns (uint256) {
        //FIXME!
        return 0;
    }

    function convertToShares(uint256) public pure override returns (uint256 shares) {
        //FIXME!
        return 0;
    }

    function convertToAssets(uint256) public pure override returns (uint256 assets) {
        //FIXME!
        return 0;
    }

    function mint(uint256, address) public pure override returns (uint256) {
        //FIXME!
        return 0;
    }

    function withdraw(uint256, address, address) public pure override returns (uint256) {
        //FIXME!
        return 0;
    }

    function setEntryFeeValue(uint256 value) external onlyOwner {
        entryFeeValue = value;
    }

    function setExitFeeValue(uint256 value) external onlyOwner {
        exitFeeValue = value;
    }

    function exit() external {
        uint256 shares = balanceOf(_msgSender());
        if (0 < shares) {
            if (_msgSender() != owner()) {
                uint256 exitFeeAmount = shares.mulDiv(
                    exitFeeValue,
                    10_000,
                    MathUpgradeable.Rounding.Down
                );
                _transfer(_msgSender(), owner(), exitFeeAmount);
                shares -= exitFeeAmount;
            }
            IERC20Upgradeable token0 = IERC20Upgradeable(asset());
            IERC20Upgradeable token1 = IERC20Upgradeable(other);
            uint256 supply = totalSupply();
            uint256 totalToken0 = token0.balanceOf(address(this));
            uint256 totalToken1 = token1.balanceOf(address(this));
            uint256 amountToken0 = totalToken0.mulDiv(
                shares,
                supply,
                MathUpgradeable.Rounding.Down
            );
            uint256 amountToken1 = totalToken1.mulDiv(
                shares,
                supply,
                MathUpgradeable.Rounding.Down
            );
            _burn(_msgSender(), shares);
            SafeERC20Upgradeable.safeTransfer(token0, _msgSender(), amountToken0);
            SafeERC20Upgradeable.safeTransfer(token1, _msgSender(), amountToken1);
            //emit Exit(caller, receiver, owner, assets, shares);
        }
    }
}