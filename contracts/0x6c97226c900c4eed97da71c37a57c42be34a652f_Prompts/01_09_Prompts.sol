// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "ERC721A/ERC721A.sol";
import "solmate/auth/Owned.sol";
import "solmate/utils/ReentrancyGuard.sol";
import "src/ICurveDeposit.sol";
import "src/ICurveTokenMinter.sol";
import "src/ILiquidityGauge.sol";
import "src/IERC20.sol";

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒▒░░░░░░░░░░░░░░░░░░░▒▒▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒▒░░░░░░░░░░░░▒▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒▒░░░░░░░░░░░░░▒▒▒▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒▒▒▒░░░░░░░░░░░▒▒▒▓▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒▒▒▒░░░░░░░░░░▒▒▓▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒░░░░▒▒▒▒░░░░░░░░░▒▒▓▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒▒░░░▒▒▒▒▒░░░░░░░▒▒▓▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒░░▒░░░▒▒▒▒▒▒░░░░░▒▒▓▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒▒▒░░▒▒▒▒░░░░░░▒▓▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒▒▒▒▒▒▒▒▒▓▒░░░░▒▒▒▒▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▓▓░▒▓▓██▓▓▒▒▒▒▒▒▒▒▓▒▒▒▒▓▓▓█░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒████████████████████████████▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▓████████▓▒▒▒▒▒▒▒▒▒▒▓▒▒▒▒▒▒▒▒▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▓██▒▒▓███▒▓▒▒▒░▒▒▒▒▒▒░░▒░▒▒░▒░░░░▒▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▓█▓░░░▒█▓█▒▒▒▒░▒▒▒▒▒▒▒░░▒▒░░░░░░░░░▒▒▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒▓▓▒░░░▒▓█▓▓▒▒░░▒▒▒▒▒▒▒░░░░░░░░░░░░░░░░▒▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
// ░░░░░░░░░░░░░░░░░░░░░░░░░░░▒▓▓▒░░▒▒▒▓▓▓▓▒▒░▒▒▒▒▒░▒▒░░░░░░░░░░░░░░░░▒░░▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
// ░░░░░░░░░░░░░░░░░░░░░░░░░░▒▓▓▓░░▒▒▓▓█▓▓▓▒▒▒▒▒▒▒░░░▒░░░░░░░░░░░░░░░▒▒▒▒▒▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░
// ░░░░░░░░░░░░░░░░░░░░░░░░░░█▓▓░░▒▒▒▓▓▓▒█▒▒▒▒▒▒▒░░░░░░░░░░░░░░░░░░░░░▒▒▒▒▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░
// ░░░░░░░░░░░░░░░░░░░░░░░░░▓█▓░░▒▒▒▓▒▓▓▓█▒▒▒▒▒▒░░░░░░░░░░░░░░░░░░░░░▒▒▒▒▒▒▒░░░░░░░░░░░░░░░░░░░░░░░░░░░
// ░░░░░░░░░░░░░░░░░░░░░░░░▒██░░▒▒▒▓▒▒█▒▓▓▒▒▒▒▒░░▒▒░░░░░░░░░░░░░░░░░░▒▒▒▒▒▒░▒░░░░░░░░░░░░░░░░░░░░░░░░░░
// ░░░░░░░░░░░░░░░░░░░░░░░░██▒░▒▒▒▒▒▒▓▓▒▓▓▒▒▒▒░░▒█▓░░▓█░░░░░░░░░░░░▒▒▒▒▒░░░░▒▒░░░░░░░░░░░░░░░░░░░░░░░░░
// ░░░░░░░░░░░░░░░░░░░░░░░▒██░▒▒▒▒▒▒▒█▓▒▓▒▒▒▒▒▒▓▓██████▓▓▒▒█▒░░░░░░░▒░░░░░░░▒▒▒░░░░░░░░░░░░░░░░░░░░░░░░
// ░░░░░░░░░░░░░░░░░░░░░░░▒█▓▒▒▒▒▒▒▒▒█▒▓█▒▒▓████▓█▓░░███████▒░░░░░░░▒░░░░░░▒░▒░░░░░░░░░░░░░░░░░░░░░░░░░
// ░░░░░░░░░░░░░░░░░░░░░░░▓█▒▒▒▒▒▒▒▒▓▓▒█▓▒████▓░▒█▒░░█▓░▓███▒░░░░░░░░░░░░░░▒▒░░░░░░░░░░░░░░░░░░░░░░░░░░
// ░░░░░░░░░░░░░░░░░░░░░░░█▓▒▒▒▒▒▒▒▒█▓▓█▒▓████░░▒█▒░░█▓░░▓██▓░░░░░░░░░░░░░░▒▒░░░▒░░░░░░░░░░░░░░░░░░░░░░
// ░░░░░░░░░░░░░░░░░░░░░░░█▒▒▒▒▒▒▒▒▓█▓█▒▒█████░░▓█▒░░█▓░░░▓█▓░░░░░░░░░░░░░░░▒▒░░▒░░░░░░░░░░░░░░░░░░░░░░
// ░░░░░░░░░░░░░░░░░░░░░░▓█▒▒▒▒▒▒▒▒▓▓█▒▒▒█████▓░▒█▒░░█▓░░░░▒▒░░░░░░░░░░░░░░░░▒░░░░░░░░░░░░░░░░░░░░░░░░░
// ░░░░░░░░░░░░░░░░░░░░░▒█▓▒▒▒▒▒▒▒▒██▓▒▒▒██████▓▓█▒░░█▓░░░░░░░░░░░░░░░░░░░░░░░░░░░▒░░░░░░░░░░░░░░░░░░░░
// ░░░░░░░░░░░░░░░░░░░░░▓█▓▒▒▒▒▒▒▒▒█▓▒▒▒░▓█████████▓▓█▓▒░░░░░░░░░░░░░░░░░░░░░░░░░░▒░░░░░░░░░░░░░░░░░░░░
// ░░░░░░░░░░░░░░░░░░░░▒▓█▒▒▒▒▒▒▒▓██▒▒▒▒░░▓██████████████▓▓▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
// ░░░░░░░░░░░░░░░░░░░▒▒▓█▒▒▒▒▒▒▒███▓▒▒░░░░▒▓███████████████▓░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
// ░░░░░░░░░░░░░░░░░░░▒▒██▒▒▒▒▒▒▓███▓▒▒▒░░░░░░▒▓█████████████▓░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
// ░░░░░░░░░░░░░░░░░░▒▒███▓▒▒▒▓██▓▓▒░▒▒▒▒░░░░░░░▓█▒▒▒█████████▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
// ░░░░░░░░░░░░░░░░░░▒▒███▓▒▒▒▒▓▒░░░░▒▒▒░▒█▓░░░░▓█▒░▒█▓▒▓█████▓░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
// ░░░░░░░░░░░░░░░░░░▓███▓▒▒▒▒▒░░░░░░░░░░▒██░░░░▓█▒░▒█▓░░▓████▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
// ░░░░░░░░░░░░░░░░░▒▓██▒▒▒▒▒▒▒▒░░░░░░░░░▒██▓░░░▓█▒░▒█▓░░▓████▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
// ░░░░░░░░░░░░░░░░░▒▒▒▒▒▒▒▒▒▒▒░░░░░░░░░░▓███▓░░▓█▒░▒█▓░░▓███▓░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
// ░░░░░░░░░░░░░░░░░▒▒▒▒▒▒▒▒▒▒▒▒▒░░░░░░░░▓█████▒▓█▒░▒█▓▒▓███▓░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
// ░░░░░░░░░░░░░░░░░▒▒▒▒▒▒▒▒▒▒▒░░░░░░░░░░▓▓▒▒▓████▓▒▓█████▓▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
// ░░░░░░░░░░░░░░░░░▒▒▒▒▒▒▒▒▒▒░░░░░░░░░░░░░░░░░▒▓█▓▓▓█▓▒▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
// ░░░░░░░░░░░░░░░░░▒▒▒▒▒▒░▒▒▒░░░░░░░░░░░░░░░░░░▓█▒░▒█▓░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
// ░░░░░░░░░░░░░░░░░▒▒▒▒▒▒░░░░░░░░░░░░░░░░░░░░░░▒▒░░░▒▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
// ░░░░░░░░░░░░░░░░░░▒▒▒▒▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
// ░░░░░░░░░░░░░░░░░░░▒▒▒▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
// ░░░░░░░░░░░░░░░░░░░░░▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒▓▒▒▒▒▒░░░░░░░░░░░░░
// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒▓▓▒░░░░░░▒▒▓▓░░░░░░░░░░
// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▓▒░░░░░░░░░░░░░▓▓░░░░░░░░
// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░█░░░░░░░░░░░░░░░░▒█░░░░░░░
// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░█░░░░░░░░░░░░░░░░░░▓▒░░░░░░
// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒█░░░░░░░░░░░░░░░░░░▒▓░░░░░░
// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒▓█▓█░░░░░░░░░░░░░░░░░░▒▓░░░░░░
// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒▓▓▒█▒░▒▓░░░░░░░░░░░░░░░░░█░░░░░░░
// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▓▓▒░▒▓░░░░▒▓░░░░░░░░░░░░░░▒█░░░░░░░░
// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▓▓▒░░░▓▒░░░░░░░▓▓▒░░░░░░░░░▒▓▒░░░░░░░░░
// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒▓▒░░░░▓█░░░░░░░░░░░░▒▒▓▒▒▒▓▒▒░░░░░░░░░░░░
// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒▓▓░░░░░░▓▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▓▓▒░░░░░░▒▓░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒█▓░░░░░░░░▓▓░░░░░░░░░░░░░░░▓▓▓▒▒▒▒▒▓▓▒░░░░░░░░░░░
// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒▓▓▒░░░░░░░░░▓▒░░░░░░░░░░░░░▒▓▒░░░░░░░░░░▒▓▓░░░░░░░░░
// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▓▓▒░░░░░░░░░░░█░░░░░░░░░░░░░░▓▓░░░░░░░░░░░░░░░▓▒░░░░░░░
// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▓▓▒░░░░░░░░░░░░▒▓░░░░░░░░░░░░░░▒▓░░░░░░░░░░░░░░░░░█░░░░░░░
// ░░░░░░░░░░░░▒▓▓▓▓▓▓▓▓▓▒░░░░░░░░░░░░░░░░▒▓▒░░░░░░░░░░░░░░▓▒░░░░░░░░░░░░░░░█░░░░░░░░░░░░░░░░░░▒▓░░░░░░
// ░░░░░░░░░▒▓▓▒░░░░░░░░░▒▓▓░░░░░░░░░░░▒▓▓░░░░░░░░░░░░░░░▒█░░░░░░▒▒▒▒▒▒▒▒▓█▓█░░░░░░░░░░░░░░░░░░▒▓░░░░░░
// ░░░░░░░░▓▓░░░░░░░░░░░░░░▒█░░░░░░░▒▓▓▒░░░░░░░░░░░░░░▒▒▓█▒▒▒▒▒▒▒░░░░░░░▓▓░░▓▒░░░░░░░░░░░░░░░░░█░░░░░░░
// ░░░░░░░▓▓░░░░░░░░░░░░░░░░▒█░░░▒▓▓▒░░░░░░▒▒▒▒▒▓▒▒▒▒▒▒█▒░░░░░░░░░░░░▒▓▒░░░░░▓▒░░░░░░░░░░░░░░░▓▒░░░░░░░
// ░░░░░░░█░░░░░░░░░░░░░░░░░░▓▓▓█▓▓▒▓▓▒▒▒▒▒░░░░░░░░░░▓▓░░░░░░░░░░░░▓▓▒░░░░░░░░▒▓▒░░░░░░░░░░░▓▓░░░░░░░░░
// ░░░░░░░█░░░░░░░░░░░░░░░░░░▓███▓▒░░░░░░░░░░░░░░░░░█▒░░░░░░░░░░░▓▓░░░░░░░░░░░░░▒▓▓▒▒░░░▒▓▓▓░░░░░░░░░░░
// ░░░░░░░█▒░░░░░░░░░░░░░░░░░█▒▒██▒▓▓▓▓▒░░░░░░░░░░▒█░░░░░░░░░░░▓▓░░░░░░░░░░░░░░░░░░░▒▒▒▒▒░░░░░░░░░░░░░░
// ░░░░░░░░█▒░░░░░░░░░░░░░░░▓▓░░░█▓▓▒░░░▒▓▓▓▒▒░░░▓▓░░░░░░░░░░▓▓░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
// ░░░░░░░░░▓▓▒░░░░░░░░░░░▒▓▒░░░░░▓▓▒▓▓░░░░░░░▒▓██▒░░░░░░░▒▓▒░░░░░░░░░░░░░░░░░░░░░▒▒▒▓▓▒▒▒▒░░░░░░░░░░░░
// ░░░░░░░░░░░▓▓▓▒▒▒▒▒▒▒▓▓▒░░░░░░░░▒█▒░▓▓░░░░░▒▓░░░▒▓▒▓▒▒█▒░░░░░░░░░░░░░░░░░░░░▒▓▒░░░░░░░░▒▓▓▒░░░░░░░░░
// ░░░░░░░░░░░░░░░▒▒▒▒▒░░░░░░░░░░░░░░▒▓░░▒▓▒░▓▓░░░░░░░▒▓▒▒▓▓▓▒▒░░░░░░░░░░░░░░▒▓▒░░░░░░░░░░░░░▒▓░░░░░░░░
// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░█░░░▓█▓░░░░░▒▓▓░░░░░░░░▒▒▓▓▓▒░░░░░░░░▒▓░░░░░░░░░░░░░░░░▒█░░░░░░░
// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▓▒▒▓░▒▓▒░▒▓▒░░░░░░░░░░░░░░░░▒▓▓▓▓▒░░█░░░░░░░░░░░░░░░░░░▓▒░░░░░░
// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░██░░░░▓██░░░░░░░░░░░░░░░░░░░░░░░▒███░░░░░░░░░░░░░░░░░░▒▓░░░░░░
// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▓▒▒▓░▒▓▒░▒▓▒░░░░░░░░░░░░░░░░▒▓▓▓▓▒░░█░░░░░░░░░░░░░░░░░░▓▒░░░░░░
// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒█░░░▓█▓░░░░░▒▓▓▒░░░░░░░▒▒▓▓▓▒░░░░░░░░▒█░░░░░░░░░░░░░░░░▒█░░░░░░░
// ░░░░░░░░░░░░░░▒▒▒▒▒▒░░░░░░░░░░░░░░▓▓░░▒▓▒░▓▓░░░░░░░▒▓▒▒▓▓▓▒▒░░░░░░░░░░░░░░▒▓▒░░░░░░░░░░░░░▒▓░░░░░░░░
// ░░░░░░░░░░░▓▓▓▒▒▒▒▒▒▒▓▓▒░░░░░░░░▒█▒░▓▓░░░░░▒▓░░░▒▓▒▓▓▒▓▒░░░░░░░░░░░░░░░░░░░░▒▓▒▒░░░░░░░▒▓▓▒░░░░░░░░░
// ░░░░░░░░░▓▓░░░░░░░░░░░░▒▓▒░░░░░▓▓▒▓▓░░░░░░▒▒▓██▒░░░░░░░░▓▓░░░░░░░░░░░░░░░░░░░░░▒▒▒▒▒▒▒▒▒░░░░░░░░░░░░
// ░░░░░░░░█▒░░░░░░░░░░░░░░░▓▓░░░█▓▓▒░░░▒▓▓▓▒▒░░░▓▓░░░░░░░░░░▓▓░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
// ░░░░░░░█▒░░░░░░░░░░░░░░░░░█▒▓██▓▓▒▓▓▒░░░░░░░░░░░█░░░░░░░░░░░▓▓░░░░░░░░░░░░░░░░░░░▒▒▒▒▒░░░░░░░░░░░░░░
// ░░░░░░░█░░░░░░░░░░░░░░░░░░▓███▓░░░░░░░░░░░░░░░░░░█▓░░░░░░░░░░░▓▓░░░░░░░░░░░░░▒▓▓▒▒░░░▒▒▓▓░░░░░░░░░░░
// ░░░░░░░█░░░░░░░░░░░░░░░░░░▓▓▓█▓▓▒▒▓▒▒▓▒▒░░░░░░░░░░▓▓░░░░░░░░░░░░▓▓▒░░░░░░░░▒▓▒░░░░░░░░░░░▒▓░░░░░░░░░
// ░░░░░░░▓▓░░░░░░░░░░░░░░░░▒█░░░▒▓▓▒░░░░░░▒▒▒▒▒▓▒▒▒▒▒▒█▒░░░░░░░░░░░░▒▓▒░░░░░▓▒░░░░░░░░░░░░░░░▓▒░░░░░░░
// ░░░░░░░░▓▓░░░░░░░░░░░░░░▒█░░░░░░░▒▓▓▒░░░░░░░░░░░░░░░▒▓█▒▒▒▒▒▒▒▒░░░░░░▓▓░░▓▒░░░░░░░░░░░░░░░░░█░░░░░░░
// ░░░░░░░░░▒▓▓▒░░░░░░░░░▒▓▓░░░░░░░░░░░▒▓▓░░░░░░░░░░░░░░░░█░░░░░░▒▒▒▓▒▒▒▒▓█▓█░░░░░░░░░░░░░░░░░░▒▓░░░░░░
// ░░░░░░░░░░░░▒▓▓▓▓▓▓▓▓▓▒░░░░░░░░░░░░░░░░▒▓▒░░░░░░░░░░░░░░▓▒░░░░░░░░░░░░░░░█░░░░░░░░░░░░░░░░░░▒▓░░░░░░
// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒▓▒░░░░░░░░░░░░▒▓░░░░░░░░░░░░░░▒▓░░░░░░░░░░░░░░░░░█░░░░░░░
// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▓▓▒░░░░░░░░░░░█▒░░░░░░░░░░░░░▓▓░░░░░░░░░░░░░░░█▒░░░░░░░
// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒▓▓▒░░░░░░░░░▓▓░░░░░░░░░░░░░░▓▓░░░░░░░░░░▒▓▓░░░░░░░░░
// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒█▓░░░░░░░░▒▓░░░░░░░░░░░░░░░▓▓▓▒▒▒▒▓▓▓▒░░░░░░░░░░░
// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▓▓▒░░░░░░▒▓░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒▓▓░░░░░░▓▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒▓▒░░░░▓█▒░░░░░░░░░░▒▒▓▒▒▒▒▓▒▒░░░░░░░░░░░░
// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒▓▒░░░▓▓░░░░░░░▓▓▒░░░░░░░░░▒▓▒░░░░░░░░░
// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▓▓▒░▒▓░░░░▒▓░░░░░░░░░░░░░░▒█░░░░░░░░
// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒▒▓▓█▒░▒▓░░░░░░░░░░░░░░░░░█░░░░░░░
// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▓█▓█░░░░░░░░░░░░░░░░░░▒▓░░░░░░
// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒█░░░░░░░░░░░░░░░░░░▒▓░░░░░░
// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░█▒░░░░░░░░░░░░░░░░░▓▒░░░░░░
// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░█░░░░░░░░░░░░░░░░▒▓░░░░░░░
// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▓▒░░░░░░░░░░░░░▓▓░░░░░░░░
// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒▓▓▒░░░░░░▒▒▓▓░░░░░░░░░░
// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒▒▓▒▓▒▒░░░░░░░░░░░░░
// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// @title Prompts - an experiment in near zero risk NFT fundraising via annuities
/// @author @EtDu
/// @notice Deposit ETH to mint an NFT. NFTs represent prompts for AI image generation. 
/// All proceeds are locked in a curve pool to generate yield.
/// All of the yield is collected by us, so we can build an AI supercomputer.
/// Holders of the NFT are entitled to use the supercomputer.
/// Redeem the NFT to withdraw the principle deposit amount at any time, minus the service fee.
/// This model is also useful for non profits or NGOs who wish to capitalize on annuities without regulatory risk.
/// The only investment risk is smart contract exploitation, but if that happens we may as well
/// just quit crypto anyway. Enjoy!
/// @dev Intended for Ethereum Mainnet only
contract Prompts is ERC721A, Owned, ReentrancyGuard {
  /*//////////////////////////////////////////////////////////////
                          NFT VARIABLES
  //////////////////////////////////////////////////////////////*/

  string public baseURI;
  string public provenanceHash;

  bool provenanceSet;

  uint256 public maxPossibleSupply;
  uint256 public mintPrice;

  /*//////////////////////////////////////////////////////////////
                          ANNUITY VARIABLES
  //////////////////////////////////////////////////////////////*/

  // deposit ETH to the Lido Curve ETH/STETH pool
  address lidoCurvePoolAddress = 0xDC24316b9AE028F1497c275EB9192a3Ea0f67022;
  ICurveDeposit lidoCurvePool = ICurveDeposit(lidoCurvePoolAddress);

  // receive ETH/STETH LP token in return
  address ETHstETHLPTokenAddress = 0x06325440D014e39736583c165C2963BA99fAf14E;
  IERC20 ETHstETHLPToken = IERC20(ETHstETHLPTokenAddress);

  // stake LP to the Guage and receive Guage tokens in return
  // claim LDO token rewards
  // withdraw when necessary to credit NFT redeems 
  address stETHLiquidityGaugeAddress = 0x182B723a58739a9c974cFDB385ceaDb237453c28;
  ILiquidityGauge stETHLiquidityGauge = ILiquidityGauge(stETHLiquidityGaugeAddress);

  // mint CRV token rewards
  address curveTokenMinterAddress = 0xd061D61a4d941c39E5453435B6345Dc261C2fcE0;
  ICurveTokenMinter curveTokenMinter = ICurveTokenMinter(curveTokenMinterAddress);

  // send CRV token rewards to owner
  address curveTokenAddress = 0xD533a949740bb3306d119CC777fa900bA034cd52;
  IERC20 curveToken = IERC20(curveTokenAddress);

  // send LDO rewards to owner
  address ldoAddress = 0x5A98FcBEA516Cf06857215779Fd812CA3beF1B32;
  IERC20 ldoToken = IERC20(ldoAddress);

  // send STETH liquidity back to depositor
  address stETHTokenAddress = 0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84;
  IERC20 stETHToken = IERC20(stETHTokenAddress);

  // redemption fee of 0.3%. Covers Curve protocol fees and any withdrawal slippage
  uint256 immutable fee = 300;
  uint256 immutable denominator = 100000;
  // track total ETH locked by depositors
  uint256 public totalETHLocked;
  // map token IDs to boolean. Whether or not the given tokenID is redeemed
  mapping(uint256 => bool) redeemed;

  /*//////////////////////////////////////////////////////////////
                            CONSTRUCTOR
  //////////////////////////////////////////////////////////////*/

  constructor(
    uint256 _maxPossibleSupply,
    uint256 _mintPrice
  ) ERC721A("Prompts", "PROMPTS") Owned(msg.sender) {
    maxPossibleSupply = _maxPossibleSupply;
    mintPrice = _mintPrice;
    // Approve liquidity Gauge to spend LP tokens once
    ETHstETHLPToken.approve(stETHLiquidityGaugeAddress, 2**256 - 1);
  }

  /*//////////////////////////////////////////////////////////////
                            NFT LOGIC
  //////////////////////////////////////////////////////////////*/

  /// @notice Sets provenance hash for token image data. Preserves ordering and authenticity.
  /// @param newHash new provenance hash to set
  function setProvenanceHash(string calldata newHash) public onlyOwner {
    require(!provenanceSet);
    provenanceHash = newHash;
    provenanceSet = true;
  }

  /// @notice Mints a token. Must send valid ETH amount according to mintPrice.
  /// @param amount amount of tokens to mint
  function mint(uint256 amount) nonReentrant external payable {
    require(totalSupply() + amount <= maxPossibleSupply, "Max possible supply reached!");
    require(mintPrice * amount == msg.value, "Invalid ETH amount sent");
    _safeMint(msg.sender, amount);
  }

  /// @notice Internal helper function, gets the base URI
  function _baseURI() internal view override returns (string memory) {
    return baseURI;
  }

  /// @notice Sets the base URI for the token metadata
  /// @param newURI New base URI
  function setBaseURI(string calldata newURI) external onlyOwner {
    baseURI = newURI;
  }

  function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
  ) external returns (bytes4) {
    return ERC721A__IERC721Receiver.onERC721Received.selector;
  }

  receive() external payable {
    require(msg.sender == lidoCurvePoolAddress, "Only Lido Curve pool can send ETH!");
  }

  /*//////////////////////////////////////////////////////////////
                          ANNUITY LOGIC
  //////////////////////////////////////////////////////////////*/

  /// @notice Checks if token has been redeemed
  /// @param tokenID Token ID to check
  /// @return redeemed true or false
  function checkRedeemed(uint256 tokenID) external view returns (bool) {
    return redeemed[tokenID];
  }


  /// @notice Adds entire contract's ETH liquidity to the Lido/Curve ETH/STETH pool.
  /// Stakes LP tokens into the STETH liquidity gauge.
  /// Only callable by the owner to prevent bad actors from setting
  /// absurdly high slippage
  /// @param minTokenAmount minimum LP token amount to receive after slippage
  function addLiquidityAndStake(uint minTokenAmount) nonReentrant onlyOwner external {
    uint256 thisBalance = address(this).balance;
    lidoCurvePool.add_liquidity{ value: thisBalance }([thisBalance, 0], minTokenAmount);
    stETHLiquidityGauge.deposit(ETHstETHLPToken.balanceOf(address(this)));
    totalETHLocked += thisBalance;
  }

  /// @notice Redeem NFT to reclaim deposited ETH. Must approve token ID first.
  /// @param tokenID Token ID to redeem
  /// @param totalSupplyLP Total amount of ETH/STETH LP tokens in existence
  /// @param poolBalanceETH Total amount of ETH in the ETH/STETH curve pool
  /// @param poolBalanceSTETH Total amount of STETH in the ETH/STETH curve pool
  /// @param slippage Slippage to apply when withdrawing ETH & STETH
  function redeem(
    uint256 tokenID,
    uint256 totalSupplyLP,
    uint256 poolBalanceETH,
    uint256 poolBalanceSTETH,
    uint256 slippage
  ) external nonReentrant {
    require(ownerOf(tokenID) == msg.sender, "Must own tokenID!");
    require(!redeemed[tokenID], "Token ID must not be redeemed!");

    // contract permanently absorbs NFT, effectively burning it
    safeTransferFrom(msg.sender, address(this), tokenID);

    // get contract LP token balance
    uint256 promptsLPHoldings = stETHLiquidityGauge.balanceOf(address(this));

    // get token ID LP holdings, relative to total ETH locked by the contract
    // this does not include any ETH in this contract yet to be staked, so it may
    // be beneficial to call addLiquidityAndStake() first
    uint256 tokenIDLPHoldings = promptsLPHoldings * mintPrice / totalETHLocked;

    // if tokenID LP holdings exceeds the total holdings, withdraw total holdings
    // this could potentially only happen if the depositor is the last to withdraw
    if (tokenIDLPHoldings > promptsLPHoldings) {
      tokenIDLPHoldings = promptsLPHoldings;
    }

    stETHLiquidityGauge.withdraw(tokenIDLPHoldings);

    // apply slippage to withdraw ETH/STEH for tokenID's LP holdings
    uint256 ETHToRemove = poolBalanceETH * tokenIDLPHoldings / totalSupplyLP * (denominator - slippage) / denominator;
    uint256 stETHToRemove = poolBalanceSTETH * tokenIDLPHoldings / totalSupplyLP * (denominator - slippage) / denominator;

    uint256[2] memory coinsRemoved = lidoCurvePool.remove_liquidity(tokenIDLPHoldings, [ETHToRemove, stETHToRemove]);

    // apply fee
    uint256 ethToTransfer = coinsRemoved[0] - (coinsRemoved[0] * fee / denominator);
    uint256 stETHToTransfer = coinsRemoved[1] - (coinsRemoved[1] * fee / denominator);

    // send balances to depositor
    payable(msg.sender).transfer(ethToTransfer);
    stETHToken.transfer(msg.sender, stETHToTransfer);

    redeemed[tokenID] = true;
    totalETHLocked -= mintPrice;
  }

  /// @notice Claim staking rewards (LDO & CRV tokens) to owner. 
  /// Transfer any ETH & STETH accumulated by fees.
  function claimRewards() external {
    address thisAddress = address(this);
    stETHLiquidityGauge.claim_rewards();
    curveTokenMinter.mint(stETHLiquidityGaugeAddress);
    ldoToken.transfer(owner, ldoToken.balanceOf(thisAddress));
    curveToken.transfer(owner, curveToken.balanceOf(thisAddress));

    // claim ETH & STETH from fees
    payable(owner).transfer(thisAddress.balance + totalETHLocked - (totalSupply() * mintPrice - balanceOf(thisAddress) * mintPrice));
    stETHToken.transfer(owner, stETHToken.balanceOf(thisAddress));
  }
}