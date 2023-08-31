// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "erc721a/contracts/ERC721A.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";

error ErrorSaleNotStarted();
error ErrorExceedMaxSupply();
error ErrorExceedWalletLimit();
error ErrorInsufficientFund();
error ErrorContractInteractionForbidden();

contract Wunky is ERC2981, ERC721A, Ownable, DefaultOperatorFilterer {
    using Address for address payable;
    using Strings for uint256;

    uint256 public immutable _mintPrice;
    uint32 public immutable _maxSupply;
    uint32 public immutable _walletLimit;
    uint32 public immutable _freeAmount;

    bool public _mintStarted;

    string public _metaDataURI = "ipfs://bafybeigctdzuhn7nan4fxj2v7urfqqoa2hffmdmyrtsx5yjduhgdaixixe/";

    constructor(
        uint256 mintPrice,
        uint32 maxSupply,
        uint32 walletLimit,
        uint32 freeAmount,
        uint32 initialAirdropAmount
    ) ERC721A("Wunky", "WKY") {
        _mintPrice = mintPrice;
        _maxSupply = maxSupply;
        _walletLimit = walletLimit;
        _freeAmount = freeAmount;

        _mint(msg.sender, initialAirdropAmount);
    }

    function mint(uint32 amount) external payable {
        if (!_mintStarted) revert ErrorSaleNotStarted();
        if (tx.origin != msg.sender) revert ErrorContractInteractionForbidden();
        if (amount + _totalMinted() > _maxSupply) revert ErrorExceedMaxSupply();
        uint256 requiredValue = amount * _mintPrice;
        uint256 userMinted = _numberMinted(msg.sender);
        if (userMinted == 0) {
            requiredValue -= _mintPrice;
        }
        if (userMinted > _walletLimit) revert ErrorExceedWalletLimit();
        if (msg.value < requiredValue) revert ErrorInsufficientFund();
        _safeMint(msg.sender, amount);
    }

    function mint(
        address[] calldata recipients,
        uint256[] calldata amounts
    ) external onlyOwner {
        require(recipients.length == amounts.length);
        for (uint256 i = 0; i < recipients.length; i++) {
            _mint(recipients[i], amounts[i]);
        }
        if (_totalMinted() > _maxSupply) revert ErrorExceedMaxSupply();
    }

    function _info(
        address minter
    )
        external
        view
        returns (
            uint256 mintPrice,
            uint32 freeAmount,
            uint32 walletLimit,
            uint32 maxSupply,
            uint32 totalMinted,
            uint32 userMinted,
            bool mintStarted,
            bool soldout
        )
    {
        mintPrice = _mintPrice;
        freeAmount = _freeAmount;
        walletLimit = _walletLimit;
        maxSupply = _maxSupply;
        totalMinted = uint32(ERC721A._totalMinted());
        userMinted = uint32(ERC721A._numberMinted(minter));
        mintStarted = _mintStarted;
        soldout = _totalMinted() >= _maxSupply;
    }

    function setMintStarted(bool started) external onlyOwner {
        _mintStarted = started;
    }

    function setMetadataURI(string memory uri) external onlyOwner {
        _metaDataURI = uri;
    }

    function tokenURI(
        uint256 tokenId
    ) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
        string memory baseURI = _metaDataURI;
        return string(abi.encodePacked(baseURI, tokenId.toString(), ".json"));
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function withdraw() external onlyOwner {
        payable(msg.sender).sendValue(address(this).balance);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC2981, ERC721A) returns (bool) {
        return
            ERC2981.supportsInterface(interfaceId) ||
            ERC721A.supportsInterface(interfaceId);
    }

    function setFeeNumerator(uint96 feeNumerator) external onlyOwner {
        _setDefaultRoyalty(owner(), feeNumerator);
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