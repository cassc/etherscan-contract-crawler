// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

import "@imtbl/imx-contracts/contracts/Mintable.sol";
import "@imtbl/imx-contracts/contracts/utils/Minting.sol";

/**
 * @dev {ERC721} token, including:
 */
contract NiftyItemL2 is ERC721EnumerableUpgradeable, OwnableUpgradeable, PausableUpgradeable, IMintable {
  using StringsUpgradeable for uint256;

  /// @dev Token URI
  string public uri;

  /// @dev IMX address
  address public imx;

  /// @dev TokenID -> Item ID
  /// @dev ItemID1 - item 1, ItemID 2 - item 2, ,,,, ItemID 6 - item6, ItemID 7 - key
  mapping(uint256 => uint256) public itemIdByTokenId;

  event AssetMinted(address to, uint256 id, bytes blueprint);

  modifier onlyOwnerOrIMX() {
    require(msg.sender == imx || msg.sender == owner(), "Function can only be called by owner or IMX");
    _;
  }

  function initialize(address _imx) external initializer {
    __ERC721_init("NiftyItemL2", "NiftyItemL2");
    __Ownable_init();
    __Pausable_init();

    imx = _imx;
  }

  function mintFor(
    address _to,
    uint256 _quantity,
    bytes calldata _mintingBlob
  ) external override onlyOwnerOrIMX whenNotPaused {
    require(_quantity == 1, "Amount must be 1");
    (uint256 id, bytes memory blueprint) = Minting.split(_mintingBlob);
    _mint(_to, id, blueprint);

    emit AssetMinted(_to, id, blueprint);
  }

  function _mint(
    address _to,
    uint256 _tokenId,
    bytes memory blueprint
  ) internal {
    uint256 itemId = Bytes.toUint(blueprint);
    itemIdByTokenId[_tokenId] = itemId;

    _safeMint(_to, _tokenId);
  }

  function setURI(string calldata _uri) external onlyOwner {
    uri = _uri;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return uri;
  }

  function burn(uint256 _tokenId) external whenNotPaused {
    _burn(_tokenId);
  }

  function pause() public onlyOwner {
    _pause();
  }

  function unpause() public onlyOwner {
    _unpause();
  }
}