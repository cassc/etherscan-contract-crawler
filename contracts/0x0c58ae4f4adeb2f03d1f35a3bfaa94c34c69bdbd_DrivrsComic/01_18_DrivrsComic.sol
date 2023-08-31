// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {ERC1155} from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import {ERC2981} from "@openzeppelin/contracts/token/common/ERC2981.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./operator-filter-registry/OperatorFilterer.sol";


contract DrivrsComic is ERC1155, ERC2981, OperatorFilterer, Ownable {

         string public name;
    string public symbol;
    string public baseUri;

 constructor() ERC1155("") OperatorFilterer(address(0x3cc6CddA760b79bAfa08dF41ECFA224f810dCeB6), false) {
         name = "DRVRS Comics";
        symbol = "DRVRSCOMIC";
 }


    bytes32 freemintRoot;

    bool public isFreeMintActive = false;

    struct UserPurchaseInfo {
        uint16 freeMinted;
    }

   
    struct ChapterInfo{
        uint16 maxSupply;
        uint16 mintedSupply;
         mapping(address => UserPurchaseInfo) userPurchase; 
    }

    mapping(uint16 => ChapterInfo) public chapters;

    uint16 currentChapter = 1;
    
    modifier isSecured(uint16 mintType) {
        require(tx.origin == msg.sender, "CONTRACTS_NOT_ALLOWED_TO_MINT");
        if (mintType == 3) {
            require(isFreeMintActive, "FREE_MINT_IS_NOT_YET_ACTIVE");
        }
        _;
    }

  modifier supplyMintLimit(uint16 numberOfTokens) {
    require(
        numberOfTokens + chapters[currentChapter].mintedSupply <= chapters[currentChapter].maxSupply,
        "NOT_ENOUGH_SUPPLY"
    );
    _;
}

    function freeMint(
        bytes32[] memory proof,
        uint16 numberOfTokens,
        uint16 maxMint
    ) external isSecured(3) supplyMintLimit(numberOfTokens) {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, maxMint));
        require(MerkleProof.verify(proof, freemintRoot, leaf), "PROOF_INVALID");
        require(
            chapters[currentChapter].userPurchase[msg.sender].freeMinted + numberOfTokens <= maxMint,
            "EXCEED_ALLOCATED_MINT_LIMIT"
        );
         chapters[currentChapter].userPurchase[msg.sender].freeMinted += numberOfTokens;
        chapters[currentChapter].mintedSupply += numberOfTokens;
        _mint(msg.sender, currentChapter,numberOfTokens, "");
    }

    function setChapterSupply(uint16 chapter, uint16 supply) external onlyOwner{
        chapters[chapter].maxSupply = supply;
    }

    function setCurrentChapter(uint16 chapter) external onlyOwner{
        currentChapter = chapter;
    }

    function setFreeMintStatus() external onlyOwner {
        isFreeMintActive = !isFreeMintActive;
    }
    
    function setFreeMintRoot(bytes32 _freemintRoot) external onlyOwner {
        freemintRoot = _freemintRoot;
    }

    //Overrides
    function safeTransferFrom(address from, address to, uint256 tokenId, uint256 amount, bytes memory data)
        public
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, amount, data);
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override onlyAllowedOperator(from) {
        super.safeBatchTransferFrom(from, to, ids, amounts, data);
    }
    
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function uri(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        return baseUri;
    }

    function setUri(string memory uri) external onlyOwner {
        baseUri = uri;
    }
}