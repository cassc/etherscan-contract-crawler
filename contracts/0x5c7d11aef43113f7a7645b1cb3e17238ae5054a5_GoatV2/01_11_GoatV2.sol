// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.6;

import "./Goat.sol";

contract GoatV2 is Goat {
  constructor(
    string memory _name,
    string memory _symbol,
    string memory _initBaseURI,
    address _signer
  ) Goat(_name, _symbol, _initBaseURI, _signer) {}

  function sendToken(
    uint256 _tokenId,
    address _receiver,
    uint256 _price,
    bytes memory _signature
  ) external payable override {
    address owner = ownerOf(_tokenId);
    require(
      isSignatureValid(owner, _receiver, _tokenId, _price, sendNonce[_tokenId], _signature),
      "Goat: invalid signature"
    );
    require(msg.value >= _price, "Goat: price is higher than the amount of ETH sent");

    safeTransferFromWithoutCheckingNesting(owner, _receiver, _tokenId);

    if (_price != 0) {
      (bool success, ) = address(owner).call{value: _price}("");
      require(success, "Unable to send ETH to owner of token");

      if (_price < msg.value) {
        (success, ) = address(_receiver).call{value: msg.value - _price}("");
        require(success, "Unable to send ETH to buyer");
      }
    }

    sendNonce[_tokenId] += 1;
  }
}