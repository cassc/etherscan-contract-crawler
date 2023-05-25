// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/IERC677.sol";
import "./interfaces/IERC677Receiver.sol";
import "@openzeppelin/contracts/token/ERC777/ERC777.sol";

abstract contract ERC677 is ERC777, IERC677 {
  /**
  * @dev transfer token to a contract address with additional data if the recipient is a contact.
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  * @param _data The extra data to be passed to the receiving contract.
  */
  function transferAndCall(address _to, uint _value, bytes calldata _data)
    public
    override
    returns (bool success)
  {
    super.transfer(_to, _value);
    emit TransferWithData(msg.sender, _to, _value, _data);
    if (isContract(_to)) {
      contractFallback(_to, _value, _data);
    }
    return true;
  }

  function contractFallback(address _to, uint _value, bytes calldata _data)
    private
  {
    IERC677Receiver receiver = IERC677Receiver(_to);
    receiver.onTokenTransfer(msg.sender, _value, _data);
  }

  function isContract(address _addr)
    private
    view
    returns (bool hasCode)
  {
    uint length;
    assembly { length := extcodesize(_addr) }
    return length > 0;
  }
}