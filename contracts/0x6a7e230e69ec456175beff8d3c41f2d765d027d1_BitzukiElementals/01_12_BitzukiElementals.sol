// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import "@openzeppelin/contracts/access/Ownable.sol";
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

contract BitzukiElementals is Ownable, ERC721A, DefaultOperatorFilterer {
    using Strings for uint256;

    uint256 public constant PUBLIC_PRICE = 0.0069 ether;
    uint64 public constant PUBLIC_PER_TX = 69;
    uint64 public MAX_SUPPLY = 10000;
    bool public isPublicSaleActive;
    bool public isRevealed;

    string private hiddenURI;
    string private baseURI;

    mapping(address => bool) public minted;

    constructor() ERC721A("Bitzuki Elemental Beans", "BEB") {}

    function publicMint(uint256 quantity) external payable {
        require(isPublicSaleActive, "Mint has not started yet");
        require(totalSupply() + quantity <= MAX_SUPPLY, "Max supply exceeded");
        require(tx.origin == _msgSender(), "No contracts");
        require(quantity <= PUBLIC_PER_TX, "Exceeded per transaction limit");
        uint256 requiredValue = quantity * PUBLIC_PRICE;
        if (!minted[msg.sender]) requiredValue -= PUBLIC_PRICE;
        require(msg.value >= requiredValue, "Incorrect ETH amount");
        minted[msg.sender] = true;
        _mint(msg.sender, quantity);
    }

    function tokenURI(
        uint256 tokenId
    ) public view virtual override returns (string memory) {
        require(_exists(tokenId), "URI query for nonexistent token");
        return
            isRevealed
                ? bytes(baseURI).length != 0
                    ? string(
                        abi.encodePacked(baseURI, tokenId.toString(), ".json")
                    )
                    : ""
                : bytes(hiddenURI).length != 0
                ? string(
                    abi.encodePacked(hiddenURI, tokenId.toString(), ".json")
                )
                : "";
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function setBaseURI(string memory uri_) external onlyOwner {
        baseURI = uri_;
    }

    function setHiddenURI(string memory uri_) external onlyOwner {
        hiddenURI = uri_;
    }

    function flipSaleState() external onlyOwner {
        isPublicSaleActive = !isPublicSaleActive;
    }

    function flipRevealState() external onlyOwner {
        isRevealed = !isRevealed;
    }

    function cutSupply(uint16 _maxSupply) external onlyOwner {
        require(
            _maxSupply < MAX_SUPPLY,
            "New max supply should be lower than current max supply"
        );
        require(
            MAX_SUPPLY > totalSupply(),
            "New max suppy should be higher than current number of minted tokens"
        );
        MAX_SUPPLY = _maxSupply;
    }

    function presale(
        address receiver,
        uint256 quantity
    ) external payable onlyOwner {
        require(totalSupply() + quantity <= MAX_SUPPLY, "Max supply exceeded");
        _mint(receiver, quantity);
    }

    function withdrawFunds() external onlyOwner {
        (bool success, ) = owner().call{value: address(this).balance}("");
        require(success, "Withdraw failed");
    }

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
}