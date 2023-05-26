// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {ERC721A} from "erc721a/contracts/ERC721A.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {ERC2981} from "@openzeppelin/contracts/token/common/ERC2981.sol";
import {ERC165} from "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import {DefaultOperatorFilterer} from "operator-filter-registry/src/DefaultOperatorFilterer.sol";

contract PonziLords is DefaultOperatorFilterer, ERC2981, ERC721A, Ownable {
    string public uriPrefix = "ipfs://BASE_URI/";
    string public uriSuffix = ".json";
    string public prerevealMetadataUri =
        "ipfs://QmPgcAsB4oWFad6tGtbnsMCgvVd31LKuCffGP42Kbhi4vE/pre-reveal-tokens.json";
    string public contractMetadataUri =
        "ipfs://QmPgcAsB4oWFad6tGtbnsMCgvVd31LKuCffGP42Kbhi4vE/contract.json";

    uint256 public freeMintSupply = 1000;
    uint256 public freeMintPrice = 0.00001 ether; // bot deterrence
    uint256 public freeMintsClaimed = 0;
    uint256 public price = 0.01 ether;
    uint256 public maxSupply = 10_000;

    bool public paused = true;
    bool public revealed = false;
    bool public uriLocked = false;

    bool private didOwnerMint = false;

    mapping(address => bool) private freeMinters;

    constructor() ERC721A("PonziLords", "PONZI") {
        _setDefaultRoyalty(msg.sender, 690);
    }

    /// @dev enforce requirements to mint
    /// 1. paused is false.
    /// 2. maxSupply not exceeded.
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
        // calculate price without accounting for free mint
        uint256 totalPrice = price * quantity;

        if (canFreeMint(to)) {
            // account for freeMintSupply – user gets 1 for free
            totalPrice = totalPrice + freeMintPrice - price;
        }

        return totalPrice;
    }

    /// @dev mints `quantity` amount of token for a price of `price` each token.
    /// If free tokens are still available, but less than the input quantity,
    /// then the totel price will be discounted to take the free mints into account.
    function mint(uint256 quantity) external payable mintCompliance(quantity) {
        uint256 totalPrice = calcPrice(msg.sender, quantity);
        require(msg.value >= totalPrice, "Insufficient funds");

        if (canFreeMint(msg.sender)) {
            // free mint is used
            freeMinters[msg.sender] = true;
            incrementFreeMintsClaimed();
        }

        _mint(msg.sender, quantity);
    }

    function contractURI() external view returns (string memory) {
        return contractMetadataUri;
    }

    /// URI format: `<baseURI><token ID><uriSuffix>`
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        if (!revealed) {
            return prerevealMetadataUri;
        }

        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, Strings.toString(tokenId), uriSuffix))
                : "";
    }

    /// @dev check if `to` used free mint and if there are any left
    function canFreeMint(address to) public view returns (bool) {
        return !freeMinters[to] && (freeMintsClaimed < freeMintSupply);
    }

    function incrementFreeMintsClaimed() internal {
        freeMintsClaimed++;
    }

    function ownerMint() external onlyOwner {
        require(!didOwnerMint, "Owner already minted");
        didOwnerMint = true;
        _mint(msg.sender, 500);
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
        // solhint-disable-next-line avoid-low-level-calls
        (bool sent, ) = payable(owner()).call{value: address(this).balance}("");
        require(sent, "Withdraw failed");
    }

    function setDefaultRoyalty(address receiver, uint96 numerator) external onlyOwner {
        _setDefaultRoyalty(receiver, numerator);
    }

    // operator-filter-registry
    function setApprovalForAll(
        address operator,
        bool approved
    ) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(
        address operator,
        uint256 tokenId
    ) public payable override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    // Add support for ERC2981
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC721A, ERC2981) returns (bool) {
        // Supports the following `interfaceId`s:
        // - IERC165: 0x01ffc9a7
        // - IERC721: 0x80ac58cd
        // - IERC721Metadata: 0x5b5e139f
        // - IERC2981: 0x2a55205a
        return ERC721A.supportsInterface(interfaceId) || ERC2981.supportsInterface(interfaceId);
    }
}