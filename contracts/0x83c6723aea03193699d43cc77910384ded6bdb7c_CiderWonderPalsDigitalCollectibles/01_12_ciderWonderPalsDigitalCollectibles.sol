// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@paperxyz/contracts/keyManager/IPaperKeyManager.sol";

contract CiderWonderPalsDigitalCollectibles is ERC1155Supply, Ownable {
  IPaperKeyManager paperKeyManager;

  uint8 public constant MAX_PER_WALLET_FREE = 1;
  uint8 public constant MAX_PER_WALLET_PRE_SALE = 5;
  uint8 public constant MAX_PER_WALLET_PUBLIC_SALE = 10;
  uint256 public constant MAX_SUPPLY = 3888;

  uint256 public preSaleDiscountPrice = 35000000000000000;
  uint256 public publicSalePrice = 80000000000000000;

  uint256 public preSaleWindowOpens = 1667174400;
  uint256 public publicSaleWindowOpens = 1667433600;
  uint256 public publicSaleWindowCloses = 1667692800;

  mapping(address => uint256) public mintedFreeTokens;
  mapping(address => uint256) public mintedPreSaleTokens;
  mapping(address => uint256) public mintedPublicTokens;
  uint256 public mintedToken = 0;
  uint256 public randNonce = 0;

  address payable private withdrawalWallet = payable(0x0c4F8E6b5516251364cf00893C7671747dBbd0d2);

  constructor(
    string memory _name,
    string memory _symbol,
    string memory initialBaseURI,
    address _paperKeyManagerAddress
  ) ERC1155(initialBaseURI) {
    _name = _name;
    _symbol = _symbol;
    paperKeyManager = IPaperKeyManager(_paperKeyManagerAddress);
  }

  modifier onlyPaper(
    bytes32 _hash,
    bytes32 _nonce,
    bytes calldata _signature
  ) {
    bool success = paperKeyManager.verify(_hash, _nonce, _signature);
    require(success, "Failed to verify signature");
    _;
  }

  function registerPaperKey(address paperKey) public onlyOwner {
    paperKeyManager.register(paperKey);
  }

  function setURI(string memory newuri) public onlyOwner {
    _setURI(newuri);
  }

  function checkPreSaleClaimEligibility(
    address toAddress,
    uint256 amount,
    bool isFree
  ) external view returns (string memory) {
    if (mintedToken + amount > MAX_SUPPLY) {
      return "Max token supply reached";
    }

    if (block.timestamp < preSaleWindowOpens || block.timestamp > publicSaleWindowCloses) {
      return "Pre sale window closed";
    }

    if (mintedPreSaleTokens[toAddress] + amount > MAX_PER_WALLET_PRE_SALE) {
      return "Max supply of wallet reached";
    }

    if (isFree && (mintedFreeTokens[toAddress] + amount > MAX_PER_WALLET_FREE)) {
      return "Max supply of free mint reached";
    }

    return "";
  }

  function checkPublicSaleClaimEligibility(address toAddress, uint256 amount)
    external
    view
    returns (string memory)
  {
    if (mintedToken + amount > MAX_SUPPLY) {
      return "Max token supply reached";
    }

    if (block.timestamp < publicSaleWindowOpens || block.timestamp > publicSaleWindowCloses) {
      return "Public sale window closed";
    }

    if (mintedPublicTokens[toAddress] + amount > MAX_PER_WALLET_PUBLIC_SALE) {
      return "Max supply of wallet reached";
    }

    return "";
  }

  function preSaleMint(
    address toAddress,
    uint256 amount,
    bool isFree,
    bytes32 _nonce,
    bytes calldata _signature
  )
    external
    payable
    onlyPaper(keccak256(abi.encode(toAddress, amount, isFree)), _nonce, _signature)
  {
    require(
      block.timestamp >= preSaleWindowOpens && block.timestamp <= publicSaleWindowCloses,
      "Pre sale window closed"
    );

    require(mintedToken + amount <= MAX_SUPPLY, "Max token supply reached");

    require(
      mintedPreSaleTokens[toAddress] + amount <= MAX_PER_WALLET_PRE_SALE,
      "Max supply of wallet reached"
    );

    require(
      !isFree || (mintedFreeTokens[toAddress] + amount <= MAX_PER_WALLET_FREE),
      "Invalid amount"
    );

    require(
      (isFree && msg.value == 0) || (!isFree && msg.value == preSaleDiscountPrice * amount),
      "Incorrect payment value"
    );

    for (uint256 i = 0; i < amount; i++) {
      uint256 id = _tokenId(toAddress);
      _mint(toAddress, id, 1, "");
    }

    if (isFree) {
      mintedFreeTokens[toAddress] += amount;
    }

    mintedPreSaleTokens[toAddress] += amount;
    mintedToken += amount;
  }

  function publicSaleMint(address toAddress, uint256 amount) external payable {
    require(
      block.timestamp >= publicSaleWindowOpens && block.timestamp <= publicSaleWindowCloses,
      "Public sale window closed"
    );

    require(mintedToken + amount <= MAX_SUPPLY, "Max token supply reached");

    require(
      mintedPublicTokens[toAddress] + amount <= MAX_PER_WALLET_PUBLIC_SALE,
      "Max supply of wallet reached"
    );

    require(msg.value == publicSalePrice * amount, "Incorrect payment value");

    for (uint256 i = 0; i < amount; i++) {
      uint256 id = _tokenId(toAddress);
      _mint(toAddress, id, 1, "");
    }

    mintedPublicTokens[toAddress] += amount;
    mintedToken += amount;
  }

  function editWindowsForProduction() external onlyOwner {
    preSaleWindowOpens = 1667174400;
    publicSaleWindowOpens = 1667433600;
    publicSaleWindowCloses = 1667692800;
  }

  function editWindowsForTest() external onlyOwner {
    preSaleWindowOpens = 1666908000;
    publicSaleWindowOpens = 1666908000;
    publicSaleWindowCloses = 1667080800;
  }

  function mintBatch(
    address to,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data
  ) external onlyOwner {
    uint256 i;
    uint256 sum = 0;
    _mintBatch(to, ids, amounts, data);
    for (i = 0; i < amounts.length; i++) {
      sum = sum + amounts[i];
    }
    mintedToken += sum;
  }

  function setPreSaleDiscountPrice(uint256 _preSaleDiscountPrice) external onlyOwner {
    preSaleDiscountPrice = _preSaleDiscountPrice;
  }

  function setPublicSalePrice(uint256 _publicSalePrice) external onlyOwner {
    publicSalePrice = _publicSalePrice;
  }

  function setWithdrawalWallet(address payable walletAddress) external onlyOwner {
    withdrawalWallet = (walletAddress);
  }

  function withdraw() external onlyOwner {
    payable(withdrawalWallet).transfer(address(this).balance);
  }

  function _tokenId(address toAddress) private returns (uint256) {
    randNonce++;
    uint256 number = uint256(keccak256(abi.encodePacked(block.timestamp, toAddress, randNonce))) %
      200;
    if (number == 0) {
      return 1;
    } else if (1 <= number && number <= 2) {
      return 2;
    } else if (3 <= number && number <= 5) {
      return 3;
    } else if (6 <= number && number <= 13) {
      return 4;
    } else if (14 <= number && number <= 23) {
      return 5;
    } else if (24 <= number && number <= 37) {
      return 6;
    } else if (38 <= number && number <= 51) {
      return 7;
    } else if (52 <= number && number <= 73) {
      return 8;
    } else if (74 <= number && number <= 95) {
      return 9;
    } else if (96 <= number && number <= 121) {
      return 10;
    } else if (122 <= number && number <= 153) {
      return 11;
    } else {
      return 12;
    }
  }
}