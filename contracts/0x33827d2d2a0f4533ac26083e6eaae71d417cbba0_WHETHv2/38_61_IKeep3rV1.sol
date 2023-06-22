// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12;

interface IKeep3rV1 {
    function KPRH() external returns (address);

    function name() external returns (string memory);

    function isKeeper(address) external returns (bool);

    function worked(address keeper) external;

    function workReceipt(address keeper, uint amount) external;

    function receiptETH(address keeper, uint256 amount) external;

    function receipt(address credit, address keeper, uint256 amount) external;

    function addKPRCredit(address job, uint256 amount) external;

    function addCredit(address asset, address job, uint256 amount) external;

    function addJob(address job) external;
}