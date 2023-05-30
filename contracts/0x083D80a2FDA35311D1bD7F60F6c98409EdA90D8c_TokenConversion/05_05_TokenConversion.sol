// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

// Errors
error Conversion_Expired();
error Only_Stream_Owner();
error Invalid_Stream_Owner();
error Invalid_Recipient();
error Invalid_Stream_StartTime();
error Invalid_Token_Decimals();
error Insufficient_Reserves();

// Interfaces
interface IERC20Burnable is IERC20 {
    function burnFrom(address account, uint256 amount) external;
}

/// Converts a token to another token where the conversion price is fixed and the output token is streamed to the
/// owner over a fixed duration.
contract TokenConversion is Ownable {
    // Constants
    address public immutable tokenIn; // the token to deposit
    address public immutable tokenOut; // the token to stream
    uint256 public immutable rate; // tokenIn (in tokenIn precision) that converts to 1 tokenOut (in tokenOut precision)
    uint256 public immutable duration; // the vesting duration
    uint256 public immutable expiration; // expiration of the conversion program

    // Structs
    struct Stream {
        uint128 total; // expressed in tokenOut precision
        uint128 claimed; // expressed in tokenOut precision
    }

    // Storage vars
    // Stream owner and startTime is encoded in streamId
    mapping(uint256 => Stream) public streams;
    // Total unclaimed tokenOut
    uint256 public totalUnclaimed;

    // Events
    event Convert(
        uint256 indexed streamId,
        address indexed sender,
        address indexed owner,
        uint256 amountIn,
        uint256 amountOut
    );
    event Claim(
        uint256 indexed streamId,
        address indexed owner,
        address indexed recipient,
        uint256 amount
    );
    event UpdateStreamOwner(
        uint256 indexed streamId,
        address indexed owner,
        address indexed newOwner,
        uint256 newStreamId
    );

    /// Instantiates a new converter contract with an owner
    /// @dev owner is able to withdraw tokenOut from the conversion contract
    constructor(
        address _tokenIn,
        address _tokenOut,
        uint256 _rate,
        uint256 _duration,
        uint256 _expiration,
        address _owner
    ) {
        // initialize conversion terms
        tokenIn = _tokenIn;
        tokenOut = _tokenOut;
        rate = _rate;
        duration = _duration;
        expiration = _expiration;

        // Sanity checks
        if (IERC20Metadata(tokenIn).decimals() != 18)
            revert Invalid_Token_Decimals();
        if (IERC20Metadata(tokenOut).decimals() != 18)
            revert Invalid_Token_Decimals();

        transferOwnership(_owner);
    }

    /// Burns `amount` of tokenIn tokens and creates a new stream of tokenOut
    /// tokens claimable by `owner` over the stream `duration`
    /// @param amount The amount of tokenIn to convert (in tokenIn precision)
    /// @param owner The owner of the new stream
    /// @return streamId Encoded identifier of the stream [owner, startTime]
    function convert(uint256 amount, address owner)
        external
        returns (uint256 streamId)
    {
        // assert conversion is not expired
        if (block.timestamp > expiration) revert Conversion_Expired();

        // don't convert to zero address
        if (owner == address(0)) revert Invalid_Stream_Owner();

        // compute stream amount
        // rate converts from tokenIn precision to tokenOut precision
        uint256 amountOut = amount / rate;

        // do not convert if insufficient reserves
        uint256 newTotalUnclaimed = totalUnclaimed + amountOut;
        if (IERC20(tokenOut).balanceOf(address(this)) < newTotalUnclaimed)
            revert Insufficient_Reserves();

        // update total unclaimed tokenOut
        totalUnclaimed = newTotalUnclaimed;

        // create new stream or add to existing stream created in same block
        streamId = encodeStreamId(owner, uint64(block.timestamp));
        Stream storage stream = streams[streamId];
        // this is safe bc tokenOut totalSupply is only 10**7
        stream.total = uint128(amountOut + stream.total);

        // burn deposited tokens
        // reverts if insufficient allowance or balance
        IERC20Burnable(tokenIn).burnFrom(msg.sender, amount);
        emit Convert(streamId, msg.sender, owner, amount, amountOut);
    }

    /// Withdraws claimable tokenOut tokens to the stream's `owner`
    /// @param streamId The encoded identifier of the stream to claim from
    /// @return claimed The amount of tokens claimed
    /// @dev Reverts if not called by the stream's `owner`
    function claim(uint256 streamId) external returns (uint256 claimed) {
        Stream memory stream = streams[streamId];
        (address streamOwner, uint64 startTime) = decodeStreamId(streamId);

        // withdraw claimable amount
        return _claim(stream, streamId, streamOwner, streamOwner, startTime);
    }

    /// Withdraws claimable tokenOut tokens to a designated `recipient`
    /// @param streamId The encoded identifier of the stream to claim from
    /// @param recipient The recipient of the claimed token amount
    /// @return claimed The amount of tokens claimed
    /// @dev Reverts if not called by the stream's `owner`
    function claim(uint256 streamId, address recipient)
        external
        returns (uint256 claimed)
    {
        // don't claim to zero address
        if (recipient == address(0)) revert Invalid_Recipient();

        Stream memory stream = streams[streamId];
        (address streamOwner, uint64 startTime) = decodeStreamId(streamId);

        // withdraw claimable amount
        return _claim(stream, streamId, streamOwner, recipient, startTime);
    }

    // Implementation of the claim feature
    function _claim(
        Stream memory stream,
        uint256 streamId,
        address streamOwner,
        address recipient,
        uint64 startTime
    ) private returns (uint256 claimed) {
        // check owner
        if (msg.sender != streamOwner) revert Only_Stream_Owner();

        // compute claimable amount and update stream
        claimed = _claimableBalance(stream, startTime);
        stream.claimed = uint128(stream.claimed + claimed);
        streams[streamId] = stream;

        // update remaining total allocated tokenOut
        // claimed <= stream.total and stream.total <= total
        totalUnclaimed = totalUnclaimed - claimed;

        // withdraw claimable amount
        // reverts if insufficient balance
        IERC20(tokenOut).transfer(recipient, claimed);
        emit Claim(streamId, streamOwner, recipient, claimed);
    }

    /// Transfers stream to a new owner
    /// @param streamId The encoded identifier of the stream to transfer to a new owner
    /// @param owner The new owner of the stream
    /// @return newStreamId New identifier of the stream [newOwner, startTime]
    /// @dev Reverts if not called by the stream's `owner`
    function transferStreamOwnership(uint256 streamId, address owner)
        external
        returns (uint256 newStreamId)
    {
        // don't transfer stream to zero address
        if (owner == address(0)) revert Invalid_Stream_Owner();

        Stream memory stream = streams[streamId];
        (address currentOwner, uint64 startTime) = decodeStreamId(streamId);

        // only stream owner is allowed to update ownership
        if (currentOwner != msg.sender) revert Only_Stream_Owner();

        // don't transfer stream to currentOwner
        if (owner == currentOwner) revert Invalid_Stream_Owner();

        // store stream with new streamId or add to existing stream
        newStreamId = encodeStreamId(owner, startTime);

        Stream memory newStream = streams[newStreamId];
        newStream.total += stream.total;
        newStream.claimed += stream.claimed;
        streams[newStreamId] = newStream;

        delete streams[streamId];
        emit UpdateStreamOwner(streamId, currentOwner, owner, newStreamId);
    }

    // Owner methods

    /// Withdraws `amount` of tokenOut to owner
    /// @param amount The amount of tokens to withdraw from the conversion contract
    /// @dev Reverts if not called by the contract's `owner`
    /// @dev This is used in two scenarios:
    /// - Emergency such as a vulnerability in the contract
    /// - Recover unconverted funds
    function withdraw(uint256 amount) external onlyOwner {
        // reverts if insufficient balance
        IERC20(tokenOut).transfer(owner(), amount);
    }

    // View methods

    /// Returns the claimable balance for a stream
    /// @param streamId The encoded identifier of the stream to view `claimableBalance` of
    /// @return claimable The amount of tokens claimable
    function claimableBalance(uint256 streamId)
        external
        view
        returns (uint256 claimable)
    {
        (, uint64 startTime) = decodeStreamId(streamId);
        return _claimableBalance(streams[streamId], startTime);
    }

    // Implementation of claimableBalance query
    // claimable <= stream.total and stream.total <= total so that claimable <= tokenOut.balanceOf(this)
    function _claimableBalance(Stream memory stream, uint64 startTime)
        private
        view
        returns (uint256 claimable)
    {
        uint256 endTime = startTime + duration;
        if (block.timestamp <= startTime) {
            revert Invalid_Stream_StartTime();
        } else if (endTime <= block.timestamp) {
            claimable = stream.total - stream.claimed;
        } else {
            uint256 diffTime = block.timestamp - startTime;
            claimable = (stream.total * diffTime) / duration - stream.claimed;
        }
    }

    /// @notice Encodes `owner` and `startTime` as `streamId`
    /// @param owner Owner of the stream
    /// @param startTime Stream startTime timestamp
    /// @return streamId Encoded identifier of the stream [owner, startTime]
    function encodeStreamId(address owner, uint64 startTime)
        public
        pure
        returns (uint256 streamId)
    {
        unchecked {
            streamId = (uint256(uint160(owner)) << 96) + startTime;
        }
    }

    /// @notice Decodes the `owner` and `startTime` from `streamId`
    /// @param streamId The encoded stream identifier consisting of [owner, startTime]
    /// @return owner owner extracted from `streamId`
    /// @return startTime startTime extracted from `streamId`
    function decodeStreamId(uint256 streamId)
        public
        pure
        returns (address owner, uint64 startTime)
    {
        owner = address(uint160(uint256(streamId >> 96)));
        startTime = uint64(streamId);
    }
}