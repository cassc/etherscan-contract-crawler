// SPDX-License-Identifier: None
pragma solidity ^0.8.8;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "./Treasury.sol";
import "./ERC2981.sol";

struct SaleConfig {
  uint32 preSaleStartTime;
  uint32 publicSaleStartTime;
  uint32 txLimit;
  uint32 supplyLimit;
}

contract JuiceboxFrens is Ownable, ERC721, ERC2981, Treasury {
  using SafeCast for uint256;
  using ECDSA for bytes32;

  uint256 public constant mintPrice = 0.024 ether;

  uint256 public totalSupply = 0;

  SaleConfig public saleConfig;
  string public baseURI;
  address public whitelistSigner;

  mapping(address => uint256) private presaleMinted;

  address payable public withdrawalAddress;

  bytes32 private DOMAIN_SEPARATOR;
  bytes32 private TYPEHASH = keccak256("presale(address buyer,uint256 limit)");

  address[] private mintPayees = [
    0xD32E3382Aa09323a08C226c6662E12B434c701B3,
    0x3A6E953A119bA4665877EA1A095855405AAb360D
  ];

  uint256[] private mintShares = [98, 2];

  constructor(string memory inputBaseUri)
    ERC721("Juicebox Frens", "JBF")
    Treasury(mintPayees, mintShares)
  {
    baseURI = inputBaseUri;

    saleConfig = SaleConfig({
      preSaleStartTime: 1647645600, // Fri Mar 18 2022 23:20:00 GMT+0000
      publicSaleStartTime: 1647818400, // Sun Mar 20 2022 23:20:00 GMT+0000
      txLimit: 3,
      supplyLimit: 6969
    });

    _setRoyalties(address(this), 500); // 5% royalties

    uint256 chainId;
    assembly {
      chainId := chainid()
    }

    DOMAIN_SEPARATOR = keccak256(
      abi.encode(
        keccak256(
          "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        ),
        keccak256(bytes("JuiceboxFrens")),
        keccak256(bytes("1")),
        chainId,
        address(this)
      )
    );
  }

  function _baseURI() internal view override returns (string memory) {
    return baseURI;
  }

  function setBaseURI(string calldata newBaseUri) external onlyOwner {
    baseURI = newBaseUri;
  }

  function setRoyalties(address recipient, uint256 value) external onlyOwner {
    require(recipient != address(0), "zero address");
    _setRoyalties(recipient, value);
  }

  function setWhiteListSigner(address signerToSet) external onlyOwner {
    require(signerToSet != address(0), "zero address");
    whitelistSigner = signerToSet;
  }

  function configureSales(
    uint256 preSaleStartTime,
    uint256 publicSaleStartTime,
    uint256 txLimit,
    uint256 supplyLimit
  ) external onlyOwner {
    uint32 _preSaleStartTime = preSaleStartTime.toUint32();
    uint32 _publicSaleStartTime = publicSaleStartTime.toUint32();
    uint32 _txLimit = txLimit.toUint32();
    uint32 _supplyLimit = supplyLimit.toUint32();

    require(0 < _preSaleStartTime, "Invalid time");
    require(_preSaleStartTime < _publicSaleStartTime, "Invalid time");

    saleConfig = SaleConfig({
      preSaleStartTime: _preSaleStartTime,
      publicSaleStartTime: _publicSaleStartTime,
      txLimit: _txLimit,
      supplyLimit: _supplyLimit
    });
  }

  function buyPresale(
    bytes memory signature,
    uint256 numberOfTokens,
    uint256 approvedLimit
  ) external payable {
    require(
      block.timestamp >= saleConfig.preSaleStartTime &&
        block.timestamp < saleConfig.publicSaleStartTime,
      "Presale is not active"
    );
    require(whitelistSigner != address(0), "White list signer not yet set");
    require(msg.value == (mintPrice * numberOfTokens), "Incorrect payment");
    require(
      (presaleMinted[msg.sender] + numberOfTokens) <= approvedLimit,
      "Wallet limit exceeded"
    );

    bytes32 digest = keccak256(
      abi.encodePacked(
        "\x19\x01",
        DOMAIN_SEPARATOR,
        keccak256(abi.encode(TYPEHASH, msg.sender, approvedLimit))
      )
    );

    address signer = digest.recover(signature);

    require(
      signer != address(0) && signer == whitelistSigner,
      "Invalid signature"
    );

    presaleMinted[msg.sender] = presaleMinted[msg.sender] + numberOfTokens;
    mint(msg.sender, numberOfTokens);
  }

  function buy(uint256 numberOfTokens) external payable {
    SaleConfig memory _saleConfig = saleConfig;

    require(
      block.timestamp >= _saleConfig.publicSaleStartTime,
      "Sale is not active"
    );
    require(
      numberOfTokens <= _saleConfig.txLimit,
      "Transaction limit exceeded"
    );
    require(msg.value == (mintPrice * numberOfTokens), "Incorrect payment");

    mint(msg.sender, numberOfTokens);
  }

  function mint(address to, uint256 numberOfTokens) private {
    require(
      (totalSupply + numberOfTokens) <= saleConfig.supplyLimit,
      "Not enough tokens left"
    );

    uint256 newId = totalSupply;

    for (uint256 i = 0; i < numberOfTokens; i++) {
      newId += 1;
      _safeMint(to, newId);
    }

    totalSupply = newId;
  }

  function reserve(address to, uint256 numberOfTokens) external onlyOwner {
    mint(to, numberOfTokens);
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