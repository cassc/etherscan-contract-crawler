// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./ERC721Tradable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract Toy is ERC721Tradable {
    bytes32 public merkleRoot = 0x2c2d8d0de629d0b09aea5dda700e03a490364e8c98d8d87695cea1b41dd8d814;
    bool public salePublicIsActive;
    bool public saleWhitelistIsActive = true;
    uint256 public maxByMint = 1;
    uint256 public maxSupply = 576;
    uint256 public maxPublicSupply = 566;
    uint256 public maxReservedSupply = 10;
    uint256 public fixedPrice = 0.09 ether;
    address public daoAddress = 0x8A09928a0623155F0554F42427e27b8EE88411fB;
    string internal baseTokenURI = "https://toys.0xtechno.art/api/toys/meta-v1/";
    
    using Counters for Counters.Counter;
    Counters.Counter private _totalPublicSupply;
    Counters.Counter private _totalReservedSupply;

    mapping(uint256 => string) public generativeArtScript;
    mapping(uint256 => bytes32) public tokenIdToHash;
    mapping(bytes32 => uint256) public hashToTokenId;

    mapping(uint256 => bytes32) public reservedHashes;
    mapping(address => bool) internal whitelistClaimed;
    
    constructor(
        string memory _name,
        string memory _symbol,
        address _proxyRegistryAddress
    ) ERC721Tradable(_name, _symbol, _proxyRegistryAddress) {
        /* Genesis Mint */
        reservedHashes[1] = 0x7b9e21444ee73cfd3d25cf62e4ca68550a17aab016b226cdb932541985f880f2;
        reservedHashes[2] = 0xeed1273ba39c57f40c5c07d87467b56eb64f5fa95b2c73a8bc922814e90b9f4f;
        reservedHashes[3] = 0x480b72ddca5cde3320258758f80f8dfd7ab944081952c2b74849b29627954eeb;
        reservedHashes[4] = 0xa68846590d66797ee4c3e68f41ffbda5544d52f40577eee13b73ce3bf58b6d47;
        reservedHashes[5] = 0x5b24363b957b314383046e544950a72bca4fbb5e6198390692f20b601e1f3509;
        reservedHashes[6] = 0x2fe24637ce210f1e30576f07b5e496b4783f2f44ea2a1f106a210ea07a087ad8;
        reservedHashes[7] = 0x53069495c19b713865d6e6050a5e49b7d68710a455d47bb59637188651e35b01;
        reservedHashes[8] = 0xec614b914d6d9773bd358cdcebce20e2ada5a0d6ddf13e5c61b2de823ee3a0d7;
        reservedHashes[9] = 0xde971ca1432adc37756ad9a1e08aaef3efe1a996bfe86765b52795c10865c771;
        reservedHashes[10] = 0x10b1d3dd751b818b2ed7b4d5af413466acf933645e9e94f28c81d2d90dfb64c4;
        for(uint256 i=1; i<=10; i++) {
            _totalReservedSupply.increment();
            tokenIdToHash[i]=reservedHashes[i];
            hashToTokenId[reservedHashes[i]]=i;
            _safeMint(daoAddress, i);
        }
    }

    function contractURI() public pure returns (string memory) {
        return "https://toys.0xtechno.art/api/toys/contract/1";
    }

    function _mintN(uint numberOfTokens) private {
        require(numberOfTokens <= maxByMint, "Max mint exceeded");
        require(_totalPublicSupply.current() + numberOfTokens <= maxPublicSupply, "Max supply reached");
        for(uint i = 0; i < numberOfTokens; i++) {
            _totalPublicSupply.increment();
            uint256 tokenIdToBe = this.totalSupply();
            _setHash(tokenIdToBe);
            _safeMint(msg.sender, this.totalSupply());
        }
    }

    function mintPublic(uint numberOfTokens) external payable {
        require(salePublicIsActive, "Sale not active");
        uint256 totalPrice = fixedPrice * numberOfTokens; 
        require(totalPrice <= msg.value, "Not enough ETH");
        _mintN(numberOfTokens);
    }

    function mintWhitelist(uint numberOfTokens, bytes32[] calldata _merkleProof) external payable {
        require(saleWhitelistIsActive, "Whitelist sale not active");
        require(!whitelistClaimed[msg.sender], "Address has already claimed");
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), "Must be whitelisted");
        require(fixedPrice * numberOfTokens <= msg.value, "Eth val incorrect");
        whitelistClaimed[msg.sender] = true;
        _mintN(numberOfTokens);
    }

    function tokenURI(uint256 _tokenId) override public view returns (string memory) {
        return string(abi.encodePacked(baseTokenURI, Strings.toString(_tokenId)));
    }

    function totalSupply() public view returns (uint256) {
        return _totalPublicSupply.current() + _totalReservedSupply.current();
    }

    function totalPublicSupply() public view returns (uint256) {
        return _totalPublicSupply.current();
    }

    function totalReservedSupply() public view returns (uint256) {
        return _totalReservedSupply.current();
    }

    function flipSalePublicStatus() external onlyOwner {
        salePublicIsActive = !salePublicIsActive;
    }

    function flipSaleWhitelistStatus() external onlyOwner {
        saleWhitelistIsActive = !saleWhitelistIsActive;
    }

    function setDaoAddress(address _daoAddress) external onlyOwner {
        daoAddress = _daoAddress;
    }

    function setBaseTokenURI(string memory _baseTokenURI) external onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    function setFixedPrice(uint256 _fixedPrice) external onlyOwner {
        fixedPrice = _fixedPrice;
    }

    function setMaxByMint(uint256 _maxByMint) external onlyOwner {
        maxByMint = _maxByMint;
    }

    function withdraw() external onlyOwner {
        uint balance = address(this).balance;
        require(balance > 0);
        _withdraw(daoAddress, balance);
    }

    function _withdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Tx failed");
    }

    function updateScript(uint256[] memory _indexes, string[] memory _scripts)
        external
        onlyOwner
    {
        require(
            _indexes.length == _scripts.length,
            "Array lengths are different"
        );
        for (uint256 i = 0; i < _scripts.length; i++) {
            generativeArtScript[_indexes[i]] = _scripts[i];
        }
    }

    function _generateRandomHash(uint random) private view returns (bytes32) {
        return keccak256(abi.encodePacked(block.number, blockhash(block.number - 1), msg.sender, random));
    }

    function _setHash(uint256 tokenIdToBe) private {
        bytes32 hash;
        hash = _generateRandomHash(tokenIdToBe);
        tokenIdToHash[tokenIdToBe]=hash;
        hashToTokenId[hash]=tokenIdToBe;
    }

    function setCuratedHash(uint256 tokenId, bytes32 _hash) external onlyOwner {
        tokenIdToHash[tokenId]=_hash;
        hashToTokenId[_hash]=tokenId;
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner { 
        merkleRoot = _merkleRoot;
    }

    function isWhitelistClaimed(address _address) public view returns (bool) {
        return whitelistClaimed[_address];
    }

}