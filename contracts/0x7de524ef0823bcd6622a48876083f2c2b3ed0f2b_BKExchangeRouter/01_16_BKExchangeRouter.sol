// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import "./BKCommon.sol";
import "./utils/TransferHelper.sol";

contract BKExchangeRouter is BKCommon{
    address public immutable BK_EXCHANGE;

    constructor(address bkExchangeAddress, address _owner) {
        BK_EXCHANGE = bkExchangeAddress;
        _transferOwnership(_owner);
    }

    function runWithERC20s(address[] calldata _tokenIns, uint256[] calldata _amountIns, bytes calldata _data)
    external
    payable
    whenNotPaused
    nonReentrant
    {
        require(_tokenIns.length == _amountIns.length, "_tokenIns and _amountIns length mismatched");
        for (uint256 i = 0; i < _tokenIns.length; i++) {
            TransferHelper.safeTransferFrom(
                _tokenIns[i],
                msg.sender,
                BK_EXCHANGE,
                _amountIns[i]
            );
        }

        (bool success, bytes memory resultData) = BK_EXCHANGE.call{
            value : msg.value
        }(_data);

        if (!success) {
            _revertWithData(resultData);
        }
    }

    function runWithETH(bytes calldata _data)
    external
    payable
    whenNotPaused
    nonReentrant
    {
        (bool success, bytes memory resultData) = BK_EXCHANGE.call{
            value : msg.value
        }(_data);

        if (!success) {
            _revertWithData(resultData);
        }
    }
}