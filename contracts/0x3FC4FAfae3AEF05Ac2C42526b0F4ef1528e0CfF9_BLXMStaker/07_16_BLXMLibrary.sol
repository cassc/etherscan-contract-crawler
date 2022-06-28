// SPDX-License-Identifier: GPL-3.0 License

pragma solidity ^0.8.0;


library BLXMLibrary {

    function validateAddress(address _address) internal pure {
        // reduce contract size
        require(_address != address(0), "ZERO_ADDRESS");
    }

    function currentHour() internal view returns(uint32) {
        return uint32(block.timestamp / 1 hours);
    }
}