// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165Upgradeable.sol";

import "./interfaces/iGenericHandler.sol";
import "./interfaces/iRouterCrossTalkUpgradeable.sol";

/// @title RouterCrossTalkUpgradeable contract
/// @author Router Protocol
abstract contract RouterCrossTalkUpgradeable is
  Initializable,
  ContextUpgradeable,
  iRouterCrossTalkUpgradeable,
  ERC165Upgradeable
{
  using SafeERC20Upgradeable for IERC20Upgradeable;
  iGenericHandler private handler;

  address private linkSetter;

  address private feeToken;

  mapping(uint8 => address) private Chain2Addr; // CHain ID to Address

  mapping(bytes32 => ExecutesStruct) private executes;

  modifier isHandler() {
    require(
      _msgSender() == address(handler),
      "RouterSync : Only GenericHandler can call this function"
    );
    _;
  }

  modifier isLinkSet(uint8 _chainID) {
    require(
      Chain2Addr[_chainID] == address(0),
      "RouterSync : Cross Chain Contract to Chain ID set"
    );
    _;
  }

  modifier isLinkUnSet(uint8 _chainID) {
    require(
      Chain2Addr[_chainID] != address(0),
      "RouterCrossTalk : Cross Chain Contract to Chain ID is not set"
    );
    _;
  }

  modifier isLinkSync(uint8 _srcChainID, address _srcAddress) {
    require(
      Chain2Addr[_srcChainID] == _srcAddress,
      "RouterSync : Source Address Not linked"
    );
    _;
  }

  modifier isSelf() {
    require(
      _msgSender() == address(this),
      "RouterCrossTalk : Can only be called by Current Contract"
    );
    _;
  }

  function __RouterCrossTalkUpgradeable_init(address _handler)
    internal
    initializer
  {
    __Context_init_unchained();

    handler = iGenericHandler(_handler);
  }

  function __RouterCrossTalkUpgradeable_init_unchained() internal initializer {}

  ///  @notice Used to set linker address, this function is internal and can only be set by contract owner or admins
  /// @param _addr Address of linker.
  function setLink(address _addr) internal {
    linkSetter = _addr;
  }

  /// @notice Used to set fee Token address, this function is internal and can only be set by contract owner or admins
  /// @param _addr Address of linker.
  function setFeeToken(address _addr) internal {
    feeToken = _addr;
  }

  function fetchHandler() external view override returns (address) {
    return address(handler);
  }

  function fetchLinkSetter() external view override returns (address) {
    return linkSetter;
  }

  function fetchLink(uint8 _chainID) external view override returns (address) {
    return Chain2Addr[_chainID];
  }

  function fetchFeeToken() external view override returns (address) {
    return feeToken;
  }

  function fetchExecutes(bytes32 hash)
    external
    view
    override
    returns (ExecutesStruct memory)
  {
    return executes[hash];
  }

  /// @notice routerSend This is internal function to generate a cross chain communication request.
  /// @param destChainId Destination ChainID.
  /// @param _selector Selector to interface on destination side.
  /// @param _data Data to be sent on Destination side.
  /// @param _gasLimit Gas limit provided for cross chain send.
  /// @param _gasPrice Gas price provided for cross chain send.
  function routerSend(
    uint8 destChainId,
    bytes4 _selector,
    bytes memory _data,
    uint256 _gasLimit,
    uint256 _gasPrice
  ) internal isLinkUnSet(destChainId) returns (bool, bytes32) {
    bytes memory data = abi.encode(_selector, _data);
    uint64 nonce = handler.genericDeposit(
      destChainId,
      data,
      _gasLimit,
      _gasPrice,
      feeToken
    );

    bytes32 hash = _hash(destChainId, nonce);

    executes[hash] = ExecutesStruct(destChainId, nonce);
    emitCrossTalkSendEvent(destChainId, _selector, _data, hash);

    return (true, hash);
  }

  function emitCrossTalkSendEvent(
    uint8 destChainId,
    bytes4 selector,
    bytes memory data,
    bytes32 hash
  ) private {
    emit CrossTalkSend(
      handler.fetch_chainID(),
      destChainId,
      address(this),
      Chain2Addr[destChainId],
      selector,
      data,
      hash
    );
  }

  function routerSync(
    uint8 srcChainID,
    address srcAddress,
    bytes memory data
  )
    external
    override
    isLinkSync(srcChainID, srcAddress)
    isHandler
    returns (bool, bytes memory)
  {
    uint8 cid = handler.fetch_chainID();
    (bytes4 _selector, bytes memory _data) = abi.decode(data, (bytes4, bytes));

    (bool success, bytes memory _returnData) = _routerSyncHandler(
      _selector,
      _data
    );
    emit CrossTalkReceive(srcChainID, cid, srcAddress);
    return (success, _returnData);
  }

  function routerReplay(
    bytes32 hash,
    uint256 _gasLimit,
    uint256 _gasPrice
  ) internal {
    handler.replayGenericDeposit(
      executes[hash].chainID,
      executes[hash].nonce,
      _gasLimit,
      _gasPrice
    );
  }

  /// @notice _hash This is internal function to generate the hash of all data sent or received by the contract.
  /// @param _destChainId Destination ChainID.
  /// @param _nonce Nonce for the tx.
  function _hash(uint8 _destChainId, uint64 _nonce)
    internal
    pure
    returns (bytes32)
  {
    return keccak256(abi.encode(_destChainId, _nonce));
  }

  function Link(uint8 _chainID, address _linkedContract)
    external
    override
    isHandler
    isLinkSet(_chainID)
  {
    Chain2Addr[_chainID] = _linkedContract;
    emit Linkevent(_chainID, _linkedContract);
  }

  function Unlink(uint8 _chainID) external override isHandler {
    emit Unlinkevent(_chainID, Chain2Addr[_chainID]);
    Chain2Addr[_chainID] = address(0);
  }

  function approveFees(address _feeToken, uint256 _value) internal {
    IERC20Upgradeable token = IERC20Upgradeable(_feeToken);
    token.approve(address(handler), _value);
  }

  /// @notice _routerSyncHandler This is internal function to control the handling of various selectors and its corresponding .
  /// @param _selector Selector to interface.
  /// @param _data Data to be handled.
  function _routerSyncHandler(bytes4 _selector, bytes memory _data)
    internal
    virtual
    returns (bool, bytes memory);

  uint256[100] private __gap;
}