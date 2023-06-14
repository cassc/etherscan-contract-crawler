// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import '@openzeppelin/contracts/access/Ownable.sol';
import 'erc721a/contracts/extensions/ERC721AQueryable.sol';
import 'operator-filter-registry/src/DefaultOperatorFilterer.sol';
import '@openzeppelin/contracts/token/common/ERC2981.sol';
import '@openzeppelin/contracts/security/Pausable.sol';
import '@openzeppelin/contracts/utils/structs/BitMaps.sol';

contract GoldenTicket is ERC721AQueryable, ERC2981, Ownable, Pausable, DefaultOperatorFilterer {
   string private _name;
   string private _symbol;
   string private _contractUri;
   string public baseUri;

   BitMaps.BitMap private lockedTokens;
   BitMaps.BitMap private redeemedTokens;
   mapping(address => bool) public permittedOperators;

   constructor(
      string memory __name,
      string memory __symbol,
      string memory __contractUri,
      string memory _baseUri,
      address recipient,
      uint96 value
   ) ERC721A(_name, _symbol) {
      _name = __name;
      _symbol = __symbol;
      _contractUri = __contractUri;
      baseUri = _baseUri;
      _setDefaultRoyalty(recipient, value);
      _pause();
   }

   modifier onlyPermittedOperator() {
      require(permittedOperators[msg.sender] || msg.sender == owner(), 'Not a permitted operator');
      _;
   }

   /// @notice The name of the ERC721 token.
   function name() public view override(ERC721A, IERC721A) returns (string memory) {
      return _name;
   }

   /// @notice The symbol of the ERC721 token.
   function symbol() public view override(ERC721A, IERC721A) returns (string memory) {
      return _symbol;
   }

   /// @notice Sets the name and symbol of the ERC721 token.
   /// @param newName The new name for the token.
   /// @param newSymbol The new symbol for the token.
   function setNameAndSymbol(
      string calldata newName,
      string calldata newSymbol
   ) external onlyOwner {
      _name = newName;
      _symbol = newSymbol;
   }

   /// @notice The token base URI.
   function _baseURI() internal view override returns (string memory) {
      return baseUri;
   }

   /// @notice Sets the base URI for the token metadata.
   /// @param newBaseUri The new base URI for the token metadata.
   function setBaseUri(string calldata newBaseUri) external onlyOwner {
      baseUri = newBaseUri;
   }

   /// @notice Sets the URI for the contract metadata.
   /// @param newContractUri The new contract URI for contract metadata.
   function setContractURI(string calldata newContractUri) external onlyOwner {
      _contractUri = newContractUri;
   }

   /// @notice Sets the contract URI for marketplace listings.
   function contractURI() public view returns (string memory) {
      return _contractUri;
   }

   /// @notice Pauses the contract, preventing token transfers.
   function pause() public onlyOwner {
      _pause();
   }

   /// @notice Unpauses the contract, allowing token transfers.
   function unpause() public onlyOwner {
      _unpause();
   }

   /// @notice Mints multiple tokens and assigns them to the specified addresses.
   /// @param to An array of addresses to which tokens will be minted.
   /// @param value An array of values representing the number of tokens to mint for each address.
   function mintMany(address[] calldata to, uint256[] calldata value) external onlyOwner {
      require(to.length == value.length, 'Mismatched lengths');
      unchecked {
         for (uint256 i = 0; i < to.length; i++) {
            _mint(to[i], value[i]);
         }
      }
   }

   /// @notice Sets the royalty fee for the specified recipient.
   /// @param recipient The address of the royalty recipient.
   /// @param value The value of the royalty fee.
   function setRoyalties(address recipient, uint96 value) public onlyOwner {
      _setDefaultRoyalty(recipient, value);
   }

   /// @notice Locks the specified tokens, preventing them from being transferred.
   /// @param tokenIds An array of token IDs to be locked.
   function lockTokens(uint256[] calldata tokenIds) external onlyPermittedOperator {
      unchecked {
         for (uint256 i = 0; i < tokenIds.length; i++) {
            require(_exists(tokenIds[i]), 'Token does not exist.');
            require(!BitMaps.get(lockedTokens, tokenIds[i]), 'Token is already locked');
            BitMaps.set(lockedTokens, tokenIds[i]);
         }
      }
   }

   /// @notice Admin function to unlock the specified golden tickets, allowing them to be transferred.
   /// @param tokenIds An array of token IDs to be unlocked.
   function unlockTokens(uint256[] calldata tokenIds) external onlyPermittedOperator {
      unchecked {
         for (uint256 i = 0; i < tokenIds.length; i++) {
            require(BitMaps.get(lockedTokens, tokenIds[i]), 'Token is already unlocked');
            BitMaps.unset(lockedTokens, tokenIds[i]);
         }
      }
   }

   /// @notice Check if a token is locked.
   /// @param tokenId The tokenId of the token to check.
   function isTokenLocked(uint256 tokenId) public view returns (bool) {
      return BitMaps.get(lockedTokens, tokenId);
   }

   /// @notice Check if a token has be burned and redeemed.
   /// @param tokenId The tokenId of the token to check.
   function isTokenRedeemed(uint256 tokenId) public view returns (bool) {
      return BitMaps.get(redeemedTokens, tokenId);
   }

   /// @notice Get tokenIds of all locked tokens in a given range.
   /// @param start The start tokenId of the range to check.
   /// @param end The end tokenId of the range to check.
   function getLockedTokensInRange(
      uint256 start,
      uint256 end
   ) public view returns (uint256[] memory) {
      require(end >= start, 'End must be greater than or equal to start');
      uint256[] memory result = new uint256[](end - start + 1);
      uint256 count = 0;
      unchecked {
         for (uint256 i = start; i <= end; i++) {
            if (BitMaps.get(lockedTokens, i)) {
               result[count] = i;
               count++;
            }
         }
      }
      uint256[] memory tokens = new uint256[](count);
      unchecked {
         for (uint256 i = 0; i < count; i++) {
            tokens[i] = result[i];
         }
      }
      return tokens;
   }

   /// @notice Get tokenIds of all redeemed tokens in a given range.
   /// @param start The start tokenId of the range to check.
   /// @param end The end tokenId of the range to check.
   function getRedeemedTokensInRange(
      uint256 start,
      uint256 end
   ) public view returns (uint256[] memory) {
      require(end >= start, 'End must be greater than or equal to start');
      uint256[] memory result = new uint256[](end - start + 1);
      uint256 count = 0;
      unchecked {
         for (uint256 i = start; i <= end; i++) {
            if (BitMaps.get(redeemedTokens, i)) {
               result[count] = i;
               count++;
            }
         }
      }
      uint256[] memory redeemedTokensInRange = new uint256[](count);
      unchecked {
         for (uint256 i = 0; i < count; i++) {
            redeemedTokensInRange[i] = result[i];
         }
      }
      return redeemedTokensInRange;
   }

   /// @notice Admin function to burn and redeem the golden ticket.
   /// @param tokenIds An array of locked token IDs to be burned.
   function burnAndRedeem(uint256[] calldata tokenIds) external onlyPermittedOperator {
      unchecked {
         for (uint256 i = 0; i < tokenIds.length; i++) {
            require(
               BitMaps.get(lockedTokens, tokenIds[i]),
               'Token must be locked before burn/redemption'
            );
            _burn(tokenIds[i]);
            BitMaps.set(redeemedTokens, tokenIds[i]);
         }
      }
   }

   /// @notice Adds multiple addresses as permitted operators.
   /// @param operators An array of addresses to be added as permitted operators.
   function addPermittedOperators(address[] calldata operators) external onlyOwner {
      for (uint256 i = 0; i < operators.length; i++) {
         require(!permittedOperators[operators[i]], 'At least one operator is already permitted');
         permittedOperators[operators[i]] = true;
      }
   }

   /// @notice Removes multiple addresses from the permitted operators list.
   /// @param operators An array of addresses to be removed from the permitted operators list.
   function removePermittedOperators(address[] calldata operators) external onlyOwner {
      for (uint256 i = 0; i < operators.length; i++) {
         permittedOperators[operators[i]] = false;
      }
   }

   /// @dev Ensure that a user cannot burn or transfer a locked golden ticket unless that user is a permitted operator
   function _beforeTokenTransfers(
      address from,
      address to,
      uint256 startTokenId,
      uint256 quantity
   ) internal override {
      unchecked {
         for (uint256 i = startTokenId; i < startTokenId + quantity; i++) {
            if (BitMaps.get(lockedTokens, i)) {
               require(
                  permittedOperators[msg.sender] || msg.sender == owner(),
                  'At least one token is locked and cannot be transferred.'
               );
            }
         }
      }
      super._beforeTokenTransfers(from, to, startTokenId, quantity);
   }

   function setApprovalForAll(
      address operator,
      bool approved
   ) public override(ERC721A, IERC721A) onlyAllowedOperatorApproval(operator) whenNotPaused {
      super.setApprovalForAll(operator, approved);
   }

   function approve(
      address operator,
      uint256 tokenId
   )
      public
      payable
      override(ERC721A, IERC721A)
      onlyAllowedOperatorApproval(operator)
      whenNotPaused
   {
      if (BitMaps.get(lockedTokens, tokenId)) {
         require(
            permittedOperators[msg.sender] || msg.sender == owner(),
            'Token must not be locked to grant approval.'
         );
      }
      super.approve(operator, tokenId);
   }

   function transferFrom(
      address from,
      address to,
      uint256 tokenId
   ) public payable override(ERC721A, IERC721A) onlyAllowedOperator(from) whenNotPaused {
      super.transferFrom(from, to, tokenId);
   }

   function safeTransferFrom(
      address from,
      address to,
      uint256 tokenId
   ) public payable override(ERC721A, IERC721A) onlyAllowedOperator(from) whenNotPaused {
      super.safeTransferFrom(from, to, tokenId);
   }

   function safeTransferFrom(
      address from,
      address to,
      uint256 tokenId,
      bytes memory data
   ) public payable override(ERC721A, IERC721A) onlyAllowedOperator(from) whenNotPaused {
      super.safeTransferFrom(from, to, tokenId, data);
   }

   /// @dev Supports `interfaceId`s for IERC165, IERC721, IERC721Metadata, IERC2981
   function supportsInterface(
      bytes4 interfaceId
   ) public view override(ERC721A, IERC721A, ERC2981) returns (bool) {
      return ERC721A.supportsInterface(interfaceId) || ERC2981.supportsInterface(interfaceId);
   }
}