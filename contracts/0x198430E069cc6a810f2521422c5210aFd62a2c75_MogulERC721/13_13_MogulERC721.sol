// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract MogulERC721 is ERC721URIStorage, AccessControl {
  bytes32 public constant ROLE_ADMIN = keccak256("ROLE_ADMIN");
  uint256 public totalSupply;

  modifier onlyAdmin() {
    require(hasRole(ROLE_ADMIN, msg.sender), "Sender is not admin");
    _;
  }

  constructor() ERC721("MogulERC721", "mNFT") {}

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

  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(ERC721, AccessControl)
    returns (bool)
  {
    return
      interfaceId == type(IERC721).interfaceId ||
      super.supportsInterface(interfaceId);
  }

  function mintToken(
    address to,
    uint256 id,
    string memory tokenURI
  ) external onlyAdmin {
    require(bytes(tokenURI).length > 0, "MogulNFT#mint: URI_REQUIRED");

    _mint(to, id);
    _setTokenURI(id, tokenURI);
    totalSupply += 1;
  }

  function mintBatch(
    address[] memory recipients,
    uint256[] memory ids,
    string[] memory tokenURIs
  ) external onlyAdmin {
    require(
      recipients.length == ids.length && ids.length == tokenURIs.length,
      "Incorrect input lengths"
    );

    for (uint256 j = 0; j < recipients.length; j++) {
      require(bytes(tokenURIs[j]).length > 0, "MogulNFT#mint: URI_REQUIRED");

      _mint(recipients[j], ids[j]);
      _setTokenURI(ids[j], tokenURIs[j]);
    }

    totalSupply += recipients.length;
  }
}