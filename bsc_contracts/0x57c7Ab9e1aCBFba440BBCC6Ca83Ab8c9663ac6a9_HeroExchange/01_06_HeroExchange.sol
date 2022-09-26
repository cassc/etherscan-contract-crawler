// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./lib/openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./lib/openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./lib/Signature.sol";
import "./Configable.sol";

contract HeroExchange is ReentrancyGuard, Configable {
    enum Quality { Blue, Purple, Orange }
    address immutable b_treasury;
    address immutable b_nft0;
    address immutable b_nft1;
    address public s_signer;
    mapping(Quality => uint16[]) private s_quality2tokenIds;
    mapping(Quality => uint16) private s_quality2index;

    event Exchange(address caller, uint tokenId0, uint tokenId1);

    constructor(address treasury, address nft0, address nft1, address signer) {
        require(treasury != address (0) && nft0 != address(0) && nft1 != address(0) && signer != address(0), "invalid params");
        b_treasury = treasury;
        b_nft0 = nft0;
        b_nft1 = nft1;
        s_signer = signer;
        owner = msg.sender;
    }

    function setTokenIds(Quality quality, uint16[] memory tokenIds) external onlyOwner {
        uint length = 700;
        if (quality == Quality.Purple) {
            length = 200;
        } else if (quality == Quality.Orange) {
            length = 100;
        }
        require(tokenIds.length == length, "wrong tokenIds length");
        s_quality2tokenIds[quality] = tokenIds;
    }

    function setSigner(address signer) external onlyOwner {
        require(s_signer != signer && signer != address(0), "invalid signer");
        s_signer = signer;
    }

    function exchange(uint tokenId0, Quality quality, bytes memory signature) external nonReentrant {
        require(_verifySingle(tokenId0 , quality, signature), "invalid signatures");
        _exchange(tokenId0, quality);
    }

    function batchExchange(uint[] memory tokenIds0, Quality[] memory qualities, bytes memory signature) external nonReentrant {
        require(tokenIds0.length == qualities.length, "invalid params length");
        require(_verifyBatch(tokenIds0, qualities, signature), "invalid signatures");
        for (uint i = 0; i < tokenIds0.length; i++) {
            _exchange(tokenIds0[i], qualities[i]);
        }
    }

    function qualityIndex(Quality quality) external view returns(uint16) {
        return s_quality2index[quality];
    }

    function _exchange(uint tokenId0, Quality quality) internal {
        uint tokenId1 = s_quality2tokenIds[quality][s_quality2index[quality]];
        IERC721(b_nft0).transferFrom(msg.sender, address(this), tokenId0);
        IERC721(b_nft1).transferFrom(b_treasury, msg.sender, tokenId1);
        s_quality2index[quality] = s_quality2index[quality] + 1;
        emit Exchange(msg.sender, tokenId0, tokenId1);
    }

    function _verifySingle(
        uint tokenId0,
        Quality quality,
        bytes memory signature
    ) public view returns (bool) {
        bytes32 message = keccak256(abi.encodePacked(tokenId0, quality, address(this)));
        bytes32 hash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", message));
        address[] memory signList = Signature.recoverAddresses(hash, signature);
        return signList[0] == s_signer;
    }

    function _verifyBatch(
        uint[] memory tokenIds0,
        Quality[] memory qualities,
        bytes memory signature
    ) public view returns (bool) {
        bytes32 message = keccak256(abi.encodePacked(tokenIds0, qualities, address(this)));
        bytes32 hash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", message));
        address[] memory signList = Signature.recoverAddresses(hash, signature);
        return signList[0] == s_signer;
    }

    function _verifyBatch2(
        uint[] memory tokenIds0,
        uint[] memory qualities,
        bytes memory signature
    ) public view returns (bool) {
        bytes32 message = keccak256(abi.encodePacked(tokenIds0, qualities, address(this)));
        bytes32 hash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", message));
        address[] memory signList = Signature.recoverAddresses(hash, signature);
        return signList[0] == s_signer;
    }
}