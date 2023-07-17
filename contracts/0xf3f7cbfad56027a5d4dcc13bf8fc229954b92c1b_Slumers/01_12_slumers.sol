// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import {ERC721A} from "erc721a/contracts/ERC721A.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {ERC2981} from "@openzeppelin/contracts/token/common/ERC2981.sol";

contract Slumers is ERC2981, ERC721A, Ownable {
    string public uriPrefix = "ipfs://BASE_URI/";
    string public uriSuffix = ".json";
    string public prerevealMetadataUri = "ipfs://QmUzKxJ3HeGiXQj7b1qtyMJAV1fmYg3JdSkm7vHCowHnNL/pre-reveal.json";
    string public contractMetadataUri = "ipfs://QmUzKxJ3HeGiXQj7b1qtyMJAV1fmYg3JdSkm7vHCowHnNL/contract.json";

    uint256 public freeMintSupply = 1000;
    uint256 public freeMintPrice = 0.00001 ether;
    uint256 public freeMintsClaimed;
    uint256 public price = 0.02 ether;
    uint256 public maxSupply = 6969;

    bool public paused = true;
    bool public revealed;
    bool public uriLocked;

    bool private didOwnerMint;

    mapping(address => bool) private freeMinters;

    constructor() ERC721A("Slumers", "SLUMERS") {
        _setDefaultRoyalty(msg.sender, 690);
    }

    modifier mintCompliance(uint256 quantity) {
        require(!paused, "The contract is paused");
        require(totalSupply() + quantity <= maxSupply, "Max supply exceeded");
        _;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return uriPrefix;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function calcPrice(address to, uint256 quantity) public view returns (uint256) {
        uint256 totalPrice = price * quantity;

        if (canFreeMint(to)) {
            totalPrice = totalPrice + freeMintPrice - price;
        }

        return totalPrice;
    }

    function mint(uint256 quantity) external payable mintCompliance(quantity) {
        uint256 totalPrice = calcPrice(msg.sender, quantity);
        require(msg.value >= totalPrice, "Insufficient funds");

        if (canFreeMint(msg.sender)) {
            freeMinters[msg.sender] = true;
            incrementFreeMintsClaimed();
        }

        _mint(msg.sender, quantity);
    }

    function contractURI() external view returns (string memory) {
        return contractMetadataUri;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        if (!revealed) {
            return prerevealMetadataUri;
        }

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, Strings.toString(tokenId), uriSuffix)) : "";
    }

    function canFreeMint(address to) public view returns (bool) {
        return !freeMinters[to] && (freeMintsClaimed < freeMintSupply);
    }

    function incrementFreeMintsClaimed() internal {
        freeMintsClaimed++;
    }

    function ownerMint() external onlyOwner {
        require(!didOwnerMint, "Owner already minted");
        didOwnerMint = true;
        _mint(msg.sender, 200);
    }

    function setRevealed(bool _state) external onlyOwner {
        require(!uriLocked, "URIs locked");
        revealed = _state;
    }

    function setPrice(uint256 _price) external onlyOwner {
        price = _price;
    }

    function setPrerevealMetadataUri(string memory _prerevealMetadataUri) external onlyOwner {
        require(!uriLocked, "URIs locked");
        prerevealMetadataUri = _prerevealMetadataUri;
    }

    function setContractMetadataUri(string memory _contractMetadataUri) external onlyOwner {
        require(!uriLocked, "URIs locked");
        contractMetadataUri = _contractMetadataUri;
    }

    function setUriPrefix(string memory _uriPrefix) external onlyOwner {
        require(!uriLocked, "URIs locked");
        uriPrefix = _uriPrefix;
    }

    function setUriSuffix(string memory _uriSuffix) external onlyOwner {
        require(!uriLocked, "URIs locked");
        uriSuffix = _uriSuffix;
    }

    function lockUris() external onlyOwner {
        require(!uriLocked, "URIs locked");
        uriLocked = true;
    }

    function setPaused(bool _state) external onlyOwner {
        paused = _state;
    }

    function withdraw() external onlyOwner {
        (bool sent, ) = payable(owner()).call{value: address(this).balance}("");
        require(sent, "Withdraw failed");
    }

    function setDefaultRoyalty(address receiver, uint96 numerator) external onlyOwner {
        _setDefaultRoyalty(receiver, numerator);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A, ERC2981) returns (bool) {
        return ERC721A.supportsInterface(interfaceId) || ERC2981.supportsInterface(interfaceId);
    }
}