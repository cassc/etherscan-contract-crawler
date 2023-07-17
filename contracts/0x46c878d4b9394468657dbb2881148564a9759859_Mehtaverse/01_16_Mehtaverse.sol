// SPDX-License-Identifier: None
pragma solidity ^0.8.8;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import './ERC2981.sol';

struct SaleConfig {
  uint32 privateSaleStartTime;
  uint32 preSaleStartTime;
  uint32 publicSaleStartTime;
  uint16 privateSaleSupplyLimit;
  uint8 publicSaleTxLimit;
}

contract Mehtaverse is Ownable, ERC721, ERC2981 {
  using SafeMath for uint256;
  using SafeCast for uint256;
  using ECDSA for bytes32;

  uint256 public constant supplyLimit = 2222;
  uint256 public mintPrice = 0.22 ether;
  uint256 public totalSupply = 0;

  SaleConfig public saleConfig;

  address public whitelistSigner;

  string public baseURI;

  uint256 public PROVENANCE_HASH;
  uint256 public randomizedStartIndex;

  mapping(address => uint) private presaleMinted;

  address payable public withdrawalAddress;

  bytes32 private DOMAIN_SEPARATOR;
  bytes32 private PRIVATE_SALE_TYPEHASH = keccak256("privateSale(address buyer,uint256 limit)");
  bytes32 private PRESALE_TYPEHASH = keccak256("presale(address buyer,uint256 limit)");

  constructor(
    string memory inputBaseUri,
    address payable inputWithdrawalAddress,
    uint256 provenance
  ) ERC721("Mehtaverse", "MEH") {
    baseURI = inputBaseUri;
    withdrawalAddress = inputWithdrawalAddress;
    PROVENANCE_HASH = provenance;

    saleConfig = SaleConfig({
      privateSaleStartTime:   1635690120, //31 Oct 2021 22:22:00 UTC+0800
      preSaleStartTime:       1635776520, //1 Nov 2021 22:22:00 UTC+0800
      publicSaleStartTime:    1635862920, //2 Nov 2021 22:22:00 UTC+0800
      privateSaleSupplyLimit: 267,
      publicSaleTxLimit:      5
    });

    _setRoyalties(withdrawalAddress, 750); // 7.5% royalties

    uint256 chainId;
      assembly {
        chainId := chainid()
      }

    DOMAIN_SEPARATOR = keccak256(
      abi.encode(
        keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
        keccak256(bytes("Mehtaverse")),
        keccak256(bytes("1")),
        chainId,
        address(this))
    );
  }

  function _baseURI() internal view override returns (string memory) {
    return baseURI;
  }

  function setBaseURI(string memory newBaseUri) external onlyOwner {
    baseURI = newBaseUri;
  }

  function setProvenance(uint256 provenanceHash) external onlyOwner {
    require(randomizedStartIndex == 0, "Starting index already set");
    
    PROVENANCE_HASH = provenanceHash;
  }

  function setWithdrawalAddress(address payable newAddress) external onlyOwner {
    withdrawalAddress = newAddress;
  }

  function setMintPrice(uint newPrice) external onlyOwner {
    mintPrice = newPrice;
  }

  function setWhiteListSigner(address signer) external onlyOwner {
    whitelistSigner = signer;
  }
  
  function setRoyalties(address recipient, uint256 value) external onlyOwner {
    require(recipient != address(0), "zero address");
    _setRoyalties(recipient, value);
  }

  function configureSales(
    uint256 privateSaleStartTime,
    uint256 preSaleStartTime,
    uint256 publicSaleStartTime,
    uint256 privateSaleSupplyLimit,
    uint256 publicSaleTxLimit
  ) external onlyOwner {
    uint32 _privateSaleStartTime = privateSaleStartTime.toUint32();
    uint32 _preSaleStartTime = preSaleStartTime.toUint32();
    uint32 _publicSaleStartTime = publicSaleStartTime.toUint32();
    uint16 _privateSaleSupplyLimit = privateSaleSupplyLimit.toUint16();
    uint8 _publicSaleTxLimit = publicSaleTxLimit.toUint8();

    require(0 < _privateSaleStartTime, "Invalid time");
    require(_privateSaleStartTime < _preSaleStartTime, "Invalid time");
    require(_preSaleStartTime < _publicSaleStartTime, "Invalid time");

    saleConfig = SaleConfig({
      privateSaleStartTime: _privateSaleStartTime,
      preSaleStartTime: _preSaleStartTime,
      publicSaleStartTime: _publicSaleStartTime,
      privateSaleSupplyLimit: _privateSaleSupplyLimit,
      publicSaleTxLimit: _publicSaleTxLimit
    });
  }

  function buyPrivateSale(bytes memory signature, uint numberOfTokens, uint approvedLimit) external payable {
    SaleConfig memory _saleConfig = saleConfig;

    require(block.timestamp >= _saleConfig.privateSaleStartTime && block.timestamp < _saleConfig.preSaleStartTime, "Private sale not active");
    require(whitelistSigner != address(0), "White list signer not yet set");
    require(msg.value == mintPrice.mul(numberOfTokens), "Incorrect payment");
    require((presaleMinted[msg.sender] + numberOfTokens) <= approvedLimit, "Wallet limit exceeded");
    require((totalSupply + numberOfTokens) <= _saleConfig.privateSaleSupplyLimit, "Private sale limit exceeded");

    bytes32 digest = keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, keccak256(abi.encode(PRIVATE_SALE_TYPEHASH, msg.sender, approvedLimit))));
    address signer = digest.recover(signature);

    require(signer != address(0) && signer == whitelistSigner, "Invalid signature");

    presaleMinted[msg.sender] = presaleMinted[msg.sender] + numberOfTokens;
    mint(msg.sender, numberOfTokens);
  }

  function buyPresale(bytes memory signature, uint numberOfTokens, uint approvedLimit) external payable {
    require(block.timestamp >= saleConfig.preSaleStartTime && block.timestamp < saleConfig.publicSaleStartTime, "Presale is not active");
    require(whitelistSigner != address(0), "White list signer not yet set");
    require(msg.value == mintPrice.mul(numberOfTokens), "Incorrect payment");
    require((presaleMinted[msg.sender] + numberOfTokens) <= approvedLimit, "Wallet limit exceeded");
    
    bytes32 digest = keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, keccak256(abi.encode(PRESALE_TYPEHASH, msg.sender, approvedLimit))));

    address signer = digest.recover(signature);

    require(signer != address(0) && signer == whitelistSigner, "Invalid signature");

    presaleMinted[msg.sender] = presaleMinted[msg.sender] + numberOfTokens;
    mint(msg.sender, numberOfTokens);
  }

  function buy(uint numberOfTokens) external payable {
    SaleConfig memory _saleConfig = saleConfig;

    require(block.timestamp >= _saleConfig.publicSaleStartTime, "Sale is not active");
    require(msg.value == mintPrice.mul(numberOfTokens), "Incorrect payment");
    require(numberOfTokens <= _saleConfig.publicSaleTxLimit, "Transaction limit exceeded");

    mint(msg.sender, numberOfTokens);
  }

  function mint(address to, uint numberOfTokens) private {
    require(totalSupply.add(numberOfTokens) <= supplyLimit, "Not enough tokens left");

    uint256 newId = totalSupply;

    for(uint i = 0; i < numberOfTokens; i++) {
      newId += 1;
      _safeMint(to, newId);
    }

    totalSupply = newId;
  }

  function reserve(address to, uint256 numberOfTokens) external onlyOwner {
    mint(to, numberOfTokens);
  }

  function rollStartIndex() external onlyOwner {
    require(PROVENANCE_HASH != 0, 'Provenance hash not set');
    require(randomizedStartIndex == 0, 'Index already set');
    require(block.timestamp >= saleConfig.publicSaleStartTime, "Too early to roll start index");

    uint256 number = uint256(
      keccak256(abi.encodePacked(blockhash(block.number - 1), block.coinbase, block.difficulty))
    );

    randomizedStartIndex = number % supplyLimit + 1;
  }

  function withdraw() external onlyOwner {
    require(address(this).balance > 0, "No balance to withdraw");
    
    (bool success, ) = withdrawalAddress.call{value: address(this).balance}("");
    require(success, "Withdrawal failed");
  }

  /// @inheritdoc	ERC165
  function supportsInterface(bytes4 interfaceId)
    public
    view
    override(ERC721, ERC2981)
    returns (bool)
  {
    return super.supportsInterface(interfaceId);
  }
}