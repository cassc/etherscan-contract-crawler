// SPDX-License-Identifier: ISC

pragma solidity ^0.8.13;
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "solidity-bytes-utils/contracts/BytesLib.sol";

import "./interface/ICurveRegistryAddressProvider.sol";
import "./interface/ICurveRegistry.sol";
import "./interface/ICurveFi.sol";
import "./interface/ISwapRouterCurve.sol";
import "../BaseSwapper.sol";

import "hardhat/console.sol";

/*
    Expands swapping functionality over base strategy
    - ETH in and ETH out Variants
    - Sushiswap support in addition to Uniswap
*/
contract CurveSwapper is BaseSwapper {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;
    using BytesLib for bytes;

    address public constant addressProvider =
    0x0000000022D53366457F9d5E68Ec105046FC4383;

    uint256 public constant registryId = 0;
    uint256 public constant metaPoolFactoryId = 3;

    // CURVE
    function _exchange_multiple(
        address _router,
        address _startToken,
        uint256 _amountIn,
        uint256 _amountsOutMin,
        bytes memory _pathData,
        address _recipient
    ) internal returns(uint){

        _safeApproveHelper(_startToken, _router, _amountIn);

        // encode path data curve
        (address[9] memory pathAddress, uint[3][4] memory swapParams, address[4] memory poolAddress) = _encodePathDataCurve(_pathData);

        return ISwapRouterCurve(_router).exchange_multiple(pathAddress, swapParams, _amountIn, _amountsOutMin, poolAddress, _recipient);
    }

    function _add_liquidity_single_coin(
        address swap,
        address inputToken,
        uint256 inputAmount,
        uint256 inputPosition,
        uint256 numPoolElements,
        uint256 min_mint_amount
    ) internal {
        _safeApproveHelper(inputToken, swap, inputAmount);
        if (numPoolElements == 2) {
            uint256[2] memory convertedAmounts;
            convertedAmounts[inputPosition] = inputAmount;
            ICurveFi(swap).add_liquidity(convertedAmounts, min_mint_amount);
        } else if (numPoolElements == 3) {
            uint256[3] memory convertedAmounts;
            convertedAmounts[inputPosition] = inputAmount;
            ICurveFi(swap).add_liquidity(convertedAmounts, min_mint_amount);
        } else if (numPoolElements == 4) {
            uint256[4] memory convertedAmounts;
            convertedAmounts[inputPosition] = inputAmount;
            ICurveFi(swap).add_liquidity(convertedAmounts, min_mint_amount);
        } else {
            revert("Bad numPoolElements");
        }
    }

    function _add_liquidity(
        address pool,
        uint256[2] memory amounts,
        uint256 min_mint_amount
    ) internal {
        ICurveFi(pool).add_liquidity(amounts, min_mint_amount);
    }

    function _add_liquidity(
        address pool,
        uint256[3] memory amounts,
        uint256 min_mint_amount
    ) internal {
        ICurveFi(pool).add_liquidity(amounts, min_mint_amount);
    }

    function _add_liquidity_4coins(
        address pool,
        uint256[4] memory amounts,
        uint256 min_mint_amount
    ) internal {
        ICurveFi(pool).add_liquidity(amounts, min_mint_amount);
    }

    function _remove_liquidity_one_coin(
        address swap,
        uint256 _token_amount,
        int128 i,
        uint256 _min_amount
    ) internal {
        ICurveFi(swap).remove_liquidity_one_coin(_token_amount, i, _min_amount);
    }

    function _encodePathDataCurve(bytes memory _data)
    internal pure
    returns(address[9] memory, uint[3][4] memory, address[4] memory) {
        address[9] memory addresses;
        uint[3][4] memory swapParams;
        address[4] memory poolAddress;

        uint offset = 0;
        uint j = 0;
        uint k = 0;
        uint q = 0;

        for (uint256 i = 0; i < 25; i++) {
            if ( i < 9 ) {
                offset = 20 *i;
                addresses[i] = _bytesToAddress(_data.slice(offset, 20));

            }
            if(i == 9) offset += 20;
            if ( i >= 9 && i < 21 ) {
                if(i == 12 || i == 15 || i == 18) {
                    j++;
                    k = 0;
                }
                bytes1 dataSlice = bytes1(_data.slice(offset, 1));
                swapParams[j][k] = uint(uint8(dataSlice));
                k++;
                offset += 1;
            }
            if ( i >= 21 ) {
                poolAddress[q] = _bytesToAddress(_data.slice(offset, 20));
                q += 1;
                offset += 20;
            }
        }
        return (addresses, swapParams, poolAddress);
    }

    function sliceUint8(bytes memory bs, uint start)
    internal pure
    returns (uint8)
    {
        require(bs.length >= start + 1, "slicing out of range");
        uint8 x;
        assembly {
            x := mload(add(bs, add(1, start)))
        }
        return x;
    }

}