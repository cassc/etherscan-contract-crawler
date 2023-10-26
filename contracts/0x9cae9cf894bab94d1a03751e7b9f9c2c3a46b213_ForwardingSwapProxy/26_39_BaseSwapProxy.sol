// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

import "@chainlink/contracts/src/v0.8/interfaces/FeedRegistryInterface.sol";

import "prb-math/contracts/PRBMathSD59x18.sol";
import "prb-math/contracts/PRBMathUD60x18.sol";

import "./libraries/UniswapHelpers.sol";
import "./libraries/SafeCast160.sol";

import "./interfaces/IERC20Extension.sol";
import "./interfaces/IBaseSwapProxy.sol";
import "./interfaces/IVault.sol";

/// @title BaseSwapProxy
abstract contract BaseSwapProxy is IBaseSwapProxy, AccessControlEnumerable, Pausable, ReentrancyGuard {
    // Using Fixed point calculations for these types
    using PRBMathSD59x18 for int256;
    using PRBMathUD60x18 for uint256;
    using SafeCast160 for uint256;
    using UniswapV2Helpers for IUniswapV2Router02;
    using SafeERC20 for IERC20Extension;

    IERC20Extension public immutable WETH = IERC20Extension(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

    // The ETH address according to 1inch API, this address is used as the address of the native token on all chains
    IERC20Extension public immutable ethContract = IERC20Extension(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

    // Chainlink feedRegistry
    FeedRegistryInterface public immutable feedRegistry =
        FeedRegistryInterface(0x47Fb2585D2C56Fe188D0E6ec628a38b74fCeeeDf);

    IUniswapV2Router02 public immutable uniswapV2Router =
        IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

    IPermit2 public immutable permit2 = IPermit2(0x000000000022D473030F116dDEE9F6B43aC78BA3);

    IVault public vault;

    // Percentage in the form: 100% = 1e18, 1% = 1e16
    uint256 public feePercentage;

    // Need a receive fallback function so that we can swap _fromToken for ETH to recover the _gasRefund and transfer the refund to the vault
    receive() external payable {}

    constructor(address _admin) {
        _setupRole(DEFAULT_ADMIN_ROLE, _admin);
    }

    /// @dev Allows the admin to update the vault contract
    function setVault(IVault _vault) external onlyRole(DEFAULT_ADMIN_ROLE) nonReentrant {
        vault = _vault;

        emit VaultSet(_vault, msg.sender);
    }

    /// @dev Allows the admin to update the paused status of the contract
    function setContractPaused(bool _pauseContract) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (_pauseContract) {
            _pause();
        } else {
            _unpause();
        }
    }

    /// @dev Allows the admin to withdraw any ETH or ERC20 tokens that might've accidentally been locked in the contract
    function withdrawERC20(IERC20Extension _token) external onlyRole(DEFAULT_ADMIN_ROLE) nonReentrant {
        if (_token == ethContract) {
            uint256 balance = address(this).balance;
            require(balance > 0, "Nothing to withdraw");

            (bool success, ) = _msgSender().call{value: balance}("");
            require(success, "Transfer failed");
        } else {
            uint256 balance = _token.balanceOf(address(this));
            require(balance > 0, "Nothing to withdraw");

            _token.safeTransfer(_msgSender(), balance);
        }
    }

    /// @dev Allows the admin to update the percentage fee
    function setFee(uint256 _fee) external onlyRole(DEFAULT_ADMIN_ROLE) nonReentrant {
      feePercentage = _fee;

      emit SetFee(_msgSender(), _fee);
    }

    function _handleEthTransferBack(
        uint256 _amountReturned,
        uint256 _feeTotalInETH,
        uint256 _minimumReturnAmount
    ) internal returns (uint256 amountReturnedAfterFee) {
        amountReturnedAfterFee = _amountReturned - _feeTotalInETH;

        require(amountReturnedAfterFee > _minimumReturnAmount, "Not enough tokens returned after applying fee");

        (bool success, ) = msg.sender.call{value: amountReturnedAfterFee}("");

        require(success, "ETH transfer back to user failed");
    }

    function _tryCall(address _to, bytes calldata _data) internal {
        (bool success, bytes memory result) = _to.call{value: msg.value}(_data);

        if (success) {
            return;
        }

        assembly {
            revert(add(result, 32), mload(result))
        }
    }

    function _handleERC20TransferBack(
        IERC20Extension _toToken,
        uint256 _amountReturned,
        uint256 _feeTotalInETH,
        uint256 _minimumReturnAmount
    ) internal returns (uint256 amountReturnedAfterFee) {
        amountReturnedAfterFee = _amountReturned;

        if (_feeTotalInETH == 0) {
            _toToken.safeTransfer(msg.sender, amountReturnedAfterFee);

            return amountReturnedAfterFee;
        }

        _handleApprovalFromThisForUniswap(_toToken, ethContract, amountReturnedAfterFee);

        (uint256 swappedAmountIn, ) = uniswapV2Router._swapTokensForExactETH(
            _toToken,
            _feeTotalInETH,
            amountReturnedAfterFee,
            address(this)
        );

        amountReturnedAfterFee -= swappedAmountIn;

        require(amountReturnedAfterFee > _minimumReturnAmount, "Not enough tokens returned after charging ERC20 fee");

        _toToken.safeTransfer(msg.sender, amountReturnedAfterFee);
    }

    function _handleToTokenTransferBack(
        IERC20Extension _toToken,
        uint256 _amountReturned,
        uint256 _feeTotalInETH,
        uint256 _minimumReturnAmount
    ) internal returns (uint256) {
        if (_isEth(_toToken)) {
            return _handleEthTransferBack(_amountReturned, _feeTotalInETH, _minimumReturnAmount);
        }

        return _handleERC20TransferBack(_toToken, _amountReturned, _feeTotalInETH, _minimumReturnAmount);
    }

    function _swapFromETH(
        IERC20Extension _toToken,
        SwapParams calldata _swapParams,
        uint256 _gasRefund,
        uint256 _minimumReturnAmount
    ) internal returns (uint256, uint256 amountReturned, uint256 feeTotalInETH) {
        require(msg.value >= _swapParams.value, "Not enough ETH provided");

        uint256 beforeBalanceToToken = _toToken.balanceOf(address(this));

        _tryCall(_swapParams.to, _swapParams.data);

        uint256 afterBalanceToToken = _toToken.balanceOf(address(this));

        amountReturned = afterBalanceToToken - beforeBalanceToToken;

        require(amountReturned > _minimumReturnAmount, "Not enough tokens returned");

        (feeTotalInETH, ) = _calculatePercentageFeeInETH(_toToken, amountReturned, _gasRefund);

        amountReturned = _handleERC20TransferBack(_toToken, amountReturned, feeTotalInETH, _minimumReturnAmount);

        return (_swapParams.value, amountReturned, feeTotalInETH);
    }

    function _swapFromERC20WithPermit(
        IERC20Extension _fromToken,
        IERC20Extension _toToken,
        SwapParams calldata _swapParams,
        uint256 _minimumReturnAmount,
        uint256 _gasRefund,
        IPermit2.PermitSingle calldata _permit,
        bytes calldata _signature
    ) internal returns (uint256, uint256 amountReturned, uint256 feeTotalInETH) {
        permit2.permit(msg.sender, _permit, _signature);

        permit2.transferFrom(msg.sender, address(this), _swapParams.amount.toUint160(), address(_fromToken));

        if (_fromToken.allowance(address(this), _swapParams.to) < _swapParams.amount) {
            _fromToken.safeApprove(_swapParams.to, type(uint256).max);
        }

        uint256 beforeBalanceToToken = returnTokenBalance(_toToken, address(this));

        _tryCall(_swapParams.to, _swapParams.data);

        uint256 afterBalanceToToken = returnTokenBalance(_toToken, address(this));

        amountReturned = afterBalanceToToken - beforeBalanceToToken;

        require(amountReturned > _minimumReturnAmount, "Not enough tokens returned");

        (feeTotalInETH, ) = _calculatePercentageFeeInETH(_toToken, amountReturned, _gasRefund);

        amountReturned = _handleToTokenTransferBack(_toToken, amountReturned, feeTotalInETH, _minimumReturnAmount);

        return (_swapParams.amount, amountReturned, feeTotalInETH);
    }

    function _swapFromERC20(
        IERC20Extension _fromToken,
        IERC20Extension _toToken,
        SwapParams calldata _swapParams,
        uint256 _gasRefund,
        uint256 _minimumReturnAmount
    ) internal returns (uint256, uint256 amountReturned, uint256 feeTotalInETH) {
        _fromToken.safeTransferFrom(msg.sender, address(this), _swapParams.amount);

        if (_fromToken.allowance(address(this), _swapParams.to) < _swapParams.amount) {
            _fromToken.safeApprove(_swapParams.to, type(uint256).max);
        }

        uint256 beforeBalanceToToken = returnTokenBalance(_toToken, address(this));

        _tryCall(_swapParams.to, _swapParams.data);

        uint256 afterBalanceToToken = returnTokenBalance(_toToken, address(this));

        amountReturned = afterBalanceToToken - beforeBalanceToToken;

        require(amountReturned > _minimumReturnAmount, "Not enough tokens returned");

        (feeTotalInETH, ) = _calculatePercentageFeeInETH(_toToken, amountReturned, _gasRefund);

        amountReturned = _handleToTokenTransferBack(_toToken, amountReturned, feeTotalInETH, _minimumReturnAmount);

        return (_swapParams.amount, amountReturned, feeTotalInETH);
    }

    function _swapTokens(
        IERC20Extension _fromToken,
        IERC20Extension _toToken,
        SwapParams calldata _swapParams,
        uint256 _gasRefund,
        uint256 _minimumReturnAmount
    ) internal returns (uint256 amountRequested, uint256 amountReturned, uint256 feeTotalInETH) {
        if (_isEth(_fromToken)) {
            return _swapFromETH(_toToken, _swapParams, _gasRefund, _minimumReturnAmount);
        }

        return _swapFromERC20(_fromToken, _toToken, _swapParams, _gasRefund, _minimumReturnAmount);
    }

    function _swapTokens(
        IERC20Extension _fromToken,
        IERC20Extension _toToken,
        SwapParams calldata _swapParams,
        uint256 _minimumReturnAmount,
        uint256 _gasRefund,
        IPermit2.PermitSingle calldata _permit,
        bytes calldata _signature
    ) internal returns (uint256 amountRequested, uint256 amountReturned, uint256 feeTotalInETH) {
        if (_isEth(_fromToken)) {
            revert NativePermitNotAllowed();
        }

        return
            _swapFromERC20WithPermit({
                _fromToken: _fromToken,
                _toToken: _toToken,
                _swapParams: _swapParams,
                _minimumReturnAmount: _minimumReturnAmount,
                _gasRefund: _gasRefund,
                _permit: _permit,
                _signature: _signature
            });
    }

    /// @dev Simple helper for determing if the token is ETH
    function _isEth(IERC20Extension _token) internal view returns (bool) {
        return _token == ethContract;
    }

    /// @dev Simplifies the logic of getting decimals for a given token. This function will revert if the given token doesn't have the decimals function, but it seems like a safe assumption that valid tokens will
    function _getDecimals(IERC20Extension _token) internal view returns (uint8 decimals) {
        if (_token == ethContract) {
            return 18;
        }

        return _token.decimals();
    }

    function returnTokenBalance(IERC20Extension _token, address _address) internal view returns (uint256) {
        if (!_isEth(_token)) {
            return _token.balanceOf(_address);
        }

        return _address.balance;
    }

    /// @dev A wrapper around the chainlink rate fetching to prevent reverts in the case of missing exchange rates.
    function tryGetChainlinkRate(IERC20 _fromToken, IERC20 _toToken) internal view returns (uint256) {
        // Because of how chainlink rates work, they never provide rates from ETH -> _toToken, they always go _fromToken -> ETH. So the rate needs to be inverted if the request is in the wrong direction
        bool invertRate = _fromToken == ethContract;

        if (invertRate) {
            _fromToken = _toToken;
            _toToken = ethContract;
        }

        try feedRegistry.latestRoundData(address(_fromToken), address(_toToken)) returns (
            uint80 roundId,
            int256 chainlinkPrice,
            uint256,
            uint256 updatedAt,
            uint80 answeredInRound
        ) {
            // Ensure that the chainlink response is valid. Not adding a revert message as the require statement is wrapped in a try-catch
            require(updatedAt > 0 && answeredInRound == roundId);
            // Un-invert the returned rate
            if (invertRate) {
                return uint256(1 ether).div(uint256(chainlinkPrice));
            }

            return uint256(chainlinkPrice);
        } catch {
            return 0;
        }
    }

    /// @dev This function scales the _amount up or down depending on the difference between the _inputDecimals and _outputDecimals
    function _scaleAmountFromDecimals(
        uint256 _amount,
        uint8 _inputDecimals,
        uint8 _outputDecimals
    ) internal pure returns (uint256) {
        // Scale the price up if there isn't enough decimals
        if (_inputDecimals < _outputDecimals) {
            return _amount * uint256(10 ** uint256(_outputDecimals - _inputDecimals));
            // Similarly scale the price down if there are too many decimals
        } else if (_inputDecimals > _outputDecimals) {
            return _amount / uint256(10 ** uint256(_inputDecimals - _outputDecimals));
        }

        // Otherwise if the same decimals return
        return _amount;
    }

    /// @dev Function simply gets the decimals for the provided _token parameter and then scales the _amount accordingly
    function _scaleAmountFromTokenDecimals(
        IERC20Extension _token,
        uint256 _amount,
        uint8 _inputDecimals
    ) internal view returns (uint256 amount) {
        uint8 decimals = _getDecimals(_token);

        return _scaleAmountFromDecimals(_amount, _inputDecimals, decimals);
    }

    function _getChainlinkRate(
        IERC20Extension _fromToken,
        IERC20Extension _toToken
    ) internal view returns (uint256 exchangeRate) {
        // Chainlink doesn't handle WETH, which seems a bit silly, so modify it to use the 0xeee "ETH" contract
        if (_fromToken == WETH) {
            _fromToken = ethContract;
        }
        if (_toToken == WETH) {
            _toToken = ethContract;
        }

        // Try to get a direct rate for the provided pair
        uint256 directRate = tryGetChainlinkRate(_fromToken, _toToken);

        if (directRate != 0) {
            // Provide 18 as the current decimals as this is how chainlink returns its price data
            return _scaleAmountFromTokenDecimals(_toToken, directRate, 18);
        }

        // If no direct rate exists and either token is ETH, return now
        if (_fromToken == ethContract || _toToken == ethContract) {
            return 0;
        }

        // Otherwise try and get a rate by going: _fromToken -> ETH -> _toToken
        uint256 toETHRate = tryGetChainlinkRate(_fromToken, ethContract);
        uint256 fromETHRate = tryGetChainlinkRate(ethContract, _toToken);

        // If both rates returned, calculate the ratio between the two, then scale it to the correct decimals
        if (toETHRate != 0 && fromETHRate != 0) {
            uint256 derivedRate = toETHRate.mul(fromETHRate);
            return _scaleAmountFromTokenDecimals(_toToken, derivedRate, 18);
        }

        return 0;
    }

    function _getUniswapV2Rate(IERC20Extension _fromToken, IERC20Extension _toToken) internal view returns (uint256) {
        // Uniswap doesn't handle the ETH contract (0xeee), so update to WETH address for rate fetching
        if (_fromToken == ethContract) {
            _fromToken = WETH;
        }

        if (_toToken == ethContract) {
            _toToken = WETH;
        }

        // The rate fetching path
        address[] memory path = UniswapV2Helpers._returnUniswapV2Path(_fromToken, _toToken);

        // The return path function will return an array of 0x0 addresses if it can't find a valid path
        if (path.length == 0) return 0;

        // To calculate the amount we need to provide an amountIn. This needs to be normalised based on the amount of decimals in the given _fromToken.
        uint8 inputDecimals = _getDecimals(_fromToken);

        // Apply the decimals to the amount
        uint256 amountIn = 1 * 10 ** inputDecimals;

        // Safely call the method
        try uniswapV2Router.getAmountsOut(amountIn, path) returns (uint256[] memory rate) {
            return rate[path.length - 1];
        } catch {
            return 0;
        }
    }

    function _getExchangeRate(IERC20Extension _fromToken, IERC20Extension _toToken) internal view returns (uint256) {
        // If both tokens are either ETH or WETH, then return 1 ether as they are equivalent in value
        if ((_isEth(_fromToken) || _fromToken == WETH) && (_isEth(_toToken) || _toToken == WETH)) {
            return 1 ether;
        }

        // Try and get a rate from chainlink first
        uint256 chainlinkRate = _getChainlinkRate(_fromToken, _toToken);
        if (chainlinkRate != 0) return chainlinkRate;

        // Fallback to uniswap V2 if needed
        uint256 uniswapV2Rate = _getUniswapV2Rate(_fromToken, _toToken);

        if (uniswapV2Rate != 0) return uniswapV2Rate;

        revert("No Rate Found");
    }

    function _calculatePercentageFeeInETH(
        IERC20Extension _token,
        uint256 _amount,
        uint256 _gasRefund
    ) internal view returns (uint256 feeTotalInETH, uint256 feeTotalInToken) {
        if (_gasRefund == 0 && feePercentage == 0) {
            return (0, 0);
        }

        uint256 exchangeRateToETH = _getExchangeRate(_token, WETH);

        uint8 tokenDecimals = _getDecimals(_token);

        // To calculate the correct value here we must scale the value, either up or down depending on the decimals in _fromToken
        uint256 amountInETH = _scaleAmountFromDecimals(_amount.mul(exchangeRateToETH), tokenDecimals, 18);

        require(amountInETH > _gasRefund, "Not swapping enough to recover the gas refund");

        // Deducting _gasRefund from the amountInETH, because the _gasRefund is already being added on-top of the percentageFeeInETH and we don't want to double-charge
        uint256 percentageFeeInETH = (amountInETH - _gasRefund).mul(feePercentage);

        feeTotalInETH = percentageFeeInETH + _gasRefund;

        uint256 scaledFeeTotalFromToken = _scaleAmountFromDecimals(feeTotalInETH, 18, tokenDecimals);
        uint256 scaledExchangeRate = uint256(1 ether).div(exchangeRateToETH);

        feeTotalInToken = scaledFeeTotalFromToken.mul(scaledExchangeRate);
    }

    /// @notice This method simplifies handling approvals, it also contains logic to detect if the approval balance is greater than the supplied amount (in-case of tokens that decrement the approval balance when the balance is MAX uint256)
    /// @param _token The token to do unlimited approvals for
    /// @param _token The token to handle approvals for
    /// @param _amount The amount to validate the approval balance for
    function _handleApprovalFromThis(IERC20Extension _token, address _spender, uint256 _amount) internal {
        if (_isEth(_token) || _token.allowance(address(this), _spender) >= _amount) {
            return;
        }

        _token.safeApprove(_spender, type(uint256).max);
    }

    /// @notice This method is targeted at handling approvals when swapping through Uniswap. The difference being Uniswap doesn't support swapping WETH -> ETH and we will instead wrap the ETH using the WETH contract directly. So modify the approval address if the conditions are met
    /// @param _fromToken The token to do unlimited approvals for
    /// @param _toToken The token that we are swapping into
    /// @param _amount The amount to validate the approval balance for
    function _handleApprovalFromThisForUniswap(
        IERC20Extension _fromToken,
        IERC20Extension _toToken,
        uint256 _amount
    ) internal {
        if (_fromToken == WETH && _toToken == ethContract) {
            _handleApprovalFromThis(_fromToken, address(WETH), _amount);
        } else {
            _handleApprovalFromThis(_fromToken, address(uniswapV2Router), _amount);
        }
    }
}