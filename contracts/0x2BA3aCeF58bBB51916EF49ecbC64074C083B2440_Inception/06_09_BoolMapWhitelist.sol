///SPDX-License-Identifier:MIT
pragma solidity 0.8.13;

/*
This contract is modified version of openzeppelin bitmap https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/structs/BitMaps.sol
Goal is storing 255 boolean in one slot. First bit cannot be changed by users.
*/

contract BoolMap {
    mapping(uint256 => uint256) private mintMap;
    uint256 private totalWhitelistedAddresses;

    //Makes the first bit of the slots 1. In this way, the person who mints first and the person who mint the second pays the same gas fee.
    function optimizeSlots(uint256 whitelistedAddressAmount) internal {
        uint256 _totalWhitelistedAddresses = totalWhitelistedAddresses;
        uint256 startSlot = _totalWhitelistedAddresses % 255 == 0
            ? _totalWhitelistedAddresses / 255
            : (_totalWhitelistedAddresses / 255) + 1;

        uint256 totalAddress = _totalWhitelistedAddresses + whitelistedAddressAmount;
        uint256 finalSlot = totalAddress % 255 == 0 ? totalAddress / 255 : (totalAddress / 255) + 1;

        for (uint256 i = startSlot; i < finalSlot; ) {
            mintMap[i] |= 1;

            unchecked {
                ++i;
            }
        }

        totalWhitelistedAddresses = totalAddress;
    }

    function setMinted(uint16 index) internal {
        uint256 slot = index / 255;
        mintMap[slot] |= 2 << (index % 255);
    }

    function canMint(uint16 index) internal view returns (bool) {
        uint256 slot = index / 255;
        uint256 num = mintMap[slot] & (2 << (index % 255));
        return num == 0;
    }
}