// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

////////////////////////////////////////////////////////////////////////////////////////////////////////
// ██╗   ██╗ ██████╗  ██████╗ ██╗   ██╗██████╗ ████████╗    ██╗   ██╗███████╗██████╗ ███████╗███████╗ //
// ╚██╗ ██╔╝██╔═══██╗██╔════╝ ██║   ██║██╔══██╗╚══██╔══╝    ██║   ██║██╔════╝██╔══██╗██╔════╝██╔════╝ //
//  ╚████╔╝ ██║   ██║██║  ███╗██║   ██║██████╔╝   ██║       ██║   ██║█████╗  ██████╔╝███████╗█████╗   //
//   ╚██╔╝  ██║   ██║██║   ██║██║   ██║██╔══██╗   ██║       ╚██╗ ██╔╝██╔══╝  ██╔══██╗╚════██║██╔══╝   //
//    ██║   ╚██████╔╝╚██████╔╝╚██████╔╝██║  ██║   ██║        ╚████╔╝ ███████╗██║  ██║███████║███████╗ //
//    ╚═╝    ╚═════╝  ╚═════╝  ╚═════╝ ╚═╝  ╚═╝   ╚═╝         ╚═══╝  ╚══════╝╚═╝  ╚═╝╚══════╝╚══════╝ //
////////////////////////////////////////////////////////////////////////////////////////////////////////

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "erc721a/contracts/ERC721A.sol";

contract yogurtverse is ERC721A, Ownable {
    uint256 public constant maxSupply = 321;
    string public baseURI = "ipfs://QmQgY7JP5zWJeQeatZpk6TwC6hxMmw8JQyGAf4C8VHPYNM/";
    bool public privateSale = false;
    bool public publicSale = false;
    mapping(address => bool) public hasMinted;

    bytes32 merkleRoot;

    constructor() ERC721A("Yogurt Verse", "YGRT") {}

    function whitelistMint(bytes32[] calldata _merkleProof) external {
        address _caller = _msgSender();
        require(privateSale, "Private sale not live");
        require(maxSupply >= totalSupply() + 1, "Exceeds max supply");
        require(tx.origin == _caller, "No contracts");
        require(!hasMinted[msg.sender], "Already minted");

        bytes32 node = keccak256(abi.encodePacked(msg.sender));
        require(
            MerkleProof.verify(_merkleProof, merkleRoot, node),
            "Invalid proof"
        );

        hasMinted[msg.sender] = true;
        _mint(_caller, 1);
    }

    function publicMint() external {
        address _caller = _msgSender();
        require(publicSale, "Public sale not live");
        require(maxSupply >= totalSupply() + 1, "Exceeds max supply");
        require(tx.origin == _caller, "No contracts");
        require(!hasMinted[msg.sender], "Already minted");

        hasMinted[msg.sender] = true;
        _mint(_caller, 1);
    }

    function ownerMint(uint256 _amount, address _to) external onlyOwner {
        require(totalSupply() + _amount <= maxSupply, "Exceeds max supply");
        _mint(_to, _amount);
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        (bool success, ) = _msgSender().call{value: balance}("");
        require(success, "Failed to send");
    }

    function setPrivateSale(bool _state) external onlyOwner {
        privateSale = _state;
    }

    function setPublicSale(bool _state) external onlyOwner {
        publicSale = _state;
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "Token does not exist.");
        return bytes(baseURI).length > 0 ? string(
            abi.encodePacked(
              baseURI,
              Strings.toString(_tokenId)
            )
        ) : "";
    }
}