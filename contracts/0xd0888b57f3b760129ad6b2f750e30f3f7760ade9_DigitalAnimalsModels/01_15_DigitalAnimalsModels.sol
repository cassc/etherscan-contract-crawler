// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./IDigitalAnimals.sol";
import "./ReentrancyGuard.sol";
import "./Signable.sol";

contract DigitalAnimalsModels is ERC1155, Ownable, Signable, ReentrancyGuard {

    string public name = "Digital Animals Models Airdrop";
    string public symbol = "DAMA";

    string private _baseTokenURI;

    // DA Contract
    IDigitalAnimals private _originalContract;

    mapping(uint256 => uint256) private claimedBitMap;

    constructor(IDigitalAnimals originalContract) ERC1155("") { 
        _originalContract = originalContract;
        _baseTokenURI = "https://digitalanimals.club/airdrop_1/data/";
    }

    function setBaseURI(string memory baseURI_) public onlyOwner {
        _baseTokenURI = baseURI_;
    }

    function mint(uint256 tokenId, uint256 modelId, bytes calldata signature) public lock {
        require(!isClaimed(tokenId), "Token already claimed");
        require(_originalContract.ownerOf(tokenId) == msg.sender, "You don't own this token");
        require(_verify(signer(), _hash(tokenId, modelId), signature), "Invalid signature");
        _mint(msg.sender, modelId, 1, "");
        _setClaimed(tokenId);
    }

    function uri(uint256 index) public view virtual override returns (string memory) {
        return string(abi.encodePacked(_baseTokenURI, Strings.toString(index), ".json"));
    }

    function isClaimed(uint256 index) public view returns (bool) {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        uint256 claimedWord = claimedBitMap[claimedWordIndex];
        uint256 mask = (1 << claimedBitIndex);
        return claimedWord & mask == mask;
    }

    function isClaimedValues(uint256[] memory indexes) public view returns (bool[] memory) {
        uint size = indexes.length;
        bool[] memory result = new bool[](size);
        for (uint i = 0; i < size; i++) {
            result[i] = isClaimed(indexes[i]);
        }
        return result;
    }

    function _verify(address signer, bytes32 hash, bytes memory signature) private pure returns (bool) {
        return signer == ECDSA.recover(hash, signature);
    }
    
    function _hash(uint256 tokenId, uint256 modelId) private pure returns (bytes32) {
        return ECDSA.toEthSignedMessageHash(keccak256(abi.encodePacked(tokenId, modelId)));
    }

    function _setClaimed(uint256 index) private {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        claimedBitMap[claimedWordIndex] = claimedBitMap[claimedWordIndex] | (1 << claimedBitIndex);
    }
}