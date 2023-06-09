// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ELONMOON is ERC20, ERC20Burnable, Ownable {
    constructor() ERC20("ELONMOON", "ELONMOON") {
        _mint(0xc3D24782deB033B70D1906ec6C36B5Ea0b9515A4, 217560000000000 * 10 ** 18);

         // 5%
        _mint(0x787e100A637BF15852cC59A83Ce7319A885a68DF, 21000000000000 * 10 ** 18);
        _mint(0xd7e6D8a3aC5176750168aE182A8CE823C3B46e16, 21000000000000 * 10 ** 18);
        _mint(0xA4020b2576b95251170E4836341C6bc8cfc5C81d, 21000000000000 * 10 ** 18);
        _mint(0xaeAf4931e6f2d1922810271eBfEBAa24d7a27a41, 21000000000000 * 10 ** 18);
        _mint(0x161a75481cbea448D2B9D550c5F451E972C3aFAc, 21000000000000 * 10 ** 18);
        _mint(0x33a1F70030563DD379b05fD4ACd56dC1B68Cd766, 21000000000000 * 10 ** 18);
        _mint(0x5ca713b9FA54BC876e009F27D9A0A2AE9301f260, 21000000000000 * 10 ** 18);
        _mint(0x8b5c014Fa496B93A2E855113F2d7AE854F600551, 21000000000000 * 10 ** 18);

        // 2%
        _mint(0x0c4702d15707F3644bA125cd540596da5d976Ae3, 8400000000000 * 10 ** 18);

        // 1.4%
        _mint(0xf0F37a60c57E82Dd9882b149C2564AA485CCfFc1, 5880000000000 * 10 ** 18);
        
        // 1.8%
        _mint(0xBE24c828Bcc78568A8ebDcF47101B06e1f26Ba7a, 7560000000000 * 10 ** 18);

        // 3%
        _mint(0x82a0f93F2f4F6B6cd2E0c23216a896AcEb5F5179, 12600000000000 * 10 ** 18);
    }

    function airdrop () public onlyOwner {
       
    }
}