// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";


pragma solidity ^0.8.0;

contract DinomonksClaimPass is ERC721, AccessControl, ReentrancyGuard, Ownable {
    using Counters for Counters.Counter;

    // The Merkle Root
    bytes32 public root;

    address private constant TREASURY_ADDRESS = 0xbfCF42Ef3102DE2C90dBf3d04a0cCe90eddA6e3F;

    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");

    bool public mintingOpen = false;
    uint256 public mintPrice = 88000000000000000; // 0.0880 eth

    mapping(address => bool) public hasMinted;

    // Base token URI
    string private _baseTokenURI;

    // The total number that have ever been minted.
    Counters.Counter private totalMinted;

    
    constructor(
        bytes32 _merkleRoot
    ) ERC721("KOD Dinomonks Claim Pass", "KODDINO") {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(BURNER_ROLE, msg.sender);
        root = _merkleRoot;
    }

     function mint(
        bytes32[] calldata _merkleProof
    ) external payable nonReentrant {
        require(mintingOpen, "Minting must be open");
        require(hasMinted[msg.sender] == false, "You can only mint once per allow listed address");
        require(msg.value >= mintPrice, "Must supply proper amount to pay for purchase");

        // Verify exists in merkletree
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_merkleProof, root, leaf), "Invalid proof.");

        uint256 nextTokenId = totalMinted.current() + 1;
        _mint(msg.sender, nextTokenId);     

        totalMinted.increment();
        hasMinted[msg.sender] = true;   
    }

    function amIEligible2(address _addr, bytes32[] calldata _merkleProof) public view returns (bool) {
        return MerkleProof.verify(_merkleProof, root, keccak256((abi.encodePacked(_addr))));
    }

    function didWalletClaim(address _target) public view returns (bool) {
        return hasMinted[_target];
    }

    function getMerkleRoot() public view returns (bytes32) {
        return root;
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        root = _merkleRoot;
    }

    function getPrice() public view returns (uint256) {
        return mintPrice;
    }

    function setPrice(uint256 _price) external onlyOwner {
        mintPrice = _price;
    }

    function setMintingOpen(bool _isOpen) external onlyOwner {
        mintingOpen = _isOpen;
    }
    function getMintingOpen() public view returns (bool) {
        return mintingOpen;
    }

    // The total number of NFTs ever minted for this collection. Ignoring burning.
    function getTotalMintCount() public view returns (uint256) {
        return totalMinted.current();
    }

    // If an address has the BURNER_ROLE, they can burn tokens
    function burn(uint256 _tokenID) external nonReentrant {
        require(hasRole(BURNER_ROLE, msg.sender), "Must have burner permissions");
        require(_exists(_tokenID));
        _burn(_tokenID);
    }

    // Toggle the base URI
    function setBaseURI(string memory baseURI) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Must be an admin to set the base URI");
        _baseTokenURI = baseURI;
    }
    

    // Getter for the value of the base token uri
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function getTreasuryAddress() public pure returns (address) {
        return TREASURY_ADDRESS;
    }

    // Always withdraw to the treasury address. Allow anyone to withdraw, such that there can be no issues with keys.
    function withdrawAll() public payable {
        require(payable(getTreasuryAddress()).send(address(this).balance));
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

}