// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/// @creator NFTinit.com
/// @author Racherin - racherin.eth

import "./ERC721A.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Mushboomers is ERC721A, Ownable {

    uint256 public maxSupply = 1240;
    uint256 public salePrice;
    uint256 public maxMintsPerWallet = 1;
    
    //  0: INACTIVE, 1: PRE_SALE, 2: PUBLIC_SALE
    uint256 public saleState = 0;

    bytes32 private merkleRoot;

    string public hiddenMetadataUri = "ipfs://bafkreigj73keggkx6xds2eawy4hy4mn2j6zdbtwlveey5ps2sfy4gplglm";
    string public baseURI = "";
    bool public revealed = false;

    constructor() ERC721A("Mushboomers", "MUSH") {}


    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {

        require(_exists(_tokenId), "MUSH: URI query for nonexistent token");

        if (revealed == false) {
        return hiddenMetadataUri;
        }
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, _toString(_tokenId))) : '';
    }

    function airdrop(
        address[] calldata receivers,
        uint256[] calldata quantities
    ) external onlyOwner {
        require(receivers.length == quantities.length, "MUSH : Receiver and quantity arrays are not equal.");
        uint256 total;
        for (uint256 i = 0; i < quantities.length; i++) {
            total += quantities[i];
        }
        require(_totalMinted() + total <= maxSupply, "MUSH: Max supply reached.");
        for (uint256 i = 0; i < receivers.length; i++) {
            _safeMint(receivers[i], quantities[i]);
        }
    }

    function setRevealed(bool _state) public onlyOwner {
    revealed = _state;
    }

    function setHiddenMetadataUri(string memory _hiddenMetadataUri) public onlyOwner {
        hiddenMetadataUri = _hiddenMetadataUri;
    }

    function mintWhitelist(uint256 _amount, bytes32[] calldata merkleProof) external payable {
        require(saleState == 1, "MUSH: Pre-sale has not started yet.");
        require(
            MerkleProof.verify(
                merkleProof,
                merkleRoot,
                keccak256(abi.encodePacked(msg.sender))
            ),
            "MUSH: Merkle verification has failed, address is not in the pre-sale whitelist."
        );
        require(msg.value >= salePrice, "MUSH: Insufficient funds.");
        require(_totalMinted() + _amount <= maxSupply, "MUSH: Max supply reached.");
        require(_numberMinted(msg.sender) + 1 <= maxMintsPerWallet, "MUSH: Max mint amount reached.");
        _safeMint(msg.sender, _amount);
    }

    function mintPublic(uint256 _amount) external payable {
        require(saleState == 2, "MUSH: Public-sale has not started yet.");
        require(msg.value >= salePrice, "MUSH: Insufficient funds.");
        require(_totalMinted() + _amount <= maxSupply, "MUSH: Max supply reached.");
        require(_numberMinted(msg.sender) + 1 <= maxMintsPerWallet, "MUSH: Max mint amount reached.");
        _safeMint(msg.sender, _amount);
    }

    function mintOwner(uint256 _amount) external onlyOwner {
        _safeMint(msg.sender, _amount);
    }

    function setPrice(uint _price) external onlyOwner {
        salePrice = _price;
    }

    function setMaxSupply(uint _maxSupply) external onlyOwner {
        require(_maxSupply >= maxSupply, "MUSH: New supply can't be less than current last supply.");
        maxSupply = _maxSupply;
    }

    function setMaxMintsPerWallet(uint _maxMintsPerWallet) external onlyOwner {
        maxMintsPerWallet = _maxMintsPerWallet;
    }

    function setSaleState(uint256 _saleState) external onlyOwner {
        require(
            _saleState >= 0 && _saleState < 3,
            "MUSH: Invalid new sale state."
        );
        saleState = _saleState;
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function setBaseURI(string memory _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;
    }

    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
    
}