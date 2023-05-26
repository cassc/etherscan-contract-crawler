// SPDX-License-Identifier: MIT

/**
         @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                                        
        @@                                                                            @@@@                                    
       @@@                                                                                @@@                                  
       @@@                                                                                   @@                                 
       @@@      @@@@@@@@@@@@@@@@         @@@@@@@@@@@@@@@@        @@@@@@@@         @@@@@@       @@                                
       @@@      @@@@@@@@@@@@@@@@@@@      @@@@@@@@@@@@@@@@@@        @@@@@@@       @@@@@         @@@                               
       @@@      @@@@            @@@@     @@@@           @@@@         @@@@@@    @@@@@           @@@                               
       @@@      @@@@             @@@     @@@@             @@@          @@@@@  @@@@             @@@                               
       @@@      @@@@            @@@      @@@@            @@@@           @@@@@@@@               @@@                               
       @@@      @@@@@@@@@@@@@@@@@        @@@@@@@@@@@@@@@@@@@             @@@@@@                @@@                               
       @@@      @@@@@@@@@@@@@@@@@@@@     @@@@@@@@@@@@@@@@                 @@@@@@               @@@                               
       @@@      @@@@             @@@@    @@@@@@@@@@@@@                   @@@@@@@@@             @@@                               
       @@@      @@@@              @@@@   @@@@    @@@@@@@               @@@@   @@@@@            @@@                               
       @@@      @@@@            @@@@@@   @@@@      @@@@@@            @@@@@     @@@@@           @@@                               
       @@@      @@@@@@@@@@@@@@@@@@@@@    @@@@        @@@@@         @@@@@        @@@@@@         @@@                               
        @@       @@@@@@@@@@@@@@@@@@      @@@@         @@@@@@     @@@@@@          @@@@@@        @@@                               
        @@@          @@@@@@@@            @@@@          @@@@@@   @@@@@             @@@@@@@      @@@                               
          @@@                                                                                  @@@                               
            @@@@@                                                                             @@@                                
                @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                                 
*/

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

contract ZeroCrate is DefaultOperatorFilterer, ERC721A, ERC2981, Ownable {

  string private baseTokenUri;

  constructor(string memory _baseUri) ERC721A("ZeroCrate", "ZRC") {
      baseTokenUri = _baseUri;

  }

  //URI to metadata
  function _baseURI() internal view virtual override returns (string memory) {
      return baseTokenUri;
  }

  function setBaseUri(string calldata _newTokenURI) external onlyOwner {
      baseTokenUri = _newTokenURI;
  }

  function _startTokenId() internal view virtual override returns (uint256) {
      return 1;
  }

  function airdrop(address[] calldata _receivers) external onlyOwner {
    for (uint256 i = 0; i < _receivers.length; i++) {
      _mint(_receivers[i], 1);
    }
  }

  function setApprovalForAll(
      address operator,
      bool approved
  ) public override onlyAllowedOperatorApproval(operator) {
      super.setApprovalForAll(operator, approved);
  }

  function approve(
      address operator,
      uint256 tokenId
  ) public payable override onlyAllowedOperator(operator) {
      super.approve(operator, tokenId);
  }

  function transferFrom(
      address from,
      address to,
      uint256 tokenId
  ) public payable override onlyAllowedOperator(from) {
      super.transferFrom(from, to, tokenId);
  }

  function safeTransferFrom(
      address from,
      address to,
      uint256 tokenId
  ) public payable override onlyAllowedOperator(from) {
      super.safeTransferFrom(from, to, tokenId);
  }

  function safeTransferFrom(
      address from,
      address to,
      uint256 tokenId,
      bytes memory data
  ) public payable override onlyAllowedOperator(from) {
      super.safeTransferFrom(from, to, tokenId, data);
  }

  function setDefaultRoyalty(address receiver, uint96 feeNumerator) external onlyOwner {
      _setDefaultRoyalty(receiver, feeNumerator);
  }

  function deleteDefaultRoyalty() external onlyOwner {
      _deleteDefaultRoyalty();
  }

  function supportsInterface(
      bytes4 interfaceId
  ) public view virtual override(ERC721A, ERC2981) returns (bool) {
      return ERC721A.supportsInterface(interfaceId) || ERC2981.supportsInterface(interfaceId);
  }
}