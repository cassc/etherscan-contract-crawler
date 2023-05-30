// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

// File: contracts/ChinaChic.sol

/*
 ██████╗██╗  ██╗██╗███╗   ██╗ █████╗      ██████╗██╗  ██╗██╗ ██████╗
██╔════╝██║  ██║██║████╗  ██║██╔══██╗    ██╔════╝██║  ██║██║██╔════╝
██║     ███████║██║██╔██╗ ██║███████║    ██║     ███████║██║██║     
██║     ██╔══██║██║██║╚██╗██║██╔══██║    ██║     ██╔══██║██║██║     
╚██████╗██║  ██║██║██║ ╚████║██║  ██║    ╚██████╗██║  ██║██║╚██████╗
 ╚═════╝╚═╝  ╚═╝╚═╝╚═╝  ╚═══╝╚═╝  ╚═╝     ╚═════╝╚═╝  ╚═╝╚═╝ ╚═════╝
*/

/**
 * @title ChinaChic contract
 * @dev Extends ERC721 Non-Fungible Token Standard basic implementation
 */
contract ChinaChic is ERC721A, Ownable, Pausable, ReentrancyGuard {
    // Constant variables
    // ------------------------------------------------------------------------
    uint256 public constant MAX_SUPPLY = 2600;
    uint256 public constant MAX_PER_ADDRESS = 1;
    uint256 public constant RESERVES = 578;

    // State variables
    // ------------------------------------------------------------------------
    string private _baseTokenURI;
    bool public isWhitlistSaleActive = false;
    bool public isPublicSaleActive = false;

    // Sale mappings
    // ------------------------------------------------------------------------
    mapping(address => bool) private mintedAddress;

    // Merkle Root Hash
    // ------------------------------------------------------------------------
    bytes32 private _merkleRoot;

    // Modifiers
    // ------------------------------------------------------------------------
    modifier onlyWhitelistSale() {
        require(isWhitlistSaleActive, "Whitelist sale is not active");
        _;
    }

    modifier onlyPublicSale() {
        require(isPublicSaleActive, "Public sale is not active");
        _;
    }

    // Modifier to ensure that the call is coming from an externally owned account, not a contract
    modifier onlyEOA() {
        require(
            tx.origin == msg.sender,
            "Contract caller must be externally owned account"
        );
        _;
    }

    // Constructor
    // ------------------------------------------------------------------------
    constructor(string memory name, string memory symbol)
        ERC721A(name, symbol)
    {}

    // URI functions
    // ------------------------------------------------------------------------
    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    // Operational functions
    // ------------------------------------------------------------------------
    function collectReserves(uint256 numberOfTokens) external onlyOwner {
        require(
            totalSupply() + numberOfTokens <= RESERVES,
            "Exceeds reserves supply"
        );
        _safeMint(_msgSender(), numberOfTokens);
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    // Merkle root functions
    // ------------------------------------------------------------------------
    function setMerkleRoot(bytes32 rootHash) external onlyOwner {
        _merkleRoot = rootHash;
    }

    function verifyProof(bytes32[] memory _merkleProof)
        internal
        view
        returns (bool)
    {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        return MerkleProof.verify(_merkleProof, _merkleRoot, leaf);
    }

    // Sale switch functions
    // ------------------------------------------------------------------------
    function flipWhitelistSale() public onlyOwner {
        isWhitlistSaleActive = !isWhitlistSaleActive;
    }

    function flipPublicSale() public onlyOwner {
        isPublicSaleActive = !isPublicSaleActive;
    }

    // Mint functions
    // ------------------------------------------------------------------------
    function whitelistMint(bytes32[] calldata proof)
        public
        nonReentrant
        whenNotPaused
        onlyEOA
        onlyWhitelistSale
    {
        require(verifyProof(proof), "Not in the whitelist");
        require(mintedAddress[_msgSender()] == false, "Already purchsed");
        require(
            totalSupply() + MAX_PER_ADDRESS <= MAX_SUPPLY,
            "Exceed max supply"
        );

        mintedAddress[_msgSender()] = true;
        _safeMint(_msgSender(), MAX_PER_ADDRESS);
    }

    function publicMint()
        public
        nonReentrant
        whenNotPaused
        onlyEOA
        onlyPublicSale
    {
        require(mintedAddress[_msgSender()] == false, "Already purchsed");
        require(
            totalSupply() + MAX_PER_ADDRESS <= MAX_SUPPLY,
            "Exceed max supply"
        );

        mintedAddress[_msgSender()] = true;
        _safeMint(_msgSender(), MAX_PER_ADDRESS);
    }
}