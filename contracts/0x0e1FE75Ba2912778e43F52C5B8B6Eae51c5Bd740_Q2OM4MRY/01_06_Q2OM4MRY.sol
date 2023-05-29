pragma solidity ^0.8.4;

import "ERC721A/ERC721A.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";
import "openzeppelin-contracts/contracts/utils/cryptography/MerkleProof.sol";
// import "forge-std/console.sol";

contract Q2OM4MRY is ERC721A, Ownable {
 
    uint256 private constant MAXSUPPLY = 10000;
    address public burner;
    bytes32 public merkleRoot;
    uint16 private genesis;

    mapping(uint16 => mapping(address => bool)) public whitelistClaimed;

    function onlyBurner() private view {
        require(
            burner == msg.sender, "The sender is not the burner"
        );
    }

    constructor() ERC721A("QR81V", "Q2_OMAMORY") {
        genesis++;
        _mintERC2309(msg.sender, 340);
    }

    function ownerMint(uint256 quantity) external payable onlyOwner {
        // `_mint`'s second argument now takes in a `quantity`, not a `tokenId`.
        require(
            totalSupply() + quantity <= MAXSUPPLY, "mas supply limit has been reached"
        );
        _mintERC2309(msg.sender, quantity);
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
        genesis++;
        // uwuRoot = _uwulistRoot;
        // teamRoot = _teamRoot;
    }
    function whitelistMint(bytes32[] memory _merkleProof) public {
        require(!whitelistClaimed[genesis][msg.sender], "address already claimed");
        require(
            totalSupply() + 1 <= MAXSUPPLY, "mas supply limit has been reached"
        );
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(
            MerkleProof.verify(_merkleProof, merkleRoot, leaf),
            "invalid merkle proof"
        );
        _mint(msg.sender, 1);
        whitelistClaimed[genesis][msg.sender] = true;
    }

    function _baseURI() internal view override returns (string memory) {
        return 'https://assets.qr81v.com/';
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _baseURI();
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, _toString(tokenId), ".json")) : '';
    }

    function burn(address sender, uint256 tokenId) public {
        onlyBurner();
        require(sender == ownerOf(tokenId), "sender is not an owner");
        _burn(tokenId);
    }

    function setBurner(address _burner) public onlyOwner {
        burner = _burner;
    }
}