// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "erc721a/contracts/extensions/IERC721ABurnable.sol";

contract OrdinalsBurnRegistry {
  /// @notice Contract to register ordinals burns for
  IERC721ABurnable public burnableContract;

  /// @notice Stored burn data
  mapping(uint256 => OrdinalsBurnDetails) public burnDetails;

  /// @notice Burn details
  struct OrdinalsBurnDetails {
    /// @notice Token ID in the ETH contract (Not Ordinals ID)
    uint256 tokenId;
    /// @notice ETH address of the NFT contract
    address contractAddress;
    /// @notice ETH address of the owner
    address ownerEthAddress;
    /// @notice Target ordinals address of the owner
    string ownerOrdinalsAddress;
    /// @notice Whether token is burned or not
    bool burned;
  }

  /// @notice Event emitted when a token is burned
  /// @param tokenId Token ID in the ETH contract (Not Ordinals ID)
  /// @param contractAddress ETH address of the NFT contract
  /// @param ownerEthAddress ETH address of the owner
  /// @param ownerOrdinalsAddress Target ordinals address of the owner
  event OrdinalsBurned(
    uint256 indexed tokenId,
    address indexed contractAddress,
    address ownerEthAddress,
    string ownerOrdinalsAddress
  );

  constructor(address contractAddress) {
    burnableContract = IERC721ABurnable(contractAddress);
  }

  /// @notice Burns the given token ID, registers the burn details and emits a OrdinalsBurned event
  /// @param tokenId Token ID to be burned
  /// @param ordinalsAddress Target ordinals address to receive the ordinal
  function burn(uint256 tokenId, string calldata ordinalsAddress) public {
    burnableContract.burn(tokenId);

    OrdinalsBurnDetails storage b = burnDetails[tokenId];

    b.tokenId = tokenId;
    b.contractAddress = address(burnableContract);
    b.ownerEthAddress = msg.sender;
    b.ownerOrdinalsAddress = ordinalsAddress;
    b.burned = true;

    emit OrdinalsBurned(
      tokenId,
      address(burnableContract),
      msg.sender,
      ordinalsAddress
    );
  }

  /// @notice Batch burns the given token IDs, registers the burn details and emits OrdinalsBurned events
  /// @param tokenIds Token IDs to be burned
  /// @param ordinalsAddresses Target ordinals addresses to receive the ordinal
  function burnBatch(
    uint256[] calldata tokenIds,
    string[] calldata ordinalsAddresses
  ) external {
    require(
      tokenIds.length == ordinalsAddresses.length,
      "Param arrays must be the same length"
    );
    for (uint256 i = 0; i < tokenIds.length; i++) {
      burn(tokenIds[i], ordinalsAddresses[i]);
    }
  }
}