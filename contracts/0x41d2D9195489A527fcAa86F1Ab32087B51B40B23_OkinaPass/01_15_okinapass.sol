// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol';
import '@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol';
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract OkinaPass is ERC1155Supply, ERC1155Burnable, Ownable, ReentrancyGuard {
    
    string private _name;
    string private _symbol;
    string private _baseURI;

    bytes32 public merkleRoot;
    mapping(uint => uint) public supplyLimit;
    mapping(bytes32 => bool) public claimed;

    constructor() 
        ERC1155("") {
        _symbol = "OKINA";
        _name = "Okina Pass";

        supplyLimit[0] = 1000; // Ruby
        supplyLimit[1] = 444;  // Gold
    }

    function claimPass(uint tokenId, bytes32[] memory proof) external nonReentrant {
        require(merkleRoot != bytes32(0), "Merkle root not set"); 
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, tokenId));
        require(!claimed[leaf], "Already claimed");
        require(MerkleProof.verify(proof, merkleRoot, leaf), "Invalid proof");
        require(totalSupply(tokenId) + 1 <= supplyLimit[tokenId], "Exceeds supply");
        claimed[leaf] = true;
        _mint(msg.sender, tokenId, 1, "");
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function setBaseURI(string memory uri_) external onlyOwner {
        _baseURI = uri_;
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

    function setMerkleRoot(bytes32 root) external onlyOwner {
        merkleRoot = root;
    }

    function adminMint(address addr, uint tokenId, uint total) external onlyOwner {
        require(totalSupply(tokenId) + total <= supplyLimit[tokenId], "Exceeds supply");
        require(total > 0, "Must be greater than 0");
        _mint(addr, tokenId, total, "");
    }

    function clearClaimed(address addr, uint tokenId) external onlyOwner {
        bytes32 leaf = keccak256(abi.encodePacked(addr, tokenId));
        claimed[leaf] = false;
    }

    function addPass(uint tokenId, uint total) external onlyOwner {
        require(supplyLimit[tokenId] == 0 || totalSupply(tokenId) == 0, "Pass already exists");
        supplyLimit[tokenId] = total;
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