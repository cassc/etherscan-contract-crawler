// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import '@openzeppelin/contracts/access/Ownable.sol';
import 'erc721a/contracts/extensions/ERC721AQueryable.sol';
import 'operator-filter-registry/src/DefaultOperatorFilterer.sol';
import '@openzeppelin/contracts/token/common/ERC2981.sol';

contract ChibiCoup is
    ERC721A('ChibiCoup', 'CC'),
    ERC721AQueryable,
    ERC2981,
    Ownable,
    DefaultOperatorFilterer
{
    uint256 public maxMintPerWallet = 4;
    uint256 public maxFreeMintPerWallet = 1;
    uint256 public mintPrice = 0.003 ether;
    uint256 public maxSupply = 3333;
    uint256 public royaltyBPS = 500;
    bool public paused = true;
    string public baseURI;

    function mint(uint256 amount) external payable {
        require(!paused, 'ChibiCoup: Public Sale paused');
        require(tx.origin == msg.sender, 'ChibiCoup: No contracts');
        require(totalSupply() + amount <= maxSupply, 'ChibiCoup: Max supply minted');

        uint256 previous = _numberMinted(_msgSender());

        require(previous + amount <= maxMintPerWallet, 'ChibiCoup: Exceeds public mint limit');

        uint256 freeMinted = _getAux(_msgSender());

        uint256 freeCount = freeMinted >= maxFreeMintPerWallet
            ? 0
            : maxFreeMintPerWallet - freeMinted;

        if (freeCount > 0) {
            _setAux(_msgSender(), uint64(freeMinted + freeCount));
        }

        uint256 paidCount = amount - freeCount;

        require(msg.value >= mintPrice * paidCount, 'ChibiCoup: Incorrect amount sent');

        /// Mint the token
        _safeMint(_msgSender(), amount);
    }

    function numberFreeMinted(address wallet) external view returns (uint256) {
        return _getAux(wallet);
    }

    function numberMinted(address wallet) external view returns (uint256) {
        return _numberMinted(wallet);
    }

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(
        uint256 tokenId
    ) public view virtual override(ERC721A, IERC721A) returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length != 0
                ? string(abi.encodePacked(baseURI, _toString(tokenId), '.json'))
                : '';
    }

    // royalty functions
    function supportsInterface(
        bytes4 interfaceId
    ) public view override(IERC721A, ERC2981, ERC721A) returns (bool) {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }

    // admin functions
    /// @param _royaltyBPS 100 = 1%, 500 = 5%, 1000 = 10%
    function setRoyaltyBPS(uint256 _royaltyBPS) external onlyOwner {
        royaltyBPS = _royaltyBPS;
    }

    function setMaxMintPerWallet(uint256 _maxMintPerWallet) external onlyOwner {
        maxMintPerWallet = _maxMintPerWallet;
    }

    function setMaxFreePerWallet(uint256 _maxFreeMintPerWallet) external onlyOwner {
        maxFreeMintPerWallet = _maxFreeMintPerWallet;
    }

    function setMintPrice(uint256 _mintPrice) external onlyOwner {
        mintPrice = _mintPrice;
    }

    function setMaxSupply(uint256 _maxSupply) external onlyOwner {
        maxSupply = _maxSupply;
    }

    function setPaused(bool isPaused) external onlyOwner {
        paused = isPaused;
    }

    function setBaseURI(string memory newBaseURI) external onlyOwner {
        baseURI = newBaseURI;
    }

    function airdrop(address recipient, uint256 amount) external onlyOwner {
        require(
            totalSupply() + amount <= maxSupply,
            'ChibiCoup: Airdrop amount exceeds maximum supply'
        );

        _safeMint(recipient, amount);
    }

    function withdraw() external onlyOwner {
        (bool success, ) = owner().call{value: address(this).balance}('');
        require(success, 'ChibiCoup: Withdraw failed');
    }

    // opensea overrides
    function setApprovalForAll(
        address operator,
        bool approved
    ) public override(ERC721A, IERC721A) onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(
        address operator,
        uint256 tokenId
    ) public payable override(ERC721A, IERC721A) onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override(ERC721A, IERC721A) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override(ERC721A, IERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable override(ERC721A, IERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    // internal overrides
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }
}