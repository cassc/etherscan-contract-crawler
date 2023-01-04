// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {TokenCodec} from "./codecs/TokenCodec.sol";
import {RaiseCodec} from "./codecs/RaiseCodec.sol";
import {TokenData, TokenType} from "../structs/TokenData.sol";
import {RaiseData, TierType} from "../structs/RaiseData.sol";
import {TWO_BYTES} from "../constants/Codecs.sol";

//   |------------ Token data is encoded in 32 bytes ---------------|
// 0x0000000000000000000000000000000000000000000000000000000000000000
//   1 byte token type                                             tt
//   1 byte encoding version                                     vv
//   |------- Raise token data is encoded in 30 bytes ----------|
//   4 byte project ID                                   pppppppp
//   4 byte raise ID                             rrrrrrrr
//   4 byte tier ID                      tttttttt
//   1 byte tier type                  TT
//   |------- 17 empty bytes --------|

/// @title RaiseToken - Raise token encoder/decoder
/// @notice Converts numeric token IDs to TokenData/RaiseData structs.
library RaiseToken {
    function encode(TierType _tierType, uint32 _projectId, uint32 _raiseId, uint32 _tierId)
        internal
        pure
        returns (uint256)
    {
        RaiseData memory raiseData =
            RaiseData({tierType: _tierType, projectId: _projectId, raiseId: _raiseId, tierId: _tierId});
        TokenData memory tokenData =
            TokenData({tokenType: TokenType.Raise, encodingVersion: 0, data: RaiseCodec.encode(raiseData)});
        return TokenCodec.encode(tokenData);
    }

    function decode(uint256 tokenId) internal pure returns (TokenData memory, RaiseData memory) {
        TokenData memory token = TokenCodec.decode(tokenId);
        RaiseData memory raise = RaiseCodec.decode(token.data);
        return (token, raise);
    }

    function projectId(uint256 tokenId) internal pure returns (uint32) {
        return uint32(tokenId >> TWO_BYTES);
    }
}