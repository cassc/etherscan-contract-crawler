// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract Protectors is ERC721A, Ownable, ReentrancyGuard{


    uint256 public constant mintSupply = 367;
    uint256 public maxMintTx = 10;
    uint256 public constant gwMintPrice = 0.05 ether;



    // Image/Meta/Token Info
    string public uriSuffix = '.json';
    string public hiddenMetadataUri;
    string private baseTokenUri;


    bool public isRevealed;
    bool public whiteListSale;
    bool public teamSale;
    bool public pause;

    bytes32 private merkleRoot;
    using Strings for uint256;

    mapping(address => uint256) public totalWhitelistMint;

    constructor() ERC721A("Protectors", "COBWP"){

    }


    function whitelistMint(bytes32[] memory _merkleProof, uint256 _quantity) external payable {
        require(whiteListSale, "The Golden Whitelist is not open!");
        require((totalSupply() + _quantity) <= mintSupply, "Max supply has been reached");
        require((totalWhitelistMint[msg.sender] + _quantity)  <= maxMintTx, "Cannot mint beyond whitelist max mint");
        require(msg.value >= (gwMintPrice * _quantity), "Incorrect purchase amount");
        //create leaf node
        bytes32 sender = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_merkleProof, merkleRoot, sender), "You are not on the whitelist");

        totalWhitelistMint[msg.sender] += _quantity;
        _safeMint(msg.sender, _quantity);
    }

    function teamMint() external onlyOwner{
        require(teamSale, "Dev team mint complete!");
        _safeMint(msg.sender, 33);
    }


    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenUri;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory){
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        uint256 trueId = tokenId + 1;

        if (isRevealed == false) {
            return hiddenMetadataUri;
        }

        string memory currentBaseURI = _baseURI();
        return
        bytes(currentBaseURI).length > 0
        ? string(
            abi.encodePacked(
                currentBaseURI,
                trueId.toString(),
                uriSuffix
            )
        )
        : "";
    }

    // Change Max Mint limit per Address
    function changeMaxTx(uint256 _maxMintTx) external onlyOwner{
        maxMintTx = _maxMintTx;
    }

    // Post Sale Reveal
    function setTokenUri(string memory _baseTokenUri) external onlyOwner{
        baseTokenUri = _baseTokenUri;
    }

    // IPFS hidden Meta
    function setHiddenUri(string memory _hiddenMetadataUri) external onlyOwner{
        hiddenMetadataUri = _hiddenMetadataUri;
    }

    // Set merkle root for Whitelist
    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner{
        merkleRoot = _merkleRoot;
    }

    // View current Merkle root set
    function getMerkleRoot() external view returns (bytes32){
        return merkleRoot;
    }

    // Activate Whitelist sale
    function toggleWhiteListSale() external onlyOwner{
        whiteListSale = !whiteListSale;
    }

    // Activate meta reveal
    function toggleReveal() external onlyOwner{
        isRevealed = !isRevealed;
    }

    // Activate Dev Reserved supply
    function devReveal() external onlyOwner{
        teamSale = !teamSale;
    }

    // Retrieve funds to the owner of the Contract
    function withdraw() external onlyOwner nonReentrant{
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
}