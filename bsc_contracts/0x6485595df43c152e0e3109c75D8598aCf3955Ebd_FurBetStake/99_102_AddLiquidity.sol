// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./abstracts/BaseContract.sol";

// Interfaces.
import "./interfaces/IToken.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "./interfaces/ILiquidityManager.sol";

/**
 * @title Furio AddLiquidity
 * @author Steve Harmeyer
 * @notice This contract creates the liquidity pool for $FUR/_payment_
 */

/// @custom:security-contact [email protected]
contract AddLiquidity is BaseContract {
    /**
     * Contract initializer.
     * @dev This intializes all the parent contracts.
     */
    function initialize() public initializer {
        __BaseContract_init();
    }

    function SetLmAddr(address _lmsAddress) external onlyOwner {
        _lms = ILiquidityManager(_lmsAddress);
    }

    /**
     * add liquidity.
     * @notice Creates LP token  with _payment and _token and send LP staking contract.
     */
    function addLiquidity() external {
        IERC20 _payment_ = IERC20(addressBook.get("payment"));
        IToken _token_ = IToken(addressBook.get("token"));
        IUniswapV2Router02 _router_ = IUniswapV2Router02(
            addressBook.get("router")
        );
        address _RewardPool_ = addressBook.get("lpStaking");
        require(address(_payment_) != address(0), "Payment token not set");
        require(address(_token_) != address(0), "Token not set");
        require(address(_router_) != address(0), "Router not set");
        require(_RewardPool_ != address(0), "lpRewardPool not set");

        uint256 _LiquidityAmount_ = _token_.balanceOf(address(this));
        uint256 _amountToLiquify_ = _LiquidityAmount_ / 2;
        uint256 _amountToSwap_ = _LiquidityAmount_ - _amountToLiquify_;

        if (_amountToSwap_ == 0) {
            return;
        }

        _token_.approve(address(_router_), _amountToSwap_);
        address[] memory _path_ = new address[](2);
        _path_[0] = address(_token_);
        _path_[1] = address(_payment_);
        uint256 _balanceBefore_ = _payment_.balanceOf(address(this));

        _lms.swapTokenForUsdcToWallet(
            address(this),
            address(this),
            _amountToSwap_,
            10
        );
        /* _router_.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            _amountToSwap_,
            0,
            _path_,
            address(this),
            block.timestamp + 3600
        ); */

        uint256 _amount_payment_Liquidity_ = _payment_.balanceOf(
            address(this)
        ) - _balanceBefore_;

        _payment_.approve(address(_router_), _amount_payment_Liquidity_);
        _token_.approve(address(_router_), _amountToLiquify_);

        if (_amountToLiquify_ > 0 && _amount_payment_Liquidity_ > 0) {
            _router_.addLiquidity(
                address(_token_),
                address(_payment_),
                _amountToLiquify_,
                _amount_payment_Liquidity_,
                0,
                0,
                _RewardPool_,
                block.timestamp + 3600
            );
        }
    }

    function withdraw() external onlyOwner {
        IERC20 _payment_ = IERC20(addressBook.get("payment"));
        IToken _token_ = IToken(addressBook.get("token"));
        _payment_.transfer(msg.sender, _payment_.balanceOf(address(this)));
        _token_.transfer(msg.sender, _token_.balanceOf(address(this)));
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[45] private __gap;
    ILiquidityManager _lms; // Liquidity manager
}