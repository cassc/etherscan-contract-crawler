// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {ERC721A} from "erc721a/contracts/ERC721A.sol";
import {ERC721ABurnable} from "erc721a/contracts/extensions/ERC721ABurnable.sol";
import {Ownable} from "openzeppelin-contracts/access/Ownable.sol";
import {IERC2981, ERC2981} from "@openzeppelin/contracts/token/common/ERC2981.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {OperatorFilterer} from "./OperatorFilterer.sol";


interface Distortion {
    function generateDistortion(uint256 tokenId) external view returns (string memory);
}

contract DistortionOrdinalClaimPass is ERC721A, ERC721ABurnable, OperatorFilterer, Ownable, ReentrancyGuard, ERC2981 {

    constructor() ERC721A("Distortion Ordinal Claim Pass", "DSTOCP") {
        _registerForOperatorFiltering();
        operatorFilteringEnabled = true;
        _setDefaultRoyalty(msg.sender, 500);
    }

    event bridgeDistortionEvent(uint256 indexed _tokenId, string _btcAddress, uint256 _number, string _inscription);

    struct inscriptionDetails {
        bool enabled;
        uint256 inscriptionNumber;
        string inscription;
        string color;
        string btcAddress;
        bool bridged;
    }

    event MetadataUpdate(uint256 _tokenId);
    mapping (uint256 => inscriptionDetails) tokenToInscriptionDetails;
    bool airdropCompleted;
    bool bridgeIsOpen;
    bool public operatorFilteringEnabled;
    address internal distortionAddress = 0x205A10c241cA38918d3790C89F16675cC46D10a9;
    bytes32 public root = 0x7b22e66c9205da18f358dd6bea45eda0e9b00fc7e1609040713b5ab33392bedd;

    function editRoot(bytes32 _root) external onlyOwner {
        root = _root;
    }

    function closeAirdrop() external onlyOwner {
        airdropCompleted = true;
    }

    function bridgeStatus(bool _open) external onlyOwner {
        bridgeIsOpen = _open;
    }

    function airdrop(address[] memory _addresses) public onlyOwner {
        require(!airdropCompleted, "Can only airdrop once.");
        for (uint i = 0; i < _addresses.length; i++) {
            _safeMint(msg.sender, 1);
        }
    }

    function updateMetadata(uint256 _tokenId, uint256 _inscriptionNumber, string memory _inscription, string memory _color, bytes32[] calldata _p) external nonReentrant{
        require(msg.sender == ownerOf(_tokenId), "Must be the owner of the token to update it's metadata.");
        require(!tokenToInscriptionDetails[_tokenId].enabled, "No need to update this token's metadata as it has already been set.");
        bool validProof = MerkleProof.verify(_p, root, keccak256(abi.encodePacked(_tokenId, _inscriptionNumber, _inscription, _color)));
        require(validProof, "If you want your pass to display an inscription number, or you want to bridge, you need to update your metadata. This is verified by a merkle root.");
        tokenToInscriptionDetails[_tokenId].inscriptionNumber = _inscriptionNumber;
        tokenToInscriptionDetails[_tokenId].inscription = _inscription;
        tokenToInscriptionDetails[_tokenId].color = _color;
        tokenToInscriptionDetails[_tokenId].enabled = true;
        emit MetadataUpdate(_tokenId);
    }

    function bridgDistortionToBitcoin(uint256 _tokenId, string memory _btcAddress, uint256 _inscriptionNumber, string memory _inscription, string memory _color, bytes32[] calldata _p) external nonReentrant {

        require(bridgeIsOpen, "Bridge must be open.");
        require(ownerOf(_tokenId) == msg.sender, "Must own a Distortion Pass to burn it.");

        tokenToInscriptionDetails[_tokenId].btcAddress = _btcAddress;
        tokenToInscriptionDetails[_tokenId].bridged = true;

        if (tokenToInscriptionDetails[_tokenId].enabled == true) {
            emit bridgeDistortionEvent(_tokenId, _btcAddress, tokenToInscriptionDetails[_tokenId].inscriptionNumber, tokenToInscriptionDetails[_tokenId].inscription);
        } else {
            bool validProof = MerkleProof.verify(_p, root, keccak256(abi.encodePacked(_tokenId, _inscriptionNumber, _inscription, _color)));
            require(validProof, "Must pass the proof to burn without metadata update.");
            tokenToInscriptionDetails[_tokenId].inscription = _inscription;
            emit bridgeDistortionEvent(_tokenId, _btcAddress, _inscriptionNumber, _inscription);
        }
        _burn(_tokenId, true);

    }

    function isTokenMetadataSet(uint256 _tokenId) public view returns (bool) {
        return tokenToInscriptionDetails[_tokenId].enabled;
    }

    function getTokenBridgingRequest(uint256 _tokenId) public view returns (string[2] memory) {
        require(tokenToInscriptionDetails[_tokenId].bridged, "Token is not bridged yet.");
        return [tokenToInscriptionDetails[_tokenId].btcAddress, tokenToInscriptionDetails[_tokenId].inscription];
    }
                                                       
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory inscrNum;
        string memory inscr;
        string memory color;

        if (tokenToInscriptionDetails[tokenId].enabled) {
            inscrNum = _toString(tokenToInscriptionDetails[tokenId].inscriptionNumber);
            inscr = tokenToInscriptionDetails[tokenId].inscription;
            color = tokenToInscriptionDetails[tokenId].color;
        } else {
            inscrNum = "Owner must update metadata.";
            inscr = "Owner must update metadata.";
            color = "Owner must update metadata.";
        }

        string memory dstImage = Base64.encode(bytes(Distortion(distortionAddress).generateDistortion(tokenId)));
        string memory image = Base64.encode(bytes(string(abi.encodePacked(
                '<svg width="100%" height="100%" style="background-color:black" version="1.1" viewBox="0 0 1e3 1e3" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink"> <rect x="20%" y="5%" width="60%" height="90%" style="fill:#101010;stroke-width:3;stroke:grey;" /> <image x="22.5%" y="7.5%" width="55%" height="55%" xlink:href="data:image/svg+xml;base64,',
                dstImage,
                '"></image> <rect x="20%" y="70%" width="60%" height="15%" style="fill:grey;stroke-width:3;stroke:grey;" /> <text x="50%" y="76%" dominant-baseline="middle" fill="#101010" font-family="Courier" font-size="80px" font-weight="250" text-anchor="middle">DISTORTION</text> <text x="50%" y="81%" dominant-baseline="middle" fill="#101010" font-family="Courier" font-size="43px" font-weight="250" text-anchor="middle">ORDINAL CLAIM PASS</text> <text x="50%" y="90%" dominant-baseline="middle" fill="grey" font-family="Courier" font-size="25px" font-weight="250" text-anchor="middle">',
                (!tokenToInscriptionDetails[tokenId].enabled) ? inscrNum : string(abi.encodePacked('Inscription #', inscrNum)),
                '</text></svg>'
            ))));

        string memory json = string(abi.encodePacked(
                '{"name": "Distortion Ordinal Claim Pass #',
                _toString(tokenId),
                '", "description": "This pass can be burned to obtain the associated inscription on the Bitcoin blockchain. View an inscription for a specific token ID, update your pass metadata or burn your pass for its corresponding Bitcoin inscription [here](https://distortion.nullish.org).","attributes": [ { "trait_type": "Inscription Number", "value": ',
                (!tokenToInscriptionDetails[tokenId].enabled) ? string(abi.encodePacked('"', inscrNum, '"')) : inscrNum,
                ' }, { "trait_type": "Inscription", "value": "',
                inscr,
                '"}, { "trait_type": "Color", "value": "',
                color,
                '"}],'
                '"image": "data:application/json;base64,',
                image,
                '"}'
            ));

        return string(abi.encodePacked('data:application/json;base64,',Base64.encode(bytes(json))));
    }

    function setApprovalForAll(address operator, bool approved)
        public
        override
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId)
        public
        payable
        override
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId)
        public
        payable
        override
        onlyAllowedOperator(from)
    {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId)
        public
        payable
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        payable
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override (ERC721A, ERC2981)
        returns (bool)
    {
        // Supports the following `interfaceId`s:
        // - IERC165: 0x01ffc9a7
        // - IERC721: 0x80ac58cd
        // - IERC721Metadata: 0x5b5e139f
        // - IERC2981: 0x2a55205a
        return ERC721A.supportsInterface(interfaceId) || ERC2981.supportsInterface(interfaceId);
    }

    function setDefaultRoyalty(address receiver, uint96 feeNumerator) public onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function setOperatorFilteringEnabled(bool value) public onlyOwner {
        operatorFilteringEnabled = value;
    }

    function _operatorFilteringEnabled() internal view override returns (bool) {
        return operatorFilteringEnabled;
    }

    function _isPriorityOperator(address operator) internal pure override returns (bool) {
        // OpenSea Seaport Conduit:
        // https://etherscan.io/address/0x1E0049783F008A0085193E00003D00cd54003c71
        // https://goerli.etherscan.io/address/0x1E0049783F008A0085193E00003D00cd54003c71
        return operator == address(0x1E0049783F008A0085193E00003D00cd54003c71);
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