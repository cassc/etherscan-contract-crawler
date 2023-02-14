// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC777/IERC777.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@uniswap/lib/contracts/libraries/TransferHelper.sol";
import "./interfaces/IUniversalTokenRouter.sol";

contract UniversalTokenRouter is IUniversalTokenRouter {
    // values with a single 1-bit are preferred
    uint constant TRANSFER_FROM_SENDER  = 0;
    uint constant TRANSFER_FROM_ROUTER  = 1;
    uint constant TRANSFER_CALL_VALUE   = 2;
    uint constant IN_TX_PAYMENT         = 4;
    uint constant ALLOWANCE_BRIDGE      = 8;

    uint constant AMOUNT_EXACT      = 0;
    uint constant AMOUNT_ALL        = 1;

    uint constant EIP_ETH           = 0;

    uint constant ID_721_ALL = uint(keccak256('UniversalTokenRouter.ID_721_ALL'));

    uint constant ACTION_IGNORE_ERROR       = 1;
    uint constant ACTION_RECORD_CALL_RESULT = 2;
    uint constant ACTION_INJECT_CALL_RESULT = 4;

    // non-persistent in-transaction pending payments
    mapping(bytes32 => uint) s_payments;

    // accepting ETH for WETH.withdraw
    receive() external payable {}

    function exec(
        Output[] memory outputs,
        Action[] memory actions
    ) override external payable {
    unchecked {
        // track the expected balances before any action is executed
        for (uint i = 0; i < outputs.length; ++i) {
            Output memory output = outputs[i];
            uint balance = _balanceOf(output.recipient, output.eip, output.token, output.id);
            uint expected = output.amountOutMin + balance;
            require(expected >= balance, 'UniversalTokenRouter: OVERFLOW');
            output.amountOutMin = expected;
        }

        bool dirty = false;

        bytes memory callResult;
        for (uint i = 0; i < actions.length; ++i) {
            Action memory action = actions[i];
            uint value;
            for (uint j = 0; j < action.inputs.length; ++j) {
                Input memory input = action.inputs[j];
                uint mode = input.mode;
                address sender = mode == TRANSFER_FROM_ROUTER ? address(this) : msg.sender; 
                uint amount;
                if (input.amountSource == AMOUNT_EXACT) {
                    amount = input.amountInMax;
                } else {
                    if (input.amountSource == AMOUNT_ALL) {
                        amount = _balanceOf(sender, input.eip, input.token, input.id);
                    } else {
                        amount = _sliceUint(callResult, input.amountSource);
                    }
                    require(amount <= input.amountInMax, "UniversalTokenRouter: EXCESSIVE_INPUT_AMOUNT");
                }
                if (mode == TRANSFER_CALL_VALUE) {
                    value = amount;
                    continue;
                }
                if (mode == TRANSFER_FROM_SENDER || mode == TRANSFER_FROM_ROUTER) {
                    _transferToken(sender, input.recipient, input.eip, input.token, input.id, amount);
                    continue;
                }
                if (mode == IN_TX_PAYMENT) {
                    bytes32 key = keccak256(abi.encodePacked(msg.sender, input.recipient, input.eip, input.token, input.id));
                    s_payments[key] += amount;  // overflow: harmless
                    dirty = true;
                    continue;
                }
                if (mode == ALLOWANCE_BRIDGE) {
                    _approve(input.recipient, input.eip, input.token, type(uint).max);
                    _transferToken(msg.sender, address(this), input.eip, input.token, input.id, amount);
                    dirty = true;
                }
            }
            if (action.data.length > 0) {
                if (action.flags & ACTION_INJECT_CALL_RESULT != 0) {
                    action.data = _concat(action.data, action.data.length, callResult);
                }
                (bool success, bytes memory result) = action.code.call{value: value}(action.data);
                if (!success && action.flags & ACTION_IGNORE_ERROR == 0) {
                    assembly {
                        revert(add(result,32),mload(result))
                    }
                }
                // delete value;   // clear the ETH value after call
                if (action.flags & ACTION_RECORD_CALL_RESULT != 0) {
                    callResult = result;
                }
            }
        }

        // verify balance changes
        for (uint i = 0; i < outputs.length; ++i) {
            Output memory output = outputs[i];
            uint balance = _balanceOf(output.recipient, output.eip, output.token, output.id);
            require(balance >= output.amountOutMin, 'UniversalTokenRouter: INSUFFICIENT_OUTPUT_AMOUNT');
        }

        // clear all in-transaction storages
        if (dirty) {
            for (uint i = 0; i < actions.length; ++i) {
                Action memory action = actions[i];
                for (uint j = 0; j < action.inputs.length; ++j) {
                    Input memory input = action.inputs[j];
                    if (input.mode == IN_TX_PAYMENT) {
                        bytes32 key = keccak256(abi.encodePacked(msg.sender, input.recipient, input.eip, input.token, input.id));
                        delete s_payments[key];
                        continue;
                    }
                    if (input.mode == ALLOWANCE_BRIDGE) {
                        _approve(input.recipient, input.eip, input.token, 0);
                        uint balance = _balanceOf(address(this), input.eip, input.token, input.id);
                        if (balance > 0) {
                            _transferToken(address(this), msg.sender, input.eip, input.token, input.id, balance);
                        }
                    }
                }
            }
        }

        // refund any left-over ETH
        uint leftOver = address(this).balance;
        if (leftOver > 0) {
            TransferHelper.safeTransferETH(msg.sender, leftOver);
        }
    } }

    function pay(
        address sender,
        address recipient,
        uint eip,
        address token,
        uint id,
        uint amount
    ) public {
    unchecked {
        bytes32 key = keccak256(abi.encodePacked(sender, recipient, eip, token, id));
        require(s_payments[key] >= amount, 'UniversalTokenRouter: INSUFFICIENT_ALLOWANCE');
        s_payments[key] -= amount;
        _transferToken(sender, recipient, eip, token, id, amount);
    } }

    function _transferToken(
        address sender,
        address recipient,
        uint eip,
        address token,
        uint id,
        uint amount
    ) internal {
        if (eip == 20) {
            if (sender == address(this)) {
                TransferHelper.safeTransfer(token, recipient, amount);
            } else {
                TransferHelper.safeTransferFrom(token, sender, recipient, amount);
            }
        } else if (eip == 1155) {
            IERC1155(token).safeTransferFrom(sender, recipient, id, amount, "");
        } else if (eip == 721) {
            IERC721(token).safeTransferFrom(sender, recipient, id);
        } else if (eip == EIP_ETH) {
            require(sender == address(this), 'UniversalTokenRouter: INVALID_ETH_SENDER');
            TransferHelper.safeTransferETH(recipient, amount);
        } else {
            revert("UniversalTokenRouter: INVALID_EIP");
        }
    }

    function _approve(
        address recipient,
        uint eip,
        address token,
        uint amount
    ) internal {
        if (eip == 20) {
            TransferHelper.safeApprove(token, recipient, amount);
        } else if (eip == 1155) {
            IERC1155(token).setApprovalForAll(recipient, amount > 0);
        } else if (eip == 721) {
            IERC721(token).setApprovalForAll(recipient, amount > 0);
        } else {
            revert("UniversalTokenRouter: INVALID_EIP");
        }
    }

    function _balanceOf(
        address owner,
        uint eip,
        address token,
        uint id
    ) internal view returns (uint balance) {
        if (eip == 20) {
            return IERC20(token).balanceOf(owner);
        }
        if (eip == 1155) {
            return IERC1155(token).balanceOf(owner, id);
        }
        if (eip == 721) {
            if (id == ID_721_ALL) {
                return IERC721(token).balanceOf(owner);
            }
            try IERC721(token).ownerOf(id) returns (address currentOwner) {
                return currentOwner == owner ? 1 : 0;
            } catch {
                return 0;
            }
        }
        if (eip == EIP_ETH) {
            return owner.balance;
        }
        revert("UniversalTokenRouter: INVALID_EIP");
    }

    function _sliceUint(bytes memory bs, uint start) internal pure returns (uint x) {
        // require(bs.length >= start + 32, "slicing out of range");
        assembly {
            x := mload(add(bs, start))
        }
    }

    /// https://github.com/GNSPS/solidity-bytes-utils/blob/master/contracts/BytesLib.sol
    /// @param length length of the first preBytes
    function _concat(
        bytes memory preBytes,
        uint length,
        bytes memory postBytes
    ) internal pure returns (bytes memory bothBytes) {
        assembly {
            // Get a location of some free memory and store it in bothBytes as
            // Solidity does for memory variables.
            bothBytes := mload(0x40)

            // Store the length of the first bytes array at the beginning of
            // the memory for bothBytes.
            mstore(bothBytes, length)

            // Maintain a memory counter for the current write location in the
            // temp bytes array by adding the 32 bytes for the array length to
            // the starting location.
            let mc := add(bothBytes, 0x20)
            // Stop copying when the memory counter reaches the length of the
            // first bytes array.
            let end := add(mc, length)

            for {
                // Initialize a copy counter to the start of the preBytes data,
                // 32 bytes into its memory.
                let cc := add(preBytes, 0x20)
            } lt(mc, end) {
                // Increase both counters by 32 bytes each iteration.
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                // Write the preBytes data into the bothBytes memory 32 bytes
                // at a time.
                mstore(mc, mload(cc))
            }

            // Add the length of postBytes to the current length of bothBytes
            // and store it as the new length in the first 32 bytes of the
            // bothBytes memory.
            length := mload(postBytes)
            mstore(bothBytes, add(length, mload(bothBytes)))

            // Move the memory counter back from a multiple of 0x20 to the
            // actual end of the preBytes data.
            mc := sub(end, 0x20)
            // Stop copying when the memory counter reaches the new combined
            // length of the arrays.
            end := add(end, length)

            for {
                let cc := postBytes
            } lt(mc, end) {
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                mstore(mc, mload(cc))
            }

            // Update the free-memory pointer by padding our last write location
            // to 32 bytes: add 31 bytes to the end of bothBytes to move to the
            // next 32 byte block, then round down to the nearest multiple of
            // 32. If the sum of the length of the two arrays is zero then add
            // one before rounding down to leave a blank 32 bytes (the length block with 0).
            // mstore(0x40, and(
            //   add(add(end, iszero(add(length, mload(preBytes)))), 31),
            //   not(31) // Round down to the nearest 32 bytes.
            // ))
        }
    }
}