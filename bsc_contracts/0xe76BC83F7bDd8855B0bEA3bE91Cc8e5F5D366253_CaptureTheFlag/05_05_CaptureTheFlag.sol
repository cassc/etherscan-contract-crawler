/**
 * SPDX-License-Identifier:MIT
 */
pragma solidity ^0.8.6;
import "@opengsn/contracts/src/ERC2771Recipient.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract CaptureTheFlag is ERC2771Recipient, Ownable {

    event FlagCaptured(address previousHolder, address currentHolder);

    address public currentHolder = address(0);

    function captureTheFlag() external {
        address previousHolder = currentHolder;

        currentHolder = _msgSender();

        emit FlagCaptured(previousHolder, currentHolder);
    }

    constructor(address forwarder) {
        _setTrustedForwarder(forwarder);
    }

  function _msgSender() internal view override(Context, ERC2771Recipient)
      returns (address sender) {
      sender = ERC2771Recipient._msgSender();
  }

  function _msgData() internal view override(Context, ERC2771Recipient)
      returns (bytes memory) {
      return ERC2771Recipient._msgData();
  }
}