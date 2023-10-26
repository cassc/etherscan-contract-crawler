// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import "src/interfaces/IERC721.sol";

import "src/commons/receiver/ReceiverHub.sol";
import "src/commons/Permissions.sol";
import "src/commons/Pausable.sol";

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";


abstract contract VaultERC721 is Initializable, ReceiverHub, Permissions, Pausable {
  uint8 public PERMISSION_SEND_ERC721;

  error ArrayLengthMismatchERC721(uint256 _array1, uint256 _array2, uint256 _array3);


  function __initializeERC721(uint8 _sendErc721Permission) internal onlyInitializing  {
    PERMISSION_SEND_ERC721 = _sendErc721Permission;

    __initializeReceiverHub();

    _registerPermission(PERMISSION_SEND_ERC721);
  }

  function sendERC721(
    IERC721 _token,
    uint256 _from,
    address _to,
    uint256 _id
  ) external notPaused onlyPermissioned(PERMISSION_SEND_ERC721) {
    Receiver receiver = useReceiver(_from);

    executeOnReceiver(receiver, address(_token), 0, abi.encodeWithSelector(
        _token.transferFrom.selector,
        address(receiver),
        _to,
        _id
      )
    );
  }

  function sendBatchERC721(
    IERC721 _token,
    uint256[] calldata _ids,
    address[] calldata _tos,
    uint256[] calldata _tokenIds
  ) external notPaused onlyPermissioned(PERMISSION_SEND_ERC721) {
    unchecked {
      uint256 idsLength = _ids.length;

      if (idsLength != _tos.length || idsLength != _tokenIds.length) {
        revert ArrayLengthMismatchERC721(idsLength, _tos.length, _tokenIds.length);
      }

      for (uint256 i = 0; i < idsLength; ++i) {
        Receiver receiver = useReceiver(_ids[i]);
        executeOnReceiver(receiver, address(_token), 0, abi.encodeWithSelector(
            _token.transferFrom.selector,
            address(receiver),
            _tos[i],
            _tokenIds[i]
          )
        );
      }
    }
  }
}