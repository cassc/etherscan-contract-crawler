// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./DefaultOperatorFilterer.sol";


contract LCRC is ERC721A, ReentrancyGuard, Ownable, DefaultOperatorFilterer {
    constructor(string memory _customBaseURI)
	ERC721A( "Lucky Charm Rabbit Cards", "LCRC" ){ customBaseURI = _customBaseURI; }


    mapping(address => uint256) public mintedAmount;
    mapping(address => uint256) public mintedFree;
    mapping(address => mapping(uint256 => uint256)) public mintedClasses;
    mapping(uint256 => uint256) public tokenClass;
    mapping(uint256 => uint256) public classCounter;
    uint256 classMIN = 0;
    uint256 classMAX = 3;
    uint256[] public priceByClassWL = [ 2800000000000000, 8800000000000000, 80000000000000000, 8800000000000000000 ];
    uint256[] public priceByClass   = [ 2800000000000000, 8800000000000000, 80000000000000000, 8800000000000000000 ];


    enum mintTypes{ Closed, WL, OG, Public, Free }
    mintTypes public mintType;
    function setMintType(mintTypes _mintType) external onlyOwner {
        mintType = _mintType;
    }
    function getMintType() public view returns (mintTypes) {
        return mintType;
    }


    uint256 public MAX_SUPPLY = 8888;
    function setMAX_SUPPLY(uint256 _count) external onlyOwner {
        MAX_SUPPLY = _count;
    }
    uint256 public WL_SUPPLY = 1000;
    function setCONFIG(uint256 _count) external onlyOwner {
        WL_SUPPLY = _count;
    }


    uint[] public limitByClass   = [ MAX_SUPPLY, 888, 88, 1 ];


    uint256 public MAX_MULTIMINT = 8;
    function setMAX_MULTIMINT(uint256 _count) external onlyOwner {
        MAX_MULTIMINT = _count;
    }

    uint256 public LIMIT_PER_WALLET = 8;
    function setLIMIT_PER_WALLET(uint256 _count) external onlyOwner {
        LIMIT_PER_WALLET = _count;
    }

    function setPRICE_WL(uint256 _price, uint256 _class) external onlyOwner {
        require( _class >= classMIN, "Wrong class" );
        require( _class <= classMAX, "Wrong class" );
        priceByClassWL[_class] = _price;
    }
    function setPRICE(uint256 _price, uint256 _class) external onlyOwner {
        require( _class >= classMIN, "Wrong class" );
        require( _class <= classMAX, "Wrong class" );
        priceByClass[_class] = _price;
    }


    bytes32 public merkleRoot;
    function setRoot(bytes32 _root) external onlyOwner {
        merkleRoot = _root;
    }
    function isValid(bytes32[] memory proof) public view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        return MerkleProof.verify(proof, merkleRoot, leaf);
    }


    function addItems( address _to, uint256 _count, uint256 _last, uint256 _class ) internal {
        uint256 _a = mintedClasses[_to][_class];
        mintedClasses[_to][_class] = _a + _count;
        uint256 _b = classCounter[_class];
        classCounter[_class] = _b + _count;
        for (uint256 i = ( _last - _count ); i < _last; i++) {
            tokenClass[i] = _class;
        }
    }


    function freeMintWL(bytes32[] memory _proof) public nonReentrant {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_proof, merkleRoot, leaf), "Invalid proof!");

        require( mintType == mintTypes.WL, "WL Sale not active" );
        require( totalSupply() + 1 <= WL_SUPPLY, "Exceeds WL max supply" );
        require( totalSupply() + 1 <= MAX_SUPPLY, "Exceeds max supply" );
        uint256 _class = 0;
        uint256 _count = 1;
        uint256 _classCount = classCounter[_class];
        require( _classCount + _count <= limitByClass[_class], "Exceeds max class supply" );
        uint256 _mintedAmount = mintedAmount[msg.sender];
        require( _mintedAmount + _count <= LIMIT_PER_WALLET, "Exceeds max mints per wallet" );
        uint256 _freeAmount = mintedFree[msg.sender];
        require( _freeAmount == 0, "Exceeds max claim free per wallet" );

        _mint(msg.sender, _count);
        mintedFree[msg.sender] = 1;

        mintedAmount[msg.sender] = _mintedAmount + 1;
        addItems( msg.sender, _count, totalSupply(), _class );
    }


    function freeMint() public nonReentrant {
        require( mintType == mintTypes.Public, "Sale not active" );
        require( totalSupply() + 1 <= MAX_SUPPLY, "Exceeds max supply" );
        uint256 _class = 0;
        uint256 _count = 1;
        uint256 _classCount = classCounter[_class];
        require( _classCount + _count <= limitByClass[_class], "Exceeds max class supply" );
        uint256 _mintedAmount = mintedAmount[msg.sender];
        require( _mintedAmount + _count <= LIMIT_PER_WALLET, "Exceeds max mints per wallet" );
        uint256 _freeAmount = mintedFree[msg.sender];
        require( _freeAmount == 0, "Exceeds max claim free per wallet" );

        _mint(msg.sender, _count);
        mintedFree[msg.sender] = 1;

        mintedAmount[msg.sender] = _mintedAmount + 1;
        addItems( msg.sender, _count, totalSupply(), _class );
    }


    function mintWL(uint256 _count, uint256 _class, bytes32[] memory _proof) public payable nonReentrant {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_proof, merkleRoot, leaf), "Invalid proof!");

        require( mintType == mintTypes.WL, "WL Sale not active" );
        require( _count > 0, "0 tokens to mint" );
        require( _class >= classMIN, "Wrong class" );
        require( _class <= classMAX, "Wrong class" );
        require( totalSupply() + _count <= WL_SUPPLY, "Exceeds WL max supply" );
        require( totalSupply() + _count <= MAX_SUPPLY, "Exceeds max supply" );
        uint256 _classCount = classCounter[_class];
        require( _classCount + 1 <= limitByClass[_class], "Exceeds max class supply" );
        require( _count <= MAX_MULTIMINT, "Exceeds max mints per transaction" );
        require( msg.value >= priceByClassWL[_class] * _count, "Insufficient payment"  );
        uint256 _mintedAmount = mintedAmount[msg.sender];
        require( _mintedAmount + _count <= LIMIT_PER_WALLET, "Exceeds max mints per wallet" );

        _mint(msg.sender, _count);

        mintedAmount[msg.sender] = _mintedAmount + _count;
        addItems( msg.sender, _count, totalSupply(), _class );
    }


    function mint(uint256 _count, uint256 _class) public payable nonReentrant {
        require( mintType == mintTypes.Public, "Sale not active" );
        require( _count > 0, "0 tokens to mint" );
        require( _class >= classMIN, "Wrong class" );
        require( _class <= classMAX, "Wrong class" );
        require( totalSupply() + _count <= MAX_SUPPLY, "Exceeds max supply" );
        uint256 _classCount = classCounter[_class];
        require( _classCount + 1 <= limitByClass[_class], "Exceeds max class supply" );
        require( _count <= MAX_MULTIMINT, "Exceeds max mints per transaction" );
        require( msg.value >= priceByClass[_class] * _count, "Insufficient payment"  );
        uint256 _mintedAmount = mintedAmount[msg.sender];
        require( _mintedAmount + _count <= LIMIT_PER_WALLET, "Exceeds max mints per wallet" );

        _mint(msg.sender, _count);

        mintedAmount[msg.sender] = _mintedAmount + _count;
        addItems( msg.sender, _count, totalSupply(), _class );
    }


    function mintOne(address _to, uint256 _count, uint256 _class) external onlyOwner {
        require( _count > 0, "0 tokens to mint" );
        require( _class >= classMIN, "Wrong class" );
        require( _class <= classMAX, "Wrong class" );
        require( totalSupply() + _count <= MAX_SUPPLY, "Exceeds max supply" );
        uint256 _classCount = classCounter[_class];
        require( _classCount + _count <= limitByClass[_class], "Exceeds max class supply" );
        uint256 _mintedAmount = mintedAmount[_to];

        _mint(msg.sender, _count);

        mintedAmount[_to] = _mintedAmount + _count;
        addItems( _to, _count, totalSupply(), _class );
    }


    string private customBaseURI;
    function setBaseURI(string memory _URI) external onlyOwner {
        customBaseURI = _URI;
    }
    function _baseURI() internal view virtual override returns (string memory) {
        return customBaseURI;
    }


    function getTokenClass( uint256 _id ) public view returns (uint) {
        if( _id < totalSupply() ){
            return tokenClass[_id];
        }else{
            return 666;
        }
    }


    string public _metadataURI = "";
    function setMetadataURI(string memory _URI) external onlyOwner {
        _metadataURI = _URI;
    }


    function _withdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Transfer failed.");
    }
    function withdraw() public nonReentrant onlyOwner {
        uint256 balance = address(this).balance;
        Address.sendValue(payable(owner()), balance);
    }


    modifier isHuman() {
        address _addr = msg.sender;
        uint256 _codeLength;
        assembly {_codeLength := extcodesize(_addr)}
        require(_codeLength == 0, "sorry humans only");
        _;
    }


    function transferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }
    function safeTransferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}