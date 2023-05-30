//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "erc721psi/contracts/ERC721Psi.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

contract TOKEN is
    ERC721Psi,
    ERC2981,
    Ownable,
    ReentrancyGuard,
    DefaultOperatorFilterer
{
    using Strings for uint256;

    uint256 public constant MAX_SUPPLY = 3333;
    uint256 public constant PRICE = 0.02 ether;

    bool public preSaleStart;
    bool public pubSaleStart;
    uint256 public mintLimit = 2;
    bytes32 public merkleRoot = 0x87f07491173c26aa3a9bb1708649473aa467a6db407fb2ad31c1cfe4b1a310b5;

    string private _baseTokenURI = "https://d1tzqlpa5utiea.cloudfront.net/romaco_abuse_music/metadata/";

    mapping(address => uint256) public claimed;

    constructor() ERC721Psi("Romaco Abuse Music", "RAM") {
        _setDefaultRoyalty(0x2Ad9c33fB92bc5E4eE740a77Ff4F94a7F5572acC, 1000);

        _member.founder = 0x2Ad9c33fB92bc5E4eE740a77Ff4F94a7F5572acC;
        _member.illustrator = 0xd87DfEe4724AfaB22Ba21053d42f6d2b9a68C41C;
        _member.marketer = 0x2c2D9a9fac936A8729B22579eC1FCA50F4C6445F;
        _member.musician = 0x5DadE3533eC6789F5DCd3190323F40b3f4bB6dC6;
        _member.developer = 0x48A23fb6f56F9c14D29FA47A4f45b3a03167dDAe;

        _safeMint(owner(), 1);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override(ERC721Psi)
        returns (string memory)
    {
        return string(abi.encodePacked(ERC721Psi.tokenURI(_tokenId), ".json"));
    }

    function pubMint(uint256 _quantity) public payable nonReentrant {
        uint256 supply = totalSupply();
        uint256 cost = PRICE * _quantity;
        require(pubSaleStart, "Before sale begin.");
        _mintCheck(_quantity, supply, cost);

        claimed[msg.sender] += _quantity;
        _safeMint(msg.sender, _quantity);
    }

    function checkMerkleProof(bytes32[] calldata _merkleProof)
        public
        view
        returns (bool)
    {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        return MerkleProof.verifyCalldata(_merkleProof, merkleRoot, leaf);
    }

    function preMint(uint256 _quantity, bytes32[] calldata _merkleProof)
        public
        payable
        nonReentrant
    {
        uint256 supply = totalSupply();
        uint256 cost = PRICE * _quantity;
        require(preSaleStart, "Before sale begin.");
        _mintCheck(_quantity, supply, cost);

        require(checkMerkleProof(_merkleProof), "Invalid Merkle Proof");

        claimed[msg.sender] += _quantity;
        _safeMint(msg.sender, _quantity);
    }

    function _mintCheck(
        uint256 _quantity,
        uint256 _supply,
        uint256 _cost
    ) private view {
        require(_supply + _quantity <= MAX_SUPPLY, "Max supply over");
        require(_quantity <= mintLimit, "Mint quantity over");
        require(msg.value >= _cost, "Not enough funds");
        require(
            claimed[msg.sender] + _quantity <= mintLimit,
            "Already claimed max"
        );
    }

    function ownerMint(address _address, uint256 _quantity) public onlyOwner {
        uint256 supply = totalSupply();
        require(supply + _quantity <= MAX_SUPPLY, "Max supply over");
        _safeMint(_address, _quantity);
    }

    // only owner
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
        address founder;
        address illustrator;
        address marketer;
        address musician;
        address developer;
    }
    ProjectMember private _member;

    function setMemberAddress(
        address _founder,
        address _illustrator,
        address _marketer,
        address _musician,
        address _developer
    ) public onlyOwner {
        _member.founder = _founder;
        _member.illustrator = _illustrator;
        _member.marketer = _marketer;
        _member.musician = _musician;
        _member.developer = _developer;
    }

    function withdraw() external onlyOwner {
        require(
            _member.founder != address(0) &&
            _member.illustrator != address(0) &&
            _member.marketer != address(0) &&
            _member.musician != address(0) &&
            _member.developer != address(0),
            "Please set member address"
        );

        uint256 balance = address(this).balance;
        Address.sendValue(payable(_member.founder), ((balance * 2800) / 10000));
        Address.sendValue(
            payable(_member.illustrator),
            ((balance * 1000) / 10000)
        );
        Address.sendValue(payable(_member.marketer), ((balance * 1400) / 10000));
        Address.sendValue(payable(_member.musician), ((balance * 2800) / 10000));
        Address.sendValue(
            payable(_member.developer),
            ((balance * 2000) / 10000)
        );
    }

    // OperatorFilterer
    function setOperatorFilteringEnabled(bool _state) external onlyOwner {
        operatorFilteringEnabled = _state;
    }

    function setApprovalForAll(address operator, bool approved)
        public
        override
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId)
        public
        override
        onlyAllowedOperatorApproval(operator)
    {
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

    // Royality
    function setRoyalty(address _royaltyAddress, uint96 _feeNumerator)
        external
        onlyOwner
    {
        _setDefaultRoyalty(_royaltyAddress, _feeNumerator);
    }

    function supportsInterface(bytes4 _interfaceId)
        public
        view
        virtual
        override(ERC721Psi, ERC2981)
        returns (bool)
    {
        return
            ERC721Psi.supportsInterface(_interfaceId) ||
            ERC2981.supportsInterface(_interfaceId);
    }
}