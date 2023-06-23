// SPDX-License-Identifier: MIT

pragma solidity ^0.7.3;

import "./ERC721.sol";
import "./WhitelistExchangesProxy.sol";
import "./mixin/MixinOwnable.sol";

contract HashBaseV2 is Ownable, ERC721 {

    string public baseMetadataURI;
    string public contractURI;

    constructor (
      string memory name_,
      string memory symbol_
    ) ERC721(name_, symbol_) {
    }

    function setBaseMetadataURI(string memory _baseMetadataURI) public onlyOwner {
      baseMetadataURI = _baseMetadataURI;
    }

    function setContractURI(string calldata newContractURI) external onlyOwner {
        contractURI = newContractURI;
    }

    function _baseURI() override internal view virtual returns (string memory) {
      return baseMetadataURI;
    }
}