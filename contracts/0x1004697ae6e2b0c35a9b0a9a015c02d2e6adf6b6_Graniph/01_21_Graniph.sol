// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "erc721a-upgradeable/contracts/extensions/ERC721AQueryableUpgradeable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "operator-filter-registry/src/upgradeable/DefaultOperatorFiltererUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./IGraniphCountries.sol";

contract Graniph is
    Initializable,
    ERC721AQueryableUpgradeable,
    OwnableUpgradeable,
    IERC2981,
    DefaultOperatorFiltererUpgradeable
{
    string baseURI;
    bytes32 private _merkleRoot;

    bool public isPreSale;
    bool public isPublicSale;
    bool public isEndOfSale;

    uint256 private constant _PRE_MINT_PRICE = 0.0078 ether;
    uint256 private constant _PUBLIC_MINT_PRICE = 0.012 ether;
    uint256 private constant _TOTAL_SUPPLY = 2500;
    uint256 private constant _MAX_QUANTITY_PER_ADDRESS = 10;
    uint256 private constant _COUNTRY_COUNT = 196;

    address private _graniphCountriesAddr;
    address payable private _royaltyWallet;
    uint256 public royaltyBasis;

    mapping(uint256 => Location) private _tokenIdToLocation; // token id => location

    function initialize() initializerERC721A public initializer {
        __ERC721A_init("World Weather Control Bear", "WWCB");
        __Ownable_init();
        __DefaultOperatorFilterer_init();

        _royaltyWallet = payable(0xEC2f0EC388db1DA2F4EC543761C8F20ca50E1cbd);
        royaltyBasis = 250; // 2.5%
    }

    function setGraniphCountriesAddr(address newGraniphCountriesAddr) external onlyOwner {
        _graniphCountriesAddr = newGraniphCountriesAddr;
    }

    function setMerkleRoot(bytes32 merkleRoot) external onlyOwner {
        _merkleRoot = merkleRoot;
    }

    function isAllowlisted(bytes32[] calldata proof) public view returns(bool) {
        bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(msg.sender))));
        return MerkleProof.verify(proof, _merkleRoot, leaf);
    }

    function setIsPreSale(bool newIsPreSale) external onlyOwner {
        isPreSale = newIsPreSale;
    }

    function setIsPublicSale(bool newIsPublicSale) external onlyOwner {
        isPublicSale = newIsPublicSale;
    }

    function setIsEndOfSale(bool newIsEndOfSale) external onlyOwner {
        isEndOfSale = newIsEndOfSale;
    }

    function setRoyaltyWallet(address payable royaltyWallet) external onlyOwner {
        _royaltyWallet = royaltyWallet;
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;
    }

    function _mint(uint256 quantity) private {
        require(
            totalSupply() + quantity <= _TOTAL_SUPPLY,
            "Reached max supply"
        );

        uint256 nextTokenId = _nextTokenId();

        for (uint256 i = nextTokenId; i < nextTokenId + quantity; i++) {
            uint256 cityId = (i - 1) % _COUNTRY_COUNT;
            _tokenIdToLocation[i] = IGraniphCountries(_graniphCountriesAddr).generateLocation(cityId);
        }

        _mint(msg.sender, quantity);
    }

    function ownerMint(uint256 quantity) external onlyOwner {
        _mint(quantity);
    }

    function preMint(uint256 quantity, bytes32[] calldata proof) external payable {
        require(isPreSale, "PreSale is not active.");
        require(isAllowlisted(proof), "Invalid proof");
        require(_numberMinted(msg.sender) + quantity <= _MAX_QUANTITY_PER_ADDRESS, "Reached max quantity per address");
        require(msg.value == _PRE_MINT_PRICE * quantity, "Wrong price");
        _mint(quantity);
    }

    function publicMint(uint256 quantity) external payable {
        require(isPublicSale, "PublicSale is not active.");
        require(_numberMinted(msg.sender) + quantity <= _MAX_QUANTITY_PER_ADDRESS, "Reached max quantity per address");
        require(msg.value == _PUBLIC_MINT_PRICE * quantity, "Wrong price");
        _mint(quantity);
    }

    function setApprovalForAll(
        address operator,
        bool approved
    ) public override(ERC721AUpgradeable, IERC721AUpgradeable) onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(
        address operator,
        uint256 tokenId
    )
        public
        payable
        override(ERC721AUpgradeable, IERC721AUpgradeable)
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override(ERC721AUpgradeable, IERC721AUpgradeable) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override(ERC721AUpgradeable, IERC721AUpgradeable) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable override(ERC721AUpgradeable, IERC721AUpgradeable) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function getLocation(
        uint256 tokenId
    ) external view virtual returns (Location memory) {
        require(_exists(tokenId), "No token");
        return _tokenIdToLocation[tokenId];
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC721AUpgradeable, IERC165, IERC721AUpgradeable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function royaltyInfo(
        uint256 tokenId,
        uint256 salePrice
    )
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        require(_exists(tokenId), "Nonexistent token");
        return (payable(_royaltyWallet), uint((salePrice * royaltyBasis)/10000));
    }

    function withdraw() external onlyOwner {
        (bool sent,) = _royaltyWallet.call{value: address(this).balance}("");
        require(sent, "Failed to send Ether");
    }
}