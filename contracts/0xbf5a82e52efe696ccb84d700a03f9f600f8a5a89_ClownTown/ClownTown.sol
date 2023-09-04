/**
 *Submitted for verification at Etherscan.io on 2023-08-05
*/

/**
// SPDX-License-Identifier: MIT
    __  _       ___   __    __  ____       ______   ___   __    __  ____  
   /  ]| |     /   \ |  |__|  ||    \     |      | /   \ |  |__|  ||    \ 
  /  / | |    |     ||  |  |  ||  _  |    |      ||     ||  |  |  ||  _  |
 /  /  | |___ |  O  ||  |  |  ||  |  |    |_|  |_||  O  ||  |  |  ||  |  |
/   \_ |     ||     ||  `  '  ||  |  |      |  |  |     ||  `  '  ||  |  |
\     ||     ||     | \      / |  |  |      |  |  |     | \      / |  |  |
 \____||_____| \___/   \_/\_/  |__|__|      |__|   \___/   \_/\_/  |__|__|
                                                                          
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣤⣤⠶⠖⠒⠛⠛⠛⠒⠶⢦⣤⣤⡶⠶⠶⠶⠶⠶⢶⣶⣦⣤⣴⣤⣤⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣀⣤⣤⣤⣴⣤⣤⣴⡶⠛⠉⠁⠀⠀⠀⠀⠀⠀⠀⠀⣠⠞⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣰⡟⠉⠙⢿⣧⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣴⡿⠛⠉⠀⠀⢀⣴⠏⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⡾⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠐⢿⡀⠀⠀⠀⠻⣷⣄⡀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣴⡿⠁⠀⠀⠀⠀⣠⠞⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠐⣇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⣿⡄⠀⠀⠀⠀⠙⠻⣷⣄⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣴⡿⠋⠀⠀⠀⠀⠀⣰⠋⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣸⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣾⠃⠀⠀⠀⠀⠀⠀⠈⢿⣦⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⢠⣴⠟⠉⠀⠀⠀⠀⠀⠀⣼⠃⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣠⠞⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣶⠟⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⢻⣦⠀⠀⠀
⠀⠀⠀⠀⠀⠀⢠⣿⠇⠀⠀⠀⠀⠀⠀⠀⢸⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⡞⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣿⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣼⡿⣷⣄⠀
⠀⠀⠀⠀⠀⠀⢸⣿⣦⡀⠀⠀⠀⠀⠀⠀⠀⠹⣆⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢻⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣿⠃⠀⠀⠀⠀⠀⠀⠀⠐⣼⡟⠋⠀⠈⢻⣇
⠀⠀⠀⠀⠀⢠⣾⠟⢸⡇⠀⠀⠀⠀⠀⠀⠀⠀⣸⡆⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣼⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣼⠋⠀⠀⠀⠀⠀⠀⠀⠀⠀⢿⡆⠀⠀⠀⠸⣿
⠀⠀⠀⠀⢠⣿⠇⠀⣾⡇⠀⠀⠀⠀⠀⠀⠀⠀⣽⠃⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣸⠁⠀⠀⢀⣀⣀⡀⠀⠀⠀⠀⠀⠀⢠⡞⠃⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⠀⠀⠀⣼⡏
⠀⠀⠀⠀⢸⣿⠀⠀⠹⣧⠀⠀⠀⠀⠀⠀⠀⠀⢿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣀⣿⣤⠶⠛⠛⠋⠉⠙⠛⠓⠶⣤⡀⠀⢸⡇⠀⠀⣠⣤⣴⠶⠶⠟⠛⠻⠶⢾⣿⣤⡀⠛⢹⣇
⠀⠀⠀⣰⡿⠋⠀⠀⠀⢹⡆⠀⠀⠀⠀⠀⠀⠀⠈⢷⣀⠀⠀⠀⠀⠀⢀⣤⡶⠟⠋⠁⠀⠀⠀⣀⣀⣀⣀⣀⠀⠀⠈⠻⣦⡘⣷⡾⠟⠉⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠉⠻⣷⣼⡏
⠀⠀⢰⣿⠃⠀⠀⠀⠀⢾⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠉⠓⠶⣤⣠⣴⠟⠁⢀⣀⣤⡶⠾⠛⠋⠉⠁⠀⠉⠉⠛⢶⣄⠀⢹⣿⠋⣀⣠⣶⠾⠟⠛⠋⠉⠉⠛⠛⠷⣦⣀⠀⢹⣿⠃
⠀⠀⢸⣿⠀⠀⠀⠀⠀⠸⣧⡀⠀⠀⠀⠀⢀⣠⣤⣶⠾⠿⠟⢛⣉⣤⡴⠾⠛⠉⠀⣀⣀⣀⠀⠀⠀⠀⠀⠀⠀⠀⠘⣷⣼⣿⠿⠛⣹⠃⠀⠀⢀⣀⣀⡀⠀⠀⠀⠀⠙⢷⣆⣿⠀
⠀⠀⠘⣿⡆⠀⠀⠀⠀⠀⠙⠳⣤⣄⣀⣴⡿⠋⠉⠀⣠⡶⠛⠛⡫⠁⠀⠀⢀⡴⠛⢻⣿⣿⣿⣦⡀⠀⠀⠀⠀⠀⠀⠸⡿⠃⠀⢰⠁⠀⣤⠞⠛⢿⣿⣿⣶⡄⠀⠀⠀⠀⢹⣇⠀
⠀⠀⣠⣿⠃⠀⠀⠀⠀⠀⠀⢀⣠⣽⡿⠋⠀⠀⠀⣰⣿⠀⠀⠀⡇⠀⠀⠀⣿⡀⢀⣼⣿⣿⣿⣿⣇⠀⠀⠀⠀⠀⠀⢀⣿⣀⣀⡀⠀⢰⣧⣀⣠⣾⣿⣿⣿⡇⠀⠀⠀⠀⢸⣿⠀
⠀⢸⣿⡇⠀⠀⠀⠀⠀⣀⣾⡿⠛⠁⠀⠀⠀⠀⣸⠟⢻⣆⠀⠀⢳⡀⠀⠀⢿⣿⣿⣿⣿⣿⣿⣿⡏⠀⠀⠀⣀⣴⠾⠛⠉⢉⣿⢿⣿⣾⣿⣿⣿⣿⣿⣿⣿⠇⠀⠀⠀⠀⣾⠇⠀
⠀⠈⠻⣿⣦⣤⣀⣀⣴⡿⠋⠀⠀⠀⠀⠀⠀⠀⢿⡄⠀⠙⢷⣄⡀⠙⢤⡀⠈⠻⠿⣿⣿⡿⠿⠋⠀⠀⢀⣼⣟⣁⠀⠀⠰⣟⠀⠀⠈⠻⣿⣿⡿⠿⠟⠛⠁⠀⠀⠀⢀⣾⢷⡄⠀
⠀⠀⠀⠈⢙⣿⠟⠛⠉⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⢿⣄⠀⠀⠉⠻⢶⣤⣄⣀⡀⠀⠠⠀⢀⣀⡀⠠⣤⣾⢿⣿⣿⡄⠀⠀⠙⢷⣄⣀⣠⣿⠻⣷⣀⣀⣀⣀⣠⣤⡾⠟⠁⣸⡏⠀
⠀⠀⠀⢠⣿⠋⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠙⠷⠀⠀⠀⠀⠈⠉⠛⠛⠛⠒⠶⠶⠶⠶⠿⢻⣿⣾⣿⣿⣷⡄⠀⠀⠀⠈⣿⠋⠙⣶⣿⠋⠉⠉⠉⠉⠀⣀⣤⣾⡏⠀⠀
⠀⠀⢠⣿⠃⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣴⠟⠉⠉⠉⠙⠳⢦⣄⡀⠀⠀⠀⠀⠀⠘⣿⡘⣿⣿⣿⣿⣷⣤⣀⠀⠘⠷⠾⢻⡿⠀⠀⠀⣀⠀⠀⠁⠀⠙⣿⡄⠀
⠀⢀⣾⠏⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⡇⠀⠰⣦⣀⠀⠀⠀⠈⠙⠛⠶⢶⣤⣄⣀⣹⣷⣜⠻⣿⣿⣿⣿⣿⣿⠀⢀⣴⣿⠶⠞⠛⠉⠉⠙⣷⠀⠀⠀⢹⣿⠀
⠀⣸⡿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢿⡀⠀⢿⣄⠀⠉⠻⢿⣦⣄⣀⠀⠀⠀⠀⠀⠀⠉⠉⠉⠛⠿⣶⣤⣭⣭⣤⡴⠾⠟⠋⠀⠀⠀⠀⠀⣀⣴⡿⠀⠀⠀⢸⣿⠀
⠀⣿⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠸⣷⡀⠀⠛⢦⣄⡀⠀⠈⠉⠛⠛⠶⠶⣤⣤⣤⣄⣀⣀⣀⣀⣀⣀⣀⣀⣀⣀⣀⣤⣤⣤⡴⠶⠾⢿⡟⠉⠀⠀⠀⠀⣸⡿⠀
⠀⣿⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠻⢦⣄⠀⠉⠻⢶⣤⣄⣀⠀⠀⠀⠀⠈⠉⠉⠉⠉⠙⠛⠛⠛⠛⠛⠛⠋⠉⠉⠉⠀⠀⠀⢀⣼⠇⠀⠀⠀⠀⢀⣿⠃⠀
⠀⣿⣇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠉⠉⠛⠻⠶⠶⠶⠶⣦⣤⣤⣤⣤⣤⣤⣤⣤⣤⣤⣤⣶⠶⠶⠶⠿⠛⠁⠀⠀⠀⠀⢀⣿⠇⠀⠀
⠀⢸⣿⣦⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣀⣠⣤⣤⣀⣀⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣀⣠⣤⣤⣄⠀⠀⠀⠀⠀⠀⠀⠀⠀⣠⣿⠏⠀⠀⠀
⠀⣿⣿⣿⣿⣦⣀⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣼⠏⢠⡟⠀⠈⢻⡛⠻⢦⣄⡀⢀⣀⣀⡀⠀⣀⡴⠞⢻⡏⠀⠀⣿⣿⣧⠀⠀⠀⠀⠀⣀⣤⣾⣿⣇⠀⠀⠀⠀
⢠⣿⣿⣿⣿⣿⣿⣿⣶⣦⣤⣀⣀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⡿⠙⣎⢷⣄⣀⣼⣇⣀⠀⢨⣿⣿⡉⠉⢹⣿⠛⠁⣀⣤⡷⢤⠴⢻⠀⣿⣀⣤⣴⣶⣿⣿⣿⣿⣿⣿⣦⠀⠀⠀
⢸⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣷⣶⣶⣶⣶⣶⣶⣾⣇⣠⡏⣠⡭⢭⡀⢻⣍⢉⣻⣇⣈⣙⣾⡿⣿⣟⡉⣹⢁⡤⠒⢦⡀⠓⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣧⡀⠀
⢸⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠀⢰⡏⠀⠀⣹⠄⢙⡯⠉⣿⣭⣍⣀⣴⣟⠉⠉⠉⢸⡄⠀⢀⣷⡴⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣷⠀
⢸⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡈⢷⠟⢦⢶⣋⣀⣭⣴⣿⣿⣿⣿⣿⣿⣿⣷⣤⣛⡀⠙⠛⠋⡯⢀⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡇
⢸⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣇

clowntown.bet
t.me/clowntown_bsc

*/
pragma solidity ^0.8.0;


interface IERC165 {

 function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

pragma solidity ^0.8.0;


contract ERC165 is IERC165 {
 
 function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 return interfaceId == type(IERC165).interfaceId;
 }
}




pragma solidity ^0.8.0;

library SignedMath {

 function max(int256 a, int256 b) internal pure returns (int256) {
 return a > b ? a : b;
 }


 function min(int256 a, int256 b) internal pure returns (int256) {
 return a < b ? a : b;
 }




 function average(int256 a, int256 b) internal pure returns (int256) {
 int256 x = (a & b) + ((a ^ b) >> 1);
 return x + (int256(uint256(x) >> 255) & (a ^ b));
 }

 function abs(int256 n) internal pure returns (uint256) {
 unchecked {
 // must be unchecked in order to support `n = type(int256).min`
 return uint256(n >= 0 ? n : -n);
 }
 }
 
}

pragma solidity ^0.8.0;


library Math {
 enum Rounding {
 Down, 
 Up, 
 Zero 
 }

 function max(uint256 a, uint256 b) internal pure returns (uint256) {
 return a > b ? a : b;
 }

 function min(uint256 a, uint256 b) internal pure returns (uint256) {
 return a < b ? a : b;
 }

 function average(uint256 a, uint256 b) internal pure returns (uint256) {
 // (a + b) / 2 can overflow.
 return (a & b) + (a ^ b) / 2;
 }


 function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
 return a == 0 ? 0 : (a - 1) / b + 1;
 }


 function mulDiv(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 result) {
 unchecked {
 uint256 prod0; // Least significant 256 bits of the product
 uint256 prod1; // Most significant 256 bits of the product
 assembly {
 let mm := mulmod(x, y, not(0))
 prod0 := mul(x, y)
 prod1 := sub(sub(mm, prod0), lt(mm, prod0))
 }

 if (prod1 == 0) {
 return prod0 / denominator;
 }

 require(denominator > prod1, "Math: mulDiv overflow");


 uint256 remainder;
 assembly {
 remainder := mulmod(x, y, denominator)

 prod1 := sub(prod1, gt(remainder, prod0))
 prod0 := sub(prod0, remainder)
 }


 uint256 twos = denominator & (~denominator + 1);
 assembly {
 
 denominator := div(denominator, twos)

 prod0 := div(prod0, twos)

 twos := add(div(sub(0, twos), twos), 1)
 }

 prod0 |= prod1 * twos;

 uint256 inverse = (3 * denominator) ^ 2;

 inverse *= 2 - denominator * inverse; // inverse mod 2^8
 inverse *= 2 - denominator * inverse; // inverse mod 2^16
 inverse *= 2 - denominator * inverse; // inverse mod 2^32
 inverse *= 2 - denominator * inverse; // inverse mod 2^64
 inverse *= 2 - denominator * inverse; // inverse mod 2^128
 inverse *= 2 - denominator * inverse; // inverse mod 2^256

 result = prod0 * inverse;
 return result;
 }
 }

 function mulDiv(uint256 x, uint256 y, uint256 denominator, Rounding rounding) internal pure returns (uint256) {
 uint256 result = mulDiv(x, y, denominator);
 if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
 result += 1;
 }
 return result;
 }


 function sqrt(uint256 a) internal pure returns (uint256) {
 if (a == 0) {
 return 0;
 }

 uint256 result = 1 << (log2(a) >> 1);

 
 unchecked {
 result = (result + a / result) >> 1;
 result = (result + a / result) >> 1;
 result = (result + a / result) >> 1;
 result = (result + a / result) >> 1;
 result = (result + a / result) >> 1;
 result = (result + a / result) >> 1;
 result = (result + a / result) >> 1;
 return min(result, a / result);
 }
 }

 function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
 unchecked {
 uint256 result = sqrt(a);
 return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
 }
 }


 function log2(uint256 value) internal pure returns (uint256) {
 uint256 result = 0;
 unchecked {
 if (value >> 128 > 0) {
 value >>= 128;
 result += 128;
 }
 if (value >> 64 > 0) {
 value >>= 64;
 result += 64;
 }
 if (value >> 32 > 0) {
 value >>= 32;
 result += 32;
 }
 if (value >> 16 > 0) {
 value >>= 16;
 result += 16;
 }
 if (value >> 8 > 0) {
 value >>= 8;
 result += 8;
 }
 if (value >> 4 > 0) {
 value >>= 4;
 result += 4;
 }
 if (value >> 2 > 0) {
 value >>= 2;
 result += 2;
 }
 if (value >> 1 > 0) {
 result += 1;
 }
 }
 return result;
 }


 function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
 unchecked {
 uint256 result = log2(value);
 return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
 }
 }

 
 function log10(uint256 value) internal pure returns (uint256) {
 uint256 result = 0;
 unchecked {
 if (value >= 10 ** 64) {
 value /= 10 ** 64;
 result += 64;
 }
 if (value >= 10 ** 32) {
 value /= 10 ** 32;
 result += 32;
 }
 if (value >= 10 ** 16) {
 value /= 10 ** 16;
 result += 16;
 }
 if (value >= 10 ** 8) {
 value /= 10 ** 8;
 result += 8;
 }
 if (value >= 10 ** 4) {
 value /= 10 ** 4;
 result += 4;
 }
 if (value >= 10 ** 2) {
 value /= 10 ** 2;
 result += 2;
 }
 if (value >= 10 ** 1) {
 result += 1;
 }
 }
 return result;
 }


 function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
 unchecked {
 uint256 result = log10(value);
 return result + (rounding == Rounding.Up && 10 ** result < value ? 1 : 0);
 }
 }

 
 function log256(uint256 value) internal pure returns (uint256) {
 uint256 result = 0;
 unchecked {
 if (value >> 128 > 0) {
 value >>= 128;
 result += 16;
 }
 if (value >> 64 > 0) {
 value >>= 64;
 result += 8;
 }
 if (value >> 32 > 0) {
 value >>= 32;
 result += 4;
 }
 if (value >> 16 > 0) {
 value >>= 16;
 result += 2;
 }
 if (value >> 8 > 0) {
 result += 1;
 }
 }
 return result;
 }

 
 function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
 unchecked {
 uint256 result = log256(value);
 return result + (rounding == Rounding.Up && 1 << (result << 3) < value ? 1 : 0);
 }
 }
}

pragma solidity ^0.8.0;



library Strings {
 bytes16 private constant _SYMBOLS = "0123456789abcdef";
 uint8 private constant _ADDRESS_LENGTH = 20;

 function toString(uint256 value) internal pure returns (string memory) {
 unchecked {
 uint256 length = Math.log10(value) + 1;
 string memory buffer = new string(length);
 uint256 ptr;
 /// @solidity memory-safe-assembly
 assembly {
 ptr := add(buffer, add(32, length))
 }
 while (true) {
 ptr--;
 /// @solidity memory-safe-assembly
 assembly {
 mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
 }
 value /= 10;
 if (value == 0) break;
 }
 return buffer;
 }
 }


 function toString(int256 value) internal pure returns (string memory) {
 return string(abi.encodePacked(value < 0 ? "-" : "", toString(SignedMath.abs(value))));
 }

 function toHexString(uint256 value) internal pure returns (string memory) {
 unchecked {
 return toHexString(value, Math.log256(value) + 1);
 }
 }

 
 function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
 bytes memory buffer = new bytes(2 * length + 2);
 buffer[0] = "0";
 buffer[1] = "x";
 for (uint256 i = 2 * length + 1; i > 1; --i) {
 buffer[i] = _SYMBOLS[value & 0xf];
 value >>= 4;
 }
 require(value == 0, "Strings: hex length insufficient");
 return string(buffer);
 }


 function toHexString(address addr) internal pure returns (string memory) {
 return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
 }


 function equal(string memory a, string memory b) internal pure returns (bool) {
 return keccak256(bytes(a)) == keccak256(bytes(b));
 }
}

pragma solidity ^0.8.0;

contract Context {
 function _msgSender() internal view virtual returns (address) {
 return msg.sender;
 }

 function _msgData() internal view virtual returns (bytes calldata) {
 return msg.data;
 }
}
pragma solidity ^0.8.0;

interface IAccessControl {

 event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

 
 event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

 
 event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

 
 function hasRole(bytes32 role, address account) external view returns (bool);

 
 function getRoleAdmin(bytes32 role) external view returns (bytes32);

 
 function grantRole(bytes32 role, address account) external;

 function revokeRole(bytes32 role, address account) external;

 
 function renounceRole(bytes32 role, address account) external;
}


pragma solidity ^0.8.0;



contract AccessControl is Context, IAccessControl, ERC165 {
 struct RoleData {
 mapping(address => bool) members;
 bytes32 adminRole;
 }

 mapping(bytes32 => RoleData) private _roles;

 bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

 modifier onlyRole(bytes32 role) {
 _checkRole(role);
 _;
 }

 
 function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
 }

 
 function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
 return _roles[role].members[account];
 }


 function _checkRole(bytes32 role) internal view virtual {
 _checkRole(role, _msgSender());
 }

 
 function _checkRole(bytes32 role, address account) internal view virtual {
 if (!hasRole(role, account)) {
 revert(
 string(
 abi.encodePacked(
 "AccessControl: account ",
 Strings.toHexString(account),
 " is missing role ",
 Strings.toHexString(uint256(role), 32)
 )
 )
 );
 }
 }


 function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
 return _roles[role].adminRole;
 }

 function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
 _grantRole(role, account);
 }


 function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
 _revokeRole(role, account);
 }

 
 function renounceRole(bytes32 role, address account) public virtual override {
 require(account == _msgSender(), "AccessControl: can only renounce roles for self");

 _revokeRole(role, account);
 }

 
 function _setupRole(bytes32 role, address account) internal virtual {
 _grantRole(role, account);
 }

 function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
 bytes32 previousAdminRole = getRoleAdmin(role);
 _roles[role].adminRole = adminRole;
 emit RoleAdminChanged(role, previousAdminRole, adminRole);
 }

 
 function _grantRole(bytes32 role, address account) internal virtual {
 if (!hasRole(role, account)) {
 _roles[role].members[account] = true;
 emit RoleGranted(role, account, _msgSender());
 }
 }

 
 function _revokeRole(bytes32 role, address account) internal virtual {
 if (hasRole(role, account)) {
 _roles[role].members[account] = false;
 emit RoleRevoked(role, account, _msgSender());
 }
 }
}


pragma solidity ^0.8.0;


interface IERC20 {
 
 event Transfer(address indexed from, address indexed to, uint256 value);

 
 event Approval(address indexed owner, address indexed spender, uint256 value);

 
 function totalSupply() external view returns (uint256);

 
 function balanceOf(address account) external view returns (uint256);

 
 function transfer(address to, uint256 amount) external returns (bool);

 
 function allowance(address owner, address spender) external view returns (uint256);

 function approve(address spender, uint256 amount) external returns (bool);

 
 function transferFrom(address from, address to, uint256 amount) external returns (bool);
}




pragma solidity ^0.8.0;



interface IERC20Metadata is IERC20 {
 
 function name() external view returns (string memory);

 
 function symbol() external view returns (string memory);


 function decimals() external view returns (uint8);
}



pragma solidity ^0.8.0;




contract ClownTown is IERC20, IERC20Metadata, AccessControl {
 // Role-based access control
 bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
 bytes32 public constant OWNER_ROLE = keccak256("OWNER_ROLE");

 // Token details
 string private _name;
 string private _symbol;
 uint8 private _decimals;
 uint256 private _totalSupply;

 mapping(address => uint256) private _balances;
 mapping(address => mapping(address => uint256)) private _allowances;

 // Custom variables
 uint256 private constant _threshold1 = 69; // Threshold for transferring pot to the house address
 uint256 private constant _threshold2 = 420; // Threshold for transferring pot to the swapping wallet
 uint256 private constant _threshold3 = 1337; // Threshold for burning the pot balance
 uint256 private _pot; // Internal balance of the pot
 address private _house; // Address of the house wallet
 uint256 private _burnedTokens; // Total burned tokens

 uint256 private _fibonacciSequence;
 uint256 private _fibonacciIndex;

 // Events
 event HouseAddressChanged(address indexed previousHouse, address indexed newHouse);
 event PotTransferredToHouse(address indexed houseAddress, uint256 amount);
 event PotTransferredToSender(address indexed sender, uint256 amount);
 event PotBurned(uint256 amount);

 bool private _locked; // Variable to track reentrancy

 modifier nonReentrant() {
 require(!_locked, "Reentrant call");
 _locked = true;
 _;
 _locked = false;
 }

 constructor() {
 _name = "ClownTown";
 _symbol = "CLOWNS";
 _decimals = 18;
 _totalSupply = 1000000000 * 10**uint256(_decimals);

 _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
 _setupRole(ADMIN_ROLE, msg.sender);
 _setupRole(OWNER_ROLE, msg.sender);

 _balances[msg.sender] = _totalSupply;

 _house = address(0);
 _fibonacciSequence = 1;
 _fibonacciIndex = 1;
 }

 function name() public view virtual override returns (string memory) {
 return _name;
 }

 function symbol() public view virtual override returns (string memory) {
 return _symbol;
 }

 function decimals() public view virtual override returns (uint8) {
 return _decimals;
 }

 function totalSupply() public view virtual override returns (uint256) {
 return _totalSupply;
 }

 function balanceOf(address account) public view virtual override returns (uint256) {
 return _balances[account];
 }

 function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
 _transfer(msg.sender, recipient, amount);
 return true;
 }

 function allowance(address owner, address spender) public view virtual override returns (uint256) {
 return _allowances[owner][spender];
 }

 function approve(address spender, uint256 amount) public virtual override returns (bool) {
 _approve(msg.sender, spender, amount);
 return true;
 }

 function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
 _transfer(sender, recipient, amount);
 uint256 currentAllowance = _allowances[sender][msg.sender];
 require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
 _approve(sender, msg.sender, currentAllowance - amount);
 return true;
 }

 function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
 _approve(msg.sender, spender, _allowances[msg.sender][spender] + addedValue);
 return true;
 }

 function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
 uint256 currentAllowance = _allowances[msg.sender][spender];
 require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
 _approve(msg.sender, spender, currentAllowance - subtractedValue);
 return true;
 }

 function _transfer(address sender, address recipient, uint256 amount) internal virtual nonReentrant {
 require(sender != address(0), "ERC20: transfer from the zero address");
 require(recipient != address(0), "ERC20: transfer to the zero address");
 require(_balances[sender] >= amount, "ERC20: transfer amount exceeds balance");

 uint256 taxAmount = amount / 100; // 1% tax
 uint256 potAmount = taxAmount / 2; // 50% of taxAmount to the pot
 uint256 burnAmount = taxAmount - potAmount; // Remaining 50% to be burned

 uint256 transferAmount = amount - taxAmount;

 _balances[sender] = _balances[sender] - amount;

 _balances[recipient] += transferAmount;

 _pot += potAmount;

 _totalSupply -= burnAmount;
 _burnedTokens += burnAmount;
 emit Transfer(sender, address(0), burnAmount);

 emit Transfer(sender, recipient, transferAmount);
 emit Transfer(sender, address(this), potAmount); // Emit separate event for the pot transfer

 _calculateNextFibonacciNumber();

 if (_pot > 0) {
 uint256 num = block.timestamp + potAmount + _fibonacciSequence;

 num = num % 10**9;

 if (num % _threshold1 == 0) {
 _transferPotToHouse();
 } else if (num % _threshold2 == 0) {
 _transferPotToSender(msg.sender);
 } else if (num % _threshold3 == 0) {
 _burnPot();
 }
 }
 }

 function _approve(address owner, address spender, uint256 amount) internal virtual {
 require(owner != address(0), "ERC20: approve from the zero address");
 require(spender != address(0), "ERC20: approve to the zero address");

 _allowances[owner][spender] = amount;
 emit Approval(owner, spender, amount);
 }

 function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {
 }


 function getPot() public view virtual returns (uint256) {
 return _pot;
 }

 function getBurnedTokens() public view virtual returns (uint256) {
 return _burnedTokens;
 }

 function setHouse(address account) public onlyRole(ADMIN_ROLE) {
 require(account != address(0), "ClownTown: Invalid house address");

 require(!hasRole(ADMIN_ROLE, account), "ClownTown: House address already has ADMIN_ROLE");

 grantRole(ADMIN_ROLE, account);

 if (_house != address(0)) {
 revokeRole(ADMIN_ROLE, _house);
 }

 _house = account;
 emit HouseAddressChanged(_house, account);
 }

 function _transferPotToHouse() internal {
 require(_house != address(0), "ClownTown: House address not set");
 require(_pot > 0, "ClownTown: Pot balance is zero");

 uint256 potAmount = _pot;
 _pot = 0;

 _balances[_house] += potAmount;
 emit PotTransferredToHouse(_house, potAmount);
 }

 function _transferPotToSender(address sender) internal {
 require(sender != address(0), "ClownTown: Sender address is zero");
 require(_pot > 0, "ClownTown: Pot balance is zero");

 uint256 potAmount = _pot;
 _pot = 0;

 // Transfer the pot balance to the wallet that initiated the transfer
 _balances[sender] += potAmount;
 emit PotTransferredToSender(sender, potAmount);
 }

 function _burnPot() internal {
 require(_pot > 0, "ClownTown: Pot balance is zero");

 uint256 potAmount = _pot;
 _pot = 0;

 // Burn the pot balance
 _totalSupply -= potAmount;
 _burnedTokens += potAmount;
 emit PotBurned(potAmount);
 }

 function _calculateNextFibonacciNumber() internal {
 _fibonacciIndex++;
 if (_fibonacciIndex > 42) {
 _fibonacciSequence = 1;
 _fibonacciIndex = 1;
 } else if (_fibonacciIndex <= 2) {
 _fibonacciSequence = 1;
 } else {
 uint256 a = 1;
 uint256 b = 1;
 for (uint256 i = 3; i <= _fibonacciIndex; i++) {
 uint256 c = a + b;
 a = b;
 b = c;
 }
 _fibonacciSequence = b;
 }
 }
}