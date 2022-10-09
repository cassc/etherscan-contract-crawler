// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

// solhint-disable-next-line private-vars-leading-underscore, func-visibility
function _eip2771Context(bytes calldata _data, address _msgSender)
    pure
    returns (bytes memory)
{
    return abi.encodePacked(_data, _msgSender);
}