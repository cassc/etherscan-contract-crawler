// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


contract HackedGameState {

    uint256 internal constant LAST_TOKEN_ID = 2222;

    mapping(uint256 => uint256) private _tokenState;
    mapping(uint256 => uint256) private _symbolState;

    uint256 private _gameState;


    function _decodeSymbolState(uint256 symbols) internal view returns (
        uint256 gameId,
        uint256 tokenId
    ) {
        uint256 state = _symbolState[symbols]; 
        gameId  = uint256(uint16(state      ));
        tokenId = uint256(uint16(state >> 16));
    }

    function _encodeSymbolState(
        uint256 symbols, 
        uint256 gameId, 
        uint256 tokenId) internal 
    {
        _symbolState[symbols] = gameId
            | (tokenId << 16);
    }
   
    function _decodeTokenState(uint256 tokenId) internal view returns (
        uint256 gameId,
        uint256 defaultSymbols,
        uint256 symbols,
        uint256 reentriesUsed
    ) {
        uint256 state = _tokenState[tokenId]; 
        gameId         = uint256(uint16(state      ));
        defaultSymbols = uint256(uint16(state >> 16));
        symbols        = uint256(uint16(state >> 32));
        reentriesUsed  = uint256(uint16(state >> 48));
    }

    function _encodeTokenState(
        uint256 tokenId, 
        uint256 gameId,
        uint256 defaultSymbols,
        uint256 symbols,
        uint256 reentriesUsed) internal 
    {
        _tokenState[tokenId] = gameId
            | (defaultSymbols << 16)
            | (symbols        << 32)
            | (reentriesUsed  << 48);
    }

    function _decodeGameState() internal view returns (
        uint256 gameId,
        uint256 roundId,
        uint256 pattern,
        uint256 patternMask,
        uint256 lastPattern,
        uint256 lastPatternMask,
        uint256 lastSymbol,
        uint256 roundStartedAt
    ) {
        uint256 state = _gameState; 
        gameId          = uint256(uint16(state       ));
        roundId         = uint256(uint16(state >>  16));
        pattern         = uint256(uint16(state >>  32));
        patternMask     = uint256(uint16(state >>  48));
        lastPattern     = uint256(uint16(state >>  64));
        lastPatternMask = uint256(uint16(state >>  80));
        lastSymbol      = uint256(uint16(state >>  96));
        roundStartedAt  = uint256(uint32(state >> 112));
    }

    function _encodeGameState(
        uint256 gameId,
        uint256 roundId,
        uint256 pattern,
        uint256 patternMask,
        uint256 lastPattern,
        uint256 lastPatternMask,
        uint256 lastSymbols,
        uint256 roundStartedAt) internal 
    {
        _gameState = gameId
            | (roundId         <<  16)
            | (pattern         <<  32)
            | (patternMask     <<  48)
            | (lastPattern     <<  64)
            | (lastPatternMask <<  80)
            | (lastSymbols     <<  96)
            | (roundStartedAt  << 112);
    }

    function gameState() external view returns (
        uint256 gameId,
        uint256 roundId,
        uint256 pattern,
        uint256 patternMask,
        uint256 lastPattern,
        uint256 lastPatternMask,
        uint256 lastSymbol,
        uint256 roundStartedAt
    ) {
        return _decodeGameState();
    }

    function tokenState(uint256 tokenId) external view returns (
        uint256 gameId,
        uint256 defaultSymbols,
        uint256 symbols,
        uint256 reentriesUsed
    ) {
        return _decodeTokenState(tokenId);
    }

    function symbolsState(uint256 symbols) external view returns (
        uint256 gameId,
        uint256 tokenId
    ) {
        return _decodeSymbolState(symbols);
    }
}