pragma solidity ^0.8.0;

struct Trait {
    string traitName;
    string traitType;
    string[] pixels;
    uint256[] pixelCount;
}

struct AppStorage {
  mapping(uint256 => Trait[]) traitTypes;
  mapping(string => bool) hashToMinted;
  mapping(uint256 => string) tokenIdToHash;
  mapping(uint256 => string) tokenIdToName;
  mapping(uint256 => string) tokenIdToBio;
  mapping(uint256 => uint256) tokenIdToLevel;
	mapping (string => bool) nameReserved;
  uint256 LAST_MINT_TIME;
  uint256 MAX_SUPPLY;
  uint256 SEED_NONCE;
  uint16[][20] TIERS;
  string name;
  string[] LETTERS;
  address _owner;
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