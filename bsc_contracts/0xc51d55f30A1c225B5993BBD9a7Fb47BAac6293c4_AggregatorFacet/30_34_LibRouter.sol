// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.17;

import {LibDiamond} from "../diamond/LibDiamond.sol";
import {IAddressProvider} from "../interfaces/curve/IAddressProvider.sol";
import {Amm, AppStorage, CurveSettings, LibMagpieAggregator} from "../libraries/LibMagpieAggregator.sol";
import {LibAsset} from "../libraries/LibAsset.sol";
import {LibBytes} from "../libraries/LibBytes.sol";
import {LibUint256Array} from "../libraries/LibUint256Array.sol";
import {Hop} from "./LibCommon.sol";

struct SwapArgs {
    uint256 amountOutMin;
    uint256 deadline;
    uint256[] amountIns;
    bytes32[] hops;
    bytes addresses;
    bytes poolData;
}

struct SwapState {
    uint256 i;
    uint256 lastAmountOut;
    uint256 hopsLength;
    uint256 amountIn;
    uint256 amountInAcc;
    address fromAssetAddress;
    address toAssetAddress;
    address currentFromAssetAddress;
}

error RouterAmmCallFailed(bytes returnData);
error RouterInvalidPath();
error RouterExpiredTransaction();
error RouterInsufficientOutputAmount();
error RouterInvalidAmountIn();
error RouterInvalidProtocol();

library LibRouter {
    using LibAsset for address;
    using LibBytes for bytes;
    using LibUint256Array for uint256[];

    function getHopParams(
        bytes32 data,
        bytes memory addresses,
        bytes memory poolData,
        uint256[] memory amountIns
    )
        public
        pure
        returns (
            uint16 ammId,
            uint256 amountIn,
            address[] memory path,
            bytes[] memory poolDataList
        )
    {
        uint256 pl;
        uint256 pdl;
        uint256 poolDataPosition;
        uint256 poolDataLength;

        assembly {
            amountIn := mload(add(amountIns, add(32, mul(shr(248, data), 32))))
            ammId := shr(240, shl(8, data))
            pl := shr(248, shl(24, data))
            pdl := shr(248, shl(32, data))
        }

        path = new address[](pl);

        assembly {
            let i := 0
            let pathPosition := add(path, 32)

            for {

            } lt(i, pl) {
                i := add(i, 1)
                pathPosition := add(pathPosition, 32)
            } {
                mstore(
                    pathPosition,
                    shr(
                        96,
                        mload(
                            add(
                                add(addresses, 32),
                                mul(
                                    shr(248, shl(mul(add(5, i), 8), data)), /* pathIndex */
                                    20
                                )
                            )
                        )
                    )
                )
            }
        }

        poolDataList = new bytes[](pdl);

        for (uint256 i = 0; i < pdl; ) {
            assembly {
                poolDataPosition := shr(248, shl(mul(add(9, i), 8), data))
                poolDataLength := shr(240, shl(mul(add(13, mul(i, 2)), 8), data))
            }

            poolDataList[i] = poolData.slice(poolDataPosition, poolDataLength);

            unchecked {
                i++;
            }
        }
    }

    function swap(SwapArgs memory swapArgs) internal returns (uint256 amountOut) {
        AppStorage storage s = LibMagpieAggregator.getStorage();
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();

        address fromAssetAddress = swapArgs.addresses.toAddress(20);
        address toAssetAddress = swapArgs.addresses.toAddress(40);

        SwapState memory ss = SwapState({
            i: 0,
            lastAmountOut: 0,
            hopsLength: swapArgs.hops.length,
            amountIn: swapArgs.amountIns.sum(),
            amountInAcc: 0,
            fromAssetAddress: fromAssetAddress,
            toAssetAddress: toAssetAddress,
            currentFromAssetAddress: fromAssetAddress
        });

        if (fromAssetAddress.isNative()) {
            ss.fromAssetAddress = s.weth;
            ss.currentFromAssetAddress = s.weth;
        } else if (toAssetAddress.isNative()) {
            ss.toAssetAddress = s.weth;
        }

        Hop memory hop = Hop({addr: address(0), amountIn: 0, poolDataList: new bytes[](0), path: new address[](0)});

        if (ss.hopsLength == 0) {
            ss.amountInAcc = ss.amountIn;
            amountOut = ss.amountIn;
        }

        for (ss.i; ss.i < ss.hopsLength; ) {
            uint16 ammId;
            uint256 amountIn;
            (ammId, amountIn, hop.path, hop.poolDataList) = getHopParams(
                swapArgs.hops[ss.i],
                swapArgs.addresses,
                swapArgs.poolData,
                swapArgs.amountIns
            );
            hop.addr = s.amms[ammId].addr;

            if (hop.path[0].isNative()) {
                hop.path[0] = s.weth;
            } else if (hop.path[hop.path.length - 1].isNative()) {
                hop.path[hop.path.length - 1] = s.weth;
            }

            if ((ss.currentFromAssetAddress == ss.toAssetAddress || ss.i == 0) && hop.path[0] == ss.fromAssetAddress) {
                ss.currentFromAssetAddress = ss.fromAssetAddress;
                hop.amountIn = amountIn;
                ss.amountInAcc += hop.amountIn;
            } else {
                hop.amountIn = ss.lastAmountOut;
            }

            address hopToAssetAddress = hop.path[hop.path.length - 1];

            if (ss.currentFromAssetAddress != hop.path[0]) {
                revert RouterInvalidPath();
            }

            if (ss.currentFromAssetAddress == ss.toAssetAddress) {
                if (amountOut > hop.amountIn) {
                    amountOut -= hop.amountIn;
                } else {
                    amountOut = 0;
                }
            }

            if (s.amms[ammId].protocolId == 0) {
                revert RouterInvalidProtocol();
            }

            address facet = ds.selectorToFacetAndPosition[s.amms[ammId].selector].facetAddress;
            bytes memory ammCall = abi.encodeWithSelector(s.amms[ammId].selector, hop);
            (bool success, bytes memory returnData) = address(facet).delegatecall(ammCall);
            if (!success) {
                revert RouterAmmCallFailed(returnData);
            }

            ss.lastAmountOut = hopToAssetAddress.getBalance() - s.deposits[hopToAssetAddress];

            if (hopToAssetAddress == ss.toAssetAddress) {
                amountOut = ss.lastAmountOut;
            }

            ss.currentFromAssetAddress = hopToAssetAddress;

            unchecked {
                ss.i++;
            }
        }

        if (amountOut < swapArgs.amountOutMin || amountOut == 0) {
            revert RouterInsufficientOutputAmount();
        }

        if (ss.amountIn != ss.amountInAcc) {
            revert RouterInvalidAmountIn();
        }
    }

    function enforceDeadline(uint256 deadline) internal view {
        if (deadline < block.timestamp) {
            revert RouterExpiredTransaction();
        }
    }
}