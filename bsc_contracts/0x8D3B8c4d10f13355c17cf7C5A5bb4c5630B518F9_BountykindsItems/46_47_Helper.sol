// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;
pragma abicoder v2;

library Helper {
    function toAddress(uint256 val_) internal pure returns (address) {
        return address(uint160(val_));
    }

    function toAddress(uint256 val_, bool shifted_) internal pure returns (address addr) {
        unchecked {
            addr = shifted_ ? address(uint160(val_ >> 0x60)) : address(uint160(val_));
        }
    }

    function toBytes32(uint256 val_) internal pure returns (bytes32) {
        return bytes32(val_);
    }

    function toUint256(address addr_) internal pure returns (uint256) {
        return uint256(uint160(addr_));
    }

    function toUint256(bytes32 data_) internal pure returns (uint256) {
        return uint256(data_);
    }

    function decode(bytes memory result_) internal pure returns (string memory) {
        if (result_.length < 68) return "";
        assembly {
            result_ := add(result_, 0x04)
        }
        return abi.decode(result_, (string));
    }
}