// SPDX-License-Identifier: MIT

// Ordinals Manifest: 92999b4c3050547bfdc644ee1c4bb226a5fb843ab00ce27736426587dcb2ffbfi0
// Sub-100k inscriptions original collection
// Made by Mudrock, with love.

pragma solidity 0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

contract AntiflowOrdinals is ERC721, DefaultOperatorFilterer, Ownable {
    uint256 public constant MAX_SUPPLY = 100;
    uint256 public constant PUBLIC_SUPPLY = 51;

    string public baseTokenURI = "ipfs://QmQWYSp5QJUoyY6Xjf4xk6uxzdRt52Entiih1nnn9UhCfw/";
    bytes32 public merkleRoot = 0x8ca778716975541347f66b94820a56e3ed5ea265124ba4e8aec07b1135401aea;

    bool public publicSaleOpen = false;
    uint256 public publicMinted = 0;
    uint256 public publicPrice = 0.25 ether; // Public sale will open about a minute after whitelist opens
    uint256 public whitelistPrice = 0.2 ether; // This will decrease by 0.05 approximately every 5 minutes

    mapping(address => bool) public whitelistMinted;

    constructor() ERC721("Antiflow Ordinals", "ANTIFLOW") {}

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseURI(string memory _baseTokenURI) public onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    function setMerkleRoot(bytes32 _newRoot) public onlyOwner {
        merkleRoot = _newRoot;
    }

    function setPublicPrice(uint256 _newPrice) public onlyOwner {
        publicPrice = _newPrice;
    }

    function setWhitelistPrice(uint256 _newPrice) public onlyOwner {
        whitelistPrice = _newPrice;
    }

    function setPublicSaleOpen(bool _status) public onlyOwner {
        publicSaleOpen = _status;
    }

    modifier mintCompliance(uint256 _tokenID) {
        // This guarantees no more than MAX_SUPPLY will be minted
        require(
            _tokenID > 0 && _tokenID <= MAX_SUPPLY,
            "Pick a number between 1 and 100"
        );
        require(!_exists(_tokenID), "That number is already minted SORRY!");
        _;
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    // It takes balls to frontrun on a .25 mint dontcha think
    // I respect balls
    function mint(uint256 _tokenID)
        public
        payable
        mintCompliance(_tokenID)
        callerIsUser
    {
        require(publicSaleOpen, "You can't mint yet :(");
        require(publicMinted < PUBLIC_SUPPLY, "Out of public mints SORRY!");
        require(
            msg.value >= publicPrice,
            "Make sure you're paying the right amount"
        );

        publicMinted++;
        _mint(msg.sender, _tokenID);
    }

    function whitelistMint(uint256 _tokenID, bytes32[] calldata _merkleProof)
        public
        payable
        mintCompliance(_tokenID)
    {
        require(
            !whitelistMinted[msg.sender],
            "You can't mint again SORRY! Try the paid mint if you really want another."
        );
        require(
            msg.value >= whitelistPrice,
            "You probably need to wait a bit to mint for this price."
        );
        require(
            _checkWhitelisted(msg.sender, merkleRoot, _merkleProof),
            "Incorrect proof for whitelist."
        );

        whitelistMinted[msg.sender] = true;
        _mint(msg.sender, _tokenID);
    }

    function withdraw() public payable onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No ether left to withdraw");

        (bool success, ) = (msg.sender).call{value: balance}("");
        require(success, "Transfer failed.");
    }

    function _checkWhitelisted(
        address _target,
        bytes32 _root,
        bytes32[] calldata _merkleProof
    ) internal pure returns (bool) {
        bytes32 node = keccak256(abi.encodePacked(_target));
        return MerkleProof.verify(_merkleProof, _root, node);
    }

    // Operator Filterer Overrides
    function setApprovalForAll(address operator, bool approved)
        public
        override
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId)
        public
        override
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}