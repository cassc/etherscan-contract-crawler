// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

//***************************************************************#
//*KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK#
//*K                                                            K#
//*K                                                            K#
//*K                           KKKKKK                           K#
//*K                          IIIIIIII                          K#
//*K             NNN          NNNNNNNN          NNN             K#
//*K            GGGGGG          GGGG          GGGGGG            K#
//*K         C c C cC           CCC            Cc C cC          K#
//*K          K &#              OOOO              %& K          K#
//*K        , K &#             IIIII              %& K          K#
//*K          K &&             NNNNNN             K& K          K#
//*K          &,&/&           GGGGGGGG          #&/% &          K#
//*K           #% /&&        %#&& %&&#(        &% #,&           K#
//*K           ##   (%%&   %%%&&   %%%%&    &#%,  ((&           K#
//*K            && #&%(&&%%&#&&#    %%&%&&%&##&&%%%&            K#
//*K            KINGKINGKINGKINGKINGKINGKINGKINGKING            K#
//*K             ETHKINGCOIN            ETHKINGCOIN             K#
//*K             KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK             K#
//*K             GGGGGGGG                 GGGGGGGGG             K#
//*K                    KKKKKKKKKKKKKKKKKKK                     K#
//*K                                                            K#
//*K                                                            K#
//*K                         @ETHKingCoin                       K#
//*K                                                            K#
//*KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK#

import "./ERC20.sol";

uint256 constant PEON_MAX_HOLDING = 28000000 ether;
uint256 constant QUEEN_ALLOC = 750000000 ether;
uint256 constant KING_ALLOC = 28000000000 ether;

contract KingCoin is ERC20 {
  error LetThemEatCake();
  error NoMoreNoLess();
  error CantTakeMyThrone();

  event MayTheGamesBegin();

  address public immutable QUEEN; // The queen outlives the king
  address public uniswapV2Pair;
  bool private _initialized;

  constructor() ERC20("King Coin", "KING") payable {
    QUEEN = msg.sender;
    _mint(msg.sender, QUEEN_ALLOC + KING_ALLOC);
  }

  function initialize(address pair) external {
    if (_initialized) {
      revert CantTakeMyThrone();
    }
    if (msg.sender != QUEEN) {
      revert LetThemEatCake();
    }
    if (_balances[pair] != KING_ALLOC) {
      revert NoMoreNoLess();
    }
    uniswapV2Pair = pair;
    _initialized = true;
    emit MayTheGamesBegin();
  }

  function burn(uint256 value) external {
    _burn(msg.sender, value);
  }
}