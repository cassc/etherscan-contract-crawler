// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol';
import '@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol';
import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract OkinaLabs is ERC1155Supply, ERC1155Burnable, Ownable, ReentrancyGuard {
    
    string private _name;
    string private _symbol;
    string private _baseURI;

    bytes32 public merkleRootForClaim;
    mapping(bytes32 => bool) public claimed;
    mapping(uint => TokenData) public tokenData;

    event ItemUsed(uint indexed _tokenId, address collection, uint _pfpTokenId);

    struct TokenData {
        address collection;
        uint supplyLimit;
        mapping(uint => bool) applied;
        bytes32 merkleRootForUse;
        bool enabled;
    }

    constructor() 
        ERC1155("") {
        _symbol = "OKINA";
        _name = "Okina Labs";
    }

    function claimItem(uint tokenId, uint quantity, bytes32[] memory proof) external nonReentrant {
        require(merkleRootForClaim != bytes32(0), "Merkle root not set"); 
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, tokenId, quantity));
        require(!claimed[leaf], "Already claimed");
        require(MerkleProof.verify(proof, merkleRootForClaim, leaf), "Invalid proof");
        require(totalSupply(tokenId) + 1 <= (tokenData[tokenId].supplyLimit), "Exceeds supply");
        claimed[leaf] = true;
        _mint(msg.sender, tokenId, quantity, "");
    }

    function useItem(uint labsTokenId, uint pfpTokenId, bytes32[] memory proof) external nonReentrant {
        TokenData storage tokenInfo = tokenData[labsTokenId];
        require(tokenInfo.enabled, "Item cannot be used at this time");
        if(tokenInfo.merkleRootForUse != bytes32(0)) {
            require(MerkleProof.verify(proof, tokenInfo.merkleRootForUse, keccak256(abi.encodePacked(pfpTokenId))), "Invalid pfp token id proof");
        }
        require(ERC721(tokenInfo.collection).ownerOf(pfpTokenId) == msg.sender, "You do not own this token");
        require(tokenInfo.applied[pfpTokenId] == false, "This pfp token already used this type of item");
        this.burn(msg.sender, labsTokenId, 1);
        emit ItemUsed(labsTokenId, tokenInfo.collection, pfpTokenId);
        tokenInfo.applied[pfpTokenId] = true;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function supplyLimit(uint tokenId) public view returns(uint) {
        return tokenData[tokenId].supplyLimit;
    }

    function uri(uint256 _tokenId) public view override returns (string memory) {
        require(exists(_tokenId), "Token does not exist.");
        return bytes(_baseURI).length > 0 ? string(
            abi.encodePacked(
                _baseURI,
                Strings.toString(_tokenId),
                ".json"
            )
        ) : "";
    }

    function isEnabled(uint tokenId) public view returns(bool) {
        return tokenData[tokenId].enabled;
    }

    function merkleRootForUse(uint tokenId) public view returns(bytes32) {
        return tokenData[tokenId].merkleRootForUse;
    }

    function isItemApplied(uint tokenId, uint pfpTokenId) public view returns(bool) {
        return tokenData[tokenId].applied[pfpTokenId];
    }

    function pfpCollectionAddress(uint tokenId) public view returns(address) {
        return tokenData[tokenId].collection;
    }

    function setBaseURI(string memory uri_) external onlyOwner {
        _baseURI = uri_;
    }

    function setMerkleRootForClaim(bytes32 root) external onlyOwner {
        merkleRootForClaim = root;
    }

    function setMerkleRootForUse(uint tokenId, bytes32 root) external onlyOwner {
        tokenData[tokenId].merkleRootForUse = root;
    }

    function setCollection(uint tokenId, address addr) external onlyOwner {
        tokenData[tokenId].collection = addr;
    }

    function setEnabled(uint tokenId, bool enabled) external onlyOwner {
        tokenData[tokenId].enabled = enabled;
    }

    function adminMint(address addr, uint tokenId, uint total) external onlyOwner {
        require(totalSupply(tokenId) + total <= (tokenData[tokenId].supplyLimit), "Exceeds supply");
        require(total > 0, "Must be greater than 0");
        _mint(addr, tokenId, total, "");
    }

    function clearClaimed(address addr, uint quantity, uint tokenId) external onlyOwner {
        bytes32 leaf = keccak256(abi.encodePacked(addr, tokenId, quantity));
        claimed[leaf] = false;
    }

    function addItem(uint tokenId, address collection, uint total) external onlyOwner {
        require((tokenData[tokenId].supplyLimit) == 0 || totalSupply(tokenId) == 0, "Item already exists");
        tokenData[tokenId].supplyLimit = total;
        tokenData[tokenId].collection = collection;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override(ERC1155Supply, ERC1155) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }
}