/*
 ___        ______  ___________  ___________  _______   _______   ___  ___ 
|"  |      /    " \("     _   ")("     _   ")/"     "| /"      \ |"  \/"  |
||  |     // ____  \)__/  \\__/  )__/  \\__/(: ______)|:        | \   \  /
|:  |    /  /    ) :)  \\_ /        \\_ /    \/    |  |_____/   )  \\  \/
 \  |___(: (____/ //   |.  |        |.  |    // ___)_  //      /   /   /
( \_|:  \\        /    \:  |        \:  |   (:      "||:  __   \  /   /
 \_______)\"_____/      \__|         \__|    \_______)|__|  \___)|___/

*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

/// @notice 一张彩票信息
struct Lottery {
  /// @notice 玩法金额
  uint256 amount;

  /// @notice 期数
  uint256 period;

  /// @notice 编码
  uint256 code;

  /// @notice 号码
  uint256 number;

  /// @notice 彩票创建者
  address creator;

  /// @notice 是否开奖
  uint256 isOpen;

  /// @notice 中奖号码
  uint256 winNumber;

  /// @notice 是否中奖
  uint256 isWin;

  /// @notice 中奖金额
  uint256 winAmount;

  /// @notice 是否兑奖
  uint256 isRedeem;
}