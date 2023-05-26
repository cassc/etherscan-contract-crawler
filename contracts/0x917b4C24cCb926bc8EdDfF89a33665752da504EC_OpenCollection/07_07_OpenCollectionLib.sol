pragma solidity ^0.8.0;

library OpenCollectionLib {
    function _isUnique(uint256 randomNumber, uint256[] memory selected) private pure returns (bool) {
        for (uint256 j = 0; j < selected.length; j++) {
            if (selected[j] == randomNumber) {
                return false;
            }
        }
        return true;
    }

    function _selectUniqueRandom(uint256 seed, uint256 max, uint256 count) internal pure returns (uint256[] memory) {
        require(max >= count, "Count must be less than or equal to max");

        uint256[] memory selected = new uint256[](count);
        uint256 selectedIndex = 0;

        for (uint256 i = 0; selectedIndex < count; i++) {
            uint256 randomNumber = uint256(keccak256(abi.encodePacked(seed, selectedIndex, i))) % max;

            bool isUnique = _isUnique(randomNumber, selected);
            if (isUnique) {
                selected[selectedIndex] = randomNumber;
                selectedIndex++;
            }
        }

        return selected;
    }

    function toBytes32(address addr) internal pure returns (bytes32) {
        return bytes32(uint256(uint160(addr)) << 96);
    }
}