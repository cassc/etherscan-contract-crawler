// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./CryptoFoxesAllowed.sol";
import "./interfaces/ICryptoFoxesSteakBurnableShop.sol";

contract CryptoFoxesShopWithdraw is CryptoFoxesAllowed {
    using SafeMath for uint256;

    struct Part {
        address wallet;
        uint256 part;
        uint256 timestamp;
    }
    uint256 startIndexParts = 0;

    Part[] public parts;

    ICryptoFoxesSteakBurnableShop public cryptoFoxesSteak;

    constructor(address _cryptoFoxesSteak) {
        cryptoFoxesSteak = ICryptoFoxesSteakBurnableShop(_cryptoFoxesSteak);

        parts.push(Part(address(0), 90, block.timestamp));
    }

    function changePart(Part[] memory _parts) public isFoxContractOrOwner{
        startIndexParts = parts.length;
        for(uint256 i = 0; i < _parts.length; i++){
            parts.push(Part(_parts[i].wallet, _parts[i].part, block.timestamp));
        }
    }

    function getParts() public view returns(Part[] memory){
        return parts;
    }

    //////////////////////////////////////////////////
    //      WITHDRAW                                //
    //////////////////////////////////////////////////

    function withdrawAndBurn() public isFoxContractOrOwner {
        uint256 balance = cryptoFoxesSteak.balanceOf(address(this));
        require(balance > 0);

        for (uint256 i = startIndexParts; i < parts.length; i++) {
            if (parts[i].part == 0) {
                continue;
            }
            if (parts[i].wallet == address(0)) {
                cryptoFoxesSteak.burn(balance.mul(parts[i].part).div(100));
            } else {
                cryptoFoxesSteak.transfer(parts[i].wallet, balance.mul(parts[i].part).div(100));
            }
        }

        cryptoFoxesSteak.transfer(owner(), cryptoFoxesSteak.balanceOf(address(this)));
    }
}