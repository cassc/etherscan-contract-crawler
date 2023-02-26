// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "solmate/src/tokens/ERC721.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "./interfaces/IBabes.sol";

contract Babes is IBabes, Ownable, ERC721, ERC2981 {
  // EVENTS *****************************************************

  event ConfigUpdated(bytes32 config, bytes value);
  event ConfigLocked(bytes32 config);

  // ERRORS *****************************************************

  error InvalidConfig(bytes32 config);
  error ConfigIsLocked(bytes32 config);
  error Unauthorized();
  error NonExistentToken(uint256 tokenId);

  // Storage *****************************************************

  /// @notice Maximum tokenId that can be minted
  uint256 public constant TOKEN_LIMIT = 101;

  /// @notice Address approved to mint tokens in this contract
  address public approvedMinter;

  /// @notice BaseURI for token metadata
  string public baseURI = "ipfs://bafybeigvjsxzoq3zrp5gaptgxeptd5a75kddzg3l3yvlzit2kzdw5smrfy/";

  /// @notice Contract metadata URI
  string public contractURI = "ipfs://bafkreiea6sdtrmwizoftolktj24ott3fwgzzmdi2oi46jp2lj56adjn2li";

  mapping(bytes32 => bool) configLocked;

  // Constructor *****************************************************

  constructor() ERC721("101 BABES", "BABE") {
    _setDefaultRoyalty(0x19461698453e26b98ceE5B984e1a86e13C0f68Be, 1000); // 10% royalties
  }

  // Modifiers *****************************************************

  modifier onlyApprovedMinter() {
    if (msg.sender != approvedMinter) revert Unauthorized();
    _;
  }

  // Owner Methods *****************************************************

  function updateConfig(bytes32 config, bytes calldata value) external onlyOwner {
    if (configLocked[config]) revert ConfigIsLocked(config);

    if (config == "baseURI") baseURI = abi.decode(value, (string));
    else if (config == "contractURI") contractURI = abi.decode(value, (string));
    else if (config == "minter") approvedMinter = abi.decode(value, (address));
    else if (config == "royalty") {
      (address recipient, uint96 numerator) = abi.decode(value, (address, uint96));
      _setDefaultRoyalty(recipient, numerator);
    } else revert InvalidConfig(config);

    emit ConfigUpdated(config, value);
  }

  function lockConfig(bytes32 config) external onlyOwner {
    configLocked[config] = true;

    emit ConfigLocked(config);
  }

  // Restricted Methods *****************************************************

  function mint(address to, uint256[] calldata tokenIds) external onlyApprovedMinter {
    unchecked {
      for (uint256 i = 0; i < tokenIds.length; i++) {
        if (tokenIds[i] > TOKEN_LIMIT) revert NonExistentToken(tokenIds[i]);

        _mint(to, tokenIds[i]);
      }
    }
  }

  // Override Methods *****************************************************

  /// @notice Returns the metadata URI for a given token
  function tokenURI(uint256 tokenId) public view override returns (string memory) {
    if (_ownerOf[tokenId] == address(0)) revert NonExistentToken(tokenId);

    return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, Strings.toString(tokenId))) : "";
  }

  function supportsInterface(bytes4 interfaceId) public view override(ERC2981, ERC721) returns (bool) {
    return ERC721.supportsInterface(interfaceId) || ERC2981.supportsInterface(interfaceId);
  }
}