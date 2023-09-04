//SPDX-License-Identifier: MIT

pragma solidity >=0.5.8 <0.9.0;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {ERC2981} from "@openzeppelin/contracts/token/common/ERC2981.sol";
import {ERC721Psi} from "./ERC721Psi.sol";
import {DefaultOperatorFilterer} from "./operator-filter-registry/src/DefaultOperatorFilterer.sol";

contract NFTxCMusic is
    ERC721Psi,
    ERC2981,
    Ownable,
    ReentrancyGuard,
    DefaultOperatorFilterer
{
    using Strings for uint256;

    uint256 public constant MAX_SUPPLY = 777;
    uint256 public constant PRE_PRICE = 0.0077 ether;
    uint256 public constant PUB_PRICE = 0.0077 ether;

    bool public preSaleStart;
    bool public pubSaleStart;

    uint256 public mintLimit = 5;

    bytes32 public merkleRoot;

    string private _baseTokenURI;

    mapping(address => uint256) public claimed;

    event minted(
        address indexed sender,
        address indexed receiver,
        uint256 indexed quantity
    );

    constructor() ERC721Psi("NFTxC Music", "NFTXCM") {}

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function tokenURI(
        uint256 _tokenId
    ) public view virtual override(ERC721Psi) returns (string memory) {
        return string(abi.encodePacked(ERC721Psi.tokenURI(_tokenId), ".json"));
    }

    function checkMerkleProof(
        bytes32[] calldata _merkleProof
    ) public view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        return MerkleProof.verifyCalldata(_merkleProof, merkleRoot, leaf);
    }

    function preMint(
        uint256 _quantity,
        bytes32[] calldata _merkleProof
    ) public payable nonReentrant {
        require(preSaleStart, "Before sale begin.");
        require(totalSupply() + _quantity <= MAX_SUPPLY, "Max supply over");
        require(msg.value >= PRE_PRICE * _quantity, "Not enough funds");
        require(_quantity <= mintLimit, "Mint quantity over");
        require(
            claimed[msg.sender] + _quantity <= mintLimit,
            "Already claimed max"
        );
        require(checkMerkleProof(_merkleProof), "Invalid Merkle Proof");

        claimed[msg.sender] += _quantity;
        _safeMint(msg.sender, _quantity);

        emit minted(msg.sender, msg.sender, _quantity);
    }

    function pubMint(
        uint256 _quantity,
        address _receiver
    ) public payable nonReentrant {
        require(pubSaleStart, "Before sale begin.");
        require(totalSupply() + _quantity <= MAX_SUPPLY, "Max supply over");
        require(msg.value >= PUB_PRICE * _quantity, "Not enough funds");

        claimed[_receiver] += _quantity;
        _safeMint(_receiver, _quantity);

        emit minted(msg.sender, _receiver, _quantity);
    }

    function ownerMint(address _receiver, uint256 _quantity) public onlyOwner {
        require(totalSupply() + _quantity <= MAX_SUPPLY, "Max supply over");
        _safeMint(_receiver, _quantity);

        emit minted(msg.sender, _receiver, _quantity);
    }

    function setBaseURI(string calldata _uri) external onlyOwner {
        _baseTokenURI = _uri;
    }

    function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function setPresale(bool _state) public onlyOwner {
        preSaleStart = _state;
    }

    function setPubsale(bool _state) public onlyOwner {
        pubSaleStart = _state;
    }

    function setMintLimit(uint256 _quantity) public onlyOwner {
        mintLimit = _quantity;
    }

    struct ProjectMember {
        address soundDesert;
        address onigiriman;
        address ruriho;
        address artKungFu;
        address mai;
        address hayamiAsuka;
        address ciana;
        address musician;
    }
    ProjectMember private _member;

    function setMemberAddress(
        address _soundDesert,
        address _onigiriman,
        address _ruriho,
        address _artKungFu,
        address _mai,
        address _hayamiAsuka,
        address _ciana,
        address _musician
    ) public onlyOwner {
        _member.soundDesert = _soundDesert;
        _member.onigiriman = _onigiriman;
        _member.ruriho = _ruriho;
        _member.artKungFu = _artKungFu;
        _member.mai = _mai;
        _member.hayamiAsuka = _hayamiAsuka;
        _member.ciana = _ciana;
        _member.musician = _musician;
    }

    function withdraw() external onlyOwner {
        require(
            _member.soundDesert != address(0) &&
                _member.onigiriman != address(0) &&
                _member.ruriho != address(0) &&
                _member.artKungFu != address(0) &&
                _member.mai != address(0) &&
                _member.hayamiAsuka != address(0) &&
                _member.ciana != address(0) &&
                _member.musician != address(0),
            "Please set members address"
        );
        uint256 balance = address(this).balance;
        Address.sendValue(
            payable(_member.soundDesert),
            ((balance * 2000) / 10000)
        );
        Address.sendValue(
            payable(_member.onigiriman),
            ((balance * 600) / 10000)
        );
        Address.sendValue(payable(_member.ruriho), ((balance * 600) / 10000));
        Address.sendValue(
            payable(_member.artKungFu),
            ((balance * 1500) / 10000)
        );
        Address.sendValue(payable(_member.mai), ((balance * 600) / 10000));
        Address.sendValue(
            payable(_member.hayamiAsuka),
            ((balance * 1100) / 10000)
        );
        Address.sendValue(payable(_member.ciana), ((balance * 600) / 10000));
        Address.sendValue(
            payable(_member.musician),
            ((balance * 3000) / 10000)
        );
    }

    function setOperatorFilteringEnabled(bool _state) external onlyOwner {
        operatorFilteringEnabled = _state;
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
    ) public override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function setRoyalty(
        address _royaltyAddress,
        uint96 _feeNumerator
    ) external onlyOwner {
        _setDefaultRoyalty(_royaltyAddress, _feeNumerator);
    }

    function supportsInterface(
        bytes4 _interfaceId
    ) public view virtual override(ERC721Psi, ERC2981) returns (bool) {
        return
            ERC721Psi.supportsInterface(_interfaceId) ||
            ERC2981.supportsInterface(_interfaceId);
    }
}