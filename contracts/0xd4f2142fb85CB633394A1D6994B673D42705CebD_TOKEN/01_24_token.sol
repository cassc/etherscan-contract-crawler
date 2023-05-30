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

    uint256 public constant MAX_SUPPLY = 1000;
    uint256 public constant PRICE = 0.02 ether;

    bool public alSaleStart;
    bool public mlSaleStart;
    bool public pubSaleStart;

    mapping(uint256 => uint256) public mintLimit; // 0: AL, 1~3: ML, 4: public
    mapping(uint256 => bytes32) public merkleRoot; // 0: AL, 1~3: ML

    string private _baseTokenURI;

    mapping(address => uint256) public claimed;

    struct ProjectMember {
        address founder;
        address illustrator;
        address musician;
        address developer;
    }
    ProjectMember private _member;

    constructor() ERC721Psi("HOOPLA!", "HPA") {
        _setDefaultRoyalty(0x02cF19C4793A76797bD85C4c71209C398EaE2591, 1000);
        mintLimit[0] = 2; // AL
        mintLimit[1] = 2; // ML1
        mintLimit[2] = 4; // ML2
        mintLimit[3] = 6; // ML3
        mintLimit[4] = 100; // Public

        _member.founder = 0x135C84f1589b260440D4404f405Ee6bB294bA5DC;
        _member.illustrator = 0x4907a97379788E7415D5CcDecdaaC0DA26CcC5AC;
        _member.musician = 0x5DadE3533eC6789F5DCd3190323F40b3f4bB6dC6;
        _member.developer = 0x48A23fb6f56F9c14D29FA47A4f45b3a03167dDAe;
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
        _mintCheck(_quantity, supply, cost, 4);

        claimed[msg.sender] += _quantity;
        _safeMint(msg.sender, _quantity);
    }

    function checkMerkleProof(bytes32[] calldata _merkleProof, uint256 _alType)
        public
        view
        returns (bool)
    {
        require(_alType < 4, "AL Type is incorrect.");
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        return MerkleProof.verifyCalldata(_merkleProof, merkleRoot[_alType], leaf);
    }

    function alMint(uint256 _quantity, bytes32[] calldata _merkleProof)
        public
        payable
        nonReentrant
    {
        uint256 supply = totalSupply();
        uint256 cost = PRICE * _quantity;
        require(alSaleStart, "Before sale begin.");
        _mintCheck(_quantity, supply, cost, 0);

        require(checkMerkleProof(_merkleProof, 0), "Invalid Merkle Proof");

        claimed[msg.sender] += _quantity;
        _safeMint(msg.sender, _quantity);
    }

    function mlMint1(uint256 _quantity, bytes32[] calldata _merkleProof)
        public
        payable
        nonReentrant
    {
        uint256 supply = totalSupply();
        uint256 cost = PRICE * _quantity;
        require(mlSaleStart, "Before sale begin.");
        _mintCheck(_quantity, supply, cost, 1);

        require(checkMerkleProof(_merkleProof, 1), "Invalid Merkle Proof");

        claimed[msg.sender] += _quantity;
        _safeMint(msg.sender, _quantity);
    }

    function mlMint2(uint256 _quantity, bytes32[] calldata _merkleProof)
        public
        payable
        nonReentrant
    {
        uint256 supply = totalSupply();
        uint256 cost = PRICE * _quantity;
        require(mlSaleStart, "Before sale begin.");
        _mintCheck(_quantity, supply, cost, 2);

        require(checkMerkleProof(_merkleProof, 2), "Invalid Merkle Proof");

        claimed[msg.sender] += _quantity;
        _safeMint(msg.sender, _quantity);
    }

    function mlMint3(uint256 _quantity, bytes32[] calldata _merkleProof)
        public
        payable
        nonReentrant
    {
        uint256 supply = totalSupply();
        uint256 cost = PRICE * _quantity;
        require(mlSaleStart, "Before sale begin.");
        _mintCheck(_quantity, supply, cost, 3);

        require(checkMerkleProof(_merkleProof, 3), "Invalid Merkle Proof");

        claimed[msg.sender] += _quantity;
        _safeMint(msg.sender, _quantity);
    }

    function _mintCheck(
        uint256 _quantity,
        uint256 _supply,
        uint256 _cost,
        uint256 _alType
    ) private view {
        require(_supply + _quantity <= MAX_SUPPLY, "Max supply over");
        require(msg.value >= _cost, "Not enough funds");
        require(_alType < 5, "AL Type is incorrect.");
        require(_quantity <= mintLimit[_alType], "Mint quantity over");
        require(claimed[msg.sender] + _quantity <= mintLimit[_alType], "Already claimed max");
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

    function setMerkleRoot(bytes32 _merkleRoot, uint256 _alType) public onlyOwner {
        require(_alType < 4, "AL Type is incorrect.");
        merkleRoot[_alType] = _merkleRoot;
    }

    function setALsale(bool _state) public onlyOwner {
        alSaleStart = _state;
    }
    function setMLsale(bool _state) public onlyOwner {
        mlSaleStart = _state;
    }

    function setPubsale(bool _state) public onlyOwner {
        pubSaleStart = _state;
    }

    function setMintLimit(uint256 _quantity, uint256 _alType) public onlyOwner {
        require(_alType < 5, "AL Type is incorrect.");
        mintLimit[_alType] = _quantity;
    }

    function setMemberAddress(
        address _founder,
        address _illustrator,
        address _musician,
        address _developer
    ) public onlyOwner {
        _member.founder = _founder;
        _member.illustrator = _illustrator;
        _member.musician = _musician;
        _member.developer = _developer;
    }

    function withdraw() external onlyOwner {
        require(
            _member.founder != address(0) &&
            _member.illustrator != address(0) &&
            _member.musician != address(0) &&
            _member.developer != address(0),
            "Please set member address"
        );

        uint256 balance = address(this).balance;
        Address.sendValue(payable(_member.founder), ((balance * 3400) / 10000));
        Address.sendValue(payable(_member.illustrator), ((balance * 2300) / 10000));
        Address.sendValue(payable(_member.musician), ((balance * 2300) / 10000));
        Address.sendValue(payable(_member.developer), ((balance * 2000) / 10000));
    }

    // OperatorFilterer
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