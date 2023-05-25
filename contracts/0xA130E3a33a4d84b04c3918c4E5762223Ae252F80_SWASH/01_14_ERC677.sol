// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./IERC677.sol";
import "./IERC677Receiver.sol";


abstract contract ERC677 is ERC20, IERC677 {
  /**
   * @dev transfer token to a contract address with additional data if the recipient is a contact.
   * @param _to The address to transfer to.
   * @param _value The amount to be transferred.
   * @param _data The extra data to be passed to the receiving contract.
   */
  function transferAndCall(address _to, uint _value, bytes calldata _data)
    public
    override
    virtual
    returns (bool success)
  {
    super.transfer(_to, _value);
    emit Transfer(msg.sender, _to, _value, _data);
    if (isContract(_to)) {
      contractFallback(_to, _value, _data);
    }
    return true;
  }


  /**
   * @dev call the onTokenTransfer function of a contract with address _to.
   * @param _to The address of the calling contract.
   * @param _value The amount to be transferred.
   * @param _data The extra data to be passed to the calling contract.
   */
  function contractFallback(address _to, uint _value, bytes memory _data)
    private
  {
    IERC677Receiver receiver = IERC677Receiver(_to);
    receiver.onTokenTransfer(msg.sender, _value, _data);
  }

  /**
   * @dev Check an address is a contract or not.
   * @param _addr The address to be checked.
   * @return bool return true if the _addr is a contract address.
   */   
  function isContract(address _addr)
    internal
    view
    returns (bool)
  {
    uint256 size;
    assembly {
        size := extcodesize(_addr)
    }
    return (size > 0);
  }  
}