// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/// @title iRouterCrossTalk contract interface for router Crosstalk
/// @author Router Protocol
interface iRouterCrossTalk is IERC165 {
  struct ExecutesStruct {
    uint8 chainID;
    uint64 nonce;
  }

  /// @notice Link event is emitted when a new link is created.
  /// @param ChainID Chain id the contract is linked to.
  /// @param linkedContract Contract address linked to.
  event Linkevent(uint8 indexed ChainID, address indexed linkedContract);

  /// @notice UnLink event is emitted when a link is removed.
  /// @param ChainID Chain id the contract is unlinked to.
  /// @param linkedContract Contract address unlinked to.
  event Unlinkevent(uint8 indexed ChainID, address indexed linkedContract);

  /// @notice CrossTalkSend Event is emited when a request is generated in soruce side when cross chain request is generated.
  /// @param sourceChain Source ChainID.
  /// @param destChain Destination ChainID.
  /// @param sourceAddress Source Address.
  /// @param destinationAddress Destination Address.
  /// @param _selector Selector to interface on destination side.
  /// @param _data Data to interface on Destination side.
  /// @param _hash Hash of the data sent.
  event CrossTalkSend(
    uint8 indexed sourceChain,
    uint8 indexed destChain,
    address sourceAddress,
    address destinationAddress,
    bytes4 indexed _selector,
    bytes _data,
    bytes32 _hash
  );

  /// @notice CrossTalkReceive Event is emited when a request is recived in destination side when cross chain request accepted by contract.
  /// @param sourceChain Source ChainID.
  /// @param destChain Destination ChainID.
  /// @param sourceAddress Address of source contract.
  event CrossTalkReceive(
    uint8 indexed sourceChain,
    uint8 indexed destChain,
    address sourceAddress
  );

  /// @notice routerSync This is a public function and can only be called by Generic Handler of router infrastructure
  /// @param srcChainID Source ChainID.
  /// @param srcAddress Destination ChainID.
  /// @param data Data to interface on Destination side.
  // /// @param hash Hash of the data sent.
  function routerSync(
    uint8 srcChainID,
    address srcAddress,
    bytes calldata data
  )
    external
    returns (
      // bytes32 hash
      bool,
      bytes memory
    );

  /// @notice Link This is a public function and can only be called by Generic Handler of router infrastructure
  /// @notice This function links contract on other chain ID's.
  /// @notice This is an administrative function and can only be initiated by linkSetter address.
  /// @param _chainID network Chain ID linked Contract linked to.
  /// @param _linkedContract Linked Contract address.
  function Link(uint8 _chainID, address _linkedContract) external;

  /// @notice UnLink This is a public function and can only be called by Generic Handler of router infrastructure
  /// @notice This function unLinks contract on other chain ID's.
  /// @notice This is an administrative function and can only be initiated by linkSetter address.
  /// @param _chainID network Chain ID linked Contract linked to.
  function Unlink(uint8 _chainID) external;

  /// @notice fetchLinkSetter This is a public function and fetches the linksetter address.
  function fetchLinkSetter() external view returns (address);

  /// @notice fetchLinkSetter This is a public function and fetches the address the contract is linked to.
  /// @param _chainID Chain ID information.
  function fetchLink(uint8 _chainID) external view returns (address);

  /// @notice fetchLinkSetter This is a public function and fetches the generic handler address.
  function fetchHandler() external view returns (address);

  /// @notice fetchFeeToken This is a public function and fetches the fee token set by admin.
  function fetchFeeToken() external view returns (address);

  /// @notice fetchExecutes This is a public function and fetches the executes struct.
  function fetchExecutes(bytes32 _hash)
    external
    view
    returns (ExecutesStruct memory);
}