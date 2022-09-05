pragma solidity ^0.8.0;

struct AppStorage {
  mapping(uint256 => string) tokenIdToImage;
  mapping(uint256 => bool) tokenIdToToggleGif;
  string name;
}

library LibAppStorage {

    function diamondStorage() internal pure returns (AppStorage storage ds) {
        assembly {
            ds.slot := 0
        }
    }

    function abs(int256 x) internal pure returns (uint256) {
        return uint256(x >= 0 ? x : -x);
    }
}