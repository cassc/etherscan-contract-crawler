// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol"; 
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {DefaultOperatorFilterer} from "./operator-filter-registry/DefaultOperatorFilterer.sol";


contract BigBoyCrypto is ERC721A, Ownable, Pausable, ReentrancyGuard, DefaultOperatorFilterer {

    uint256 maxSupply = 3333;

    uint256 mintRate = 0.0029 ether;
    uint256 maxMintPerTransaction = 10;

    mapping(address => bool) minted;
    string private baseURI;

    error WithdrawalFailed();

    constructor() ERC721A("Big Boy Crypto", "BBCrypto") {
        baseURI = "ipfs://bafybeifhhkz2muwh33hb34ret364dry4svisutqcgy2a6obtti4p5n565u/"; 
        _pause();
    }

    function publicMint(uint quantity) external payable nonReentrant whenNotPaused {

        require((_totalMinted() + quantity) <= maxSupply, "ERROR: Not enough tokens left");
        require(quantity <= maxMintPerTransaction, "ERROR: Maximum mint per transaction exceeded");
        require(!minted[msg.sender], "ERROR: Address has already minted.");
        

        //First mint is free
        if (quantity >= (maxMintPerTransaction - 1)) {
            require(msg.value >= (mintRate * (quantity - 1)), "ERROR: Not enough ether sent");
        }

        _safeMint(msg.sender, quantity);
        minted[msg.sender] = true; //register the address that minted

        if (_totalMinted() >= maxSupply) {
            _pause();
        }
    }

    function teamMint(uint16 _qty) public onlyOwner {
        require((_totalMinted() + _qty) <= maxSupply, "ERROR: Not enough tokens left");
        _safeMint(msg.sender, _qty);
    }

    function airdrop(uint256 _qty, address _recipient) public onlyOwner whenNotPaused {
        require((_totalMinted() + _qty) <= maxSupply, "ERROR: Not enough tokens left");
        _safeMint(_recipient, _qty);
    }

    function setMaxSupply(uint256 _rate) external onlyOwner whenNotPaused {
        maxSupply = _rate;
    }

    function setMintRate(uint256 _mintRate) public onlyOwner whenNotPaused {
        mintRate = _mintRate;
    }

    function setMintPerTxn(uint256 _mintPerTxn) public onlyOwner whenNotPaused {
        maxMintPerTransaction = _mintPerTxn;
    }

    function unPause() public onlyOwner {
        _unpause();
    }

    function pause() public onlyOwner whenNotPaused {
        _pause();
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