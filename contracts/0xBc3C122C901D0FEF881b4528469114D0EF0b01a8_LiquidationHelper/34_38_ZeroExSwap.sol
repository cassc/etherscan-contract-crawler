// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../lib/RevertBytes.sol";

/// @dev Based on demo contract that swaps its ERC20 balance for another ERC20.
/// demo source: https://github.com/0xProject/0x-api-starter-guide-code/blob/master/contracts/SimpleTokenSwap.sol
contract ZeroExSwap is Ownable {
    using RevertBytes for bytes;

    /// @param sellToken The `sellTokenAddress` field from the API response.
    /// @param buyToken The `buyTokenAddress` field from the API response.
    /// @param allowanceTarget The `allowanceTarget` field from the API response.
    /// @param swapCallData The `data` field from the API response.
    struct SwapInput0x {
        address sellToken;
        address allowanceTarget;
        bytes swapCallData;
    }

    /// @dev 0x ExchangeProxy address.
    /// See https://docs.0x.org/developer-resources/contract-addresses
    /// The `to` field from the API response, but at the same time,
    /// TODO: maybe unit test that will check, if it does not changed?
    // solhint-disable-next-line var-name-mixedcase
    address public immutable EXCHANGE_PROXY;

    event BoughtTokens(address sellToken, address buyToken, uint256 boughtAmount);

    error AddressZero();
    error TargetNotExchangeProxy();
    error ApprovalFailed();

    constructor(address _exchangeProxy) {
        if (_exchangeProxy == address(0)) revert AddressZero();

        EXCHANGE_PROXY = _exchangeProxy;
    }

    /// @dev Swaps ERC20->ERC20 tokens held by this contract using a 0x-API quote.
    /// Must attach ETH equal to the `value` field from the API response.
    /// @param _sellToken The `sellTokenAddress` field from the API response.
    /// @param _spender The `allowanceTarget` field from the API response.
    /// @param _swapCallData The `data` field from the API response.
    function fillQuote(address _sellToken, address _spender, bytes memory _swapCallData) public {
        IERC20(_sellToken).approve(_spender, type(uint256).max);

        // Call the encoded swap function call on the contract at `swapTarget`
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory data) = EXCHANGE_PROXY.call(_swapCallData);
        if (!success) data.revertBytes("SWAP_CALL_FAILED");

        IERC20(_sellToken).approve(_spender, 0);
    }
}