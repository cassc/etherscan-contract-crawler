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
    uint256 public constant PRE_PRICE = 0.02 ether;
    uint256 public constant PUB_PRICE = 0.03 ether;

    bool public preSaleStart;
    bool public pubSaleStart;

    uint256 public mintLimit = 1;

    bytes32 public merkleRoot;

    bool private _revealed;
    string private _baseTokenURI;
    string private _unrevealedURI = "https://d2tnrjjpld3h2t.cloudfront.net/rvltd/unrevealed/metadata.json";

    mapping(address => uint256) public claimed;
    mapping(uint256 => address) private _owner;
    mapping(uint256 => bool) private _isExclusive;

    struct ProjectMember {
        address founder;
        address illustrator;
        address developer;
        address marketer;
        address musician;
    }
    ProjectMember private _member;

    constructor() ERC721Psi("RVLTD", "RVLTD") {
        _setDefaultRoyalty(0x9EfA220e89Cbd7d9F282c656A0d2ce8B8E8c923E, 1000);
        _member.founder = 0x9EfA220e89Cbd7d9F282c656A0d2ce8B8E8c923E;
        _member.illustrator = 0x3168ad7BEED95C5F58356Ca3c9aA961E57b1b48C;
        _member.developer = 0x7Abb65089055fB2bf5b247c89E3C11F7dB861213;
        _member.marketer = 0xf2fd31926B3bc3fB47C108B31cC0829F20DeE4c0;
        _member.musician = 0x40a6a21B4a0e988D990E4edbfC7389061F76e6DF;

        merkleRoot = 0x1e3dbf585d4954318bee95b18eb00e063e3481dd66ee0164c5c64fc81ce98b36;
        _safeMint(0x0770562708D92E6B4DA6b2047A5cd91Faa1cDBC8, 1);
        _safeMint(0x3168ad7BEED95C5F58356Ca3c9aA961E57b1b48C, 1);
        _safeMint(0x7Abb65089055fB2bf5b247c89E3C11F7dB861213, 1);
        _safeMint(0xf2fd31926B3bc3fB47C108B31cC0829F20DeE4c0, 1);
        _safeMint(0x9EfA220e89Cbd7d9F282c656A0d2ce8B8E8c923E, 1);
        _safeMint(0x40a6a21B4a0e988D990E4edbfC7389061F76e6DF, 1);
        _safeMint(0x9EfA220e89Cbd7d9F282c656A0d2ce8B8E8c923E, 1);
        _safeMint(0xdAb7b3236a69A921BFAd61d469FAa7b1f4B24267, 1);
        _safeMint(0x42A662B820e0C3a860faD43f34D92cDb4769CF8B, 1);
        _safeMint(0x96a974a4f884baA5A70A77FFb3aD9f9271c5D4F8, 1);
        _safeMint(0x0383C0bDD89e915C1E2b4Ac3445a3158211056E9, 1);
        _safeMint(0x490B9E5ECAD355efcb63461878537186771C9C29, 1);
        _safeMint(0x971740Ed368934875f1890898D5FFC10EA99FA43, 1);
        _safeMint(0xFEAF597b1d8333E6b3D48DcF54CcE89170dF5A4C, 1);
        _safeMint(0x4f4d74826c910e4621C465f09bD4373C6cD3d5fC, 1);
        _safeMint(0x6dc3120ed771D18682d7e90D30311FA2A1069Bb8, 1);
        _safeMint(0xd0D87c75324436db5722Dc11C69Fbdc9F54c903a, 1);
        _safeMint(0x4187DD52368F48eb2E1DB7ad079aFae1A0992a2d, 1);
        _safeMint(0x9EfA220e89Cbd7d9F282c656A0d2ce8B8E8c923E, 124);
        _safeMint(0x9f1498F67FD2ce379786029c308C22A4a4794599, 1);
        _safeMint(0x37139352336D0A02E1dd5B8042483f61021793E8, 1);
        _safeMint(0x54bffb4aeE67E53b3951bb397c42B855e9d945ed, 1);
        _safeMint(0x512F1f1DF1C1A179fd508BA07a082a7D8869b265, 1);
        _safeMint(0x719949c994850c7F9029b4aC1517D7721556EC4e, 1);
        _safeMint(0x6C2bB8dB1512BDF6e4A43cfD8C3a1cdc7351D753, 1);
        _safeMint(0x63542371ef68e0F4cE544dD76039dfae76858c39, 1);
        _safeMint(0x9EfA220e89Cbd7d9F282c656A0d2ce8B8E8c923E, 1);
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
        uint256 cost = PUB_PRICE * _quantity;
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
        uint256 cost = PRE_PRICE * _quantity;
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
    function setUnrevealedURI(string calldata _uri) public onlyOwner {
        _unrevealedURI = _uri;
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

    function reveal(bool _state) public onlyOwner {
        _revealed = _state;
    }

    function checkLicenseType(uint256 _tokenId)
        external
        view
        returns (string memory)
    {
        require(_exists(_tokenId), "nonexistent token");

        return _isExclusive[_tokenId] ? "Exclusive" : "Non-Exclusive";
    }

    function setLicense(uint256 _tokenId, bool _state) external {
        address owner = ownerOf(_tokenId);
        require(owner == msg.sender, "only the owner can set license");

        _isExclusive[_tokenId] = _state;
    }

    function _beforeTokenTransfers(
        address _from,
        address _to,
        uint256 _startTokenId,
        uint256 _quantity
    ) internal override(ERC721Psi) {
        for (uint256 i = 0; i < _quantity; i++) {
            uint256 tokenId = _startTokenId + i;
            if (_isExclusive[tokenId]) {
                _isExclusive[tokenId] = false;
            }
        }

        super._beforeTokenTransfers(_from, _to, _startTokenId, _quantity);
    }

    function setMemberAddress(
        address _founder,
        address _illustrator,
        address _developer,
        address _marketer,
        address _musician
    ) public onlyOwner {
        _member.founder = _founder;
        _member.illustrator = _illustrator;
        _member.developer = _developer;
        _member.marketer = _marketer;
        _member.musician = _musician;
    }

    function withdraw() external onlyOwner {
        require(
            _member.founder != address(0) &&
                _member.illustrator != address(0) &&
                _member.developer != address(0) &&
                _member.marketer != address(0) &&
                _member.musician != address(0),
            "Please set member address"
        );

        uint256 balance = address(this).balance;
        Address.sendValue(payable(_member.founder), ((balance * 2500) / 10000));
        Address.sendValue(
            payable(_member.illustrator),
            ((balance * 3000) / 10000)
        );
        Address.sendValue(
            payable(_member.developer),
            ((balance * 2000) / 10000)
        );
        Address.sendValue(payable(_member.marketer), ((balance * 1000) / 10000));
        Address.sendValue(payable(_member.musician), ((balance * 1500) / 10000));
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