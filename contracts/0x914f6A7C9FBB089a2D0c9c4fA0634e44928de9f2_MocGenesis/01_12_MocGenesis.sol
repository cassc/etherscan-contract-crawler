// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

//import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "./utils/MerkleProofWrapper.sol";

/**
 * @title MocGenesis
 * MocGenesis - ERC721 contract for MOC collection.
 */
contract MocGenesis is ERC721AQueryable, Ownable, MerkleProofWrapper {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    string public baseTokenURI;

    uint256 private _whiteListMintCount = 0;
    uint256 private _mintCount = 0;
    uint256 private _reserveCount = 0;

    uint256 public immutable publicSalePrice = 0.02 ether;
    uint256 public immutable maxTotalSupply = 5000;
    uint256 public immutable maxWhiteListSupply = 500;
    
    uint256 public maxAdminReserve = 2000;
    uint256 public maxAddrSupply = 2;
    uint256 public maxAddrWhiteListSupply = 1;

    bool public canPublicMint = false;
    bool public canWhiteListMint = false;

    bytes32 public whiteListRoot;
    mapping(address => uint256) public addressMintedCount;
    mapping(address => uint256) public addrWhiteListMintCount;

    constructor() ERC721A("MOC Genesis", "MocGenesis") {}

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }


    function getWhiteListMintCount() public view returns (uint256) {
        return _whiteListMintCount;
    }


    function getWhiteListMintCount(address addr) public view returns (uint256) {
        return addrWhiteListMintCount[addr];
    }

    function getMintCount() public view returns (uint256) {
        return _mintCount;
    }

    function getMintCount(address addr) public view returns (uint256) {
        return addressMintedCount[addr];
    }

    function getReserveCount() public view returns (uint256) {
        return _reserveCount;
    }

    function getBalance() public view onlyOwner returns (uint256) {
        return address(this).balance;
    }

    function setBaseTokenURI(string memory _baseTokenURI) public onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    function setMaxAddrSupply(uint256 _maxAddrSupply) public onlyOwner {
        require(_maxAddrSupply>1, "amount error");
        maxAddrSupply = _maxAddrSupply;
    }

    function setMaxAddrWhiteListSupply(uint256 _maxAddrWhiteListSupply) public onlyOwner {
        require(_maxAddrWhiteListSupply>=1, "amount error");
        maxAddrWhiteListSupply = _maxAddrWhiteListSupply;
    }


    function setMaxReserve(uint256 _maxReserve) public onlyOwner {
        require(_maxReserve>1, "amount error");
        require(_maxReserve < maxTotalSupply, "amount error");
        maxAdminReserve = _maxReserve;
    }

    function setPublicMint(bool _canPublicMint) public onlyOwner {
        canPublicMint = _canPublicMint;
    }

    function setWhiteListMint(bool _canWhiteListMint) public onlyOwner {
        canWhiteListMint = _canWhiteListMint;
    }

    function whiteListMint(uint256 _amount,bytes32[] memory proof) public {
        require(canWhiteListMint, "white list mint is paused");
        require(_amount>=1, "mint amount error");
        require(_amount<=maxAddrWhiteListSupply, "mint amount exceed");
        require((maxAdminReserve + _whiteListMintCount + _mintCount + _amount) <= maxTotalSupply, "not enough tokens for buyer");
        require((totalSupply() + _amount) <= maxTotalSupply, "not enough tokens");

        require(( _whiteListMintCount + _amount) <= maxWhiteListSupply, "not enough tokens for white list buyer");
        require(addrWhiteListMintCount[msg.sender] + _amount <= maxAddrWhiteListSupply, "exceed max personal supply");
        require(msg.sender == tx.origin, "mint from contract not allowed");
        

        require(whiteListVerifySender(proof), "access denied");

        _whiteListMintCount += _amount;
        addrWhiteListMintCount[msg.sender] += _amount;
        _safeMint(msg.sender, _amount);
        
    }

    function mint(uint256 _amount) public payable {
        require(canPublicMint, "mint is paused");
        require(_amount>=1, "mint amount error");
        require(_amount<=maxAddrSupply, "mint amount exceed");
        require((maxAdminReserve + _whiteListMintCount + _mintCount + _amount) <= maxTotalSupply, "not enough tokens for buyer");
        require((totalSupply() + _amount) <= maxTotalSupply, "not enough tokens");
        require(addressMintedCount[msg.sender] + _amount <= maxAddrSupply, "exceed max personal supply");
        require(msg.sender == tx.origin, "mint from contract not allowed");
        
        uint256 price = publicSalePrice * _amount;
        require(msg.value >= price, "incorrect price");

        _mintCount += _amount;
        addressMintedCount[msg.sender] += _amount;
        _safeMint(msg.sender, _amount);
        
    }

    function adminMint(uint256 _amount,bytes32[] memory proof) public {
        require(_amount>=1, "amount error");
        require(_amount<=maxAdminReserve, "amount exceed");
        require((_reserveCount + _amount) <= maxAdminReserve, "not enough tokens for reserve");
        require((totalSupply() + _amount) <= maxTotalSupply, "not enough tokens");
        require(msg.sender == tx.origin, "mint from contract not allowed");

        require(merkleVerifySender(proof), "access denied");

        _reserveCount += _amount;
        _safeMint(msg.sender, _amount);
    }

    function adminMintTo(uint256 _amount, address _to) public onlyOwner {
        require(_amount>=1, "amount error");
        require(_amount<=maxAdminReserve, "amount exceed");
        require((_reserveCount + _amount) <= maxAdminReserve, "not enough tokens for reserve");
        require((totalSupply() + _amount) <= maxTotalSupply, "not enough tokens");

        _reserveCount += _amount;
        _safeMint(_to, _amount);
    }

    function withdraw() public {
        require(msg.sender == owner(), "access denied");
        address payable _owner = payable(owner());
        uint256 balance = address(this).balance;
        _owner.transfer(balance);
    }

    function whiteListSetRoot(bytes32 _newRoot) public onlyOwner {
        whiteListRoot = _newRoot;
    }

    function whiteListVerifySender(bytes32[] memory proof) public view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        return merkleVerify(proof, whiteListRoot, leaf);
    }
}