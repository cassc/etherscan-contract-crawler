// SPDX-License-Identifier: MIT
pragma solidity =0.8.12;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "../../interfaces/IMintableERC721S.sol";
import "./ERC721S.sol";

/**
 * @notice ERC721S-compliant contract with added
 *         function for minting new NFTs to addresses.
 */
contract MintableERC721S is ERC721S, IMintableERC721S, AccessControl, Ownable {
  using Address for address;
  using Strings for uint256;

  /**
   * @dev Smart contract unique identifier, a random number
   *
   * @dev Should be regenerated each time smart contact source code is changed
   *      and changes smart contract itself is to be redeployed
   *
   * @dev Generated using https://www.random.org/bytes/
   */
  uint256 public constant UID = 0x3f38351a8d513731422d6b64f354f3cf7ea9ae952d15c73513da3b92754e778f;

  bytes32 public constant URI_MANAGER_ROLE = keccak256("URI_MANAGER_ROLE");
  bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

  constructor(string memory _name, string memory _symbol) ERC721S(_name, _symbol) {
    _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _setupRole(URI_MANAGER_ROLE, msg.sender);
    _setupRole(MINTER_ROLE, msg.sender);
  }

  string internal theBaseURI = "";

  function _baseURI() internal view virtual override returns (string memory) {
    return theBaseURI;
  }

  /**
   * @dev Fired in setBaseURI()
   *
   * @param _by an address which executed update
   * @param _oldVal old _baseURI value
   * @param _newVal new _baseURI value
   */
  event BaseURIChanged(address _by, string _oldVal, string _newVal);
 
  /**
   * @dev Restricted access function which updates base URI used to construct
   *      ERC721Metadata.tokenURI
   *
   * @param _newBaseURI new base URI to set
   */
  function setBaseURI(string memory _newBaseURI) external onlyRole(URI_MANAGER_ROLE) {
    // Fire event
    emit BaseURIChanged(msg.sender, theBaseURI, _newBaseURI);

    // Update base uri
    theBaseURI = _newBaseURI;
  }

  /**
   * @inheritdoc IMintableERC721S
   */
  function exists(uint256 _tokenId) external view returns (bool) {
    // Delegate to internal OpenZeppelin function
    return _exists(_tokenId);
  }

  /**
   * @inheritdoc IMintableERC721S
   */
  function safeMint(address _to, bool _amount) public virtual onlyRole(MINTER_ROLE) {
    _safeMint(_to, _amount);
  }

  /**
   * @inheritdoc IMintableERC721S
   */
  function safeMint(
    address _to,
    bool _amount,
    bytes memory _data
  ) public virtual onlyRole(MINTER_ROLE) {
    _safeMint(_to, _amount, _data);
  }

  /**
   * @inheritdoc IMintableERC721S
   */
  function mint(address _to, bool _amount) public virtual onlyRole(MINTER_ROLE) {
    // Delegate to internal OpenZeppelin function
    _mint(_to, _amount);
  }

  /**
   * @dev See {IERC165-supportsInterface}.
   */
  function supportsInterface(bytes4 _interfaceId) public view override(ERC721S, AccessControl) returns (bool) {
    return _interfaceId == type(IMintableERC721S).interfaceId || super.supportsInterface(_interfaceId);
  }
}