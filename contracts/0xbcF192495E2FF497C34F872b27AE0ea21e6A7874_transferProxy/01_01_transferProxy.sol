// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

/// @author lcfr.eth
/// @notice helper contract for Flashbots rescues using bundler.lcfr.io

contract transferProxy {

    error notApproved();

    function transfer(bytes[] calldata _data, address _contract, address _from) external {
        assembly {
            // check if caller isApprovedForAll() by _from on _contract or revert
            mstore(0x00, shl(224, 0xe985e9c5)) 
            mstore(0x04, _from) 
            mstore(0x24, caller())

            let success := staticcall(gas(), _contract, 0x00, 0x44, 0x00, 0x00)

            returndatacopy(0x00, 0x00, returndatasize())

            if iszero(success) {
                revert(0x00, returndatasize())
            }
            
            if iszero(mload(0x00)) {
                mstore(0x00, shl(224, 0x383462e29))
                revert(0x00, 0x04)
            }

            let i := 0
            for {} 1 { i:= add(i, 1) } {
                if eq(i, _data.length){ break }

                let data := calldataload(add(_data.offset, shl(5, i)))
                let len := calldataload(add(_data.offset, data))

                calldatacopy(0x00, add(_data.offset, add(data, 0x20)), len)
                        
                success := call( gas(), _contract, 0x00, 0x00, len, 0x00, 0x00)

                if iszero(success) {
                    returndatacopy(0x00, 0x00, returndatasize())
                    revert(0x00, returndatasize())
                }
            }
        }
    }
}