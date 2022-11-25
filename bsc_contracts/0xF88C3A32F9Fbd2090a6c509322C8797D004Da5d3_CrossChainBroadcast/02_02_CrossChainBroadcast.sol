//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.1;

import "@openzeppelin/contracts/utils/Address.sol";

contract CrossChainBroadcast {
    function execute(
        address to,
        bytes calldata data,
        address rewards
    ) public {
        uint256 gasBefore = gasleft();
        uint256 balanceBefore = rewards.balance;
        Address.functionCall(to, data);
        uint256 balanceDiff = rewards.balance - balanceBefore;
        uint256 gasUsed = gasBefore - gasleft();

        require(balanceDiff >= gasUsed * tx.gasprice);
    }
}