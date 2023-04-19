// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";

interface IMintSpot is IERC721Metadata {
  function adminBurn(uint256 tokenId) external;
}

contract GlitchOrdinalsScrivener {
  error InvalidTaprootAddress();
  error CallerNotHolder();
  error TaprootAddressAlreadySaved();
  event TaprootAddressSaved(address indexed holder, uint256 indexed tokenId, bytes32 indexed taprootAddressHash);
  address public mintSpotsAddress;
  mapping(bytes32 => bool) public submittedTaprootAddressHashes;

  constructor(address _mintSpotAddress) {
    mintSpotsAddress = _mintSpotAddress;
  }

  /**
   * Enforce the following regex: /^bc1[0-9a-z]{39,59}$/
   */
  function _validateTaprootAddress(string calldata taprootAddress) internal pure {
    bytes calldata input = bytes(taprootAddress);
    uint256 length = input.length;
    if (length < 42 || length > 62) {
      revert InvalidTaprootAddress();
    }
    for (uint256 i = 0; i < length; i++) {
      uint8 char = uint8(input[i]);
      if (
        i == 0 && char != 0x62 || // 'b'
        i == 1 && char != 0x63 || // 'c'
        i == 2 && char != 0x31    // '1'
      ) {
        revert InvalidTaprootAddress();
      }
      if (
        char < 0x30 ||
        char > 0x7a ||
        (char > 0x39 && char < 0x61)
      ) {
        revert InvalidTaprootAddress();
      }
    }
  }

  function submitTaprootWallet(uint256 tokenId, string calldata taprootAddress) external {
    IMintSpot mintSpots = IMintSpot(mintSpotsAddress);
    address owner = mintSpots.ownerOf(tokenId);
    if (owner != msg.sender) {
      revert CallerNotHolder();
    }
    _validateTaprootAddress(taprootAddress);
    bytes32 hash = keccak256(abi.encodePacked(taprootAddress));
    if (submittedTaprootAddressHashes[hash]) {
      revert TaprootAddressAlreadySaved();
    }
    submittedTaprootAddressHashes[hash] = true;
    IMintSpot(mintSpots).adminBurn(tokenId);
    emit TaprootAddressSaved(msg.sender, tokenId, hash);
  }
}