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

contract DREAMING_MUSIC is
    ERC721Psi,
    ERC2981,
    Ownable,
    ReentrancyGuard,
    DefaultOperatorFilterer
{
    using Strings for uint256;

    uint256 public constant MAX_SUPPLY = 1000;
    uint256 public constant PRE_PRICE = 0.01 ether;
    uint256 public constant PUB_PRICE = 0.015 ether;

    bool private _revealed;
    string private _baseTokenURI;
    string private _unrevealedURI = "https://example.com";

    mapping(uint256 => uint256) public mintLimit; // 0: AL1, 1: AL2, 2: Public
    mapping(uint256 => bool) public saleStart; // 0: AL1, 1: AL2, 2: Public
    mapping(uint256 => bytes32) public merkleRoot; // 0: AL1, 1: AL2
    mapping(address => uint256) public claimed;
    mapping(uint256 => mapping(address => uint256)) public phaseClaimed;  // 0: AL1, 1: AL2, 2: Public
    mapping(uint256 => uint256) public orders; // Token ID => OrderNum
    mapping(uint256 => uint256) public orderCount; // Token ID => OrderCount

    struct ProjectMember {
        address founder;
        address developer;
    }
    ProjectMember private _member;

    constructor() ERC721Psi("Dreaming Music", "DM") {
        mintLimit[0] = 2;
        mintLimit[1] = 2;
        mintLimit[2] = 4;
        _member.founder = address(0x43486d604Ea92ac9049dd97e9fD8E6c72B51Afcf);
        _member.developer = address(0x48A23fb6f56F9c14D29FA47A4f45b3a03167dDAe);
        _setDefaultRoyalty(address(0x43486d604Ea92ac9049dd97e9fD8E6c72B51Afcf), 1000);
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
        if (_revealed) {
            return
                string(abi.encodePacked(ERC721Psi.tokenURI(_tokenId), ".json"));
        } else {
            return _unrevealedURI;
        }
    }

    function pubMint(uint256 _orderNum) public payable nonReentrant {
        uint256 supply = totalSupply();
        uint256 cost = PUB_PRICE;
        require(saleStart[2], "Before sale begin.");
        require(_orderNum > 60 && _orderNum <= MAX_SUPPLY, "Order range out.");
        _mintCheck(2, supply, cost);

        claimed[msg.sender] += 1;
        phaseClaimed[2][msg.sender] += 1;
        orders[supply + 1] = _orderNum;
        orderCount[_orderNum] += 1;
        _safeMint(msg.sender, 1);
    }

    function checkMerkleProof(uint256 _mintType, bytes32[] calldata _merkleProof)
        public
        view
        returns (bool)
    {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        return MerkleProof.verifyCalldata(_merkleProof, merkleRoot[_mintType], leaf);
    }

    function preMint(uint256 _mintType, bytes32[] calldata _merkleProof, uint256 _orderNum)
        public
        payable
        nonReentrant
    {
        uint256 supply = totalSupply();
        uint256 cost = PRE_PRICE * 1;
        require(saleStart[_mintType], "Before sale begin.");
        require(_orderNum > 60 && _orderNum <= MAX_SUPPLY, "Order range out.");
        _mintCheck(_mintType, supply, cost);

        require(checkMerkleProof(_mintType, _merkleProof), "Invalid Merkle Proof");

        claimed[msg.sender] += 1;
        phaseClaimed[_mintType][msg.sender] += 1;
        orders[supply + 1] = _orderNum;
        orderCount[_orderNum] += 1;
        _safeMint(msg.sender, 1);
    }

    function _mintCheck(
        uint256 _mintType,
        uint256 _supply,
        uint256 _cost
    ) private view {
        require(_supply + 1 <= MAX_SUPPLY, "Max supply over");
        require(msg.value >= _cost, "Not enough funds");
        require(
            phaseClaimed[_mintType][msg.sender] + 1 <= mintLimit[_mintType],
            "Already claimed max"
        );
    }

    function ownerMint(address _address, uint256 _quantity) public onlyOwner {
        uint256 supply = totalSupply();
        require(supply + _quantity <= MAX_SUPPLY, "Max supply over");
        _safeMint(_address, _quantity);
    }

    // only owner
    function setUnrevealedURI(string calldata _uri) public onlyOwner {
        _unrevealedURI = _uri;
    }

    function setBaseURI(string calldata _uri) external onlyOwner {
        _baseTokenURI = _uri;
    }

    function setMerkleRoot(uint256 _saleType, bytes32 _merkleRoot) public onlyOwner {
        merkleRoot[_saleType] = _merkleRoot;
    }

    function setSaleStart(uint256 _saleType, bool _state) public onlyOwner {
        saleStart[_saleType] = _state;
    }

    function setMintLimit(uint256 _saleType, uint256 _quantity) public onlyOwner {
        mintLimit[_saleType] = _quantity;
    }

    function reveal(bool _state) public onlyOwner {
        _revealed = _state;
    }


    // 報酬配分
    function setMemberAddress(
        address _founder,
        address _developer
    ) public onlyOwner {
        _member.founder = _founder;
        _member.developer = _developer;
    }

    function withdraw() external onlyOwner {
        require(
            _member.founder != address(0) && _member.developer != address(0),
            "Please set member address"
        );

        uint256 balance = address(this).balance;
        Address.sendValue(payable(_member.founder), ((balance * 8000) / 10000));
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