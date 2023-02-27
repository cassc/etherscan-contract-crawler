// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;


import {Ownable} from "openzeppelin-contracts/access/Ownable.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {IERC721ABurnable} from "erc721a/contracts/extensions/IERC721ABurnable.sol";



contract DistortionBurnContract is Ownable, ReentrancyGuard  {

    event bridgeDistortionEvent(uint256 indexed _tokenId, string _btcAddress, uint256 _number, string _inscription);

    struct inscriptionDetails {
        uint256 inscriptionNumber;
        string inscription;
        string btcAddress;
        bool bridged;
    }

    mapping (uint256 => inscriptionDetails) tokenToInscriptionDetails;
    bool bridgeIsOpen = false;
    address internal distortionPassAddress = 0x71ac0BD96517F5469159745201702aB9227609E5;
    bytes32 public root = 0x7b22e66c9205da18f358dd6bea45eda0e9b00fc7e1609040713b5ab33392bedd;

    function editRoot(bytes32 _root) external onlyOwner {
        root = _root;
    }

    function bridgeStatus(bool _open) external onlyOwner {
        bridgeIsOpen = _open;
    }

    function burnDistortionPass(uint256 _tokenId, string memory _btcAddress, uint256 _inscriptionNumber, string memory _inscription, string memory _color, bytes32[] calldata _p) external nonReentrant {
        require(tx.origin == msg.sender);
        require(IERC721ABurnable(distortionPassAddress).ownerOf(_tokenId) == msg.sender, "Must own the token you are trying to burn.");
        if (msg.sender != owner()) { require(bridgeIsOpen, "Bridge must be open."); }
        bool validProof = MerkleProof.verify(_p, root, keccak256(abi.encodePacked(_tokenId, _inscriptionNumber, _inscription, _color)));
        require(validProof, "Must pass the correct proof");

        tokenToInscriptionDetails[_tokenId].btcAddress = _btcAddress;
        tokenToInscriptionDetails[_tokenId].bridged = true;
        tokenToInscriptionDetails[_tokenId].inscription = _inscription;
        
        IERC721ABurnable(distortionPassAddress).burn(_tokenId);
        emit bridgeDistortionEvent(_tokenId, _btcAddress, _inscriptionNumber, _inscription);
    }

    function getTokenBridgingRequest(uint256 _tokenId) public view returns (string[2] memory) {
        require(tokenToInscriptionDetails[_tokenId].bridged, "Token is not bridged yet.");
        return [tokenToInscriptionDetails[_tokenId].btcAddress, tokenToInscriptionDetails[_tokenId].inscription];
    }
                                                       


}


/// [MIT License]
/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <[email protected]>
library Base64 {
    bytes internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /// @notice Encodes some bytes to the base64 representation
    function encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((len + 2) / 3);

        // Add some extra buffer at the end
        bytes memory result = new bytes(encodedLen + 32);

        bytes memory table = TABLE;

        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)

            for {
                let i := 0
            } lt(i, len) {

            } {
                i := add(i, 3)
                let input := and(mload(add(data, i)), 0xffffff)

                let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(input, 0x3F))), 0xFF))
                out := shl(224, out)

                mstore(resultPtr, out)

                resultPtr := add(resultPtr, 4)
            }

            switch mod(len, 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }

            mstore(result, encodedLen)
        }

        return string(result);
    }
}