// SPDX-License-Identifier: None

pragma solidity ^0.8.4;

import "./DirtBirds.sol";
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract DeadBirds is ERC721A, Ownable {
  uint256 constant PRICE = 0.029 ether;
  uint256 constant MAX_SUPPLY = 3333;
  uint256 constant MAX_PER_TRANSACTION = 10;

  bool public paused = true;
  uint256 public publicMintPrice = 0;
  string tokenBaseUri = "ipfs://QmV97nkwJuyv6axWRE54HWvWFYzq2XUaUa63RqM1mQpSTT/?";

  mapping(uint256 => bool) public usedBird;

  DirtBirds private immutable dirtBirdsContract;

  constructor(address _dirtBirdsAddress) ERC721A("Dead Birds", "DeadBirds") {
    dirtBirdsContract = DirtBirds(_dirtBirdsAddress);
  }

  function mutate(uint256[] calldata _birdIds) external payable {
    require(_birdIds.length == 3, "Needs 3 dirt birds to mutate");
    require(msg.value == PRICE, "ETH sent not correct");

    require(_birdIds[0] != _birdIds[1], "No duplicate birds allowed");
    require(_birdIds[0] != _birdIds[2], "No duplicate birds allowed");
    require(_birdIds[1] != _birdIds[2], "No duplicate birds allowed");

    for (uint256 i = 0; i < _birdIds.length; ++i) {
      require(
        dirtBirdsContract.ownerOf(_birdIds[i]) == msg.sender,
        "Not dirt bird owner"
      );
      require(usedBird[_birdIds[i]] == false, "Bird already used for mutation");
    }

    usedBird[_birdIds[0]] = true;
    usedBird[_birdIds[1]] = true;

    if (isGoingToBurn(_birdIds[2])) {
      dirtBirdsContract.transferFrom(
        msg.sender,
        0x000000000000000000000000000000000000dEaD,
        _birdIds[2]
      );

      payable(msg.sender).transfer(PRICE);
    } else {
      usedBird[_birdIds[2]] = true;
    }

    _mint(msg.sender, 1);
  }

  function publicMint(uint256 _quantity) external payable {
    require(!paused, "Public mint paused");

    uint256 _totalSupply = totalSupply();

    require(_totalSupply + _quantity <= MAX_SUPPLY, "Exceeds supply");
    require(_quantity <= MAX_PER_TRANSACTION, "Exceeds max per tx");

    require(msg.value == _quantity * publicMintPrice, "ETH sent not correct");

    _mint(msg.sender, _quantity);
  }

  function isGoingToBurn(uint256 _tokenId) internal view returns (bool) {
    return
      uint256(
        keccak256(
          abi.encodePacked(
            tx.origin,
            blockhash(block.number - 1),
            block.timestamp,
            msg.sender,
            totalSupply(),
            _tokenId
          )
        )
      ) %
        10 <
      7;
  }

  function _startTokenId() internal pure override returns (uint256) {
    return 1;
  }

  function _baseURI() internal view override returns (string memory) {
    return tokenBaseUri;
  }

  function flipSale() external onlyOwner {
    paused = !paused;
  }

  function setBaseURI(string calldata _newBaseUri) external onlyOwner {
    tokenBaseUri = _newBaseUri;
  }

  function setPublicMintPrice(uint256 _newPublicMintPrice) external onlyOwner {
    publicMintPrice = _newPublicMintPrice;
  }

  function withdraw() external onlyOwner {
    require(
      payable(owner()).send(address(this).balance),
      "Withdraw unsuccessful"
    );
  }
}