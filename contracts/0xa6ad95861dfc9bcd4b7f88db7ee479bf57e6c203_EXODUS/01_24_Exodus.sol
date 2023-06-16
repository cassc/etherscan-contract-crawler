//SPDX-License-Identifier: MIT

/*

oooooooooooo                             .o8                       
`888'     `8                            "888                       
 888         oooo    ooo  .ooooo.   .oooo888  oooo  oooo   .oooo.o 
 888oooo8     `88b..8P'  d88' `88b d88' `888  `888  `888  d88(  "8 
 888    "       Y888'    888   888 888   888   888   888  `"Y88b.  
 888       o  .o8"'88b   888   888 888   888   888   888  o.  )88b 
o888ooooood8 o88'   888o `Y8bod8P' `Y8bod88P"  `V88V"V8P' 8""888P' 

*/

pragma solidity ^0.8.13;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "./ERC721Psi.sol";
import "./operator-filter-registry/src/DefaultOperatorFilterer.sol";

contract EXODUS is ERC721Psi, ERC2981, Ownable, ReentrancyGuard, DefaultOperatorFilterer {
    using Strings for uint256;
    uint256 public maxSupply = 888;
    uint256 public vipPrice = 0.035 ether;
    uint256 public prePrice = 0.01 ether;
    uint256 public publicPrice = 0.012 ether;
    uint256 public dandyPrice = 0;
    bool public vipSaleStart = false;
    bool public preSaleStart = false;
    bool public pubSaleStart = false;
    bool public dandySaleStart = false;
    uint256 public vipMintLimit = 1;
    uint256 public vipMintQuantity = 4;
    uint256 public alMintLimit = 4;
    uint256 public publicMintLimit = 10;
    uint256 public dandyMintLimit;
    mapping(address => uint256) public vipClaimedCount;
    mapping(address => uint256) public vipClaimed;
    mapping(address => uint256) public alClaimed;
    mapping(address => uint256) public publicClaimed;
    mapping(address => uint256) public dandyClaimed;
    bytes32 public vipMerkleRoot = 0x72dccd22bce759f791815f55e802762cbd43b62f32ae43ea7b7ac4c0a816c059;
    bytes32 public merkleRoot = 0x65eb01599a027f354be4984ddf2283facbe1307d3ddc4aca4f6eb5ab5ed753fa;
    bytes32 public dandyMerkleRoot = 0xeb3e53e15dd1747e75e955c81efbb4068ab2658729444ea5a849b864286ba325;
    bool public revealed = false;
    string private _baseTokenURI;
    string private hiddenUri = "https://arweave.net/Ztn9VNOmj8iaRztb9ylCZpsoH5F6I45s6bAK0Mm3DgI/hidden.json";

    constructor() ERC721Psi("EXODUS", "EX") {
        _setDefaultRoyalty(0xE8E269CB62EA0E3345C46C29A2A7291F64CF6D62, 420);

        _member.member1 = 0x75462a1041ef175754317C2a03cf12A351e63BC6;
        _member.member2 = 0x68B4008b6b69CF0A93DA3b76B90C2F26F5530f07;
        _member.member3 = 0x258a35308406F9B1E67692378630AAA09Efd0A1F;
        _member.member4 = 0x8C712B8754b8DBe89E2E3D83f96fdD7494F620e0;
        _member.member5 = 0xe8afaD3Ae50bF9D83e0B9F016C4fCb6Edd0f7A0f;
        _member.member6 = 0x07cE3bb422a537693aFD130259E5D3bD0dAC7479;
        _member.member7 = 0xeDAcc663C23ba31398550E17b1ccF47cd9Da1888;
        _member.treasury = 0xE8E269CB62EA0E3345C46C29A2A7291F64CF6D62;
    }

    // URI
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
        if (revealed) {
            return
                string(abi.encodePacked(ERC721Psi.tokenURI(_tokenId), ".json"));
        } else {
            return hiddenUri;
        }
    }

    // vipSale
    function checkVipMerkleProof(bytes32[] calldata _merkleProof) public view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        return MerkleProof.verifyCalldata(_merkleProof, vipMerkleRoot, leaf);
    }

    function _vipMintCheck(uint256 _supply,uint256 _cost) private view {
        require(_supply + vipMintQuantity <= maxSupply, "Max supply over");
        require(msg.value >= _cost, "Not enough funds");
        require(vipClaimedCount[msg.sender] + 1 <= vipMintLimit, "Already claimed max");
    }

    function vipMint(bytes32[] calldata _vipMerkleProof) public payable nonReentrant {
        uint256 supply = totalSupply();
        uint256 cost = vipPrice;
        require(vipSaleStart, "Before sale begin.");
        _vipMintCheck(supply, cost);

        require(checkVipMerkleProof(_vipMerkleProof), "Invalid Merkle Proof");

        vipClaimedCount[msg.sender] += 1;
        vipClaimed[msg.sender] += vipMintQuantity;
        _safeMint(msg.sender, vipMintQuantity);
    }

    // preSale
    function checkMerkleProof(bytes32[] calldata _merkleProof) public view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        return MerkleProof.verifyCalldata(_merkleProof, merkleRoot, leaf);
    }

    function _preMintCheck(uint256 _quantity, uint256 _supply, uint256 _cost) private view {
        require(_supply + _quantity <= maxSupply, "Max supply over");
        require(msg.value >= _cost, "Not enough funds");
        require(alClaimed[msg.sender] + _quantity <= alMintLimit,"Already claimed max");
    }

    function preMint(uint256 _quantity, bytes32[] calldata _merkleProof) public payable nonReentrant {
        uint256 supply = totalSupply();
        uint256 cost = prePrice * _quantity;
        require(preSaleStart, "Before sale begin.");
        _preMintCheck(_quantity, supply, cost);

        require(checkMerkleProof(_merkleProof), "Invalid Merkle Proof");

        alClaimed[msg.sender] += _quantity;
        _safeMint(msg.sender, _quantity);
    }

    // publicSale
    function pubMint(uint256 _quantity) public payable nonReentrant {
        uint256 supply = totalSupply();
        uint256 cost = publicPrice * _quantity;
        require(pubSaleStart, "Before sale begin.");
        _publicMintCheck(_quantity, supply, cost);

        publicClaimed[msg.sender] += _quantity;
        _safeMint(msg.sender, _quantity);
    }

    function _publicMintCheck(uint256 _quantity, uint256 _supply, uint256 _cost) private view {
        require(_supply + _quantity <= maxSupply, "Max supply over");
        require(msg.value >= _cost, "Not enough funds");
        require(publicClaimed[msg.sender] + _quantity <= publicMintLimit,"Already claimed max");
    }

    // dandySale
    function checkDandyMerkleProof(bytes32[] calldata _merkleProof) public view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        return MerkleProof.verifyCalldata(_merkleProof, dandyMerkleRoot, leaf);
    }

    function _dandyMintCheck(uint256 _quantity,uint256 _supply,uint256 _cost) private view {
        require(_supply + _quantity <= maxSupply, "Max supply over");
        require(msg.value >= _cost, "Not enough funds");
        require(dandyClaimed[msg.sender] + _quantity <= dandyMintLimit, "Already claimed max");
    }
    
    function dandyMint(uint256 _quantity, bytes32[] calldata _dandyMerkleProof) public payable nonReentrant {
        uint256 supply = totalSupply();
        uint256 cost = dandyPrice * _quantity;
        require(dandySaleStart, "Before sale begin.");
        _dandyMintCheck(_quantity, supply, cost);

        require(checkDandyMerkleProof(_dandyMerkleProof), "Invalid Merkle Proof");

        dandyClaimed[msg.sender] += _quantity;
        _safeMint(msg.sender, _quantity);
    }

    // ownerMint
    function ownerMint(address _address, uint256 _quantity) public onlyOwner {
        uint256 supply = totalSupply();
        require(supply + _quantity <= maxSupply, "Max supply over");
        _safeMint(_address, _quantity);
    }

    // setURI
    function setBaseURI(string calldata _uri) public onlyOwner {
        _baseTokenURI = _uri;
    }

    function setHiddenBaseURI(string memory uri_) public onlyOwner {
        hiddenUri = uri_;
    }

    // setReveal
    function reveal(bool bool_) public onlyOwner {
        revealed = bool_;
    }

    // setMerkleRoot
    function setVipMerkleRoot(bytes32 _vipMerkleRoot) public onlyOwner {
        vipMerkleRoot = _vipMerkleRoot;
    }

    function setAlMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function setDandyMerkleRoot(bytes32 _dandyMerkleRoot) public onlyOwner {
        dandyMerkleRoot = _dandyMerkleRoot;
    }

    // setSaleStart
    function setVipSaleStart(bool _state) public onlyOwner {
        vipSaleStart = _state;
    }

    function setPreSaleStart(bool _state) public onlyOwner {
        preSaleStart = _state;
    }

    function setPublicSaleStart(bool _state) public onlyOwner {
        pubSaleStart = _state;
    }

    function setDandySaleStart(bool _state) public onlyOwner {
        dandySaleStart = _state;
    }

    // setLimit
    function setVipMintLimit(uint256 _count) public onlyOwner {
        vipMintLimit = _count;
    }

    function setAlMintLimit(uint256 _quantity) public onlyOwner {
        alMintLimit = _quantity;
    }

    function setPublicMintLimit(uint256 _quantity) public onlyOwner {
        publicMintLimit = _quantity;
    }

    function setDandyMintLimit(uint256 _quantity) public onlyOwner {
        dandyMintLimit = _quantity;
    }

    // setMaxSupply
    function setMaxSupply(uint256 _quantity) public onlyOwner {
        require(totalSupply() <= maxSupply, "Lower than _currentIndex.");
        maxSupply = _quantity;
    }

    // setPrice
    function setVipPrice(uint256 _price) public onlyOwner {
        vipPrice = _price;
    }

    function setPrePrice(uint256 _price) public onlyOwner {
        prePrice = _price;
    }

    function setPublicPrice(uint256 _price) public onlyOwner {
        publicPrice = _price;
    }

    function setDandyPrice(uint256 _price) public onlyOwner {
        dandyPrice = _price;
    }

    // withdraw
    struct ProjectMember {
        address member1;
        address member2;
        address member3;
        address member4;
        address member5;
        address member6;
        address member7;
        address treasury;
    }
    ProjectMember private _member;

    function setMemberAddress(
        address _member1,
        address _member2,
        address _member3,
        address _member4,
        address _member5,
        address _member6,
        address _member7,
        address _treasury
    ) public onlyOwner {
        _member.member1 = _member1;
        _member.member2 = _member2;
        _member.member3 = _member3;
        _member.member4 = _member4;
        _member.member5 = _member5;
        _member.member6 = _member6;
        _member.member7 = _member7;
        _member.treasury = _treasury;
    }

    function withdraw() external onlyOwner {
        require(
            _member.member1 != address(0) &&
            _member.member2 != address(0) &&
            _member.member3 != address(0) &&
            _member.member4 != address(0) &&
            _member.member5 != address(0) &&
            _member.member6 != address(0) &&
            _member.member7 != address(0) &&
            _member.treasury != address(0),
            "Please set member address"
        );

        uint256 balance = address(this).balance;
        Address.sendValue(payable(_member.member1), ((balance * 1000) / 10000));
        Address.sendValue(payable(_member.member2),((balance * 1000) / 10000));
        Address.sendValue(payable(_member.member3), ((balance * 1000) / 10000));
        Address.sendValue(payable(_member.member4), ((balance * 1000) / 10000));
        Address.sendValue(payable(_member.member5),((balance * 1000) / 10000));
        Address.sendValue(payable(_member.member6),((balance * 1000) / 10000));
        Address.sendValue(payable(_member.member7),((balance * 1000) / 10000));
        Address.sendValue(payable(_member.treasury),((balance * 3000) / 10000));
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
    
    // walletOfOwner
    function _startTokenId() internal view virtual returns (uint256) {
        return 1;
    }

    function walletOfOwner(address _address) external view virtual returns (uint256[] memory) {
        uint256 ownerTokenCount = balanceOf(_address);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        uint256 tokenindex = 0;
        for (uint256 i = _startTokenId(); i < _minted; i++) {
            if(_address == this.tryOwnerOf(i)) tokenIds[tokenindex++] = i;
        }
        return tokenIds;
    }

    function tryOwnerOf(uint256 tokenId) external view  virtual returns (address) {
        try this.ownerOf(tokenId) returns (address _address) {
            return(_address);
        } catch {
            return (address(0));//return 0x0 if error.
        }
    }
}