// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "./interfaces/IMintableERC721.sol";

contract MintableERC721 is ERC721, ERC721Enumerable, IMintableERC721, AccessControl, Ownable {
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
	uint256 public constant UID = 0x3f38351a8d513731422d6b64f345dccf6ea9ae952d15c73513da3b92754e778f;

  bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
  bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");
  bytes32 public constant URI_MANAGER_ROLE = keccak256("URI_MANAGER_ROLE");

  constructor(string memory _name, string memory _symbol) ERC721(_name, _symbol) {
    _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _setupRole(MINTER_ROLE, msg.sender);
    _setupRole(BURNER_ROLE, msg.sender);
    _setupRole(URI_MANAGER_ROLE, msg.sender);
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
  event BaseURIChanged(
    address _by,
    string _oldVal,
    string _newVal
  );

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
   * @inheritdoc IMintableERC721
   */
  function exists(uint256 _tokenId) external view returns(bool) {
    // Delegate to internal OpenZeppelin function
    return _exists(_tokenId);
  }

  /**
   * @dev Destroys `tokenId`.
   * The approval is cleared when the token is burned.
   *
   * Requirements:
   *
   * - `tokenId` must exist.
   *
   * Emits a {Transfer} event.
   */
  function burn(uint256 _tokenId) public onlyRole(BURNER_ROLE) {
    // Delegate to internal OpenZeppelin burn function
    _burn(_tokenId);
  }

  /**
   * @inheritdoc IMintableERC721
   */
  function mint(address _to, uint256 _tokenId) public onlyRole(MINTER_ROLE) {
    // Delegate to internal OpenZeppelin function
    _mint(_to, _tokenId);
  }

  /**
   * @inheritdoc IMintableERC721
   */
  function mintBatch(address _to, uint256 _tokenId, uint256 _n) public onlyRole(MINTER_ROLE) {
    for(uint256 i = 0; i < _n; i++) {
      // Delegate to internal OpenZeppelin mint function
      _mint(_to, _tokenId + i);
    }
  }

  /**
   * @inheritdoc IMintableERC721
   */
  function safeMint(address _to, uint256 _tokenId, bytes memory _data) public onlyRole(MINTER_ROLE) {
    // Delegate to internal OpenZeppelin unsafe mint function
    _mint(_to, _tokenId);

    // If a contract, check if it can receive ERC721 tokens (safe to send)
    if(_to.isContract()) {
		  bytes4 response = IERC721Receiver(_to).onERC721Received(msg.sender, address(0), _tokenId, _data);

		  require(response == IERC721Receiver(_to).onERC721Received.selector, "Invalid onERC721Received response");
    }
  }

  /**
   * @inheritdoc IMintableERC721
   */
  function safeMint(address _to, uint256 _tokenId) public {
    // Delegate to internal safe mint function (includes permission check)
    safeMint(_to, _tokenId, "");
  }

  /**
   * @inheritdoc IMintableERC721
   */
  function safeMintBatch(address _to, uint256 _tokenId, uint256 _n, bytes memory _data) public {
    // Delegate to internal unsafe batch mint function (includes permission check)
    mintBatch(_to, _tokenId, _n);

    // If a contract, check if it can receive ERC721 tokens (safe to send)
    if(_to.isContract()) {
		  bytes4 response = IERC721Receiver(_to).onERC721Received(msg.sender, address(0), _tokenId, _data);

		  require(response == IERC721Receiver(_to).onERC721Received.selector, "Invalid onERC721Received response");
    }
  }

  /**
   * @inheritdoc IMintableERC721
   */
  function safeMintBatch(address _to, uint256 _tokenId, uint256 _n) external {
    // Delegate to internal safe batch mint function (includes permission check)
    safeMintBatch(_to, _tokenId, _n, "");
  }

  /**
   * @inheritdoc ERC721
   */
  function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable, AccessControl) returns (bool) {
    return interfaceId == type(IMintableERC721).interfaceId || super.supportsInterface(interfaceId);
  }

  /**
   * @inheritdoc ERC721
   */
  function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override(ERC721, ERC721Enumerable) {
    super._beforeTokenTransfer(from, to, tokenId);
  }
}