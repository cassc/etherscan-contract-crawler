// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/// @title Fluff ERC721A

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./DefaultOperatorFilterer.sol";
import "./ERC721A.sol";

contract FluffERC721A is
    ERC721A,
    ERC2981,
    Ownable,
    DefaultOperatorFilterer,
    PaymentSplitter
{
    using Strings for uint;

    enum Step {
        Before,
        WhitelistSale,
        PublicSale,
        SoldOut,
        Reveal
    }

    uint private constant MAX_SUPPLY = 5000;
    uint private constant maxPerAddressWl = 1;
    uint private constant maxPerAddressPublic = 1;

    mapping(address => uint) public amountNFTsperWalletWl;
    mapping(address => uint) public amountNFTsperWalletPublic;

    Step public sellingStep;
    bytes32 public merkleRoot;
    string public baseURI;
    string public baseCollectionURI;
    uint private teamLength;

    constructor(
        address[] memory _team,
        uint[] memory _teamShares,
        bytes32 _merkleRoot,
        string memory _baseURI,
        string memory _baseCollectionURI
    ) ERC721A("Fluff", "FLUFF") PaymentSplitter(_team, _teamShares) {
        merkleRoot = _merkleRoot;
        baseURI = _baseURI;
        baseCollectionURI = _baseCollectionURI;
        teamLength = _team.length;
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    function giftMany(address[] calldata _to) external onlyOwner {
        require(totalSupply() + _to.length <= MAX_SUPPLY, "Reached max supply");
        for (uint i = 0; i < _to.length; i++) {
            _safeMint(_to[i], 1);
        }
    }

    function gift(address _to, uint _quantity) external onlyOwner {
        require(totalSupply() + _quantity <= MAX_SUPPLY, "Reached max supply");
        _safeMint(_to, _quantity);
    }

    function whitelistMint(
        address _account,
        uint _quantity,
        bytes32[] calldata _proof
    ) external payable callerIsUser {
        require(
            sellingStep == Step.WhitelistSale,
            "Whitelist sale is not activated"
        );
        require(isWhiteListed(msg.sender, _proof), "Not whitelisted");
        require(
            amountNFTsperWalletWl[msg.sender] + _quantity <= maxPerAddressWl,
            "You can only get 1 NFT on the Whitelist Sale"
        );
        require(totalSupply() + _quantity <= MAX_SUPPLY, "Max supply exceeded");
        amountNFTsperWalletWl[msg.sender] += _quantity;
        _safeMint(_account, _quantity);
    }

    function publicSaleMint(
        address _account,
        uint _quantity
    ) external payable callerIsUser {
        require(sellingStep == Step.PublicSale, "Public sale is not activated");
        require(
            amountNFTsperWalletPublic[msg.sender] + _quantity <=
                maxPerAddressPublic,
            "You can only get 1 NFT on the Public Sale"
        );
        require(totalSupply() + _quantity <= MAX_SUPPLY, "Max supply exceeded");
        amountNFTsperWalletPublic[msg.sender] += _quantity;
        _safeMint(_account, _quantity);
    }

    function tokenURI(
        uint _tokenId
    ) public view virtual override returns (string memory) {
        require(_exists(_tokenId), "URI query for nonexistent token");
        return string(abi.encodePacked(baseURI, _tokenId.toString(), ".json"));
    }

    function setStep(uint _step) external onlyOwner {
        sellingStep = Step(_step);
    }

    function setBaseUri(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    function setCollectionBaseUri(
        string memory _baseCollectionURI
    ) external onlyOwner {
        baseCollectionURI = _baseCollectionURI;
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function isWhiteListed(
        address _account,
        bytes32[] calldata _proof
    ) internal view returns (bool) {
        return _verify(leaf(_account), _proof);
    }

    function leaf(address _account) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_account));
    }

    function _verify(
        bytes32 _leaf,
        bytes32[] memory _proof
    ) internal view returns (bool) {
        return MerkleProof.verify(_proof, merkleRoot, _leaf);
    }

    function releaseAll() external onlyOwner {
        for (uint i = 0; i < teamLength; i++) {
            release(payable(payee(i)));
        }
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override onlyAllowedOperator {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override onlyAllowedOperator {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable override onlyAllowedOperator {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC721A, ERC2981) returns (bool) {
        return
            ERC721A.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId);
    }

    function contractURI() public view returns (string memory) {
        return baseCollectionURI;
    }

    receive() external payable override {
        revert("Only if you mint");
    }
}