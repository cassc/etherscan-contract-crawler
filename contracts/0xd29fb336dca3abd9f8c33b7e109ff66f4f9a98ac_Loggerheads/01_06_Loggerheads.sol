// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "@rari-capital/solmate/src/auth/Owned.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";

contract Loggerheads is ERC721A, ERC721AQueryable, Owned {
  uint256 public maxSupply = 9999;  
  uint256 constant maxSupplyPlusOne = 10000;
  uint256 public maxPerTransaction = 20;
  uint256 constant maxPerTransactionPlusOne = 21;
  uint256 public extraPrice = 0.0025 ether;

  bool public paused = true;

  mapping(address => uint256) private _freeMintedCount;

  string tokenBaseUri = "ipfs://QmcSywyWkHAQM1vTU8Yc4Yt1P1CMAFKJ5MMZezfQ5n636q/";

  constructor() ERC721A("Loggerheads", "LH") Owned(msg.sender) {}

  function mint(uint256 _quantity) external payable {
    unchecked {
      require(!paused, "MINTING PAUSED");

      uint256 _totalSupply = totalSupply();

      require(_totalSupply + _quantity < maxSupplyPlusOne, "MAX SUPPLY REACHED");
      require(_quantity < maxPerTransactionPlusOne, "MAX PER TRANSACTION IS 20");

      uint256 payForCount = _quantity;
      uint256 freeMintCount = _freeMintedCount[msg.sender];

      if (freeMintCount < 1) {
        if (_quantity > 1) {
          payForCount = _quantity - 1;
        } else {
          payForCount = 0;
        }

        _freeMintedCount[msg.sender] = 1;
      }

      require(
        msg.value == payForCount * extraPrice,
        "INCORRECT ETH AMOUNT"
      );

      _mint(msg.sender, _quantity);
    }
  }

  function freeMintedCount(address owner) external view returns (uint256) {
    return _freeMintedCount[owner];
  }

  function _startTokenId() internal pure override returns (uint256) {
    return 1;
  }

  function tokenURI(uint _tokenId)
    public
    view
    virtual
    override (ERC721A, IERC721A)
    returns (string memory)
  {
    require(
      _exists(_tokenId),
      "ERC721Metadata: URI query for nonexistent token"
    );
    return string(abi.encodePacked(tokenBaseUri, "/", _toString(_tokenId), ".json"));
  }


  function flipSale() external onlyOwner {
    paused = !paused;
  }

  function devMint() external onlyOwner {
    require(totalSupply() == 0, "RESERVES TAKEN");

    _mint(msg.sender, 50);
  }

  function withdraw() external onlyOwner {
    require(
      payable(owner).send(address(this).balance),
      "UNSUCCESSFUL"
    );
  }
}