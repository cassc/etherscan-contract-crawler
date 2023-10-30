//SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "erc721a/contracts/ERC721A.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

contract LastHope is ERC721A, Ownable, DefaultOperatorFilterer {
    
// ██╗░░░░░░█████╗░░██████╗████████╗  ██╗░░██╗░█████╗░██████╗░███████╗
// ██║░░░░░██╔══██╗██╔════╝╚══██╔══╝  ██║░░██║██╔══██╗██╔══██╗██╔════╝
// ██║░░░░░███████║╚█████╗░░░░██║░░░  ███████║██║░░██║██████╔╝█████╗░░
// ██║░░░░░██╔══██║░╚═══██╗░░░██║░░░  ██╔══██║██║░░██║██╔═══╝░██╔══╝░░
// ███████╗██║░░██║██████╔╝░░░██║░░░  ██║░░██║╚█████╔╝██║░░░░░███████╗
// ╚══════╝╚═╝░░╚═╝╚═════╝░░░░╚═╝░░░  ╚═╝░░╚═╝░╚════╝░╚═╝░░░░░╚══════╝

    uint256 constant MAX_SUPPLY = 5050; 
    uint256 constant MINT_PRICE = 0.01 ether; 
    uint256 constant MAX_PER_WALLET = 3;
    uint256 constant WHITELIST_PERIOD = 4 hours;
    bytes32 constant ROOT_HASH = 0x47d5d45498eb8796e4d503033b748b1fc74bab4600e1f8700db68b56bf1330bf;

    string private _revealedbaseTokenURI;
    string private _preRevealURI = "ipfs://QmeEn9Y6UQYovzrTRKoPgFTgyPQmscbwFhkXHgeApSzkq6/";

    bool public revealed = false;
    
    bool public whitelistCanMint = false;
    uint256 public expiryTimestamp;
    uint256 public ownerMintCount = 0;

    constructor() ERC721A("Last Hope", "HOPE") {}

    function mint(uint256 quantity) external payable {
        require(totalSupply() + quantity <= MAX_SUPPLY, "Max supply reached");
        require(msg.value == MINT_PRICE * quantity, "Value sent not correct");
        require(_numberMinted(msg.sender) + quantity <= MAX_PER_WALLET, "Max amount minted"); 
        require(block.timestamp > expiryTimestamp && whitelistCanMint, "Not open for mint yet");

        _safeMint(msg.sender, quantity);
    }
    
    function whitelistMint(bytes32[] calldata _merkleProof, uint256 quantity) external payable whitelistPeriodCheck { 
        require(totalSupply() + quantity <= MAX_SUPPLY, "Max supply reached");
        require(_numberMinted(msg.sender) + quantity <= MAX_PER_WALLET, "Max amount of allowed mints claimed");
        require(msg.value == MINT_PRICE * quantity, "Value sent not correct"); 
        
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_merkleProof, ROOT_HASH, leaf), "Not whitelisted");

        _safeMint(msg.sender, quantity);
    }

    //The owner can mint only one, regardless of the changes in the ownership.
    function ownerMintOne() external payable onlyOwner {
        require(totalSupply() + 1 <= MAX_SUPPLY, "Max supply reached");
        require(msg.value == MINT_PRICE, "Value sent not correct");
        require(ownerMintCount == 0, "Owner reached limit");

        ownerMintCount += 1;
        _safeMint(msg.sender, 1);
    }

    modifier whitelistPeriodCheck {
        require(whitelistCanMint, "whitelist period not started");
        require(block.timestamp < expiryTimestamp, "whitelist period over");
        _;
    }

    function startwhitelistPeriod() external onlyOwner {
        whitelistCanMint = true;
        expiryTimestamp = block.timestamp + WHITELIST_PERIOD;
    }

    function setReveal(string memory revealURI) external onlyOwner {
        revealed = true;
        _revealedbaseTokenURI = revealURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        if (revealed) {
            return _revealedbaseTokenURI;
        }
        return _preRevealURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
        string memory metadataPointerId;
        string memory baseURI = _baseURI();

        metadataPointerId = _toString(tokenId);
        string memory result = string(abi.encodePacked(baseURI, metadataPointerId, ".json"));

        return bytes(baseURI).length != 0 ? result : "";
    }

    function transferTeam(uint256 value) external onlyOwner {
        (bool sent, ) = msg.sender.call{value: value }("");
        require(sent, "Transfer failed");
    }

    function transferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        payable
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}