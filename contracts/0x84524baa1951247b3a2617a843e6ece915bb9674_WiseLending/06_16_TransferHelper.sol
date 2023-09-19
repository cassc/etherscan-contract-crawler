// SPDX-License-Identifier: -- WISE --

pragma solidity =0.8.21;

import "./CallOptionalReturn.sol";

contract TransferHelper is CallOptionalReturn {

    bytes4 constant transfer = IERC20
        .transfer
        .selector;

    bytes4 constant transferFrom = IERC20
        .transferFrom
        .selector;

    /**
     * @dev
     * Allows to execute safe transfer for a token
     */
    function _safeTransfer(
        address _token,
        address _to,
        uint256 _value
    )
        internal
    {
        _callOptionalReturn(
            _token,
            abi.encodeWithSelector(
                transfer,
                _to,
                _value
            )
        );
    }

    /**
     * @dev
     * Allows to execute safe transferFrom for a token
     */
    function _safeTransferFrom(
        address _token,
        address _from,
        address _to,
        uint256 _value
    )
        internal
    {
        _callOptionalReturn(
            _token,
            abi.encodeWithSelector(
                transferFrom,
                _from,
                _to,
                _value
            )
        );
    }
}