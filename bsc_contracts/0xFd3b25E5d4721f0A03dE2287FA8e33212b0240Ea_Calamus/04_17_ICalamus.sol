// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./Types.sol";

interface ICalamus {
    /**
     * @notice Emits when a stream is successfully created.
     */
    event CreateStream(
        uint256 indexed streamId,
        address indexed sender,
        address indexed recipient,
        uint256 releaseAmount,
        uint256 startTime,
        uint256 stopTime,
        uint32 vestingRelease,
        uint256 releaseFrequency,
        uint8 transferPrivilege,
        uint8 cancelPrivilege,
        address tokenAddress
    );

    /**
     * @notice Emits when the recipient of a stream withdraws a portion or all their pro rata share of the stream.
     */
    event WithdrawFromStream(
        uint256 indexed streamId,
        address indexed recipient,
        uint256 amount
    );

    /**
     * @notice Emits when a stream is successfully cancelled and tokens are transferred back on a pro rata basis.
     */
    event CancelStream(
        uint256 indexed streamId,
        address indexed sender,
        address indexed recipient,
        uint256 senderBalance,
        uint256 recipientBalance
    );

    /**
     * @notice Emits when a stream is successfully transfered and tokens are transferred back on a pro rata basis.
     */
    event TransferStream(
        uint256 indexed streamId,
        address indexed sender,
        address indexed newRecipient,
        uint256 recipientBalance
    );


    /**
     * @notice Emits when a stream is successfully topuped.
     */
    event TopupStream(
        uint256 indexed streamId,
        uint256 amount,
        uint256 stopTime
    );

    function balanceOf(uint256 streamId, address who)
        external
        view
        returns (uint256 balance);

    function createStream(
        uint256 releaseAmount,
        address recipient,
        uint256 startTime,
        uint256 stopTime,
        uint32 vestingRelease,
        uint256 releaseFrequency,
        uint8 transferPrivilege,
        uint8 cancelPrivilege,
        address tokenAddress
    ) external payable;

    function withdrawFromStream(uint256 streamId, uint256 funds) external;

    function cancelStream(uint256 streamId) external;

    function transferStream(uint256 streamId, address newRecipient) external;

    function topupStream(uint256 streamId, uint256 amount) external payable;
}