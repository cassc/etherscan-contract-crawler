// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/*
 * https://twitter.com/0xGMeth
 * https://t.me/gmcoineth
*/


//    SSSSSSSSSSSSSSS              AAA           YYYYYYY       YYYYYYY             GGGGGGGGGGGGGMMMMMMMM               MMMMMMMM
//  SS:::::::::::::::S            A:::A          Y:::::Y       Y:::::Y          GGG::::::::::::GM:::::::M             M:::::::M
// S:::::SSSSSS::::::S           A:::::A         Y:::::Y       Y:::::Y        GG:::::::::::::::GM::::::::M           M::::::::M
// S:::::S     SSSSSSS          A:::::::A        Y::::::Y     Y::::::Y       G:::::GGGGGGGG::::GM:::::::::M         M:::::::::M
// S:::::S                     A:::::::::A       YYY:::::Y   Y:::::YYY      G:::::G       GGGGGGM::::::::::M       M::::::::::M
// S:::::S                    A:::::A:::::A         Y:::::Y Y:::::Y        G:::::G              M:::::::::::M     M:::::::::::M
//  S::::SSSS                A:::::A A:::::A         Y:::::Y:::::Y         G:::::G              M:::::::M::::M   M::::M:::::::M
//   SS::::::SSSSS          A:::::A   A:::::A         Y:::::::::Y          G:::::G    GGGGGGGGGGM::::::M M::::M M::::M M::::::M
//     SSS::::::::SS       A:::::A     A:::::A         Y:::::::Y           G:::::G    G::::::::GM::::::M  M::::M::::M  M::::::M
//        SSSSSS::::S     A:::::AAAAAAAAA:::::A         Y:::::Y            G:::::G    GGGGG::::GM::::::M   M:::::::M   M::::::M
//             S:::::S   A:::::::::::::::::::::A        Y:::::Y            G:::::G        G::::GM::::::M    M:::::M    M::::::M
//             S:::::S  A:::::AAAAAAAAAAAAA:::::A       Y:::::Y             G:::::G       G::::GM::::::M     MMMMM     M::::::M
// SSSSSSS     S:::::S A:::::A             A:::::A      Y:::::Y              G:::::GGGGGGGG::::GM::::::M               M::::::M
// S::::::SSSSSS:::::SA:::::A               A:::::A  YYYY:::::YYYY            GG:::::::::::::::GM::::::M               M::::::M
// S:::::::::::::::SSA:::::A                 A:::::A Y:::::::::::Y              GGG::::::GGG:::GM::::::M               M::::::M
//  SSSSSSSSSSSSSSS AAAAAAA                   AAAAAAAYYYYYYYYYYYYY                 GGGGGG   GGGGMMMMMMMM               MMMMMMMM


import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract GM is ERC20("GM","GM"), Ownable {
	constructor() {
		_mint(msg.sender, 22222 ether);
	}
}