// SPDX-License-Identifier: Apache-2.0
// Copyright 2017 Loopring Technology Limited.
// Modified by DeGate DAO, 2022
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "../../../lib/ERC20SafeTransfer.sol";
import "../../../lib/MathUint.sol";
import "../../iface/ExchangeData.sol";
import "./ExchangeMode.sol";

/// @title ExchangeTokens.
/// @author Daniel Wang  - <[email protected]>
/// @author Brecht Devos - <[email protected]>
library ExchangeTokens
{
    using MathUint          for uint;
    using ERC20SafeTransfer for address;
    using ExchangeMode      for ExchangeData.State;

    event TokenRegistered(
        address token,
        uint32  tokenId
    );

    function getTokenAddress(
        ExchangeData.State storage S,
        uint32 tokenID
        )
        public
        view
        returns (address)
    {
        require(tokenID < S.normalTokens.length.add(ExchangeData.MAX_NUM_RESERVED_TOKENS), "INVALID_TOKEN_ID");

        if (tokenID < ExchangeData.MAX_NUM_RESERVED_TOKENS) {
            return S.reservedTokens[tokenID].token;
        }

        return S.normalTokens[tokenID - ExchangeData.MAX_NUM_RESERVED_TOKENS].token;
    }

    function registerToken(
        ExchangeData.State storage S,
        address tokenAddress,
        bool isOwnerRegister
        )
        public
        returns (uint32 tokenID)
    {
        require(!S.isInWithdrawalMode(), "INVALID_MODE");
        require(S.tokenToTokenId[tokenAddress] == 0, "TOKEN_ALREADY_EXIST");

        if (isOwnerRegister) {
            require(S.reservedTokens.length < ExchangeData.MAX_NUM_RESERVED_TOKENS, "TOKEN_REGISTRY_FULL");
        } else {
            require(S.normalTokens.length < ExchangeData.MAX_NUM_NORMAL_TOKENS, "TOKEN_REGISTRY_FULL");
        }

        // Check if the deposit contract supports the new token
        if (S.depositContract != IDepositContract(0)) {
            require(S.depositContract.isTokenSupported(tokenAddress), "UNSUPPORTED_TOKEN");
        }

        // Assign a tokenID and store the token
        ExchangeData.Token memory token = ExchangeData.Token(tokenAddress);

        if (isOwnerRegister) {
            tokenID = uint32(S.reservedTokens.length);
            S.reservedTokens.push(token);
        } else {
            tokenID = uint32(S.normalTokens.length.add(ExchangeData.MAX_NUM_RESERVED_TOKENS));
            S.normalTokens.push(token);
        }
        S.tokenToTokenId[tokenAddress] = tokenID + 1;
        S.tokenIdToToken[tokenID] = tokenAddress;

        S.tokenIdToDepositBalance[tokenID] = 0;

        emit TokenRegistered(tokenAddress, tokenID);
    }

    function getTokenID(
        ExchangeData.State storage S,
        address tokenAddress
        )
        internal  // inline call
        view
        returns (uint32 tokenID)
    {
        tokenID = S.tokenToTokenId[tokenAddress];
        require(tokenID != 0, "TOKEN_NOT_FOUND");
        tokenID = tokenID - 1;
    }

    function findTokenID(
        ExchangeData.State storage S,
        address tokenAddress
        )
        internal  // inline call
        view
        returns (uint32 tokenID, bool found)
    {
        tokenID = S.tokenToTokenId[tokenAddress];
        if(tokenID == 0) {
            return (0, false);
        }
        tokenID = tokenID - 1;
        found = true;
    }

}