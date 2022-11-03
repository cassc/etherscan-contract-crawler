// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.6;

import "Address.sol";
import "PausableAccessControl.sol";

contract Invoker is PausableAccessControl {
    using Address for address;

    bytes32 public constant APPROVED_COMMAND_IMPLEMENTATION =
        keccak256("APPROVED_COMMAND_IMPLEMENTATION");

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, abi.decode(Deployer(msg.sender).deployArgs(), (address)));
    }

    receive() external payable {
        //Otherwise we can't receive ETH
    }

    function _invokeDelegate(address _to, bytes calldata _data) private returns (bytes memory) {
        require(hasRole(APPROVED_COMMAND_IMPLEMENTATION, _to), "Command not approved");
        return _to.functionDelegateCall(_data);
    }

    function invoke(address[] calldata _tos, bytes[] calldata _datas)
        external
        payable
        whenNotPaused
        returns (bytes[] memory output)
    {
        require(_tos.length == _datas.length, "dev: to+data length not equal");
        output = new bytes[](_tos.length);
        for (uint256 i = 0; i < _tos.length; i++) {
            output[i] = _invokeDelegate(_tos[i], _datas[i]);
        }
    }
}