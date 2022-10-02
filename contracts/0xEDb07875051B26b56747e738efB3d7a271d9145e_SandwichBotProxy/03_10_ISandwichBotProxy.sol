// SPDX-License-Identifier: GNU-GPL v3.0 or later

pragma solidity >=0.8.0;


interface ISandwichBotProxy {
// SPDX-License-Identifier: GNU-GPL


    function proxyCall(bytes32 poolId, address[] memory targets, uint[] memory values, bytes[] memory calldatas) external;

    function setResonateHelper(address _resonateHelper) external;

    function sandwichSnapshot(
        bytes32 poolId, 
        uint amount, 
        bool isWithdrawal
    ) external;

}