// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import {ERC20} from "lib/solmate/src/tokens/ERC20.sol";
import {SafeTransferLib} from "lib/solmate/src/utils/SafeTransferLib.sol";
import {UniswapV2Swapper} from "../dexHelpers/uniswapV2.sol";
import {UniswapV3Swapper} from "../dexHelpers/uniswapV3.sol";
import {CurveSwapper} from "../dexHelpers/curve.sol";

abstract contract SwapController is
    UniswapV2Swapper,
    UniswapV3Swapper,
    CurveSwapper
{
    using SafeTransferLib for ERC20;
    address public immutable balancerVault;
    error FailedSwap();

    constructor(
        address _uniswapV2Factory,
        address _sushiFactory,
        address _uniswapV3Factory,
        address _balancerVault,
        address _wethAddress,
        bytes memory _primaryInitHash,
        bytes memory _secondaryInitHash
    )
        UniswapV2Swapper(
            _uniswapV2Factory,
            _sushiFactory,
            _primaryInitHash,
            _secondaryInitHash
        )
        UniswapV3Swapper(_uniswapV3Factory)
        CurveSwapper(_wethAddress)
    {
        if (_balancerVault == address(0)) revert InvalidInput();
        balancerVault = _balancerVault;
    }

    function _swap(
        bytes1 dexId,
        uint256 fromAmount,
        bytes calldata swapPayload
    ) internal returns (uint256) {
        if (dexId == 0x01) return _swapUniswapV2(0x01, fromAmount, swapPayload);
        else if (dexId == 0x02) return _swapUniswapV3(fromAmount, swapPayload);
        else if (dexId == 0x03)
            return _swapUniswapV2(0x02, fromAmount, swapPayload);
        else if (dexId == 0x04) return _swapWithCurve(swapPayload);
        else revert InvalidInput();
    }

    function _swapBalancer(
        bytes calldata swapPayload
    ) internal returns (uint256) {
        (bool success, bytes memory data) = balancerVault.call(swapPayload);
        if (!success) revert FailedSwap();

        bytes4 selector = abi.decode(swapPayload, (bytes4));
        if (selector == bytes4(0x52bbbe29)) {
            return abi.decode(data, (uint256));
        } else {
            int256[] memory assetDeltas = abi.decode(data, (int256[]));
            for (uint256 i = 0; i < assetDeltas.length; ) {
                if (assetDeltas[i] < 0) return uint256(-assetDeltas[i]);
                unchecked {
                    i++;
                }
            }
            revert FailedSwap();
        }
    }
}