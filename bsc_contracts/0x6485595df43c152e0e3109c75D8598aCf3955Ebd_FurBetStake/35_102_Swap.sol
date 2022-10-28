// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./abstracts/BaseContract.sol";
// INTERFACES
import "./interfaces/IVault.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "./interfaces/ILiquidityManager.sol";

/**
 * @title Furio Swap
 * @author Steve Harmeyer
 * @notice This is the uinswap contract for $FUR.
 */

/// @custom:security-contact [email protected]
contract Swap is BaseContract {
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
     * Buy tokens.
     * @param paymentAmount_ Amount of payment.
     * @return bool True if successful.
     */
    function buy(uint256 paymentAmount_) external whenNotPaused returns (bool) {
        require(paymentAmount_ > 0, "Invalid amount");
        IERC20 _in_ = IERC20(addressBook.get("payment"));
        require(address(_in_) != address(0), "Payment not set");
        IERC20 _out_ = IERC20(addressBook.get("token"));
        require(address(_out_) != address(0), "Token not set");
        _swap(_in_, _out_, paymentAmount_, msg.sender, msg.sender);
        return true;
    }

    /**
     * Deposit buy.
     * @param paymentAmount_ Amount of payment.
     * @return bool True if successful.
     */
    function depositBuy(uint256 paymentAmount_)
        external
        whenNotPaused
        returns (bool)
    {
        return _depositBuy(paymentAmount_, address(0));
    }

    /**
     * Deposit buy with referrer.
     * @param paymentAmount_ Amount of payment.
     * @param referrer_ Address of referrer.
     * @return bool True if successful.
     */
    function depositBuy(uint256 paymentAmount_, address referrer_)
        external
        whenNotPaused
        returns (bool)
    {
        return _depositBuy(paymentAmount_, referrer_);
    }

    /**
     * Internal deposit buy.
     * @param paymentAmount_ Amount of payment.
     * @param referrer_ Address of referrer.
     * @return bool True if successful.
     */
    function _depositBuy(uint256 paymentAmount_, address referrer_)
        internal
        returns (bool)
    {
        require(paymentAmount_ > 0, "Invalid amount");
        IERC20 _in_ = IERC20(addressBook.get("payment"));
        require(address(_in_) != address(0), "Payment not set");
        IERC20 _out_ = IERC20(addressBook.get("token"));
        require(address(_out_) != address(0), "Token not set");
        IVault _vault_ = IVault(addressBook.get("vault"));
        require(address(_vault_) != address(0), "Vault not set");
        uint256 _amount_ = _swap(
            _in_,
            _out_,
            paymentAmount_,
            msg.sender,
            address(_vault_)
        );
        _vault_.depositFor(msg.sender, _amount_, referrer_);
        return true;
    }

    /**
     * Sell tokens.
     * @param sellAmount_ Amount of tokens.
     * @return bool True if successful.
     */
    function sell(uint256 sellAmount_) external whenNotPaused returns (bool) {
        require(sellAmount_ > 0, "Invalid amount");
        IERC20 _in_ = IERC20(addressBook.get("token"));
        require(address(_in_) != address(0), "Token not set");
        IERC20 _out_ = IERC20(addressBook.get("payment"));
        require(address(_out_) != address(0), "Payment not set");
        _swap(_in_, _out_, sellAmount_, msg.sender, msg.sender);
        return true;
    }

    /**
     * Get token buy output.
     * @param paymentAmount_ Amount spent.
     * @return uint Amount of tokens received.
     */
    function buyOutput(uint256 paymentAmount_) external view returns (uint256) {
        require(paymentAmount_ > 0, "Invalid amount");
        return
            _getOutput(
                addressBook.get("payment"),
                addressBook.get("token"),
                paymentAmount_
            );
    }

    /**
     * Get token sell output.
     * @param sellAmount_ Amount sold.
     * @return uint Amount of tokens received.
     */
    function sellOutput(uint256 sellAmount_) external view returns (uint256) {
        require(sellAmount_ > 0, "Invalid amount");
        return
            _getOutput(
                addressBook.get("token"),
                addressBook.get("payment"),
                sellAmount_
            );
    }

    /**
     * Swap.
     * @param in_ In token.
     * @param out_ Out token.
     * @param amount_ Amount in.
     * @param receiver_ Receiver's address.
     * @return uint256 Output amount.
     */
    function _swap(
        IERC20 in_,
        IERC20 out_,
        uint256 amount_,
        address payer_,
        address receiver_
    ) internal returns (uint256) {
        IUniswapV2Router02 _router_ = IUniswapV2Router02(
            addressBook.get("router")
        );
        require(address(_router_) != address(0), "Router not set");
        require(
            in_.transferFrom(payer_, address(this), amount_),
            "In transfer failed"
        );
        uint256 _actualAmount_ = in_.balanceOf(address(this));
        address[] memory _path_ = new address[](2);
        _path_[0] = address(in_);
        _path_[1] = address(out_);
        in_.approve(address(_lms), _actualAmount_);

        _lms.swapTokenForUsdcToWallet(
            address(this),
            address(this),
            _actualAmount_,
            10
        );
        uint256 _balance_ = out_.balanceOf(address(this));
        out_.approve(address(this), _balance_);
        require(out_.transfer(receiver_, _balance_), "Out transfer failed");
        return _balance_;
    }

    /**
     * Get output.
     * @param in_ In token.
     * @param out_ Out token.
     * @param amount_ Amount in.
     * @return uint Estimated tokens received.
     */
    function _getOutput(
        address in_,
        address out_,
        uint256 amount_
    ) internal view returns (uint256) {
        IUniswapV2Router02 _router_ = IUniswapV2Router02(
            addressBook.get("router")
        );
        require(address(_router_) != address(0), "Router not set");
        address[] memory _path_ = new address[](2);
        _path_[0] = in_;
        _path_[1] = out_;
        uint256[] memory _outputs_ = _router_.getAmountsOut(amount_, _path_);
        return _outputs_[1];
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[45] private __gap;
    ILiquidityManager _lms; // Liquidity manager
}