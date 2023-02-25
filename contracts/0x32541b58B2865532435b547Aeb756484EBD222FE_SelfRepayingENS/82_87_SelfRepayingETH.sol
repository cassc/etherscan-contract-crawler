// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {AlchemicTokenV2} from "../lib/alchemix/src/AlchemicTokenV2.sol";
import {IAlchemistV2} from "../lib/alchemix/src/interfaces/IAlchemistV2.sol";

import {ICurveCalc} from "./interfaces/ICurveCalc.sol";
import {ICurvePool} from "./interfaces/ICurvePool.sol";

/// @title SelfRepayingETH
/// @author Wary
///
/// @notice An contract helper to borrow alETH from an Alchemix account, exchange it for ETH.
abstract contract SelfRepayingETH {
    /// @notice The Alchemix alETH alchemistV2 contract.
    IAlchemistV2 public immutable alchemist;

    /// @notice The Alchemix alETH AlchemicTokenV2 contract.
    AlchemicTokenV2 public immutable alETH;

    /// @notice The CurveCalc contract.
    ICurveCalc public immutable curveCalc;

    /// @notice The alETH-ETH Curve Pool contract.
    ICurvePool public immutable alETHPool;

    /// @notice Emitted when `sreth` borrows `alETHAmount` of alETH from `owner` for `ethAmount` of ETH.
    ///
    /// @param owner The address of the Alchemix account owner.
    /// @param alETHAmount The amount of alETH debt tokens that were minted in wei.
    /// @param ethAmount The amount of exchanged ETH received in wei.
    event Borrow(address indexed owner, uint256 alETHAmount, uint256 ethAmount);

    /// @notice Initialize the contract.
    //
    /// @dev We annotate it payable to make it cheaper. Do not send ETH.
    constructor(IAlchemistV2 _alchemist, ICurvePool _alETHPool, ICurveCalc _curveCalc) payable {
        alchemist = _alchemist;
        alETHPool = _alETHPool;
        curveCalc = _curveCalc;

        alETH = AlchemicTokenV2(alchemist.debtToken());

        // Approve the `alETHPool` Curve Pool to transfer an (almost) unlimited amount of `alETH` tokens.
        alETH.approve(address(_alETHPool), type(uint256).max);
    }

    /// @notice Borrow some self repaying ETH `amount` from the `alETH` account owned by `owner`.
    ///
    /// @notice Emits a {Borrow} event.
    ///
    /// @notice **_NOTE:_** The `SelfRepayingETH` contract must have enough `AlchemistV2.mintAllowance()` to borrow `amount` ETH. The can be done via the `AlchemistV2.approveMint()` method.
    ///
    /// @dev **_NOTE:_** 💀 There is no protection against the alETH-ETH depeg.
    /// @dev **_NOTE:_** 💀 A large `amount` exchange will be taken advantage off by MEV bots in a sandwich attack.
    ///
    /// @param owner The address of the Alchemix account owner to mint alETH from.
    /// @param amount The amount of ETH to borrow in wei.
    function _borrowSelfRepayingETHFrom(address owner, uint256 amount) internal {
        // Get the EXACT amount of ETH debt (i.e. alETH) to mint from the Curve Pool by asking the CurveCalc contract.
        // ⚠️ Due to a Curve Pool limitation, we use `curveCalc.get_dx()` to get the EXACT ETH amount back in a transaction when ideally it should be called in a staticcall.
        // ⚠️ We do not check the alETH-ETH depeg.
        uint256 alETHToMint = _getAlETHToMint(amount);

        // Mint `alETHToMint` amount of alETH (i.e. debt token) from `owner` to `recipient` Alchemix account.
        alchemist.mintFrom(owner, alETHToMint, address(this));
        // Execute a Curve Pool exchange for `alETHToMint` amount of alETH tokens to at least `amount` ETH.
        alETHPool.exchange(
            1, // alETH
            0, // ETH
            alETHToMint,
            amount
        );

        emit Borrow(owner, alETHToMint, amount);
    }

    /// @dev Get the current alETH amount to get `amount` ETH amount back in from a Curve Pool exchange.
    ///
    /// @param amount The ETH amount to get back from the Curve alETH exchange in wei.
    /// @return alETHToMint The exact alETH amount to swap to get `amount` ETH back from a Curve exchange.
    function _getAlETHToMint(uint256 amount) internal view returns (uint256 alETHToMint) {
        unchecked {
            // Optimizing this solidity code:
            //
            // uint256[2] memory b = alETHPool.get_balances();
            // curveCalc.get_dx(
            //     2,
            //     [b[0], b[1], 0, 0, 0, 0, 0, 0],
            //     alETHPool.A(),
            //     alETHPool.fee(),
            //     [uint256(1e18), 1e18, 0, 0, 0, 0, 0, 0],
            //     [uint256(1), 1, 0, 0, 0, 0, 0, 0],
            //     false,
            //     1, // alETH
            //     0, // ETH
            //     amount + 1 // Because of rounding errors
            // );
            address pool = address(alETHPool);
            address calc = address(curveCalc);

            assembly ("memory-safe") {
                // Get the non allocated memory offset.
                let offset := mload(0x40)

                // Building the `curveCalc.get_dx()` calldata.
                //
                // Calldata layout:
                // fn sig (4 bytes): 0x00 -> 0x03
                // bytes4(keccak256("get_dx(int128,uint256[8],uint256,uint256,uint256[8],uint256[8],bool,int128,int128,uint256)"))
                // 0x9e440fb1
                // n_coins (32 bytes): 0x04 -> 0x23
                // 00...002
                // balances (256 bytes): 0x24 -> 0x0123
                // amp (32 bytes): 0x0124 -> 0x0143
                // fee (32 bytes): 0x0144 -> 0x0163
                // rates (256 bytes): 0x0164 -> 0x0263
                // precisions (256 bytes): 0x0263 -> 0x0363
                // underlying (32 bytes): 0x0364 -> 0x0383
                // i (32 bytes): 0x0384 -> 0x03A3
                // j (32 bytes): 0x03A4 -> 0x03C3
                // dy (32 bytes): 0x03C4 -> 0x03E3
                //
                // Optimizing MSTOREs.
                // 0x00 -> 0x1F: We concat the fn sig with the first 28 bytes of n_coins which are 0s.
                // So we can store the hardcoded fn sig << 0x70 (28 * 4 bits).
                mstore(offset, 0x9e440fb100000000000000000000000000000000000000000000000000000000)
                // 0x20 -> 0x23: First we store the value 0x02 at 0x23.
                mstore8(add(offset, 0x23), 0x02)
                // 0x24 -> 0x63: Then we call alETHPool.get_balances() and store its result at 0x24.
                // Prepare its calldata. fn sig = 0x14f05979
                let o := add(offset, 0x24)
                mstore(o, 0x14f0597900000000000000000000000000000000000000000000000000000000)
                // Execute the staticcall.
                let success :=
                    staticcall(
                        gas(), // gas
                        pool, // address
                        o, // argsOffset
                        0x04, // argsSize
                        // Reuse the memory used for the args.
                        o, // retOffset
                        0x40 // retSize
                    )
                // 0x0124 -> 0x0143: Call alETHPool.A() and store its result at 0x0124. It expands the memory and fills it with 0s.
                // Prepare its calldata.
                o := add(offset, 0x0124)
                mstore(o, 0xf446c1d000000000000000000000000000000000000000000000000000000000)
                // Execute the staticcall.
                success := staticcall(gas(), pool, o, 0x04, o, 0x20)
                // 0x0144 -> 0x0163: Call alETHPool.fee() and store its result at 0x0144.
                // Prepare its calldata.
                o := add(offset, 0x0144)
                mstore(o, 0xddca3f4300000000000000000000000000000000000000000000000000000000)
                // Execute the staticcall.
                success := staticcall(gas(), pool, o, 0x04, o, 0x20)
                // 0x0164 -> 0x0263: Store 2 1e18 on the first 64 bytes. The rest of the rates array will filled during the memory expand.
                mstore(add(offset, 0x0164), 1000000000000000000)
                mstore(add(offset, 0x0184), 1000000000000000000)
                // 0x0264 -> 0x0363: Store two 1 on the first 64 bytes and use the next memory expand to fill the rest.
                mstore(add(offset, 0x0264), 0x01)
                mstore(add(offset, 0x0284), 0x01)
                // 0x0364 -> 0x0383: Do nothing as false is 0.
                // 0x0384 -> 0x03A3
                mstore(add(offset, 0x0384), 0x01)
                // 0x03A4 -> 0x03C3: Do nothing as value is 0.
                // 0x03C4 -> 0x03E3
                mstore(add(offset, 0x03C4), add(amount, 0x01))

                // Execute the `get_dx()` call.
                o := add(offset, 0x03E4)
                success := staticcall(gas(), calc, offset, 0x03E4, o, 0x20)
                // Revert if call failed.
                if iszero(success) { revert(0x00, 0x00) }
                // Return `alETHToMint`.
                alETHToMint := mload(o)

                // Update the free memory pointer.
                mstore(0x40, add(o, 0x20))
            }
        }
    }

    /// @notice To receive ETH payments.
    /// @dev To receive ETH from alETHPool.exchange(). ⚠️ The contract can receive ETH from another Ethereum account.
    receive() external payable virtual;
}