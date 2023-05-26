// SPDX-License-Identifier: MIT

/*
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@                                               @@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@                                                   @@@@@@@@@@@@@@@@@@@@@
@@@@@                                                     @@@@@@@@@@@@@@@@@@@@@@
@@@   ,@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@          @@@@@@@@@@@@@@@@@@@@@@@
@#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@     @@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@  @@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@             @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@             @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@             @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@            @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@             @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@            @@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@             @@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@            @@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@             @@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@            @@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@             @@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@            @@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@             @@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@             @@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@               @@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
*/

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "erc721a/contracts/ERC721A.sol";

import "./mint/IRebelsMintAuthorizer.sol";
import "./render/IRebelsRenderer.sol";

abstract contract RevealInterface {
  function mint(address to, uint256[] calldata tokenIDs) external virtual;
}

contract NightCard is ERC721A, Ownable {
  uint256 immutable public maxSupply;
  address public rendererAddress;
  address public mintAuthorizerAddress;
  address public revealContractAddress;
  string public contractURI;

  uint256 private _numAvailableTokens;
  mapping(uint256 => uint256) private _availableTokens;

  constructor(
    string memory name_,
    string memory symbol_,
    uint256 maxSupply_
  ) ERC721A(name_, symbol_) {
    maxSupply = maxSupply_;
    _numAvailableTokens = maxSupply_;
  }

  function tokenURI(uint256 id) public view override returns (string memory) {
    require(rendererAddress != address(0), "Renderer address unset");
    require(_exists(id), "URI query for nonexistent token");

    IRebelsRenderer renderer = IRebelsRenderer(rendererAddress);
    return renderer.tokenURI(id);
  }

  function mint(uint256 number, bytes32[] calldata proof) external payable {
    require(tx.origin == msg.sender, "Trying to mint from a contract");
    require(mintAuthorizerAddress != address(0), "Mint authorizer address unset");

    IRebelsMintAuthorizer mintAuthorizer = IRebelsMintAuthorizer(mintAuthorizerAddress);
    mintAuthorizer.authorizeMint(msg.sender, msg.value, number, proof);

    _mint(msg.sender, number);

    require(_totalMinted() <= maxSupply, "Trying to mint more than max supply");
  }

  function reveal(uint256[] calldata tokenIDs) external {
    require(tx.origin == msg.sender, "Trying to reveal from a contract");
    require(revealContractAddress != address(0), "Reveal contract address unset");

    uint256[] memory newTokenIDs = new uint256[](tokenIDs.length);

    for (uint256 i = 0; i < tokenIDs.length; ++i) {
      require(msg.sender == ownerOf(tokenIDs[i]), "Reveal from incorrect owner");
      _burn(tokenIDs[i]);

      newTokenIDs[i] = _getRandomAvailableTokenId();
      _numAvailableTokens -= 1;
    }

    RevealInterface revealContract = RevealInterface(revealContractAddress);
    revealContract.mint(msg.sender, newTokenIDs);
  }

  function setRendererAddress(address rendererAddress_) external onlyOwner {
    rendererAddress = rendererAddress_;
  }

  function setMintAuthorizerAddress(address mintAuthorizerAddress_) external onlyOwner {
    mintAuthorizerAddress = mintAuthorizerAddress_;
  }

  function setRevealContractAddress(address revealContractAddress_) external onlyOwner {
    revealContractAddress = revealContractAddress_;
  }

  function setContractURI(string memory contractURI_) external onlyOwner {
    contractURI = contractURI_;
  }

  function withdraw() external onlyOwner {
    uint256 balance = address(this).balance;
    payable(msg.sender).transfer(balance);
  }

  function _startTokenId() internal pure override returns (uint256) {
    // 1 -> 13370 looks better.
    return 1;
  }

  function _getRandomAvailableTokenId() private returns (uint256) {
    uint256 randomNum = uint256(keccak256(abi.encode(
        tx.origin, tx.gasprice, block.number, block.timestamp,
        block.difficulty, block.coinbase, blockhash(block.number - 1),
        address(this), _numAvailableTokens)));

    uint256 randomIndex = randomNum % _numAvailableTokens;
    return _getAvailableTokenAtIndex(randomIndex);
  }

  // Adapted from CryptoPhunksV2/ERC721R.
  function _getAvailableTokenAtIndex(uint256 indexToUse) private returns (uint256) {
    uint256 valAtIndex = _availableTokens[indexToUse];
    uint256 result;
    if (valAtIndex == 0) {
      // This means the index itself is still an available token.
      result = indexToUse;
    } else {
      // This means the index itself is not an available token, but the val at
      // that index is.
      result = valAtIndex;
    }

    uint256 lastIndex = _numAvailableTokens - 1;
    if (indexToUse != lastIndex) {
      // Replace the value at indexToUse, now that it's been used. Replace it
      // with the data from the last index in the array, since we are going to
      // decrease the array size afterwards.
      uint256 lastValInArray = _availableTokens[lastIndex];
      if (lastValInArray == 0) {
        // This means the index itself is still an available token.
        _availableTokens[indexToUse] = lastIndex;
      } else {
        // This means the index itself is not an available token, but the val
        // at that index is.
        _availableTokens[indexToUse] = lastValInArray;
        // Gas refund courtsey of @dievardump.
        delete _availableTokens[lastIndex];
      }
    }

    return result;
  }
}