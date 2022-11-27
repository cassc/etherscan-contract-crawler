// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import { IERC721A } from "erc721a/contracts/IERC721A.sol";
import { ERC721A } from "erc721a/contracts/ERC721A.sol";
import { ERC721ABurnable } from "erc721a/contracts/extensions/ERC721ABurnable.sol";
import { ERC721AQueryable } from "erc721a/contracts/extensions/ERC721AQueryable.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { OperatorFilterer } from "./OperatorFilterer.sol";

contract OwangePod is ERC721A, ERC721ABurnable, ERC721AQueryable, OperatorFilterer(0x3cc6CddA760b79bAfa08dF41ECFA224f810dCeB6, true), Ownable {
    using ECDSA for bytes32;
    using Strings for uint256;

    modifier directOnly {
        require(msg.sender == tx.origin);
        _;
    }

    enum SaleStatus {
        CLOSED,
        WHITELIST,
        PUBLIC
    }

    struct AirdropData {
        address to;
        uint96 amount;
    }

    // Supply
    uint public constant MAX_SUPPLY = 10000;
    uint public MAX_PUBLIC_SUPPLY = 7000;

    // Mint settings
    uint public maxPublicMintPerWallet = 3;
    uint public whitelistPrice = 0.1 ether;
    uint public publicPrice = 0.15 ether;

    // Mutable states
    SaleStatus public saleStatus;
    string baseURI = "";
    address public signer = 0x22Bb7F78c51Dc8283950Ecd516E6Da4E1f34ef9E;
    bool public operatorFilteringEnabled = true;

    constructor() ERC721A("Owange Pod", "OWP") { }

    // Public mint
    function publicMint(uint32 amount) external payable directOnly {
        // Check for sale status
        require(saleStatus == SaleStatus.PUBLIC, "Sale is not active");

        // Make sure mint doesn't go over total supply
        require(_totalMinted() + amount <= MAX_PUBLIC_SUPPLY, "Max public supply reached");

        // Fetch amount minted for sender
        uint32 publicMinted = getPublicMinted(msg.sender);
        
        // Verify sender isn't minting over maximum allowed
        require(amount + publicMinted <= maxPublicMintPerWallet, "Max allowed mint reached");

        // Verify the ETH amount sent
        require(msg.value == amount * publicPrice, "Invalid ETH sent");

        // Update mint data for sender
        uint64 aux = _getAux(msg.sender);
        _setAux(msg.sender, (aux & 0xffffffff) + (uint64(publicMinted + amount) << 32));

        // Mint
        _mint(msg.sender, amount);

        // If maximum public supply is reached, close the saleStatus
        if (_totalMinted() == MAX_PUBLIC_SUPPLY) {
            saleStatus = SaleStatus.CLOSED;
        }
    }

    // Private mint
    function whitelistMint(uint32 amount, uint32 maxAmount, bytes calldata signature) external payable directOnly {
        // Check for sale status
        require(saleStatus == SaleStatus.WHITELIST, "Sale is not active");

        // Make sure mint doesn't go over total supply
        require(_totalMinted() + amount <= MAX_SUPPLY, "Max supply reached");

        // Fetch amount minted for sender
        uint32 whitelistMinted = getWhitelistMinted(msg.sender);
        
        // Verify sender isn't minting over maximum allowed
        require(amount + whitelistMinted <= maxAmount, "Max allowed mint reached");

        // Verify the ETH amount sent
        require(msg.value == amount * whitelistPrice, "Invalid ETH sent");

        // Verify ECDSA signature
        require(verifySignature(keccak256(abi.encode(msg.sender, maxAmount)), signature));

        // Update mint data for sender
        uint64 aux = _getAux(msg.sender);
        _setAux(msg.sender, (aux & 0xffffffff00000000) + (whitelistMinted + amount));

        // Mint
        _mint(msg.sender, amount);

        // If maximum public supply is reached, close the saleStatus
        if (_totalMinted() == MAX_SUPPLY) {
            saleStatus = SaleStatus.CLOSED;
        }
    }

    // Owner functions

    function airdrop(AirdropData[] calldata airdropData) external onlyOwner {
        unchecked {
            uint len = airdropData.length;
            for (uint i = 0; i < len; ++i) {
                airdropMint(airdropData[i]);
            }
        }
    }

    // 0: CLOSED
    // 1: WHITELIST
    // 2: PUBLIC
    function setSaleStatus(SaleStatus _saleStatus) external onlyOwner {
        saleStatus = _saleStatus;
    }

    function withdraw() external onlyOwner {
        (bool success, ) = owner().call{ value: address(this).balance }("");
        require(success, "Transfer failed");
    }

    function setSigner(address _signer) external onlyOwner {
        signer = _signer;
    }

    function setMaxPublicSupply(uint _amount) external onlyOwner {
        MAX_PUBLIC_SUPPLY = _amount;
    }

    function setMaxPublicMintPerWallet(uint _amount) external onlyOwner {
        maxPublicMintPerWallet = _amount;
    }

    function setWhitelistPrice(uint _price) external onlyOwner {
        whitelistPrice = _price;
    }

    function setPublicPrice(uint _price) external onlyOwner {
        publicPrice = _price;
    }

    function setBaseURI(string calldata _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    function setOperatorFilteringEnabled(bool _value) external onlyOwner {
        operatorFilteringEnabled = _value;
    }

    // Internal
    function verifySignature(bytes32 hash, bytes calldata signature) internal view returns(bool) {
        return hash.toEthSignedMessageHash().recover(signature) == signer;
    }

    function airdropMint(AirdropData calldata airdropData) private {
        _mint(airdropData.to, airdropData.amount);
    }

    // View
    // Bits Layout `aux`:
    // - [0...31]  `whitelistMinted`
    // - [32..63]  `publicMinted`

    function getPublicMinted(address user) public view returns(uint32) {
        return uint32(_getAux(user) >> 32);
    }

    function getWhitelistMinted(address user) public view returns(uint32) {
        return uint32(_getAux(user));
    }

    function tokenURI(uint tokenId) public view override(ERC721A, IERC721A) returns(string memory) {
        return string(abi.encodePacked(baseURI, _toString(tokenId)));
    }

    // Override approval and transfer functions to include OperatorFilterer modifier
    function approve(address to, uint256 tokenId) public payable virtual override(ERC721A, IERC721A) onlyAllowedOperatorApproval(to, operatorFilteringEnabled) {
        super.approve(to, tokenId);
    }

    function setApprovalForAll(address operator, bool approved) public virtual override(ERC721A, IERC721A) onlyAllowedOperatorApproval(operator, operatorFilteringEnabled) {
        super.setApprovalForAll(operator, approved);
    }

    function transferFrom(address from, address to, uint256 tokenId) public payable override(ERC721A, IERC721A) onlyAllowedOperator(from, operatorFilteringEnabled) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public payable override(ERC721A, IERC721A) onlyAllowedOperator(from, operatorFilteringEnabled) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public payable override(ERC721A, IERC721A) onlyAllowedOperator(from, operatorFilteringEnabled) {
        super.safeTransferFrom(from, to, tokenId, _data);
    }
}