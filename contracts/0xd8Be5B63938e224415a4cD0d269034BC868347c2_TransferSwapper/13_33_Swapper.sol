// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.8.15;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./CodecRegistry.sol";
import "./interfaces/ICodec.sol";
import "./interfaces/IWETH.sol";
import "./DexRegistry.sol";

/**
 * @title Loads codecs for the swaps and performs swap actions
 * @author Padoriku
 */
contract Swapper is CodecRegistry, DexRegistry {
    using SafeERC20 for IERC20;

    constructor(
        string[] memory _funcSigs,
        address[] memory _codecs,
        address[] memory _supportedDexList,
        string[] memory _supportedDexFuncs
    ) DexRegistry(_supportedDexList, _supportedDexFuncs) CodecRegistry(_funcSigs, _codecs) {}

    /**
     * @dev Checks the input swaps for that tokenIn and tokenOut for every swap should be the same
     * @param _swaps the swaps the check
     * @return sumAmtIn the sum of all amountIns in the swaps
     * @return tokenIn the input token of the swaps
     * @return tokenOut the desired output token of the swaps
     * @return codecs a list of codecs which each of them corresponds to a swap
     */
    function sanitizeSwaps(ICodec.SwapDescription[] memory _swaps)
        internal
        view
        returns (
            uint256 sumAmtIn,
            address tokenIn,
            address tokenOut,
            ICodec[] memory codecs // _codecs[i] is for _swaps[i]
        )
    {
        address prevTokenIn;
        address prevTokenOut;
        codecs = loadCodecs(_swaps);

        for (uint256 i = 0; i < _swaps.length; i++) {
            require(dexRegistry[_swaps[i].dex][bytes4(_swaps[i].data)], "unsupported dex");
            (uint256 _amountIn, address _tokenIn, address _tokenOut) = codecs[i].decodeCalldata(_swaps[i]);
            require(prevTokenIn == address(0) || prevTokenIn == _tokenIn, "tkin mismatch");
            prevTokenIn = _tokenIn;
            require(prevTokenOut == address(0) || prevTokenOut == _tokenOut, "tko mismatch");
            prevTokenOut = _tokenOut;

            sumAmtIn += _amountIn;
            tokenIn = _tokenIn;
            tokenOut = _tokenOut;
        }
    }

    /**
     * @notice Executes the swaps, decode their return values and sums the returned amount
     * @dev This function is intended to be used on src chain only
     * @dev This function immediately fails (return false) if any swaps fail. There is no "partial fill" on src chain
     * @param _swaps swaps. this function assumes that the swaps are already sanitized
     * @param _codecs the codecs for each swap
     * @return ok whether the operation is successful
     * @return sumAmtOut the sum of all amounts gained from swapping
     */
    function executeSwaps(
        ICodec.SwapDescription[] memory _swaps,
        ICodec[] memory _codecs // _codecs[i] is for _swaps[i]
    ) internal returns (bool ok, uint256 sumAmtOut) {
        for (uint256 i = 0; i < _swaps.length; i++) {
            (uint256 amountIn, address tokenIn, address tokenOut) = _codecs[i].decodeCalldata(_swaps[i]);
            bytes memory data = _codecs[i].encodeCalldataWithOverride(_swaps[i].data, amountIn, address(this));
            IERC20(tokenIn).safeIncreaseAllowance(_swaps[i].dex, amountIn);
            uint256 balBefore = IERC20(tokenOut).balanceOf(address(this));
            (ok, ) = _swaps[i].dex.call(data);
            if (!ok) {
                return (false, 0);
            }
            uint256 balAfter = IERC20(tokenOut).balanceOf(address(this));
            sumAmtOut += balAfter - balBefore;
        }
    }

    /**
     * @notice Executes the swaps with override, redistributes amountIns for each swap route,
     * decode their return values and sums the returned amount
     * @dev This function is intended to be used on dst chain only
     * @param _swaps swaps to execute. this function assumes that the swaps are already sanitized
     * @param _codecs the codecs for each swap
     * @param _amountInOverride the amountIn to substitute the amountIns in swaps for
     * @dev _amountInOverride serves the purpose of correcting the estimated amountIns to actual bridge outs
     * @dev _amountInOverride is also distributed according to the weight of each original amountIn
     * @return sumAmtOut the sum of all amounts gained from swapping
     * @return sumAmtFailed the sum of all amounts that fails to swap
     */
    function executeSwapsWithOverride(
        ICodec.SwapDescription[] memory _swaps,
        ICodec[] memory _codecs, // _codecs[i] is for _swaps[i]
        uint256 _amountInOverride,
        bool _allowPartialFill
    ) internal returns (uint256 sumAmtOut, uint256 sumAmtFailed) {
        (uint256[] memory amountIns, address tokenIn, address tokenOut) = _redistributeAmountIn(
            _swaps,
            _amountInOverride,
            _codecs
        );
        uint256 balBefore = IERC20(tokenOut).balanceOf(address(this));
        // execute the swaps with adjusted amountIns
        for (uint256 i = 0; i < _swaps.length; i++) {
            bytes memory swapCalldata = _codecs[i].encodeCalldataWithOverride(
                _swaps[i].data,
                amountIns[i],
                address(this)
            );
            IERC20(tokenIn).safeIncreaseAllowance(_swaps[i].dex, amountIns[i]);
            (bool ok, ) = _swaps[i].dex.call(swapCalldata);
            require(ok || _allowPartialFill, "swap failed");
            if (!ok) {
                sumAmtFailed += amountIns[i];
            }
        }
        uint256 balAfter = IERC20(tokenOut).balanceOf(address(this));
        sumAmtOut = balAfter - balBefore;
        require(sumAmtOut > 0, "all swaps failed");
    }

    /// @notice distributes the _amountInOverride to the swaps base on how much each original amountIns weight
    function _redistributeAmountIn(
        ICodec.SwapDescription[] memory _swaps,
        uint256 _amountInOverride,
        ICodec[] memory _codecs
    )
        private
        view
        returns (
            uint256[] memory amountIns,
            address tokenIn,
            address tokenOut
        )
    {
        uint256 sumAmtIn;
        amountIns = new uint256[](_swaps.length);

        // compute sumAmtIn and collect amountIns
        for (uint256 i = 0; i < _swaps.length; i++) {
            uint256 amountIn;
            (amountIn, tokenIn, tokenOut) = _codecs[i].decodeCalldata(_swaps[i]);
            sumAmtIn += amountIn;
            amountIns[i] = amountIn;
        }

        // compute adjusted amountIns with regard to the weight of each amountIns in total amountIn
        for (uint256 i = 0; i < amountIns.length; i++) {
            amountIns[i] = (_amountInOverride * amountIns[i]) / sumAmtIn;
        }
    }
}