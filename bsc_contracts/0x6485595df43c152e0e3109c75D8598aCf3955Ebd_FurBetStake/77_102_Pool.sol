// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./abstracts/BaseContract.sol";
// Interfaces.
import "./interfaces/IToken.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

/**
 * @title Furio Pool
 * @author Steve Harmeyer
 * @notice This contract creates the liquidity pool for $FUR/USDC
 */

/// @custom:security-contact [email protected]
contract Pool is BaseContract
{
    /**
     * Contract initializer.
     * @dev This intializes all the parent contracts.
     */
    function initialize() initializer public
    {
        __BaseContract_init();
        _startingPrice = 800; // 2.50 * 100
    }

    /**
     * Starting price.
     */
    uint256 private _startingPrice;

    /**
     * Create liquidity.
     * @dev Creates a liquidity pool with _payment and _token.
     */
    function createLiquidity() external onlyOwner
    {
        IERC20 _payment_ = IERC20(addressBook.get("payment"));
        IToken _token_ = IToken(addressBook.get("token"));
        IUniswapV2Router02 _router_ = IUniswapV2Router02(addressBook.get("router"));
        address _safe_ = addressBook.get("safe");
        require(address(_payment_) != address(0), "Payment token not set");
        require(address(_token_) != address(0), "Token not set");
        require(address(_router_) != address(0), "Router not set");
        require(_safe_ != address(0), "Dev wallet not set");
        uint256 _paymentBalance_ = _payment_.balanceOf(address(this));
        uint256 _amountToMint_ = _paymentBalance_ * 100 / _startingPrice;
        require(_amountToMint_ > 0, "Invalid amount");
        _token_.mint(address(this), _amountToMint_);
        _payment_.approve(address(_router_), _paymentBalance_);
        _token_.approve(address(_router_), _amountToMint_);
        _router_.addLiquidity(
            address(_payment_),
            address(_token_),
            _paymentBalance_,
            _amountToMint_,
            0,
            0,
            _safe_,
            block.timestamp + 3600
        );
    }

    function withdraw() external onlyOwner
    {
        IERC20 _payment_ = IERC20(addressBook.get("payment"));
        _payment_.transfer(msg.sender, _payment_.balanceOf(address(this)));
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[45] private __gap;
}