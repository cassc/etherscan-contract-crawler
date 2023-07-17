// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./Inscription.sol";
import "./Base64.sol";

contract Ethernals is Inscription, Ownable {
    using Counters for Counters.Counter;

    string public constant ETHERNAL_HEAER = "eth";
    uint8 public constant ETHERNAL_VER = 1;

    string private baseURL;
    Counters.Counter private _inscriptionIdTracker;

    constructor(
        string memory _baseURL
    ) Inscription("Ethernal Inscriptions", "INSCRIPTION") {
        baseURL = _baseURL;
        _inscriptionIdTracker.increment(); // default inscription ID 1
    }

    /**
     * @dev inscribe an inscription.
     * The inscribing function solely validates the format of the calldata and does not verify its content. 
     * The correct content data should be prepared.
     * The inscribing function does not check for content duplication.
     *
     * Ethernals are inscribed by sending a transaction to the contract, the calldata must encoded as follows:
     *  - 3 bytes: header, must be "eth"
     *  - 1 byte: version, must be 1
     *  - 1 byte: content type length
     *  - content type bytes with length of content type length
     *  - 4 byte: content length
     *  - content bytes with length of content length
     *
     * @param input the calldata to be inscribed
     * @return bytes inscription ID encoded by abi.encode(uint256)
     */
    fallback(bytes calldata input) external returns (bytes memory) {
        require(msg.sender == tx.origin, "only EOA");
        require(keccak256(abi.encodePacked(string(input[0:3]))) == keccak256(abi.encodePacked(ETHERNAL_HEAER)), "invalid header");
        require(uint8(input[3]) == ETHERNAL_VER, "invalid version");
        uint8 ctlen = uint8(input[4]);
        uint32 clen = uint32(bytes4(input[5+ctlen:9+ctlen]));
        require(ctlen > 0 && clen > 0 && input.length == 9 + ctlen + clen, "invalid calldata length");

        uint256 id = _inscriptionIdTracker.current();
        _inscriptionIdTracker.increment();
        _inscribe(msg.sender, id, new bytes(0));
        return abi.encode(id);
    }

    receive() external payable {
        revert();
    }

    function tokenURI(uint256 inscriptionId) override public view returns (string memory) {
        string[17] memory parts;
        parts[0] = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 300 300"><style>.base { fill: white; font-family: serif; font-size: 14px; }</style><rect width="100%" height="100%" fill="black" /><text x="10" y="30" class="base">';
        parts[1] = string(abi.encodePacked('Ethernals Protocol'));
        parts[2] = '</text><text x="10" y="60" class="base">';
        parts[3] = string(abi.encodePacked('Inscription #', toString(inscriptionId)));
        parts[4] = '</text><text x="10" y="90" class="base">';
        parts[5] = string(abi.encodePacked(baseURL, '/inscription/', toString(inscriptionId)));
        parts[6] = '</text></svg>';

        string memory output = string(abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4], parts[5], parts[6]));
        
        string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "Inscription #', toString(inscriptionId), '", "description": "The Ethernals protocol is a new way of inscribing inscriptions on the Ethereum blockchain. The content of the inscription is immutable, and the data is permanently stored on the Ethereum blockchain. Inscription supports a variety of content formats, including text, images, HTMLs, and videos.", "image": "data:image/svg+xml;base64,', Base64.encode(bytes(output)), '"}'))));
        output = string(abi.encodePacked('data:application/json;base64,', json));

        return output;
    }

    function inscriptionURL(uint256 inscriptionId) override public view returns (string memory) {
        return string(abi.encodePacked(baseURL, '/preview/', toString(inscriptionId)));
    }

    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT license
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
}