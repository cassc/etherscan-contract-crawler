// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./IReverseRegistrar.sol";
import "./ERC721.sol";

contract PokeGAN is ERC721, Ownable {
  using ECDSA for bytes32;

  uint256 public allowListMintPrice;

  address private signerAddress;
  bool public paused = true;
  bool public mintEnded = false;

  address immutable ENSReverseRegistrar = 0x084b1c3C81545d370f3634392De611CaaBFf8148;

  uint256 public currentEvolutionIndex = 0;

  // TokenID represents the seed of the corresponding pickle file
  // New Pickle files are added with a new indices as GAN training progresses
  mapping (uint256 => string) public evolutions;

  constructor(
      string memory _name,
      string memory _symbol,
      uint256 _allowListMintPrice,
      address _signerAddress
  ) ERC721(_name, _symbol, 99999) {
    allowListMintPrice = _allowListMintPrice;
    signerAddress = _signerAddress;
  }

  function flipPaused() external onlyOwner {
    paused = !paused;
  }

  function endMint() external onlyOwner {
    mintEnded = true;  
  }

  function setBaseURI(string memory baseURI) public onlyOwner {
    _setBaseURI(baseURI);
  }
  
  function evolve(string calldata newURI) external onlyOwner {
    currentEvolutionIndex = currentEvolutionIndex + 1;
    evolutions[currentEvolutionIndex] = newURI;
  }

  function mintAllowList(
    bytes32 messageHash,
    bytes calldata signature,
    uint amount
  ) public payable {
    require(!paused, "s");
    require(!mintEnded, "m");
    require(hashMessage(msg.sender, address(this)) == messageHash, "i");
    require(verifyAddressSigner(messageHash, signature), "f");
    require(allowListMintPrice * amount <= msg.value, "a");

    _safeMint(msg.sender, amount);
  }

  function addReverseENSRecord(string memory name) external onlyOwner{
    IReverseRegistrar(ENSReverseRegistrar).setName(name);
  }

  function verifyAddressSigner(bytes32 messageHash, bytes memory signature) private view returns (bool) {
    return signerAddress == messageHash.toEthSignedMessageHash().recover(signature);
  }

  function hashMessage(address sender, address thisContract) public pure returns (bytes32) {
    return keccak256(abi.encodePacked(sender, thisContract));
  }

  function withdraw() external onlyOwner() {
    uint balance = address(this).balance;
    payable(msg.sender).transfer(balance);
  }

  function withdrawTokens(address tokenAddress) external onlyOwner() {
    IERC20(tokenAddress).transfer(msg.sender, IERC20(tokenAddress).balanceOf(address(this)));
  }
}

// The High Table