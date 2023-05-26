/***
 *                 _                 _
 *     ___   __ _ | |_  __ _   __ _ (_)
 *    / __| / _` || __|/ _` | / _` || |
 *    \__ \| (_| || |_| (_| || (_| || |
 *    |___/ \__,_| \__|\__,_| \__, ||_|
 *                               |_|
 */

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract BapesGenesis1Key is ERC721A, Ownable {
  using Strings for uint256;

  string private metadataURI;
  address private withdrawWallet;
  address private burnAllowed;

  constructor(string memory _metadataURI) ERC721A("Bapes Genesis I Key", "BGK1") {
    updateMetadataURI(_metadataURI);
  }

  function tokenURI(uint256) public view virtual override returns (string memory) {
    return metadataURI;
  }

  function getOwnerTokens(address _owner) public view returns (uint256[] memory) {
    uint256 ownerBalance = balanceOf(_owner);
    uint256[] memory ownerTokens = new uint256[](ownerBalance);
    uint256 currentTokenId = _startTokenId();
    uint256 ownedTokenIndex = 0;
    address latestOwnerAddress;

    while (ownedTokenIndex < ownerBalance && currentTokenId < _currentIndex) {
      TokenOwnership memory ownership = _ownerships[currentTokenId];

      if (!ownership.burned) {
        if (ownership.addr != address(0)) {
          latestOwnerAddress = ownership.addr;
        }

        if (latestOwnerAddress == _owner) {
          ownerTokens[ownedTokenIndex] = currentTokenId;

          ownedTokenIndex++;
        }
      }

      currentTokenId++;
    }

    return ownerTokens;
  }

  function updateBurnAllowed(address _address) external onlyOwner {
    burnAllowed = _address;
  }

  function mintFor(uint256 _mintAmount, address _receiver) external onlyOwner {
    _safeMint(_receiver, _mintAmount);
  }

  function withdraw() external onlyOwner {
    (bool success, ) = payable(withdrawWallet).call{value: address(this).balance}("");

    require(success, "Withdraw failed.");
  }

  function updateWithdrawWallet(address _withdrawWallet) external onlyOwner {
    withdrawWallet = _withdrawWallet;
  }

  function updateMetadataURI(string memory _metadataURI) public onlyOwner {
    metadataURI = _metadataURI;
  }

  function burn(uint256 _amount, address _address) public returns (bool) {
    require(msg.sender == burnAllowed, "This address is not allowed to burn");
    require(balanceOf(_address) >= _amount, "Not enough keys");

    uint256[] memory tokens = getOwnerTokens(_address);

    for (uint256 i = 0; i < _amount; i++) {
      _burn(tokens[i]);
    }

    return true;
  }
}