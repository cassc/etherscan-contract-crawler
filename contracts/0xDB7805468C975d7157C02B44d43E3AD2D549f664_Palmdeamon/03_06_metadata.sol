pragma solidity ^0.8.0;
import "./generativesvg.sol";

contract Metadata is GenerativeSvg {
    function generatemetadata(
        uint256 id,
        uint256 moisture,
        uint256 temperature,
        uint256 locationcolor,
        string memory rtimestamp
    ) public view returns (string memory) {
        string memory name = generatename(id);
        string memory description = "Seed Capital - Certificates of Growth";
        string memory attributes = generateattributes(
            cschemes[locationcolor].venue,
            cschemes[locationcolor].curator
        );
        string memory image = getsvgbase64(
            moisture,
            temperature,
            locationcolor,
            rtimestamp,
            id
        );
        return
            string(
                abi.encodePacked(
                    "data:text/plain,"
                    '{"name":"',
                    name,
                    '", "description":"',
                    description,
                    '", "image": "',
                    image,
                    '",',
                    '"attributes": ',
                    attributes,
                    "}"
                )
            );
    }

    function generatename(uint256 tokenId)
        internal
        pure
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    "Certificate of Growth ",
                    Strings.toString(tokenId)
                )
            );
    }

    function generateattributes(
        string memory venue,
        string memory curator
    ) internal pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    "[",
                    '{"trait_type":"Venue",',
                    '"value":"',
                    venue,
                    '"},',
                    '{"trait_type":"Curator",',
                    '"value":"',
                    curator,
                    '"}'
                    "]"
                )
            );
    }
}