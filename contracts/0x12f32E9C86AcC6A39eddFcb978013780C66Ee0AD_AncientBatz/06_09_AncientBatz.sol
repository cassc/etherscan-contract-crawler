// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "solmate/src/tokens/ERC721.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./ERC2981.sol";

contract AncientBatz is Ownable, ERC721, ERC2981 {
  // EVENTS *****************************************************

  event ConfigUpdated(bytes32 config, bytes value);
  event ConfigLocked(bytes32 config);

  // ERRORS *****************************************************

  error InvalidConfig(bytes32 config);
  error ConfigIsLocked(bytes32 config);
  error Unauthorized();
  error InvalidToken(uint256 tokenId);

  // Storage *****************************************************

  /// @notice Maximum tokenId that can be minted
  uint256 public constant TOKEN_LIMIT = 99;

  /// @notice Address approved to mint tokens in this contract
  address public approvedMinter;

  /// @notice BaseURI for token metadata
  string public baseURI = "ipfs://bafybeiclbswvs6xpnh5mu6biljn245wtesqc6ocxck6b2ehdmnpa4dgeh4/";

  /// @notice The number of bites that each AncientBat has, pseudo-randomly assigned at mint
  mapping(uint256 => uint256) public maxBites;

  mapping(bytes32 => bool) configLocked;

  // Constructor *****************************************************

  constructor() ERC721("AncientBatz", "ABATZ") {
    _setRoyalties(0xD53A0626f891a31Ae16ae73BE0D031A7Ba88a5Fc, 750); // 7.5% royalties
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
    else if (config == "minter") approvedMinter = abi.decode(value, (address));
    else if (config == "royalty") {
      (address recipient, uint256 numerator) = abi.decode(value, (address, uint256));
      _setRoyalties(recipient, numerator);
    } else revert InvalidConfig(config);

    emit ConfigUpdated(config, value);
  }

  function lockConfig(bytes32 config) external onlyOwner {
    configLocked[config] = true;

    emit ConfigLocked(config);
  }

  // Restricted Methods *****************************************************

  function mint(address to, uint256 tokenId) external onlyApprovedMinter {
    if (tokenId == 0 || tokenId > TOKEN_LIMIT) revert InvalidToken(tokenId);

    _mint(to, tokenId);

    maxBites[tokenId] = getRandomBiteLimit(tokenId);
  }

  /// @dev Returns a pseudo random number between 10 and 99
  function getRandomBiteLimit(uint256 seed) private view returns (uint256) {
    uint256 number = uint256(
      keccak256(abi.encodePacked(blockhash(block.number - 1), block.coinbase, block.timestamp, seed))
    );

    return (number % 90) + 10;
  }

  // Override Methods *****************************************************

  /// @notice Returns the metadata URI for a given token
  function tokenURI(uint256 tokenId) public view override returns (string memory) {
    if (_ownerOf[tokenId] == address(0)) revert InvalidToken(tokenId);

    return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, Strings.toString(tokenId))) : "";
  }

  function supportsInterface(bytes4 interfaceId) public view override(ERC2981, ERC721) returns (bool) {
    return ERC721.supportsInterface(interfaceId) || ERC2981.supportsInterface(interfaceId);
  }
}