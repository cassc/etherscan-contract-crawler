import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

import "prb-math/contracts/PRBMathSD59x18.sol";
import "prb-math/contracts/PRBMathUD60x18.sol";

import "./interfaces/IERC20Extension.sol";
import "./interfaces/IForwardingSwapProxy.sol";

import "./BaseSwapProxy.sol";
import "./Whitelist.sol";

/// @title ForwardingSwapProxy
contract ForwardingSwapProxy is
    AccessControlEnumerable,
    Pausable,
    ReentrancyGuard,
    BaseSwapProxy,
    Whitelist,
    IForwardingSwapProxy
{
    // Using Fixed point calculations for these types
    using PRBMathSD59x18 for int256;
    using PRBMathUD60x18 for uint256;

    using UniswapV2Helpers for IUniswapV2Router02;

    constructor(address _admin) BaseSwapProxy(_admin) Whitelist(_admin) {}

    function _swapTokensWithChecks(
        IERC20Extension _fromToken,
        IERC20Extension _toToken,
        SwapParams calldata _swapParams,
        uint256 _minimumReturnAmount
    ) internal returns (uint256 amountReturned) {
        require(isWhitelisted(_swapParams.to), "Not whitelisted");

        if (isEth(_fromToken)) {
            require(msg.value >= _swapParams.value, "Not enough ETH provided");
        } else {
            _fromToken.transferFrom(
                _msgSender(),
                address(this),
                _swapParams.amount
            );

            _handleApprovalFromThis(
                _fromToken,
                _swapParams.to,
                _swapParams.amount
            );
        }

        // Taking the balance of _toToken before and after, this ensures compatibility with all swap services. Some might return the value within the data response, but inconsistent across swap providers
        uint256 beforeBalanceToToken = returnTokenBalance(
            _toToken,
            address(this)
        );

        // Execute the swap
        (bool success, ) = _swapParams.to.call{value: msg.value}(
            _swapParams.data
        );
        require(success, "Proxied Swap Failed");

        uint256 afterBalanceToToken = returnTokenBalance(
            _toToken,
            address(this)
        );

        amountReturned = afterBalanceToToken - beforeBalanceToToken;

        require(
            amountReturned > _minimumReturnAmount,
            "Not enough tokens returned"
        );
    }

    function proxySwapWithFee(
        IERC20Extension _fromToken,
        IERC20Extension _toToken,
        SwapParams calldata _swapParams,
        uint256 _gasRefund,
        uint256 _minimumReturnAmount
    ) external payable override whenNotPaused nonReentrant {
        require(_fromToken != _toToken, "_fromToken equal to _toToken");

        uint256 amountReturned = _swapTokensWithChecks(
            _fromToken,
            _toToken,
            _swapParams,
            _minimumReturnAmount
        );

        (uint256 feeTotalInETH, ) = calculatePercentageFeeInETH(
            _toToken,
            amountReturned,
            _gasRefund
        );

        if (isEth(_toToken)) {
            amountReturned -= feeTotalInETH;

            require(
                amountReturned > _minimumReturnAmount,
                "Not enough tokens returned"
            );

            payable(_msgSender()).transfer(amountReturned);
        } else {
            uint256 swappedAmountIn;

            if (feeTotalInETH > 0) {
                _handleApprovalFromThis(
                    _toToken,
                    address(uniswapV2Router),
                    amountReturned
                );

                (swappedAmountIn, ) = uniswapV2Router._swapTokensForExactETH(
                    _toToken,
                    feeTotalInETH,
                    amountReturned,
                    address(this)
                );
            }

            amountReturned -= swappedAmountIn;

            require(
                amountReturned > _minimumReturnAmount,
                "Not enough tokens returned"
            );

            _toToken.transfer(_msgSender(), amountReturned);
        }

        if (feeTotalInETH > 0) {
            // Transfer the vault the fees paid
            vault.paidFees{value: feeTotalInETH}(_msgSender(), feeTotalInETH);
        }

        emit ProxySwapWithFee(
            address(_fromToken),
            address(_toToken),
            isEth(_fromToken) ? msg.value : _swapParams.value,
            amountReturned,
            feeTotalInETH
        );
    }
}