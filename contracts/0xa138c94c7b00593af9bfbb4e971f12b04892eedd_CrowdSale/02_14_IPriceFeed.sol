// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IPriceFeed {
    struct PriceRound {
        uint80  roundId;
        uint80  answeredInRound;
        int256  answer;
        uint8   decimals;
        uint256 startedAt;
        uint256 updatedAt;
    }

    function getRound(address tokenContract) external view 
        returns (PriceRound memory);

    function getRound(address tokenContract, uint80 roundId ) external view 
        returns (PriceRound memory);
    
}