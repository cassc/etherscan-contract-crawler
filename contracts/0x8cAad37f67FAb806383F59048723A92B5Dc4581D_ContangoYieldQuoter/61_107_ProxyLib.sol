//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {PositionId} from "./DataTypes.sol";

library ProxyLib {
    /// Computes proxy address following EIP-1014 https://eips.ethereum.org/EIPS/eip-1014#specification
    /// @param positionId Position id used for the salt
    /// @param creator Address that created the proxy
    /// @param proxyHash Proxy bytecode hash
    /// @return computed proxy address
    function computeProxyAddress(PositionId positionId, address creator, bytes32 proxyHash)
        internal
        pure
        returns (address payable)
    {
        return payable(address(uint160(uint256(keccak256(abi.encodePacked(hex"ff", creator, positionId, proxyHash))))));
    }
}