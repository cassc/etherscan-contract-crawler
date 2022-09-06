// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract ProbablySomething is ERC721A, Ownable, ReentrancyGuard {

    uint256 public constant MAX_SUPPLY = 88;
    
    uint256 public constant PUBLIC_PRICE = 0.28 ether;

    uint256 public constant PRIVATE_PRICE = 0.28 ether;

    address private constant PAYEE_ADDRESS = 0xa0f56eE3A6E0ddd59fF37467382D161D84cc6835;

    bool public privateSaleOpen = false;

    bool public publicSaleOpen = false;

    bool public teamClaimed = false;
    
    bytes32 public merkleRoot;

    string public baseURI;

    mapping(address => bool) public privateSaleClaimed;

    constructor(string memory name_, string memory symbol_) ERC721A(name_, symbol_) {}

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "Probably Something: Caller is a contract.");
        _;
    }

    modifier isSaleOpen() {
        require(publicSaleOpen, "Probably Something: Public sale is closed.");
        _;
    }

    modifier isPrivateSaleOpen() {
        require(privateSaleOpen, "Probably Something: Private sale is closed.");
        _;
    }

    modifier meetsSaleRequirements() {
        require(msg.value == PUBLIC_PRICE, "Probably Something: Incorrect txn value");
        require(totalSupply() + 1 <= MAX_SUPPLY, "Probably Something: Exceeds remaining supply.");
        _;
    }
    
    modifier meetsPrivateSaleRequirements() {
        require(!privateSaleClaimed[msg.sender], "Probably Something: Address has already claimed.");
        require(msg.value == PRIVATE_PRICE, "Probably Something: Incorrect txn value");
        require(totalSupply() + 1 <= MAX_SUPPLY, "Probably Something: Exceeds remaining supply.");
        _;
    }

    modifier isValidProof(bytes32[] memory proof) {
        require(checkProof(proof), "Probably Something: Invalid proof.");
        _;
    }
    
    /* Validates private sale merkle proof */
    function checkProof(bytes32[] memory _proof) internal view returns(bool) {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        return MerkleProof.verify(_proof, merkleRoot, leaf);
    }

    /* Mint tokens via public sale */
    function publicSaleMint()
        public
        payable
        callerIsUser
        nonReentrant
        isSaleOpen
        meetsSaleRequirements()
    {
        _safeMint(msg.sender, 1);
    }

    /* Mint tokens via private sale */
    function privateSaleMint(bytes32[] calldata proof)
        public
        payable
        callerIsUser
        nonReentrant
        isPrivateSaleOpen
        meetsPrivateSaleRequirements
        isValidProof(proof)
    {
        _safeMint(msg.sender, 1);
        privateSaleClaimed[msg.sender] = true;
    }

    /* Dev Only: Mint tokens for team */
    function teamMint()
        public
        callerIsUser
        nonReentrant
        onlyOwner
    {
        require(!teamClaimed, "Probably Something: Team mints have already been claimed.");
        _safeMint(msg.sender, 4);
        teamClaimed = true;
    }

    /* Update base uri */
    function setBaseURI(string memory _URI) public onlyOwner {
        baseURI = _URI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    /* Update merkle root */
    function setMerkleRoot(bytes32 _root) external onlyOwner {
        merkleRoot = _root;
    }

    /* Flip the state of public sale */
    function togglePublicSale() external onlyOwner {
        publicSaleOpen = !publicSaleOpen;
    }

    /* Flip the state of private sale */
    function togglePrivateSale() external onlyOwner {
        privateSaleOpen = !privateSaleOpen;
    }

    /* Withdraw eth to PAYEE_ADDRESS wallet */
    function withdraw() external onlyOwner {
        payable(PAYEE_ADDRESS).transfer(address(this).balance);
    }
}