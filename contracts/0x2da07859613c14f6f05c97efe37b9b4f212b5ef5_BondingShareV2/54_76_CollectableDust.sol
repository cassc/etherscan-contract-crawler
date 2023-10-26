// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../interfaces/utils/ICollectableDust.sol";

abstract contract CollectableDust is ICollectableDust {
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.AddressSet;

    address public constant ETH_ADDRESS =
        0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    EnumerableSet.AddressSet internal _protocolTokens;

    // solhint-disable-next-line no-empty-blocks
    constructor() {}

    function _addProtocolToken(address _token) internal {
        require(
            !_protocolTokens.contains(_token),
            "collectable-dust::token-is-part-of-the-protocol"
        );
        _protocolTokens.add(_token);
        emit ProtocolTokenAdded(_token);
    }

    function _removeProtocolToken(address _token) internal {
        require(
            _protocolTokens.contains(_token),
            "collectable-dust::token-not-part-of-the-protocol"
        );
        _protocolTokens.remove(_token);
        emit ProtocolTokenRemoved(_token);
    }

    function _sendDust(
        address _to,
        address _token,
        uint256 _amount
    ) internal {
        require(
            _to != address(0),
            "collectable-dust::cant-send-dust-to-zero-address"
        );
        require(
            !_protocolTokens.contains(_token),
            "collectable-dust::token-is-part-of-the-protocol"
        );
        if (_token == ETH_ADDRESS) {
            payable(_to).transfer(_amount);
        } else {
            IERC20(_token).safeTransfer(_to, _amount);
        }
        emit DustSent(_to, _token, _amount);
    }
}