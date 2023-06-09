pragma solidity ^0.8.4;

interface OriginalAnonymiceInterface {
    struct Trait {
        string traitName;
        string traitType;
        string pixels;
        uint256 pixelCount;
    }
    function _tokenIdToHash(uint _tokenId) external view returns (string memory);
    function traitTypes(uint a, uint b) external view returns (string memory, string memory, string memory, uint);
}