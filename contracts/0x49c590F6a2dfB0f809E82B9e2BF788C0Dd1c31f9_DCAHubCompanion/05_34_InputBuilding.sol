// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.7 <0.9.0;

import '@mean-finance/dca-v2-core/contracts/interfaces/IDCAHub.sol';
import '../interfaces/ISharedTypes.sol';

/// @title Input Building Library
/// @notice Provides functions to build input for swap related actions
/// @dev Please note that these functions are very expensive. Ideally, these would be used for off-chain purposes
library InputBuilding {
  /// @notice Takes a list of pairs and returns the input necessary to check the next swap
  /// @dev Even though this function allows it, the DCAHub will fail if duplicated pairs are used
  /// @return _tokens A sorted list of all the tokens involved in the swap
  /// @return _pairsToSwap A sorted list of indexes that represent the pairs involved in the swap
  function buildGetNextSwapInfoInput(Pair[] calldata _pairs)
    internal
    pure
    returns (address[] memory _tokens, IDCAHub.PairIndexes[] memory _pairsToSwap)
  {
    (_tokens, _pairsToSwap, ) = buildSwapInput(_pairs, new IDCAHub.AmountOfToken[](0));
  }

  /// @notice Takes a list of pairs and a list of tokens to borrow and returns the input necessary to execute a swap
  /// @dev Even though this function allows it, the DCAHub will fail if duplicated pairs are used
  /// @return _tokens A sorted list of all the tokens involved in the swap
  /// @return _pairsToSwap A sorted list of indexes that represent the pairs involved in the swap
  /// @return _borrow A list of amounts to borrow, based on the sorted token list
  function buildSwapInput(Pair[] calldata _pairs, IDCAHub.AmountOfToken[] memory _toBorrow)
    internal
    pure
    returns (
      address[] memory _tokens,
      IDCAHub.PairIndexes[] memory _pairsToSwap,
      uint256[] memory _borrow
    )
  {
    _tokens = _calculateUniqueTokens(_pairs, _toBorrow);
    _pairsToSwap = _calculatePairIndexes(_pairs, _tokens);
    _borrow = _calculateTokensToBorrow(_toBorrow, _tokens);
  }

  /// @dev Given a list of token pairs and tokens to borrow, returns a list of all the tokens involved, sorted
  function _calculateUniqueTokens(Pair[] memory _pairs, IDCAHub.AmountOfToken[] memory _toBorrow)
    private
    pure
    returns (address[] memory _tokens)
  {
    uint256 _uniqueTokens;
    address[] memory _tokensPlaceholder = new address[](_pairs.length * 2 + _toBorrow.length);

    // Load tokens in pairs onto placeholder
    for (uint256 i; i < _pairs.length; i++) {
      bool _foundA = false;
      bool _foundB = false;
      for (uint256 j; j < _uniqueTokens && !(_foundA && _foundB); j++) {
        if (!_foundA && _tokensPlaceholder[j] == _pairs[i].tokenA) _foundA = true;
        if (!_foundB && _tokensPlaceholder[j] == _pairs[i].tokenB) _foundB = true;
      }

      if (!_foundA) _tokensPlaceholder[_uniqueTokens++] = _pairs[i].tokenA;
      if (!_foundB) _tokensPlaceholder[_uniqueTokens++] = _pairs[i].tokenB;
    }

    // Load tokens to borrow onto placeholder
    for (uint256 i; i < _toBorrow.length; i++) {
      bool _found = false;
      for (uint256 j; j < _uniqueTokens && !_found; j++) {
        if (_tokensPlaceholder[j] == _toBorrow[i].token) _found = true;
      }
      if (!_found) _tokensPlaceholder[_uniqueTokens++] = _toBorrow[i].token;
    }

    // Load sorted into new array
    _tokens = new address[](_uniqueTokens);
    for (uint256 i; i < _uniqueTokens; i++) {
      address _token = _tokensPlaceholder[i];

      // Find index where the token should be
      uint256 _tokenIndex;
      while (_tokens[_tokenIndex] < _token && _tokens[_tokenIndex] != address(0)) _tokenIndex++;

      // Move everything one place back
      for (uint256 j = i; j > _tokenIndex; j--) {
        _tokens[j] = _tokens[j - 1];
      }

      // Set token on the correct index
      _tokens[_tokenIndex] = _token;
    }
  }

  /// @dev Given a list of pairs, and a list of sorted tokens, it translates the first list into indexes of the second list. This list of indexes will
  /// be sorted. For example, if pairs are [{ tokenA, tokenB }, { tokenC, tokenB }] and tokens are: [ tokenA, tokenB, tokenC ], the following is returned
  /// [ { 0, 1 }, { 1, 1 }, { 1, 2 } ]
  function _calculatePairIndexes(Pair[] calldata _pairs, address[] memory _tokens)
    private
    pure
    returns (IDCAHub.PairIndexes[] memory _pairIndexes)
  {
    _pairIndexes = new IDCAHub.PairIndexes[](_pairs.length);
    uint256 _count;

    for (uint8 i; i < _tokens.length; i++) {
      for (uint8 j = i + 1; j < _tokens.length; j++) {
        for (uint256 k; k < _pairs.length; k++) {
          if (
            (_tokens[i] == _pairs[k].tokenA && _tokens[j] == _pairs[k].tokenB) ||
            (_tokens[i] == _pairs[k].tokenB && _tokens[j] == _pairs[k].tokenA)
          ) {
            _pairIndexes[_count++] = IDCAHubSwapHandler.PairIndexes({indexTokenA: i, indexTokenB: j});
          }
        }
      }
    }
  }

  /// @dev Given a list of tokens to borrow and a list of sorted tokens, it translated the first list into a list of amounts, sorted by the indexed of
  /// the seconds list. For example, if `toBorrow` are [{ tokenA, 100 }, { tokenC, 200 }, { tokenB, 500 }] and tokens are [ tokenA, tokenB, tokenC], the
  /// following is returned [100, 500, 200]
  function _calculateTokensToBorrow(IDCAHub.AmountOfToken[] memory _toBorrow, address[] memory _tokens)
    private
    pure
    returns (uint256[] memory _borrow)
  {
    _borrow = new uint256[](_tokens.length);

    for (uint256 i; i < _toBorrow.length; i++) {
      uint256 j;
      while (_tokens[j] != _toBorrow[i].token) j++;
      _borrow[j] = _toBorrow[i].amount;
    }
  }
}