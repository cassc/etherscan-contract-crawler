// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol"; 
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {DefaultOperatorFilterer} from "./operator-filter-registry/DefaultOperatorFilterer.sol";


contract AuthenticBean is ERC721A, Ownable, Pausable, ReentrancyGuard, DefaultOperatorFilterer {

    error WithdrawalFailed();

    uint256 immutable maxSupply = 888;
    uint256 mintingCost = 0.0009 ether;
    uint256 immutable maxMintPerTransaction = 5;
    uint256 immutable maxMintPerWallet = 5;
    uint256 numberOfFreemint = 1;

    mapping(address => uint256) freeMints; 
    mapping(address => uint256) minted; 
    
    string private baseURI = "ipfs://bafkreigd3j2pu3mgnmkcbwg6bveqamyinj63jkf6d427qvmg42dleaew6m";

    constructor() ERC721A("Authentic Bean", "ABEAN") {
        _pause();
    }

    function mint(uint256 numberOfTokens) external payable nonReentrant whenNotPaused {

        require(numberOfTokens > 0, "Number of tokens should be greater than zero");
        require((_totalMinted() + numberOfTokens) <= maxSupply, "No tokens left to mint");
        require(numberOfTokens <= maxMintPerTransaction, "Maximum number of mints per transaction exceeded");
        require((minted[msg.sender] + numberOfTokens) <= maxMintPerWallet, "Maximum mint per wallet exceeded.");
        
        uint256 totalCost;

        if ((freeMints[msg.sender] > 0)) {

            totalCost = mintingCost * numberOfTokens;
            require(msg.value >= totalCost, "Insufficient funds");

        } else {
            //block for free mint
            if (numberOfTokens == 1) {
                require(freeMints[msg.sender] == 0, "Insufficient funds");
                
            } else if (numberOfTokens > 1) {
                totalCost = mintingCost * (numberOfTokens - numberOfFreemint);
                require(msg.value >= totalCost, "Insufficient funds");
            }
            
            freeMints[msg.sender] = 1; // First mint is free
        }
        
         _safeMint(msg.sender, numberOfTokens);
         minted[msg.sender] += numberOfTokens;

         if (_totalMinted() >= maxSupply) {
            _pause();
        }

    }

    function internalMint(uint16 numberOfTokens) public onlyOwner {
        require((_totalMinted() + numberOfTokens) <= maxSupply, "Not enough tokens");
        _safeMint(msg.sender, numberOfTokens);
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

        return baseURI;        
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