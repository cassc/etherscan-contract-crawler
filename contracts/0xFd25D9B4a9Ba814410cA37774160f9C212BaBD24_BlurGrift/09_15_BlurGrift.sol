// SPDX-License-Identifier: MIT
//
// https://griftur.xyz
//
pragma solidity ^0.8.9;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "operator-filter-registry/src/RevokableOperatorFilterer.sol";
import {CANONICAL_OPERATOR_FILTER_REGISTRY_ADDRESS} from "operator-filter-registry/src/lib/Constants.sol";

abstract contract RevokableDefaultOperatorFilterer is
    RevokableOperatorFilterer
{
    address constant BLUR_CURATED_SUBSCRIPTION =
        0x9dC5EE2D52d014f8b81D662FA8f4CA525F27cD6b;

    constructor()
        RevokableOperatorFilterer(
            CANONICAL_OPERATOR_FILTER_REGISTRY_ADDRESS,
            BLUR_CURATED_SUBSCRIPTION,
            true
        )
    {}
}

contract BlurGrift is
    ERC721A,
    Pausable,
    ReentrancyGuard,
    RevokableDefaultOperatorFilterer,
    Ownable,
    ERC2981
{
    string private _baseTokenURI = "ipfs://QmYb5BQihqN6utgyeNXgdf7BfDnEWBTkwFMg95gPnL7HLm/";
    string private _baseURISuffix = ".json";

    uint256 public MINT_PRICE = 0.0069 ether;

    uint16 public MAX_SUPPLY = 666;

    uint8 public MAX_MINT_PER_TX = 3;
    uint8 public MAX_PER_WALLET = 6;

    constructor() ERC721A("Griftur", "GRIFTUR") {
        _setDefaultRoyalty(msg.sender, 250);
    }

    function mint(uint8 num) external payable whenNotPaused nonReentrant {
        uint256 requiredMintFee = MINT_PRICE * num;
        if (_numberMinted(msg.sender) == 0) {
            requiredMintFee = MINT_PRICE * (num - 1);
        }
        require(msg.value >= requiredMintFee, "Send more ETH");
        require(num <= MAX_MINT_PER_TX, "Limit 3 per transaction");
        uint256 totalMinted = _totalMinted();
        require(num + totalMinted < MAX_SUPPLY, "Cannot mint past max supply");
        uint256 mintedByWallet = _numberMinted(msg.sender);
        require(mintedByWallet + num <= MAX_PER_WALLET, "Limit 6 per wallet");
        _mint(msg.sender, num);
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override(ERC721A)
        returns (string memory)
    {
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory baseURI = _baseURI();
        string memory extension = _baseURIExtension();
        return
            bytes(baseURI).length > 0
                ? string(
                    abi.encodePacked(baseURI, _toString(_tokenId), extension)
                )
                : "";
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    function _baseURIExtension() internal view returns (string memory) {
        return _baseURISuffix;
    }

    function setBaseURI(string memory baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function setBaseURISuffix(string memory baseURISuffix) external onlyOwner {
        _baseURISuffix = baseURISuffix;
    }

    function reserve(uint8 num) external onlyOwner {
        uint256 totalMinted = _totalMinted();
        require(num + totalMinted < MAX_SUPPLY, "Cannot mint past max supply");
        _mint(msg.sender, num);
    }

    function getNumberMinted(address addr) external view returns (uint256) {
        return _numberMinted(addr);
    }

    function setMaxSupply(uint16 newSupply) public onlyOwner {
        require(newSupply <= 666, "Increasing supply not allowed");
        MAX_SUPPLY = newSupply;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function owner()
        public
        view
        virtual
        override(Ownable, UpdatableOperatorFilterer)
        returns (address)
    {
        return Ownable.owner();
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721A, ERC2981)
        returns (bool)
    {
        // Supports the following `interfaceId`s:
        // - IERC165: 0x01ffc9a7
        // - IERC721: 0x80ac58cd
        // - IERC721Metadata: 0x5b5e139f
        // - IERC2981: 0x2a55205a
        return
            ERC721A.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId);
    }

    function withdraw() external onlyOwner {
        uint256 _balance = address(this).balance;
        payable(msg.sender).transfer(_balance);
    }

    function setDefaultRoyalty(address receiver, uint96 feeNumerator)
        public
        onlyOwner
    {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override(ERC721A) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override(ERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable override(ERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}