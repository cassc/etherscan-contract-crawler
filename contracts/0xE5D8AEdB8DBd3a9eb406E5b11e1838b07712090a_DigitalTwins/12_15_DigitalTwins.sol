// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

error InvalidSupply(uint256 maxSupply_);
error CapExceeded(uint256 initialSupply_, uint256 maxSupply_);
error AlreadyAssignedTokenId(uint256 tokenId_);
error InvalidAmount(uint256 amount_);
error InvalidParametersNumber(uint256 amountIds, uint256 amountAmounts);
error InvalidParameters(uint256 amountIds);
error EmptyString(string emptyString);
error UnauthorizedBurn(uint256 ownedAmount, uint256 burnedAmount);

contract DigitalTwins is ERC1155, ERC2981, DefaultOperatorFilterer, Ownable {

  string public name;
  string public symbol;
  string public contractURI;
  mapping(uint256 => uint256) public maxSupply;
  mapping(uint256 => uint256) public totalSupply;
  mapping(uint256 => string) private tokenURIs;

  event ContractURIUpdated(string updatedContractURI);

  constructor (string memory name_, string memory symbol_, string memory contractURI_, address receiver_, uint96 feeNumerator_) ERC1155("") {
    name = name_;
    symbol = symbol_;
    setContractURI(contractURI_);
    _setDefaultRoyalty(receiver_, feeNumerator_);
  }

  /// @dev Create an ERC1155 token, with a max supply
  /// @dev The contract owner can mint tokens on demand up to the max supply
  function createForAdminMint(
      uint256 tokenId_,
      uint256 initialSupply_,
      uint256 maxSupply_,
      string memory uri_
  ) external onlyOwner {
    if (maxSupply_ == 0) revert InvalidSupply(maxSupply_);
    if (isCreated(tokenId_)) revert AlreadyAssignedTokenId(tokenId_);
    if (initialSupply_ > maxSupply_) revert CapExceeded(initialSupply_, maxSupply_);

    tokenURIs[tokenId_] = uri_;
    maxSupply[tokenId_] = maxSupply_;

    if (initialSupply_ > 0) {
        _mint(msg.sender, tokenId_, initialSupply_, hex"");
    }
  }
  
  /// @dev Mints an amount of ERC1155 tokens to an address
  function adminMint(
      address to_,
      uint256 tokenId_,
      uint256 amount_
  ) external onlyOwner {
      _mint(to_, tokenId_, amount_, hex"");
  }

  function isCreated(uint256 tokenId) public view virtual returns (bool) {
      return maxSupply[tokenId] != 0;
  }

  /// @dev Burns an amount of ERC1155 tokens from msg sender
  function burn(uint256 tokenId, uint256 amount) external {
    _burn(_msgSender(), tokenId, amount);
  }

  function uri(uint256 tokenId_) public view virtual override returns (string memory) {
    return tokenURIs[tokenId_];
  }

  function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
      super.setApprovalForAll(operator, approved);
  }

  function safeTransferFrom(address from, address to, uint256 tokenId, uint256 amount, bytes memory data) public override onlyAllowedOperator(from) {
      super.safeTransferFrom(from, to, tokenId, amount, data);
  }

  function safeBatchTransferFrom(address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) public virtual override onlyAllowedOperator(from) {
      super.safeBatchTransferFrom(from, to, ids, amounts, data);
  }
  
  function setDefaultRoyalty(address receiver_, uint96 feeNumerator_) external virtual onlyOwner {
      _setDefaultRoyalty(receiver_, feeNumerator_);
  }

  function setContractURI(string memory contractURI_) public onlyOwner {
      if (bytes(contractURI_).length == 0) revert EmptyString(contractURI_);

      contractURI = contractURI_;
      emit ContractURIUpdated(contractURI_);
  }
  
  /// @dev See {IERC165-supportsInterface}
  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155, ERC2981) returns (bool) {
      return super.supportsInterface(interfaceId);
  }

  function _mint(address account, uint256 id, uint256 amount, bytes memory data) internal virtual override {
      if (amount == 0) revert InvalidAmount(amount);
      if (totalSupply[id] + amount > maxSupply[id]) revert CapExceeded(totalSupply[id] + amount, maxSupply[id]);

      totalSupply[id] += amount;
      super._mint(account, id, amount, data);
  }

  function _mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) internal virtual override {
      if (ids.length != amounts.length) revert InvalidParametersNumber(ids.length, amounts.length);
      if (ids.length == 0) revert InvalidParameters(ids.length);

      for (uint256 i = 0; i < ids.length; i++) {
          if (amounts[i] == 0) revert InvalidSupply(amounts[i]);
          uint256 tokenId = ids[i];
          if (totalSupply[tokenId] + amounts[i] > maxSupply[tokenId]) revert CapExceeded(totalSupply[tokenId] + amounts[i], maxSupply[tokenId]);
          totalSupply[tokenId] += amounts[i];
      }
      super._mintBatch(to, ids, amounts, data);
  }

  function _burn(address from, uint256 id, uint256 amount) internal virtual override {
    totalSupply[id] -= amount;
    super._burn(from, id, amount);
  }
}