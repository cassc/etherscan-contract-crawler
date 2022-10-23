pragma solidity 0.8.16;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @title BulkSender MultiSender, support ETH and ERC20 Tokens, send ether or erc20 token to multiple addresses in batch
 * @dev To Use this Dapp: https://bulksender.app
*/

contract FreeBulkSender {
    event Bulksend(address[] _tos, uint256[] _values);
    event BulksendToken(IERC20 indexed token, address[] _tos, uint256[] _values);
    event BulksendTokens(IERC20[] tokens, address[] _tos, uint256[] _values);

    /*
        Send ether with the different value by a explicit call method
    */
    function bulksend(address[] calldata _tos, uint[] calldata _values) payable external {
        require(_tos.length == _values.length, "Wrong lengths");

        uint remainingValue = msg.value;

        for (uint256 i; i < _tos.length;) {
            remainingValue = remainingValue - _values[i];

            (bool result, ) = _tos[i].call{value: _values[i]}("");
            require(result, "Failed to send Ether");

            unchecked {
                ++i;
            }
        }

        if (remainingValue > 0) {
            (bool result, ) = msg.sender.call{value: remainingValue}("");
            require(result, "Failed to send Ether");
        }

        emit Bulksend(_tos, _values);
    }

    /*
        Send coin with the different value by a explicit call method
    */
    function bulksendToken(
        IERC20 _token,
        address[] calldata _tos,
        uint256[] calldata _values
    ) external {
        require(_tos.length == _values.length, "Wrong lengths");

        for (uint256 i; i < _tos.length;) {
            SafeERC20.safeTransferFrom(_token, msg.sender, _tos[i], _values[i]);

            unchecked {
                ++i;
            }
        }

        emit BulksendToken(_token, _tos, _values);
    }

    function bulksendTokens(
        IERC20[] calldata _tokens,
        address[] calldata _tos,
        uint256[] calldata _values
    ) external {
        require(_tokens.length == _values.length, "Wrong lengths");
        require(_tos.length == _values.length, "Wrong lengths");

        for (uint256 i; i < _tos.length;) {
            SafeERC20.safeTransferFrom(_tokens[i], msg.sender, _tos[i], _values[i]);

            unchecked {
                ++i;
            }
        }

        emit BulksendTokens(_tokens, _tos, _values);
    }
}