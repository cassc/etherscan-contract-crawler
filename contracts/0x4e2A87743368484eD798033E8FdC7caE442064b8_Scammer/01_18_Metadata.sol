pragma solidity ^0.5.0;
/**
* Metadata contract is upgradeable and returns metadata about Token
*/

import "./helpers/strings.sol";

contract Metadata {
    using strings for *;

    string private baseUrl;

    constructor(string memory _baseUrl) public {
        baseUrl = _baseUrl;
    }

    function tokenURI(uint _tokenId) public view returns (string memory _infoUrl) {
        string memory basePath = "/v1/metadata/";
        string memory base = baseUrl.toSlice().concat(basePath.toSlice());
        string memory id = uint2str(_tokenId);
        return base.toSlice().concat(id.toSlice());
    }

    function contractURI() public view returns (string memory) {
        string memory path = "/v1/metadata";
        return baseUrl.toSlice().concat(path.toSlice());
    }

    function uint2str(uint i) internal pure returns (string memory) {
        if (i == 0) return "0";
        uint j = i;
        uint length;
        while (j != 0) {
            length++;
            j /= 10;
        }
        bytes memory bstr = new bytes(length);
        uint k = length - 1;
        while (i != 0) {
            uint _uint = 48 + i % 10;
            bstr[k--] = toBytes(_uint)[31];
            i /= 10;
        }
        return string(bstr);
    }
    function toBytes(uint256 x) public pure returns (bytes memory b) {
        b = new bytes(32);
        assembly { mstore(add(b, 32), x) }
    }
}