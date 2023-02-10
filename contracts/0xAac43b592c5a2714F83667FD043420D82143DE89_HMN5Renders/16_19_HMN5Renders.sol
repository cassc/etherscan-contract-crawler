// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol';
import '@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol';
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

contract HMN5Renders is ERC1155Supply, ERC1155Burnable, Ownable, ReentrancyGuard, DefaultOperatorFilterer {
    
    mapping(address => bool) public mintTracker;

    string private _name;
    string private _symbol;
    string private _baseURI;
    string public baseURI = "";

    constructor()
        ERC1155("") {
        _symbol = "HMN5R";
        _name = "HMN5 RENDERS";
    }

    function claim(uint256[] calldata tokenIds, uint256[] calldata quantities, bytes32[] calldata proof) external nonReentrant {
        require(tx.origin == msg.sender, "No contracts");
        require(mintEnabled, "Minting is not enabled");
        require(merkleRoot != bytes32(0), "Merkle root not set");
        require(!mintTracker[msg.sender], "You already claimed your tokens");
        require(!supplyFrozen, "Supply is frozen");
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, tokenIds, quantities));
        require(MerkleProof.verify(proof, merkleRoot, leaf), "Invalid proof");
        mintTracker[msg.sender] = true;
        _mintBatch(msg.sender, tokenIds, quantities, "");
    }

    function giftMint(address account, uint256[] calldata tokenIds, uint256[] calldata quantities) external onlyOwner {
        require(!supplyFrozen, "Supply is frozen");
        _mintBatch(account, tokenIds, quantities, "");
    }

    bytes32 public merkleRoot;
    function setMerkleRoot(bytes32 merkleRoot_) external onlyOwner {
        merkleRoot = merkleRoot_;
    }

    bool public mintEnabled;
    function toggleMintEnabled() external onlyOwner {
        mintEnabled = !mintEnabled;
    }

    bool public supplyFrozen;
    function freezeSupply() external onlyOwner {
        supplyFrozen = true;
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

    function clearMintTracker(address addr_) external onlyOwner {
        mintTracker[addr_] = false;
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

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     *      In this example the added modifier ensures that the operator is allowed by the OperatorFilterRegistry.
     */
    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     *      In this example the added modifier ensures that the operator is allowed by the OperatorFilterRegistry.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, uint256 amount, bytes memory data)
        public
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     *      In this example the added modifier ensures that the operator is allowed by the OperatorFilterRegistry.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override onlyAllowedOperator(from) {
        super.safeBatchTransferFrom(from, to, ids, amounts, data);
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