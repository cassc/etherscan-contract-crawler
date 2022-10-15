// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

import "./HackedGameState.sol";
import "./RandomSequence.sol";

interface HackedGameExtension {
    function onRoundRequested(uint256 tokenId, address user) external;
    function onRoundFinished(uint256 random) external;
    function onReentered(uint256 tokenId) external;
    function onGameStarted() external;
    function onGameCompleted(uint256 tokenId) external;
}

contract HackedGameBase is HackedGameState, RandomSequence {
    using Address for address;

    address private extension;

    function _setExtension(address _extension) internal {
        extension = _extension;
    }

    function _initializeGame(uint256 startsAt) internal {
        (uint256 gameId,,,,,,,) = _decodeGameState();
        (,uint256 defaultSymbols,,) = _decodeTokenState(LAST_TOKEN_ID);
        _encodeGameState(gameId+1, 0, 0, 0, 0, 0, defaultSymbols, startsAt);

        if (extension != address(0)) extension.functionDelegateCall(abi.encodeWithSelector(HackedGameExtension(extension).onGameStarted.selector));
    }

    function _round(uint256 random, uint256 roundStartedAt) internal {
        (
            uint256 gameId,
            uint256 roundId,
            uint256 pattern,
            uint256 patternMask,
            uint256 lastPattern,
            uint256 lastPatternMask,
            uint256 lastSymbols,
        ) = _decodeGameState();
        require(roundId < BITS, "Game finished");

        roundId += 1;
        lastPattern = (random & 0x01) << (BITS - roundId);
        lastPatternMask = 1 << (BITS - roundId);
        pattern |= lastPattern;
        patternMask |= lastPatternMask;

        _encodeGameState(gameId, roundId, pattern, patternMask, lastPattern, lastPatternMask, lastSymbols, roundStartedAt);

        if (extension != address(0)) extension.functionDelegateCall(abi.encodeWithSelector(HackedGameExtension(extension).onRoundFinished.selector, random));
    }

    function _canReenter(
            uint256 tokenId, 
            uint256 reentriesMax, 
            uint256 gameId,
            uint256 pattern,
            uint256 patternMask,
            uint256 lastPatternMask,
            uint256 symbols) internal view returns (bool, uint256, string memory) {
        if (symbols == 0) return (false, 0, "No symbols left");

        (
            uint256 _gameId,
            uint256 defaultSymbols,
            uint256 _symbols,
            uint256 reentriesUsed
        ) = _decodeTokenState(tokenId);
        _symbols = _gameId == gameId ? _symbols : defaultSymbols;
        if(_matches(_symbols, patternMask, pattern)) return (false, 0, "Token not hacked");
        if(!_matches(_symbols, patternMask ^ lastPatternMask, pattern)) return (false, 0, "Too late");

        reentriesUsed = _gameId == gameId ? reentriesUsed+1 : 1;
        if(reentriesUsed > reentriesMax) return (false, 0, "Max reentries reached");

        symbols = _nextSymbols(symbols, pattern, patternMask);
        if(!_matches(symbols, patternMask, pattern)) return (false, 0, "No symbols left");

        return (true, symbols, "");
    }

    function _reenter(uint256 tokenId, uint256 reentriesMax, uint256 gameId, uint256 pattern, uint256 patternMask, uint256 lastPatternMask, uint256 lastSymbols) internal returns (uint256) {
        require(lastSymbols != 0, "No symbols left");

        (
            uint256 _gameId,
            uint256 defaultSymbols,
            uint256 _symbols,
            uint256 reentriesUsed
        ) = _decodeTokenState(tokenId);
        _symbols = _gameId == gameId ? _symbols : defaultSymbols;
        require(!_matches(_symbols, patternMask, pattern), "Token not hacked");
        require(_matches(_symbols, patternMask ^ lastPatternMask, pattern), "Too late");

        reentriesUsed = _gameId == gameId ? reentriesUsed+1 : 1;
        require(reentriesUsed <= reentriesMax, "Max reentries reached");

        lastSymbols = _nextSymbols(lastSymbols, pattern, patternMask);
        require(_matches(lastSymbols, patternMask, pattern), "No symbols left");

        _encodeSymbolState(lastSymbols, gameId, tokenId);
        _encodeTokenState(tokenId, gameId, defaultSymbols, lastSymbols, reentriesUsed);

        if (extension != address(0)) extension.functionDelegateCall(abi.encodeWithSelector(HackedGameExtension(extension).onReentered.selector, tokenId));

        return lastSymbols;
    }

    function _onGameCompleted(uint256 tokenId) internal {
        if (extension != address(0)) extension.functionDelegateCall(abi.encodeWithSelector(HackedGameExtension(extension).onGameCompleted.selector, tokenId));
    }

    function _onRoundRequested(uint256 tokenId, address user) internal {
        if (extension != address(0)) extension.functionDelegateCall(abi.encodeWithSelector(HackedGameExtension(extension).onRoundRequested.selector, tokenId, user));
    }

    function _nextSymbols(uint256 symbols, uint256 pattern, uint256 patternMask) internal pure returns (uint256) {
        do {
            symbols = _nextRandom(symbols);
        } while (!_matches(symbols, patternMask, pattern) && symbols != 0);
        
        return symbols;
    }

    function _matches(uint256 symbols, uint256 patternMask, uint256 pattern) internal pure returns (bool) {
        return (symbols & patternMask) == (pattern & patternMask);
    }

    function _getMatchingTokenTokenIds() internal view returns (uint256 tokenId, uint256 matches) {
        (
            uint256 gameId,
            uint256 roundId,
            uint256 pattern,,,,,
        ) = _decodeGameState();
        
        uint256 limit = 1 << (BITS - roundId);
        if(limit > 128) {
            return (0, limit);
        }

        for (uint256 i = 0; i < limit; ++i) {
            uint256 symbol = pattern + i;
            (
                uint256 _gameId,
                uint256 _tokenId
            ) = _decodeSymbolState(symbol);
            if (_gameId == gameId || _gameId == type(uint16).max) {
                tokenId = _tokenId;
                matches++;
            }
        }
    }

    function _getAllMatchingTokenTokenIds() internal view returns (uint256[] memory tokenIds, uint256 matches) {
        (
            uint256 gameId,
            uint256 roundId,
            uint256 pattern,,,,,
        ) = _decodeGameState();
        
        uint256 limit = 1 << (BITS - roundId);
        tokenIds = new uint256[](limit);

        for (uint256 i = 0; i < limit; ++i) {
            uint256 symbol = pattern + i;
            (
                uint256 _gameId,
                uint256 _tokenId
            ) = _decodeSymbolState(symbol);
            if (_gameId == gameId || _gameId == type(uint16).max) {
                tokenIds[matches] = _tokenId;
                matches++;
            }
        }
    }


    function tokenStates(uint256 _cursor, uint256 _length) external view returns (
        uint256 length,
        uint256[] memory symbols,
        uint256[] memory reentriesUsed,
        bool[] memory hacked
    ) {
        require(_cursor > 0 && _cursor <= LAST_TOKEN_ID, "Invalid cursor");
        length = _length;
        if (_cursor + length > LAST_TOKEN_ID + 1) {
            length = LAST_TOKEN_ID - _cursor + 1;
        }

        (uint256 _gameId,,uint256 pattern, uint256 patternMask,,,,) = _decodeGameState();

        symbols = new uint256[](length);
        reentriesUsed = new uint256[](length);
        hacked = new bool[](length);
        for (uint256 i = 0; i < length; ++i) {
            (
                uint256 gameId,
                uint256 defaultSymbols,
                uint256 _symbols,
                uint256 _reentriesUsed
            ) = _decodeTokenState(_cursor + i);
            symbols[i] = _gameId == gameId ? _symbols : defaultSymbols;
            reentriesUsed[i] = _gameId == gameId ? _reentriesUsed : 0;
            hacked[i] = !_matches(symbols[i], patternMask, pattern);
        }
    }
}