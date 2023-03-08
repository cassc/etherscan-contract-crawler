// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.17;

import {Amm, AppStorage, LibMagpieAggregator} from "../libraries/LibMagpieAggregator.sol";
import {LibAsset} from "../libraries/LibAsset.sol";
import {LibBytes} from "../libraries/LibBytes.sol";
import {LibUint256Array} from "../libraries/LibUint256Array.sol";
import {LibAggregator} from "../aggregator/LibAggregator.sol";
import {LibBalancerV2} from "./LibBalancerV2.sol";
import {LibCurve} from "./LibCurve.sol";
import {LibDodoV2} from "./LibDodoV2.sol";
import {LibUniswapV2} from "./LibUniswapV2.sol";
import {LibUniswapV3} from "./LibUniswapV3.sol";
import "../libraries/LibError.sol";

struct Hop {
    address addr;
    uint256 amountIn;
    bytes32[] poolData;
    address[] path;
}

struct SwapArgs {
    bytes addresses;
    uint256 amountOutMin;
    uint256[] amountIns;
    bytes32[] poolDataList;
    bytes32[] hops;
    uint256 deadline;
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

library LibRouter {
    using LibAsset for address;
    using LibBytes for bytes;
    using LibUint256Array for uint256[];

    function getHopParams(
        bytes32 data,
        bytes memory addresses,
        bytes32[] memory poolDataList,
        uint256[] memory amountIns
    )
        public
        pure
        returns (
            uint16 ammId,
            uint256 amountIn,
            address[] memory path,
            bytes32[] memory poolData
        )
    {
        uint256 l;

        assembly {
            amountIn := mload(add(amountIns, add(32, mul(shr(248, data), 32))))
            ammId := shr(240, shl(8, data))
            l := shr(248, shl(24, data))
        }

        path = new address[](l);
        poolData = new bytes32[](l);

        assembly {
            let i := 0
            let pathPosition := add(path, 32)
            let poolDataPosition := add(poolData, 32)

            for {

            } lt(i, l) {
                i := add(i, 1)
                pathPosition := add(pathPosition, 32)
                poolDataPosition := add(poolDataPosition, 32)
            } {
                mstore(
                    pathPosition,
                    shr(
                        96,
                        mload(
                            add(
                                add(addresses, 32),
                                mul(
                                    shr(248, shl(mul(add(4, i), 8), data)), /* pathIndex */
                                    20
                                )
                            )
                        )
                    )
                )
                mstore(
                    poolDataPosition,
                    mload(
                        add(
                            add(poolDataList, 32),
                            mul(
                                shr(248, shl(mul(add(8, i), 8), data)), /* poolDataIndex */
                                32
                            )
                        )
                    )
                )
            }
        }
    }

    function swap(SwapArgs memory swapArgs) internal returns (uint256 amountOut) {
        AppStorage storage s = LibMagpieAggregator.getStorage();

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

        if (ss.fromAssetAddress == ss.toAssetAddress && ss.hopsLength > 0) {
            revert InvalidFromToAddress();
        }

        Hop memory hop = Hop({addr: address(0), amountIn: 0, poolData: new bytes32[](0), path: new address[](0)});

        if (ss.hopsLength == 0) {
            ss.amountInAcc = ss.amountIn;
            amountOut = ss.amountIn;
        }

        for (ss.i; ss.i < ss.hopsLength; ) {
            uint16 ammId;
            uint256 amountIn;
            (ammId, amountIn, hop.path, hop.poolData) = getHopParams(
                swapArgs.hops[ss.i],
                swapArgs.addresses,
                swapArgs.poolDataList,
                swapArgs.amountIns
            );
            hop.addr = s.amms[ammId].addr;
            hop.amountIn = (ss.currentFromAssetAddress == ss.fromAssetAddress ? amountIn : ss.lastAmountOut);

            if (hop.path[0].isNative()) {
                hop.path[0] = s.weth;
            } else if (hop.path[hop.path.length - 1].isNative()) {
                hop.path[hop.path.length - 1] = s.weth;
            }

            if (ss.currentFromAssetAddress != hop.path[0]) {
                revert InvalidPath();
            }

            address hopToAssetAddress = hop.path[hop.path.length - 1];

            if (ss.currentFromAssetAddress == ss.fromAssetAddress) {
                ss.amountInAcc += hop.amountIn;
            }

            if (s.amms[ammId].protocolId == 1) {
                LibUniswapV2.swapUniswapV2(hop);
            } else if (s.amms[ammId].protocolId == 2 || s.amms[ammId].protocolId == 3) {
                LibBalancerV2.swapBalancerV2(hop);
            } else if (s.amms[ammId].protocolId == 6) {
                LibUniswapV3.swapUniswapV3(hop);
            } else if (
                s.amms[ammId].protocolId == 4 || s.amms[ammId].protocolId == 5 || s.amms[ammId].protocolId == 7
            ) {
                LibCurve.swapCurve(hop);
            } else if (s.amms[ammId].protocolId == 8) {
                LibDodoV2.swapDodoV2(hop);
            } else {
                revert InvalidProtocol();
            }

            ss.lastAmountOut = hopToAssetAddress.getBalance() - s.deposits[hopToAssetAddress];

            if (hopToAssetAddress == ss.toAssetAddress) {
                amountOut += ss.lastAmountOut;
                ss.currentFromAssetAddress = ss.fromAssetAddress;
            } else {
                ss.currentFromAssetAddress = hopToAssetAddress;
            }

            unchecked {
                ss.i++;
            }
        }

        if (amountOut < swapArgs.amountOutMin || amountOut == 0) {
            revert InsufficientOutputAmount();
        }

        if (ss.amountIn != ss.amountInAcc) {
            revert InvalidAmountIn();
        }
    }

    event AddAmm(address indexed sender, uint16 ammId, Amm amm);

    function addAmm(uint16 ammId, Amm memory amm) internal {
        AppStorage storage s = LibMagpieAggregator.getStorage();

        s.amms[ammId] = amm;

        emit AddAmm(msg.sender, ammId, amm);
    }

    event AddAmms(address indexed sender, uint16[] ammIds, Amm[] amms);

    function addAmms(uint16[] memory ammIds, Amm[] memory amms) internal {
        AppStorage storage s = LibMagpieAggregator.getStorage();

        uint256 i;
        uint256 l = amms.length;
        for (i = 0; i < l; ) {
            s.amms[ammIds[i]] = amms[i];

            unchecked {
                i++;
            }
        }

        emit AddAmms(msg.sender, ammIds, amms);
    }

    event RemoveAmm(address indexed sender, uint16 ammId);

    function removeAmm(uint16 ammId) internal {
        AppStorage storage s = LibMagpieAggregator.getStorage();

        delete s.amms[ammId];

        emit RemoveAmm(msg.sender, ammId);
    }
}