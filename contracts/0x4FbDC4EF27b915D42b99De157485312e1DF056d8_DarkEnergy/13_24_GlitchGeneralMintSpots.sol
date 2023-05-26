// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC721.sol";
import "../util/OwnableAndAdministrable.sol";
import "../libraries/UriEncode.sol";

contract GlitchGeneralMintSpots is ERC721, OwnableAndAdministrable {
  using Strings for uint256;
  using UriEncode for string;

  /**
   * @dev Revert if the royalty basis points is greater than 10_000.
     */
  error InvalidRoyaltyBasisPoints(uint256 basisPoints);

  /**
   * @dev Revert if the royalty address is being set to the zero address.
     */
  error RoyaltyAddressCannotBeZeroAddress();

  /**
   * @dev Emit an event when the royalties info is updated.
   */
  event RoyaltyInfoUpdated(address receiver, uint256 bps);

  /**
   * @notice A struct defining royalty info for the contract.
   */
  struct RoyaltyInfo {
    address royaltyAddress;
    uint96 royaltyBps;
  }

  /// @notice Track the royalty info: address to receive royalties, and
  ///         royalty basis points.
  RoyaltyInfo _royaltyInfo;

  uint256 private _tokenIdCounter = 1;
  mapping(uint256 => uint256) private _tokenSize;

  event MetadataUpdate(uint256 _tokenId);

  address public darkEnergyContract;

  constructor() ERC721("Glitchs Army: The Generals mint spot", "GMS") {
    _setOwner(tx.origin);
    _setRole(tx.origin, 0, true);
    _setRole(msg.sender, 0, true);
    _royaltyInfo.royaltyBps = 500;
    _royaltyInfo.royaltyAddress = tx.origin;
    darkEnergyContract = msg.sender;
  }

  /**
   * @notice Returns whether the interface is supported.
   *
   * @param interfaceId The interface id to check against.
   */
  function supportsInterface(
    bytes4 interfaceId
  ) public view virtual override(ERC721) returns (bool) {
    return
    interfaceId == 0x01ffc9a7 || // ER165
    interfaceId == 0x80ac58cd || // ERC721
    interfaceId == 0x5b5e139f || // ERC721-Metadata
    interfaceId == 0x2a55205a;   // ERC2981
  }

  /**
   * @notice Sets the address and basis points for royalties.
   *
   * @param newInfo The struct to configure royalties.
   */
  function setRoyaltyInfo(RoyaltyInfo calldata newInfo) external {
    // Ensure the sender is only the owner or contract itself.
    _checkRoleOrOwner(msg.sender, 1);

    // Revert if the new royalty address is the zero address.
    if (newInfo.royaltyAddress == address(0)) {
      revert RoyaltyAddressCannotBeZeroAddress();
    }

    // Revert if the new basis points is greater than 10_000.
    if (newInfo.royaltyBps > 10_000) {
      revert InvalidRoyaltyBasisPoints(newInfo.royaltyBps);
    }

    // Set the new royalty info.
    _royaltyInfo = newInfo;

    // Emit an event with the updated params.
    emit RoyaltyInfoUpdated(newInfo.royaltyAddress, newInfo.royaltyBps);
  }

  /**
   * @notice Returns the address that receives royalties.
   */
  function royaltyAddress() external view returns (address) {
    return _royaltyInfo.royaltyAddress;
  }

  /**
   * @notice Returns the royalty basis points out of 10_000.
   */
  function royaltyBasisPoints() external view returns (uint256) {
    return _royaltyInfo.royaltyBps;
  }

  /**
   * @notice Called with the sale price to determine how much royalty
   *         is owed and to whom.
   *
   * @return receiver      Address of who should be sent the royalty payment.
   * @return royaltyAmount The royalty payment amount for _salePrice.
   */
  function royaltyInfo(
    uint256,
    uint256 _salePrice
  ) external view returns (address receiver, uint256 royaltyAmount) {
    royaltyAmount = (_salePrice * _royaltyInfo.royaltyBps) / 10_000;
    receiver = _royaltyInfo.royaltyAddress;
  }

  function adminMint(address to, uint256 tokenId, uint256 size) external {
    _checkRoleOrOwner(msg.sender, 0);
    if(tokenId == _tokenIdCounter) {
      _tokenIdCounter++;
    }
    _tokenSize[tokenId] = size;
    _safeMint(to, tokenId);
  }

  function adminBurn(uint256 tokenId) external {
    _checkRoleOrOwner(msg.sender, 0);
    _burn(tokenId);
  }

  function adminSetTokenSize(uint256 tokenId, uint256 size) external {
    _checkRoleOrOwner(msg.sender, 0);
    _requireMinted(tokenId);
    _tokenSize[tokenId] = size;
    emit MetadataUpdate(tokenId);
  }

  function nextId() external view returns(uint256) {
    return _tokenIdCounter;
  }

  function tokenURI(uint256 tokenId) public view override returns(string memory) {
    _requireMinted(tokenId);
    uint256 size = _tokenSize[tokenId];
    uint256 center = 500;
    bytes6 color = bytes6(bytes("DDC159"));
    bytes6 background = bytes6(bytes("0B0B0B"));

    string memory svgData = string(abi.encodePacked(
        "<svg viewBox='0 0 1e3 1e3' xmlns='http://www.w3.org/2000/svg'><defs><radialGradient id='a' cx='500' cy='",
        center.toString(),
        "' r='",
        size.toString(),
        "' gradientUnits='userSpaceOnUse'><stop stop-color='#fff' stop-opacity='.6' offset='.17'/><stop stop-color='#fff' stop-opacity='0' offset='1'/></radialGradient></defs><circle cx='500' cy='",
        center.toString(),
        "' r='",
        size.toString(),
        "' fill='#",
        color,
        "'/><circle id='cg' cx='500' cy='",
        center.toString(),
        "' r='",
        size.toString(),
        "' fill='url(#a)' opacity='0'/><style>svg{background:#",
        background,
        "}#cg{-webkit-animation:1.5s ease-in-out infinite alternate p;animation:1.5s ease-in-out infinite alternate p}@-webkit-keyframes p{to{opacity:1}}@keyframes p{to{opacity:1}}</style></svg>"
      ));

    return string(
      abi.encodePacked(
        'data:application/json,{"name":"Glitch\'s Army: The Generals mint spot #',
        tokenId.toString(),
        '","image_data":"',
        svgData,
        '"}'
      )
    ).uriEncode();
  }

  function contractURI() external pure returns(string memory) {
    return string(abi.encodePacked(
      'data:application/json,{"name": "Glitch\'s Army: The Generals mint spot"}'
    )).uriEncode();
  }
}