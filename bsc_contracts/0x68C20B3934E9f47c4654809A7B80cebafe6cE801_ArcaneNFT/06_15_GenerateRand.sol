// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16; 

import "./SafeMath.sol"; // Importa SafeMath
import "./Ownable.sol"; // Importa Owner

contract Random is Ownable {
    using SafeMath for uint256;

    uint256 private randNonce;



    function randMod(uint256 modulus) private returns(uint256) {
        randNonce++;
        return uint256(keccak256(abi.encodePacked(block.number, _msgSender(), randNonce))) % modulus;
    }
    function generateRandMod() external onlyOwner returns(uint256) {
        uint256 rand = randMod(60);
        uint256 result;
        if (rand <= 40) {
            if(rand < 10) {
                result = 10;
            }
            else {
                result = rand;
            }
        }
        else if (rand > 40 && rand <= 45 ) {
            result = rand;
        }
        else if (rand > 45 && rand <= 50) {
            result = rand;
        }
        else if (rand > 50 && rand <= 55) {
            result = rand;
        }
        else if (rand > 55 && rand <= 58) {
            result = rand;
        }
        else if (rand > 58 && rand <= 60) {
            result = rand;
        }
        return result;
    }
}
