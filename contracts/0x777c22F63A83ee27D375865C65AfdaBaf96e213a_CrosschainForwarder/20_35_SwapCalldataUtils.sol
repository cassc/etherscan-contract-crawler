// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;

import "./CalldataUtils.sol";

library SwapCalldataUtils {
    using CalldataUtils for bytes;

    bytes4 public constant SWAP_SELECTOR = 0x7c025200;
    bytes4 public constant UNOSWAP_SELECTOR = 0x2e95b6c8;
    bytes4 public constant UNOSWAPV3_SELECTOR = 0xe449022e;
    bytes4 public constant FILLORDERRFQ_SELECTOR = 0xd0a3b665;
    bytes4 public constant CLIPPERSWAP_SELECTOR = 0xb0431182;
    bytes4 public constant YY_SWAP_NO_SPLIT = 0x6bf2df86;
    bytes4 public constant YY_SWAP_NO_SPLIT_FROM_AVAX = 0xfe38c5e6;
    bytes4 public constant YY_SWAP_NO_SPLIT_TO_AVAX = 0xf0350382;

    function patchAt(bytes memory _data, uint256 amount, uint16 pos)
        internal
        pure
        returns (bytes memory patchedData, bool success)
    {
        if (_data.length >= pos + 32) {
            success = true;
            patchedData = bytes.concat(
                _data.slice(0, pos), //   _data[:pos],
                abi.encodePacked(amount),
                _data.slice(pos + 32, _data.length - (pos + 32)) //_data[pos+32:]
            );
        }
    }

    function patch(bytes memory _data, uint256 amount)
        internal
        pure
        returns (bytes memory patchedData, bool success)
    {
        bytes4 sig = _data.getSig();
        (uint256 pos, bool success_) = getAmountPos(sig);

        if (success_ && _data.length >= pos + 32) {
            success = true;
            patchedData = bytes.concat(
                _data.slice(0, pos), //   _data[:pos],
                abi.encodePacked(amount),
                _data.slice(pos + 32, _data.length - (pos + 32)) //_data[pos+32:]
            );
        }
    }

    function getAmount(bytes memory _data)
        internal
        pure
        returns (uint256 amount, bool success)
    {
        (uint256 pos, bool amountSuccess) = getAmountPos(_data.getSig());
        if (!amountSuccess || _data.length < pos + 32) {
            return (0, false);
        }

        assembly {
            amount := mload(add(_data, add(0x20, pos)))
        }
        success = true;
    }

    function getAmountPos(bytes4 sig)
        internal
        pure
        returns (uint256 pos, bool success)
    {
        success = true;
        if (sig == SWAP_SELECTOR) {
            // 456
            pos = 228;
        } else if (sig == UNOSWAP_SELECTOR) {
            // 72
            pos = 36;
        } else if (sig == UNOSWAPV3_SELECTOR) {
            // 8
            pos = 4;
        } else if (sig == FILLORDERRFQ_SELECTOR) {
            // 584
            pos = 292;
        } else if (sig == CLIPPERSWAP_SELECTOR) {
            //136
            pos = 68;
        } else if (sig == YY_SWAP_NO_SPLIT || sig == YY_SWAP_NO_SPLIT_FROM_AVAX || sig == YY_SWAP_NO_SPLIT_TO_AVAX) {
            // 200
            pos = 100;
        } else {
            success = false;
        }
    }
}