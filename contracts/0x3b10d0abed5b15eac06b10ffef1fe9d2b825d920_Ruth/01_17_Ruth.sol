// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./ERC721A.sol";
import "./Counters.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./RandomlyAssigned.sol";
import "./MerkleProof.sol";

contract Ruth is Ownable, ERC721A, ReentrancyGuard {
    string private _baseTokenURI;
    // mapping(address => uint256) public allowlist;
    bytes32 public merkleRoot;

    mapping(address => bool) public whitelistClaimed;
    uint256 private _standardPackMint;
    uint256 private _premiumPackMint;

    uint256 private _standardPackFee;
    uint256 public totalSold;
    uint256 public totalMint;
    uint256 public soldStandardPack;

    constructor() ERC721A("RUTH", "RUTH") {

        _standardPackFee = .049 ether;

        totalSold = 0;
        totalMint = 1080;
    }

    function setRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    //start Minting
    function mint(uint256 quantity) external payable onlyOwner {
        // _safeMint's second argument now takes in a quantity, not a tokenId.

        _safeMint(msg.sender, quantity);
    }

    function whitelistMint(bytes32[] calldata _merkleProof, uint256 quantity)
        public
    {
        require(!whitelistClaimed[msg.sender], "Address has already claimed.");

        require(
            MerkleProof.verify(
                _merkleProof,
                merkleRoot,
                keccak256(abi.encodePacked(msg.sender, quantity))
            ),
            "Invalid proof"
        );

        whitelistClaimed[msg.sender] = true;
        totalSold += quantity;
        _safeMint(msg.sender, quantity);
    }

    function claimReservedToken(address to, uint256 tokenId)
        external
        onlyOwner
    {
        _claimReservedToken(to, tokenId);
        totalSold++;
    }

 
    function getStandardPackFee() external view returns (uint256) {
        return _standardPackFee;
    }

    function setStandardPackFee(uint256 packFee) external onlyOwner {
        _standardPackFee = packFee;
    }

    function setStandardPackMint(uint256 mintNumber) external onlyOwner {
        _standardPackMint = mintNumber;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function buyStandardPack(uint256 noOfPack) external payable nonReentrant {
        require(totalSold + noOfPack <= totalMint, "Max mint reached");
        require(_standardPackFee * noOfPack == msg.value, "Invalid Fee");
        _safeMint(msg.sender, noOfPack);

        totalSold += noOfPack;
    }

    function withdraw() external onlyOwner nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }
}