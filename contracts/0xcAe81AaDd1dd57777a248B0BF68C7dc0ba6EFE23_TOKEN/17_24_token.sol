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

    uint256 public constant MAX_SUPPLY = 2140;
    uint256 public pubMintMax = 15;

    uint256 public constant PRICE_AL1 = 0.012 ether;
    uint256 public constant PRICE_AL2 = 0.015 ether;
    uint256 public constant PRICE_AL3 = 0.015 ether;
    uint256 public constant PRICE_PUB = 0.02 ether;

    mapping (uint256 => bool) public saleStart; // 0: AL0, 1: AL1, 2: AL2, 3: AL3, 4: Public
    mapping (uint256 => bytes32) public merkleRoot; // 0: AL0, 1: AL1, 2: AL2, 3: AL3

    bool private _revealed;
    string private _baseTokenURI;
    string private _unrevealedURI = "https://daqa1e0ox6foy.cloudfront.net/unrevealed/metadata.json";

    mapping(address => uint256) public claimed; // totalClaimed
    mapping(uint256 => mapping(address => uint256)) public claimedForSale; // saleType => (address => claimed)

    struct ProjectMember {
        address founder;
        address developer;
        address marketer;
        address cs;
        address adviser;
    }
    ProjectMember private _member;

    constructor() ERC721Psi("NARAKU", "NARAKUI") {
        _setDefaultRoyalty(address(0xa0FFB04C24AdA30262c99dDA13C36d8871B80cB0), 1000);
        _member.founder = address(0xa0FFB04C24AdA30262c99dDA13C36d8871B80cB0);
        _member.developer = address(0x7Abb65089055fB2bf5b247c89E3C11F7dB861213);
        _member.marketer = address(0x74ed19acF50Df68E966041A9E5A83032A90aaf81);
        _member.cs = address(0x403cFce4766eC01639a724576D94f502166fdD9A);
        _member.adviser = address(0x2064f95A4537a7e9ce364384F55A2F4bBA3F0346);
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

    function pubMint(uint256 _quantity) public payable nonReentrant {
        uint256 supply = totalSupply();
        uint256 cost = PRICE_PUB * _quantity;
        require(saleStart[4], "Before sale begin.");
        _mintCheck(4, _quantity, supply, cost, pubMintMax);

        claimed[msg.sender] += _quantity;
        claimedForSale[4][msg.sender] += _quantity;
        _safeMint(msg.sender, _quantity);
    }

    function verifyAddressAndAmount(
        address _address,
        uint256 _amount,
        uint256 _mintType,
        bytes32[] calldata _merkleProof
    ) public view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(_address, _amount));
        return MerkleProof.verifyCalldata(_merkleProof, merkleRoot[_mintType], leaf);
    }

    function preMint(uint256 _mintType, uint256 _quantity, bytes32[] calldata _merkleProof, uint256 _mintLimit)
        public
        payable
        nonReentrant
    {
        uint256 supply = totalSupply();
        uint256 cost = 0;
        if (_mintType == 1) {
            cost = PRICE_AL1 * _quantity;
        } else if (_mintType == 2) {
            cost = PRICE_AL2 * _quantity;
        } else if (_mintType == 3) {
            cost = PRICE_AL3 * _quantity;
        }
        require(saleStart[_mintType], "Before sale begin.");
        require(verifyAddressAndAmount(msg.sender, _mintLimit, _mintType, _merkleProof), "Invalid Merkle Proof");
        _mintCheck(_mintType, _quantity, supply, cost, _mintLimit);

        claimed[msg.sender] += _quantity;
        claimedForSale[_mintType][msg.sender] += _quantity;
        _safeMint(msg.sender, _quantity);
    }

    function _mintCheck(
        uint256 _mintType,
        uint256 _quantity,
        uint256 _supply,
        uint256 _cost,
        uint256 _mintLimit
    ) private view {
        require(_supply + _quantity <= MAX_SUPPLY, "Max supply over");
        require(msg.value == _cost, "Not enough funds");
        require(
            claimedForSale[_mintType][msg.sender] + _quantity <= _mintLimit,
            "Mint quantity over"
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

    function setMerkleRoot(uint256 _mintType, bytes32 _merkleRoot) public onlyOwner {
        merkleRoot[_mintType] = _merkleRoot;
    }

    function setSaleStart(uint256 _mintType, bool _state) public onlyOwner {
        saleStart[_mintType] = _state;
    }

    function reveal(bool _state) public onlyOwner {
        _revealed = _state;
    }


    // 報酬配分
    function setMemberAddress(
        address _founder,
        address _developer,
        address _marketer,
        address _cs,
        address _adviser
    ) public onlyOwner {
        _member.founder = _founder;
        _member.developer = _developer;
        _member.marketer = _marketer;
        _member.cs = _cs;
        _member.adviser = _adviser;
    }

    function withdraw() external onlyOwner {
        require(
            _member.founder != address(0) &&
            _member.developer != address(0) &&
            _member.marketer != address(0) &&
            _member.cs != address(0) &&
            _member.adviser != address(0),
            "Please set member address"
        );

        uint256 balance = address(this).balance;
        Address.sendValue(payable(_member.founder), ((balance * 705000) / 1000000));
        Address.sendValue(payable(_member.developer), ((balance * 95000) / 1000000));
        Address.sendValue(payable(_member.marketer), ((balance * 35000) / 1000000));
        Address.sendValue(payable(_member.cs), ((balance * 70000) / 1000000));
        Address.sendValue(payable(_member.adviser), ((balance * 95000) / 1000000));
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