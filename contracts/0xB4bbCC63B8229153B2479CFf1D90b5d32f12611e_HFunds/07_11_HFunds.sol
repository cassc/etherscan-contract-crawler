// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../../lib/LibFeeStorage.sol";
import "../HandlerBase.sol";

contract HFunds is HandlerBase {
    using SafeERC20 for IERC20;
    using LibFeeStorage for mapping(bytes32 => bytes32);

    event ChargeFee(address indexed tokenIn, uint256 feeAmount);

    function getContractName() public pure override returns (string memory) {
        return "HFunds";
    }

    function updateTokens(
        address[] calldata tokens
    ) external payable returns (uint256[] memory) {
        uint256[] memory balances = new uint256[](tokens.length);
        for (uint256 i = 0; i < tokens.length; ) {
            address token = tokens[i];
            if (token != address(0) && token != NATIVE_TOKEN_ADDRESS) {
                // Update involved token
                _updateToken(token);
            }
            balances[i] = _getBalance(token, type(uint256).max);
            unchecked {
                ++i;
            }
        }
        return balances;
    }

    function inject(
        address[] calldata tokens,
        uint256[] calldata amounts
    ) external payable returns (uint256[] memory) {
        return _inject(tokens, amounts);
    }

    // Same as inject() and just to make another interface for different use case
    function addFunds(
        address[] calldata tokens,
        uint256[] calldata amounts
    ) external payable returns (uint256[] memory) {
        return _inject(tokens, amounts);
    }

    function sendTokens(
        address[] calldata tokens,
        uint256[] calldata amounts,
        address payable receiver
    ) external payable {
        for (uint256 i = 0; i < tokens.length; ) {
            uint256 amount = _getBalance(tokens[i], amounts[i]);
            if (amount > 0) {
                // ETH case
                if (
                    tokens[i] == address(0) || tokens[i] == NATIVE_TOKEN_ADDRESS
                ) {
                    (bool success, ) = receiver.call{value: amount}("");
                    _requireMsg(success, "sendTokens", "failed to send Ether");
                } else {
                    IERC20(tokens[i]).safeTransfer(receiver, amount);
                }
            }
            unchecked {
                ++i;
            }
        }
    }

    function sendTokenToAddresses(
        address token,
        uint256[] calldata amounts,
        address payable[] calldata receivers
    ) external payable {
        _requireMsg(
            amounts.length == receivers.length,
            "sendTokenToAddresses",
            "amount and receiver does not match"
        );
        if (_isNotNativeToken(token)) {
            for (uint256 i = 0; i < amounts.length; ) {
                if (amounts[i] > 0) {
                    IERC20(token).safeTransfer(receivers[i], amounts[i]);
                }
                unchecked {
                    ++i;
                }
            }
        } else {
            for (uint256 i = 0; i < amounts.length; ) {
                if (amounts[i] > 0) {
                    (bool success, ) = receivers[i].call{value: amounts[i]}("");
                    _requireMsg(
                        success,
                        "sendTokenToAddresses",
                        "failed to send Ether"
                    );
                }
                unchecked {
                    ++i;
                }
            }
        }
    }

    function send(uint256 amount, address payable receiver) external payable {
        amount = _getBalance(address(0), amount);
        if (amount > 0) {
            (bool success, ) = receiver.call{value: amount}("");
            _requireMsg(success, "send", "failed to send Ether");
        }
    }

    function sendToken(
        address token,
        uint256 amount,
        address receiver
    ) external payable {
        amount = _getBalance(token, amount);
        if (amount > 0) {
            IERC20(token).safeTransfer(receiver, amount);
        }
    }

    /// @notice Send ether to block miner.
    /// @dev Transfer with built-in 2300 gas cap is safer and acceptable for most miners.
    /// @param amount The ether amount.
    function sendEtherToMiner(uint256 amount) external payable {
        if (amount > 0) {
            (bool success, ) = block.coinbase.call{value: amount}("");
            _requireMsg(success, "sendEtherToMiner", "failed to send Ether");
        }
    }

    function checkSlippage(
        address[] calldata tokens,
        uint256[] calldata amounts
    ) external payable {
        _requireMsg(
            tokens.length == amounts.length,
            "checkSlippage",
            "token and amount do not match"
        );

        for (uint256 i = 0; i < tokens.length; ) {
            if (tokens[i] == address(0)) {
                if (address(this).balance < amounts[i]) {
                    string memory errMsg = string(
                        abi.encodePacked(
                            "error: ",
                            _uint2String(i),
                            "_",
                            _uint2String(address(this).balance)
                        )
                    );
                    _revertMsg("checkSlippage", errMsg);
                }
            } else if (
                IERC20(tokens[i]).balanceOf(address(this)) < amounts[i]
            ) {
                string memory errMsg = string(
                    abi.encodePacked(
                        "error: ",
                        _uint2String(i),
                        "_",
                        _uint2String(IERC20(tokens[i]).balanceOf(address(this)))
                    )
                );

                _revertMsg("checkSlippage", errMsg);
            }
            unchecked {
                ++i;
            }
        }
    }

    function getBalance(address token) external payable returns (uint256) {
        return _getBalance(token, type(uint256).max);
    }

    function _inject(
        address[] calldata tokens,
        uint256[] calldata amounts
    ) internal returns (uint256[] memory) {
        _requireMsg(
            tokens.length == amounts.length,
            "inject",
            "token and amount does not match"
        );
        address sender = _getSender();
        uint256 feeRate = cache._getFeeRate();
        address collector = cache._getFeeCollector();
        uint256[] memory amountsInProxy = new uint256[](amounts.length);

        for (uint256 i = 0; i < tokens.length; ) {
            IERC20(tokens[i]).safeTransferFrom(
                sender,
                address(this),
                amounts[i]
            );
            if (feeRate > 0) {
                uint256 fee = _calFee(amounts[i], feeRate);
                IERC20(tokens[i]).safeTransfer(collector, fee);
                amountsInProxy[i] = amounts[i] - fee;
                emit ChargeFee(tokens[i], fee);
            } else {
                amountsInProxy[i] = amounts[i];
            }

            // Update involved token
            _updateToken(tokens[i]);

            unchecked {
                ++i;
            }
        }
        return amountsInProxy;
    }

    function _calFee(
        uint256 amount,
        uint256 feeRate
    ) internal pure returns (uint256) {
        return (amount * feeRate) / PERCENTAGE_BASE;
    }
}