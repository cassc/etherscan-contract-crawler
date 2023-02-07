// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

contract PacemakerPacelist is
  ERC1155,
  ERC1155Supply,
  Ownable,
  DefaultOperatorFilterer
{
  constructor() ERC1155("") DefaultOperatorFilterer() {}

  /// @notice Tracking the tokenID to URI
  mapping(uint256 => string) private tokenURIs;

  modifier tokenExists(uint256 tokenId) {
    require(bytes(tokenURIs[tokenId]).length > 0, "tokenId doesn't exist");
    _;
  }

  /// @notice Airdrop one NFT to different wallets by tokenId
  /// @param wallets a list of walllet addresses as array
  /// @param tokenId the token ID number to airdrop
  function airdropSingleTokens(address[] calldata wallets, uint256 tokenId)
    public
    tokenExists(tokenId)
    onlyOwner
  {
    for (uint256 i = 0; i < wallets.length; i++) {
      _mint(wallets[i], tokenId, 1, "");
    }
  }

  /// @notice Airdrop many different NFTs by wallets, tokenIds and amount
  /// @param wallets a list of walllet addresses as array
  /// @param tokenIds a list of token IDs as array
  /// @param amount a list of the amount of tokens to airdrop per wallet as array
  function airdropManyTokens(
    address[] calldata wallets,
    uint256[] calldata tokenIds,
    uint256[] calldata amount
  ) public onlyOwner {
    require(
      wallets.length == tokenIds.length &&
        wallets.length == amount.length &&
        tokenIds.length == amount.length,
      "Inputs must be the same length"
    );

    for (uint256 i = 0; i < tokenIds.length; i++) {
      _mint(wallets[i], tokenIds[i], amount[i], "");
    }
  }

  /// @notice Allows the owner to set a new URI for tokens
  /// @param tokenId token ID as number
  /// @param newUri uri of the asset
  function setTokenURI(uint256 tokenId, string calldata newUri)
    public
    onlyOwner
  {
    tokenURIs[tokenId] = newUri;
  }

  function uri(uint256 tokenId)
    public
    view
    virtual
    override
    tokenExists(tokenId)
    returns (string memory)
  {
    return tokenURIs[tokenId];
  }

  function _beforeTokenTransfer(
    address operator,
    address from,
    address to,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data
  ) internal override(ERC1155, ERC1155Supply) {
    super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
  }

  /**
   * @dev See {IERC1155-setApprovalForAll}.
   *  the modifier ensures that the operator is allowed by the OperatorFilterRegistry.
   */
  function setApprovalForAll(address operator, bool approved)
    public
    override
    onlyAllowedOperatorApproval(operator)
  {
    super.setApprovalForAll(operator, approved);
  }

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    uint256 amount,
    bytes memory data
  ) public override onlyAllowedOperator(from) {
    super.safeTransferFrom(from, to, tokenId, amount, data);
  }

  function safeBatchTransferFrom(
    address from,
    address to,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data
  ) public virtual override onlyAllowedOperator(from) {
    super.safeBatchTransferFrom(from, to, ids, amounts, data);
  }

  /// @notice This function is only here in case someone sends ETH by mistake
  function withdrawFunds() external onlyOwner {
    (bool success, ) = payable(msg.sender).call{ value: address(this).balance }(
      ""
    );
    require(success, "Withdraw failed");
  }
}