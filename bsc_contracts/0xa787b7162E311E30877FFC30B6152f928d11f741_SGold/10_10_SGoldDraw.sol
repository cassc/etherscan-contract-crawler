/**
 *Submitted for verification on 2023-05-08
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// Importing the SafeMath and IERC20 contract from another file
import "./SafeMath.sol";
import "./IERC20.sol";

contract SGoldDraw {

    event BalanceUpdated(address indexed addr, uint256 newBalance);

    mapping(address => uint256) addresses;

    constructor() {
        // initialize the addresses mapping with hardcoded values
        addresses[0x1111111111111111111111111111111111111111] = 2;
        addresses[0x2222222222222222222222222222222222222222] = 4;
        addresses[0x3333333333333333333333333333333333333333] = 6;
        addresses[0x4444444444444444444444444444444444444444] = 8;
        addresses[0x5555555555555555555555555555555555555555] = 10;
        addresses[0x6666666666666666666666666666666666666666] = 12;
        addresses[0x7777777777777777777777777777777777777777] = 14;
        addresses[0x8888888888888888888888888888888888888888] = 16;
    }

    function get_eligible_addresses() private view returns (address[] memory) {
        // returns an array of addresses that have at least 2 SGold
        address[] memory result = new address[](8);
        uint256 count = 0;
        for (uint256 i = 0; i < 8; i++) {
            if (addresses[address(uint160(uint160(0x1111111111111111111111111111111111111111) + i))] >= 2) {
                result[count] = address(uint160(uint160(0x1111111111111111111111111111111111111111) + i));
                count++;
            }
        }
        address[] memory eligibleAddresses = new address[](count);
        for (uint256 i = 0; i < count; i++) {
            eligibleAddresses[i] = result[i];
        }
        return eligibleAddresses;
    }

    function random() private view returns (uint256) {
    // returns a random number between 0 and 7
    return uint256(keccak256(abi.encodePacked(block.timestamp, block.coinbase, blockhash(block.number)))) % 8;
    }

    function sum() public view returns (uint256) {
        // returns the total number of SGold in circulation
        uint256 total = 0;
        for (uint256 i = 0; i < 8; i++) {
            total += addresses[address(uint160(uint160(0x1111111111111111111111111111111111111111) + i))];
        }
        return total;
    }
    
        function generate_sgold() public {
        uint256 max_sgold = 100000000;

        // generate SGold every 200 days until max is reached
        while (sum() < max_sgold) {
            // randomly select 5 addresses that have at least 2 SGold and send them 15 SGold each
            address[] memory eligible_addresses = get_eligible_addresses();
            uint256 len = eligible_addresses.length;
            if (len > 0) {
                for (uint256 i = 0; i < 5; i++) {
                    uint256 index = random() % len;
                    addresses[eligible_addresses[index]] += 15;
                    emit BalanceUpdated(eligible_addresses[index], addresses[eligible_addresses[index]]);
                }
            }
        }
    }
}