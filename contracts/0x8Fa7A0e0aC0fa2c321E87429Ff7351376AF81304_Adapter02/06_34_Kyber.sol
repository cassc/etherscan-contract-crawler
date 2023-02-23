// SPDX-License-Identifier: ISC

pragma solidity 0.7.5;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./IKyberNetwork.sol";
import "../Utils.sol";

contract Kyber {
    struct KyberData {
        uint256 minConversionRateForBuy;
        bytes hint;
    }

    address payable public immutable _feeWallet;
    uint256 public immutable _platformFeeBps;

    constructor(address payable feeWallet, uint256 platformFeeBps) public {
        _feeWallet = feeWallet;
        _platformFeeBps = platformFeeBps;
    }

    function swapOnKyber(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 fromAmount,
        address kyberAddress,
        bytes calldata payload
    ) internal {
        KyberData memory data = abi.decode(payload, (KyberData));

        _swapOnKyber(
            address(fromToken),
            address(toToken),
            fromAmount,
            1,
            kyberAddress,
            data.hint,
            _feeWallet,
            _platformFeeBps
        );
    }

    function buyOnKyber(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 fromAmount,
        uint256 toAmount,
        address kyberAddress,
        bytes calldata payload
    ) internal {
        KyberData memory data = abi.decode(payload, (KyberData));

        Utils.approve(address(kyberAddress), address(fromToken), fromAmount);

        if (address(fromToken) == Utils.ethAddress()) {
            IKyberNetwork(kyberAddress).tradeWithHintAndFee{ value: fromAmount }(
                address(fromToken),
                fromAmount,
                address(toToken),
                payable(address(this)),
                toAmount,
                data.minConversionRateForBuy,
                _feeWallet,
                _platformFeeBps,
                data.hint
            );
        } else {
            IKyberNetwork(kyberAddress).tradeWithHintAndFee(
                address(fromToken),
                fromAmount,
                address(toToken),
                payable(address(this)),
                toAmount,
                data.minConversionRateForBuy,
                _feeWallet,
                _platformFeeBps,
                data.hint
            );
        }
    }

    function _swapOnKyber(
        address fromToken,
        address toToken,
        uint256 fromAmount,
        uint256 toAmount,
        address kyberAddress,
        bytes memory hint,
        address payable _feeWallet,
        uint256 _platformFeeBps
    ) private returns (uint256) {
        Utils.approve(kyberAddress, fromToken, fromAmount);

        uint256 receivedAmount = 0;

        if (fromToken == Utils.ethAddress()) {
            receivedAmount = IKyberNetwork(kyberAddress).tradeWithHintAndFee{ value: fromAmount }(
                fromToken,
                fromAmount,
                toToken,
                payable(address(this)),
                Utils.maxUint(),
                toAmount,
                _feeWallet,
                _platformFeeBps,
                hint
            );
        } else {
            receivedAmount = IKyberNetwork(kyberAddress).tradeWithHintAndFee(
                fromToken,
                fromAmount,
                toToken,
                payable(address(this)),
                Utils.maxUint(),
                toAmount,
                _feeWallet,
                _platformFeeBps,
                hint
            );
        }
        return receivedAmount;
    }
}