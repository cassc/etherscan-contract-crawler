// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "erc721a/contracts/ERC721A.sol";

contract ERC721AContract is ERC721A, ReentrancyGuard, Ownable {

    struct InitialParameters {
        uint256 launchpassId;
        string name;
        string symbol;
        string uri;
        uint24 maxSupply;
        uint24 maxPerWallet;
        uint24 maxPerTransaction;
        uint72 preSalePrice;
        uint72 pubSalePrice;
        address payable multisigAddress;
    }

    mapping(address => uint) public hasMinted;
    address payable public multisigAddress;
    address payable public wentMintAddress;
    uint8 public wenmintShare;
    bytes32 public merkleRoot;
    uint24 public maxSupply;
    uint24 public maxPerWallet;
    uint24 public maxPerTransaction;
    uint72 public preSalePrice;
    uint72 public pubSalePrice;
    bool public preSaleIsActive = false;
    bool public saleIsActive = false;
    bool public supplyLock = false;
    uint256 public launchpassId;
    string private _baseTokenURI;

    modifier onlyMultisig() {
        require(msg.sender == multisigAddress, "Only multisig wallet can perfrom this action");
        _;
    }

    constructor(
        address payable _wentMintAddress,
        uint8 _wenmintShare,
        address _owner,
        InitialParameters memory initialParameters
    ) ERC721A(initialParameters.name, initialParameters.symbol) {
        launchpassId = initialParameters.launchpassId;
        _baseTokenURI = initialParameters.uri;
        maxSupply = initialParameters.maxSupply;
        maxPerWallet = initialParameters.maxPerWallet;
        maxPerTransaction = initialParameters.maxPerTransaction;
        preSalePrice = initialParameters.preSalePrice;
        pubSalePrice = initialParameters.pubSalePrice;
        multisigAddress = initialParameters.multisigAddress;
        wenmintShare = _wenmintShare;
        wentMintAddress = _wentMintAddress;
        transferOwnership(_owner);
    }

    function setMaxSupply(uint24 _supply) public onlyOwner {
        require(!supplyLock, "Supply is locked.");
        maxSupply = _supply;
    }

    function lockSupply() public onlyOwner {
        supplyLock = true;
    }

    function setPreSalePrice(uint72 _price) public onlyOwner {
        preSalePrice = _price;
    }

    function setPublicSalePrice(uint72 _price) public onlyOwner {
        pubSalePrice = _price;
    }

    function setMaxPerWallet(uint24 _quantity) public onlyOwner {
        maxPerWallet = _quantity;
    }

    function setMaxPerTransaction(uint24 _quantity) public onlyOwner {
        maxPerTransaction = _quantity;
    }

    function setBaseTokenURI(string memory _uri) public onlyOwner {
        _baseTokenURI = _uri;
    }

    function setRoot(bytes32 _root) public onlyOwner {
        merkleRoot = _root;
    }

    function setPubSaleState(bool _isActive) public onlyOwner {
        saleIsActive = _isActive;
    }

    function setPreSaleState(bool _isActive) public onlyOwner {
        require(merkleRoot != "", "Merkle root is undefined.");
        preSaleIsActive = _isActive;
    }

    function baseTokenURI() virtual public view returns (string memory) {
        return _baseTokenURI;
    }

    function tokenURI(uint256 _tokenId) override public view returns (string memory) {
        return string(abi.encodePacked(baseTokenURI(), Strings.toString(_tokenId)));
    }

    function verify(bytes32 leaf, bytes32[] memory proof) public view returns (bool) {
        bytes32 computedHash = leaf;
        for (uint i = 0; i < proof.length; i++) {
          bytes32 proofElement = proof[i];
          if (computedHash <= proofElement) {
            computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
          } else {
            computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
          }
        }
        return computedHash == merkleRoot;
    }

    function mint(uint _quantity, bytes32[] memory proof) public payable {
        uint _maxSupply = maxSupply;
        uint _maxPerWallet = maxPerWallet;
        uint _maxPerTransaction = maxPerTransaction;
        uint _preSalePrice = preSalePrice;
        uint _pubSalePrice = pubSalePrice;
        bool _saleIsActive = saleIsActive;
        bool _preSaleIsActive = preSaleIsActive;
        uint _currentSupply = totalSupply();
        require(_saleIsActive, "Sale is not active.");
        require(_currentSupply <= _maxSupply, "Sold out.");
        require(_currentSupply + _quantity <= _maxSupply, "Requested quantity would exceed total supply.");
        if(_preSaleIsActive) {
            require(_preSalePrice * _quantity <= msg.value, "ETH sent is incorrect.");
            require(_quantity <= _maxPerWallet, "Exceeds wallet presale limit.");
            uint mintedAmount = hasMinted[msg.sender] + _quantity;
            require(mintedAmount <= _maxPerWallet, "Exceeds per wallet presale limit.");
            hasMinted[msg.sender] = mintedAmount;
            bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
            require(verify(leaf, proof), "You are not whitelisted.");
        } else {
            require(_pubSalePrice * _quantity <= msg.value, "ETH sent is incorrect.");
            require(_quantity <= _maxPerTransaction, "Exceeds per transaction limit for public sale.");
        }
        _safeMint(msg.sender, _quantity);
    }

    function setMultiSig(address payable _address) public onlyMultisig {
        multisigAddress = _address;
    }

    function reserve(address _address, uint _quantity) public onlyMultisig {
        _safeMint(_address, _quantity);
    }

    function withdraw() external nonReentrant onlyMultisig {
        uint balance = address(this).balance;
        uint wenMintAmount = balance * wenmintShare / 100;
        (bool sentWenMint, ) = wentMintAddress.call{ value: wenMintAmount }("");
        require(sentWenMint, "Failed to send ETH to WenMint.");
        uint multiSigAmount = balance - wenMintAmount;
        (bool sentMultiSig, ) = multisigAddress.call{ value: multiSigAmount }("");
        require(sentMultiSig, "Failed to send ETH to Gnosis Safe.");
    }
}