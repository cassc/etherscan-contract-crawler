// SPDX-License-Identifier: ---DG----

pragma solidity =0.8.21;

contract TransferHelper {

    bytes4 private constant TRANSFER = bytes4(
        keccak256(
            bytes(
                "transfer(address,uint256)" // 0xa9059cbb
            )
        )
    );

    bytes4 private constant TRANSFER_FROM = bytes4(
        keccak256(
            bytes(
                "transferFrom(address,address,uint256)" // 0x23b872dd
            )
        )
    );

    bytes4 private constant BALANCE_OF = bytes4(
        keccak256(
            bytes(
                "balanceOf(address)"
            )
        )
    );

    function safeTransfer(
        address _token,
        address _to,
        uint256 _value
    )
        internal
    {
        (bool success, bytes memory data) = _token.call(
            abi.encodeWithSelector(
                TRANSFER, // 0xa9059cbb
                _to,
                _value
            )
        );

        require(
            success && (
                data.length == 0 || abi.decode(
                    data, (bool)
                )
            ),
            "TransferHelper: TRANSFER_FAILED"
        );
    }

    function safeTransferFrom(
        address _token,
        address _from,
        address _to,
        uint _value
    )
        internal
    {
        (bool success, bytes memory data) = _token.call(
            abi.encodeWithSelector(
                TRANSFER_FROM,
                _from,
                _to,
                _value
            )
        );

        require(
            success && (
                data.length == 0 || abi.decode(
                    data, (bool)
                )
            ),
            "TransferHelper: TRANSFER_FROM_FAILED"
        );
    }

    function safeBalance(
        address _token,
        address _owner
    )
        internal
        returns (uint256)
    {
        (bool success, bytes memory data) = _token.call(
            abi.encodeWithSelector(
                BALANCE_OF,
                _owner
            )
        );

        if (success == false) return 0;

        return abi.decode(
            data,
            (uint256)
        );
    }
}