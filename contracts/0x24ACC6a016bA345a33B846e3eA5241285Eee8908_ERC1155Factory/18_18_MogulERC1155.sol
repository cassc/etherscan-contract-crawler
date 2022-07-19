// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract MogulERC1155 is ERC1155Burnable, AccessControl {
  using SafeMath for uint256;

  bytes32 public constant ROLE_ADMIN = keccak256("ROLE_ADMIN");
  mapping(uint256 => string) tokenURIs;
  uint256 public totalSupply;

  modifier onlyAdmin() {
    require(hasRole(ROLE_ADMIN, msg.sender), "Sender is not admin");
    _;
  }

  constructor() ERC1155("") {}

  /**
     * @dev Allows users with the admin role to
     * grant/revoke the admin role from other users

     * Params:
     * _admin: address of the first admin
     */
  bool initialized = false;

  function init(address _admin) public {
    require(!initialized, "cannot be initialized already");
    initialized = true;
    _setupRole(ROLE_ADMIN, _admin);
    _setRoleAdmin(ROLE_ADMIN, ROLE_ADMIN);
  }

  //Allows contract to inherit both ERC1155 and Accesscontrol
  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(ERC1155, AccessControl)
    returns (bool)
  {
    return
      interfaceId == type(IERC1155).interfaceId ||
      interfaceId == type(IERC1155MetadataURI).interfaceId ||
      super.supportsInterface(interfaceId);
  }

  function uri(uint256 id) public view override returns (string memory) {
    return tokenURIs[id];
  }

  /**
     * @dev Mint a new ERC1155 Token

     * Params:
     * recipient: recipient of the new tokens
     * tokenId: the id of the token
     * amount: amount to mint
     * data: data
     */
  function mintToken(
    address recipient,
    uint256 tokenId,
    uint256 amount,
    string memory URI,
    bytes calldata data
  ) external onlyAdmin {
    require(bytes(URI).length > 0, "MogulERC1155#mint: URI_REQUIRED");
    require(
      bytes(tokenURIs[tokenId]).length == 0,
      "MogulERC1155#mint: ID_EXISTS"
    );

    tokenURIs[tokenId] = URI;
    totalSupply += amount;
    _mint(recipient, tokenId, amount, data);
  }

  function mintBatch(
    address to,
    uint256[] memory tokenIds,
    uint256[] memory amounts,
    string[] memory URIs,
    bytes calldata data
  ) external onlyAdmin {
    for (uint256 j = 0; j < amounts.length; j++) {
      require(
        bytes(URIs[j]).length > 0,
        "MogulERC1155#mintBatch: URI_REQUIRED"
      );
      require(
        bytes(tokenURIs[tokenIds[j]]).length == 0,
        "MogulERC1155#mintBatch: ID_EXISTS"
      );
      tokenURIs[tokenIds[j]] = URIs[j];
      totalSupply += amounts[j];
    }

    _mintBatch(to, tokenIds, amounts, data);
  }

  function mintBatchMultipleRecipients(
    address[] memory to,
    uint256[] memory tokenIds,
    uint256[] memory amounts,
    string[] memory URIs,
    uint256[] memory numRecipientsPerToken,
    bytes calldata data
  ) external onlyAdmin {
    require(
      tokenIds.length == numRecipientsPerToken.length,
      "MogulERC1155#mintBatchMultipleRecipients: ids length mismatch"
    );
    require(
      URIs.length == numRecipientsPerToken.length,
      "MogulERC1155#mintBatchMultipleRecipients: URIs length mismatch"
    );

    uint256 counter = 0;
    for (uint256 i = 0; i < numRecipientsPerToken.length; i++) {
      require(
        bytes(URIs[i]).length > 0,
        "MogulERC1155#mintBatch: URI_REQUIRED"
      );
      require(
        bytes(tokenURIs[tokenIds[i]]).length == 0,
        "MogulERC1155#mintBatch: ID_EXISTS"
      );

      tokenURIs[tokenIds[i]] = URIs[i];
      totalSupply += amounts[i];

      for (uint256 j = 0; j < numRecipientsPerToken[i]; j++) {
        _mint(to[counter], tokenIds[i], amounts[counter], data);
        counter++;
      }
    }

    require(
      to.length == counter,
      "MogulERC1155#mintBatchMultipleRecipients: to length mismatch"
    );
    require(
      amounts.length == counter,
      "MogulERC1155#mintBatchMultipleRecipients: amounts length mismatch"
    );
  }
}