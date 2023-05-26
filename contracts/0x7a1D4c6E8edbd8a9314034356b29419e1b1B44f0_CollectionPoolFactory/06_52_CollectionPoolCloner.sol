// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import {ERC20} from "solmate/src/tokens/ERC20.sol";

import {ICurve} from "../bonding-curves/ICurve.sol";
import {ICollectionPoolFactory} from "../pools/ICollectionPoolFactory.sol";

library CollectionPoolCloner {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     *
     * During the delegate call, extra data is copied into the calldata which can then be
     * accessed by the implementation contract.
     */
    function cloneETHPool(
        address implementation,
        ICollectionPoolFactory factory,
        ICurve bondingCurve,
        IERC721 nft,
        uint8 poolType
    ) internal returns (address instance) {
        uint256 blockNumber = block.number;

        assembly {
            let ptr := mload(0x40)

            // -------------------------------------------------------------------------------------------------------------
            // CREATION (9 bytes)
            // -------------------------------------------------------------------------------------------------------------

            // creation size = 09
            // runtime size = 76
            // 60 runtime  | PUSH1 runtime (r)     | r                       | –
            // 3d          | RETURNDATASIZE        | 0 r                     | –
            // 81          | DUP2                  | r 0 r                   | –
            // 60 creation | PUSH1 creation (c)    | c r 0 r                 | –
            // 3d          | RETURNDATASIZE        | 0 c r 0 r               | –
            // 39          | CODECOPY              | 0 r                     | [0-runSize): runtime code
            // f3          | RETURN                |                         | [0-runSize): runtime code

            // -------------------------------------------------------------------------------------------------------------
            // RUNTIME (53 bytes of code + 65 bytes of extra data = 118 bytes)
            // -------------------------------------------------------------------------------------------------------------

            // extra data size = 41
            // 3d          | RETURNDATASIZE        | 0                       | –
            // 3d          | RETURNDATASIZE        | 0 0                     | –
            // 3d          | RETURNDATASIZE        | 0 0 0                   | –
            // 3d          | RETURNDATASIZE        | 0 0 0 0                 | –
            // 36          | CALLDATASIZE          | cds 0 0 0 0             | –
            // 3d          | RETURNDATASIZE        | 0 cds 0 0 0 0           | –
            // 3d          | RETURNDATASIZE        | 0 0 cds 0 0 0 0         | –
            // 37          | CALLDATACOPY          | 0 0 0 0                 | [0, cds) = calldata
            // 60 extra    | PUSH1 extra           | extra 0 0 0 0           | [0, cds) = calldata
            // 60 0x35     | PUSH1 0x35            | 0x35 extra 0 0 0 0      | [0, cds) = calldata // 0x35 (53) is runtime size - data
            // 36          | CALLDATASIZE          | cds 0x35 extra 0 0 0 0  | [0, cds) = calldata
            // 39          | CODECOPY              | 0 0 0 0                 | [0, cds) = calldata, [cds, cds+0x35) = extraData
            // 36          | CALLDATASIZE          | cds 0 0 0 0             | [0, cds) = calldata, [cds, cds+0x35) = extraData
            // 60 extra    | PUSH1 extra           | extra cds 0 0 0 0       | [0, cds) = calldata, [cds, cds+0x35) = extraData
            // 01          | ADD                   | cds+extra 0 0 0 0       | [0, cds) = calldata, [cds, cds+0x35) = extraData
            // 3d          | RETURNDATASIZE        | 0 cds 0 0 0 0           | [0, cds) = calldata, [cds, cds+0x35) = extraData
            // 73 addr     | PUSH20 0x123…         | addr 0 cds 0 0 0 0      | [0, cds) = calldata, [cds, cds+0x35) = extraData
            mstore(
                ptr,
                hex"60_76_3d_81_60_09_3d_39_f3_3d_3d_3d_3d_36_3d_3d_37_60_41_60_35_36_39_36_60_41_01_3d_73_00_00_00"
            )
            mstore(add(ptr, 0x1d), shl(0x60, implementation))

            // 5a          | GAS                   | gas addr 0 cds 0 0 0 0  | [0, cds) = calldata, [cds, cds+0x35) = extraData
            // f4          | DELEGATECALL          | success 0 0             | [0, cds) = calldata, [cds, cds+0x35) = extraData
            // 3d          | RETURNDATASIZE        | rds success 0 0         | [0, cds) = calldata, [cds, cds+0x35) = extraData
            // 3d          | RETURNDATASIZE        | rds rds success 0 0     | [0, cds) = calldata, [cds, cds+0x35) = extraData
            // 93          | SWAP4                 | 0 rds success 0 rds     | [0, cds) = calldata, [cds, cds+0x35) = extraData
            // 80          | DUP1                  | 0 0 rds success 0 rds   | [0, cds) = calldata, [cds, cds+0x35) = extraData
            // 3e          | RETURNDATACOPY        | success 0 rds           | [0, rds) = return data (there might be some irrelevant leftovers in memory [rds, cds+0x37) when rds < cds+0x37)
            // 60 0x33     | PUSH1 0x33            | 0x33 sucess 0 rds       | [0, rds) = return data
            // 57          | JUMPI                 | 0 rds                   | [0, rds) = return data
            // fd          | REVERT                | –                       | [0, rds) = return data
            // 5b          | JUMPDEST              | 0 rds                   | [0, rds) = return data
            // f3          | RETURN                | –                       | [0, rds) = return data
            mstore(
                add(ptr, 0x31),
                hex"5a_f4_3d_3d_93_80_3e_60_33_57_fd_5b_f3_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00"
            )

            // -------------------------------------------------------------------------------------------------------------
            // EXTRA DATA (65 bytes)
            // -------------------------------------------------------------------------------------------------------------

            mstore(add(ptr, 0x3e), shl(0x60, factory))
            mstore(add(ptr, 0x52), shl(0x60, bondingCurve))
            mstore(add(ptr, 0x66), shl(0x60, nft))
            mstore8(add(ptr, 0x7a), poolType)
            mstore(add(ptr, 0x7b), shl(0xe0, blockNumber)) // lower 32 bits only

            instance := create(0, ptr, 0x7f)
        }
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     *
     * During the delegate call, extra data is copied into the calldata which can then be
     * accessed by the implementation contract.
     */
    function cloneERC20Pool(
        address implementation,
        ICollectionPoolFactory factory,
        ICurve bondingCurve,
        IERC721 nft,
        uint8 poolType,
        ERC20 token
    ) internal returns (address instance) {
        uint256 blockNumber = block.number;

        assembly {
            let ptr := mload(0x40)

            // -------------------------------------------------------------------------------------------------------------
            // CREATION (9 bytes)
            // -------------------------------------------------------------------------------------------------------------

            // creation size = 09
            // runtime size = 8a
            // 60 runtime  | PUSH1 runtime (r)     | r                       | –
            // 3d          | RETURNDATASIZE        | 0 r                     | –
            // 81          | DUP2                  | r 0 r                   | –
            // 60 creation | PUSH1 creation (c)    | c r 0 r                 | –
            // 3d          | RETURNDATASIZE        | 0 c r 0 r               | –
            // 39          | CODECOPY              | 0 r                     | [0-runSize): runtime code
            // f3          | RETURN                |                         | [0-runSize): runtime code

            // -------------------------------------------------------------------------------------------------------------
            // RUNTIME (53 bytes of code + 85 bytes of extra data = 138 bytes)
            // -------------------------------------------------------------------------------------------------------------

            // extra data size = 55
            // 3d          | RETURNDATASIZE        | 0                       | –
            // 3d          | RETURNDATASIZE        | 0 0                     | –
            // 3d          | RETURNDATASIZE        | 0 0 0                   | –
            // 3d          | RETURNDATASIZE        | 0 0 0 0                 | –
            // 36          | CALLDATASIZE          | cds 0 0 0 0             | –
            // 3d          | RETURNDATASIZE        | 0 cds 0 0 0 0           | –
            // 3d          | RETURNDATASIZE        | 0 0 cds 0 0 0 0         | –
            // 37          | CALLDATACOPY          | 0 0 0 0                 | [0, cds) = calldata
            // 60 extra    | PUSH1 extra           | extra 0 0 0 0           | [0, cds) = calldata
            // 60 0x35     | PUSH1 0x35            | 0x35 extra 0 0 0 0      | [0, cds) = calldata // 0x35 (53) is runtime size - data
            // 36          | CALLDATASIZE          | cds 0x35 extra 0 0 0 0  | [0, cds) = calldata
            // 39          | CODECOPY              | 0 0 0 0                 | [0, cds) = calldata, [cds, cds+0x35) = extraData
            // 36          | CALLDATASIZE          | cds 0 0 0 0             | [0, cds) = calldata, [cds, cds+0x35) = extraData
            // 60 extra    | PUSH1 extra           | extra cds 0 0 0 0       | [0, cds) = calldata, [cds, cds+0x35) = extraData
            // 01          | ADD                   | cds+extra 0 0 0 0       | [0, cds) = calldata, [cds, cds+0x35) = extraData
            // 3d          | RETURNDATASIZE        | 0 cds 0 0 0 0           | [0, cds) = calldata, [cds, cds+0x35) = extraData
            // 73 addr     | PUSH20 0x123…         | addr 0 cds 0 0 0 0      | [0, cds) = calldata, [cds, cds+0x35) = extraData
            mstore(
                ptr,
                hex"60_8a_3d_81_60_09_3d_39_f3_3d_3d_3d_3d_36_3d_3d_37_60_55_60_35_36_39_36_60_55_01_3d_73_00_00_00"
            )
            mstore(add(ptr, 0x1d), shl(0x60, implementation))

            // 5a          | GAS                   | gas addr 0 cds 0 0 0 0  | [0, cds) = calldata, [cds, cds+0x35) = extraData
            // f4          | DELEGATECALL          | success 0 0             | [0, cds) = calldata, [cds, cds+0x35) = extraData
            // 3d          | RETURNDATASIZE        | rds success 0 0         | [0, cds) = calldata, [cds, cds+0x35) = extraData
            // 3d          | RETURNDATASIZE        | rds rds success 0 0     | [0, cds) = calldata, [cds, cds+0x35) = extraData
            // 93          | SWAP4                 | 0 rds success 0 rds     | [0, cds) = calldata, [cds, cds+0x35) = extraData
            // 80          | DUP1                  | 0 0 rds success 0 rds   | [0, cds) = calldata, [cds, cds+0x35) = extraData
            // 3e          | RETURNDATACOPY        | success 0 rds           | [0, rds) = return data (there might be some irrelevant leftovers in memory [rds, cds+0x37) when rds < cds+0x37)
            // 60 0x33     | PUSH1 0x33            | 0x33 sucess 0 rds       | [0, rds) = return data
            // 57          | JUMPI                 | 0 rds                   | [0, rds) = return data
            // fd          | REVERT                | –                       | [0, rds) = return data
            // 5b          | JUMPDEST              | 0 rds                   | [0, rds) = return data
            // f3          | RETURN                | –                       | [0, rds) = return data
            mstore(
                add(ptr, 0x31),
                hex"5a_f4_3d_3d_93_80_3e_60_33_57_fd_5b_f3_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00"
            )

            // -------------------------------------------------------------------------------------------------------------
            // EXTRA DATA (85 bytes)
            // -------------------------------------------------------------------------------------------------------------

            mstore(add(ptr, 0x3e), shl(0x60, factory))
            mstore(add(ptr, 0x52), shl(0x60, bondingCurve))
            mstore(add(ptr, 0x66), shl(0x60, nft))
            mstore8(add(ptr, 0x7a), poolType)
            mstore(add(ptr, 0x7b), shl(0xe0, blockNumber)) // lower 32 bits only
            mstore(add(ptr, 0x7f), shl(0x60, token))

            instance := create(0, ptr, 0x93)
        }
    }

    /**
     * @notice Checks if a contract is a clone of a CollectionPoolETH.
     * @dev Only checks the runtime bytecode, does not check the extra data.
     * @param factory the factory that deployed the clone
     * @param implementation the CollectionPoolETH implementation contract
     * @param query the contract to check
     * @return result True if the contract is a clone, false otherwise
     */
    function isETHPoolClone(
        address factory,
        address implementation,
        address query
    ) internal view returns (bool result) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(
                ptr,
                hex"3d_3d_3d_3d_36_3d_3d_37_60_41_60_35_36_39_36_60_41_01_3d_73_00_00_00_00_00_00_00_00_00_00_00_00"
            )
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(
                add(ptr, 0x28),
                hex"5a_f4_3d_3d_93_80_3e_60_33_57_fd_5b_f3_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00"
            )
            mstore(add(ptr, 0x35), shl(0x60, factory))

            // compare expected bytecode with that of the queried contract
            let other := add(ptr, 0x49)
            extcodecopy(query, other, 0, 0x49)
            result := and(
                eq(mload(ptr), mload(other)),
                and(
                    eq(mload(add(ptr, 0x20)), mload(add(other, 0x20))),
                    eq(mload(add(ptr, 0x29)), mload(add(other, 0x29)))
                )
            )
        }
    }

    /**
     * @notice Checks if a contract is a clone of a CollectionPoolERC20.
     * @dev Only checks the runtime bytecode, does not check the extra data.
     * @param implementation the CollectionPoolERC20 implementation contract
     * @param query the contract to check
     * @return result True if the contract is a clone, false otherwise
     */
    function isERC20PoolClone(
        address factory,
        address implementation,
        address query
    ) internal view returns (bool result) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(
                ptr,
                hex"3d_3d_3d_3d_36_3d_3d_37_60_55_60_35_36_39_36_60_55_01_3d_73_00_00_00_00_00_00_00_00_00_00_00_00"
            )
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(
                add(ptr, 0x28),
                hex"5a_f4_3d_3d_93_80_3e_60_33_57_fd_5b_f3_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00"
            )
            mstore(add(ptr, 0x35), shl(0x60, factory))

            // compare expected bytecode with that of the queried contract
            let other := add(ptr, 0x49)
            extcodecopy(query, other, 0, 0x49)
            result := and(
                eq(mload(ptr), mload(other)),
                and(
                    eq(mload(add(ptr, 0x20)), mload(add(other, 0x20))),
                    eq(mload(add(ptr, 0x29)), mload(add(other, 0x29)))
                )
            )
        }
    }
}