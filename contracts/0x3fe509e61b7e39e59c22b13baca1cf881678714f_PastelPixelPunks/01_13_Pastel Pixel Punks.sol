// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol"; 
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {DefaultOperatorFilterer} from "./operator-filter-registry/DefaultOperatorFilterer.sol";


contract PastelPixelPunks is ERC721A, Ownable, Pausable, ReentrancyGuard, DefaultOperatorFilterer {

    error WithdrawalFailed();
    uint256 maxSupply = 2000;
    uint256 mintRate = 0.0025 ether;
    uint256 maxMintPerTransaction = 10;
    mapping(address => uint256) minted; 
    string private baseURI;

    constructor() ERC721A("Pastel Pixel Punks", "PPPunks") {
        baseURI = "ipfs://bafybeihnokfoh6rj7s5imimpkpzc4qt2ehginnmfut5aqozx6wy77ogbxq/"; 
        _pause();
    }

    function publicMint(uint quantity) external payable nonReentrant whenNotPaused {

        require((_totalMinted() + quantity) <= maxSupply, "No tokens left to mint");
        require(quantity <= maxMintPerTransaction, "Could not mint over 10");
        require(msg.value >= (mintRate * quantity), "Insufficient funds");
        require(minted[msg.sender] <= 15, "Max per wallet reached.");

        _safeMint(msg.sender, quantity);

        minted[msg.sender] += quantity;

        if (_totalMinted() >= maxSupply) {
            _pause();
        }
    }

    function internalMint(uint16 _qty) public onlyOwner {
        require((_totalMinted() + _qty) <= maxSupply, "Not enough tokens");
        _safeMint(msg.sender, _qty);
    }

    function setMaxSupply(uint256 _rate) external onlyOwner whenNotPaused {
        maxSupply = _rate;
    }

    function setMintCost(uint256 _mintRate) public onlyOwner whenNotPaused {
        mintRate = _mintRate;
    }

    function setMintPerTxn(uint256 _mintPerTxn) public onlyOwner whenNotPaused {
        maxMintPerTransaction = _mintPerTxn;
    }

    

    function setBaseURI (string memory _baseURI) public onlyOwner whenNotPaused {
        baseURI = _baseURI;
    }

    function withdraw() public onlyOwner {
        (bool success, ) = payable(owner()).call{value: address(this).balance}("");

        if (!success) {
            revert WithdrawalFailed();
        } 
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        return string(abi.encodePacked(baseURI, Strings.toString(_tokenId), ".json"));        
    }

    function unPause() public onlyOwner {
        _unpause();
    }

    function pause() public onlyOwner whenNotPaused {
        _pause();
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     *      In this example the added modifier ensures that the operator is allowed by the OperatorFilterRegistry.
     */
    function setApprovalForAll(address operator, bool approved) public override(ERC721A) onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    /**
     * @dev See {IERC721-approve}.
     *      In this example the added modifier ensures that the operator is allowed by the OperatorFilterRegistry.
     */
    function approve(address operator, uint256 tokenId) public payable override(ERC721A) onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    /**
     * @dev See {IERC721-transferFrom}.
     *      In this example the added modifier ensures that the operator is allowed by the OperatorFilterRegistry.
     */
    function transferFrom(address from, address to, uint256 tokenId) public payable override(ERC721A) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     *      In this example the added modifier ensures that the operator is allowed by the OperatorFilterRegistry.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public payable override(ERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     *      In this example the added modifier ensures that the operator is allowed by the OperatorFilterRegistry.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        payable
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A) returns (bool) {
        return super.supportsInterface(interfaceId);
    }


}