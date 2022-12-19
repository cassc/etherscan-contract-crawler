//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import {IWallet} from "../interfaces/IWallet.sol";

/// @author Amit Molek

/// @dev The data needed for `join`
/// This needs to be encoded (you can use `JoinDataCodec`) and be passed to `join`
struct JoinData {
    address member;
    IWallet.Proposition proposition;
    bytes[] signatures;
    /// @dev How much ownership units `member` want to acquire
    uint256 ownershipUnits;
}

/// @dev Codec for `JoinData`
contract JoinDataCodec {
    function encode(JoinData memory joinData)
        external
        pure
        returns (bytes memory)
    {
        return abi.encode(joinData);
    }

    function decode(bytes memory data) external pure returns (JoinData memory) {
        return abi.decode(data, (JoinData));
    }
}