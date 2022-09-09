// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

enum WorkerPropertyDataType {
    NUMBER, BOOL, ASSET, ASSETS, LENDING_PLATFORM, EXCHANGE_PLATFORM, FARMING_PLATFORM 
}

enum WorkerStatus {
    INACTIVE, ACTIVE
}

struct WorkerProperty {
    uint16 pId;
    WorkerPropertyDataType pType;
    string name;
    bytes value;
}

interface IBotWorker {

    event Configure(uint16 pId, bytes value);
    event Deposit(address indexed platformToken, address indexed underlyingAsset, address indexed from, uint amount);
    event Withdraw(address indexed platformToken, address indexed underlyingAsset, address indexed to, uint amount);
    event ClaimReward(address indexed asset, uint amount);
    event Started();
    event Stopped();
    event Executed(uint action, bytes data);

    function initialize() external;

    function status() external view returns(WorkerStatus);

    function properties() external view returns(WorkerProperty[] memory);
    function property(uint16 pId) external view returns(bytes memory);
    function configure(uint16 pId, bytes calldata value) external;
    function configureEx(uint16[] calldata pIds, bytes[] calldata values) external;

    function accountInfo() external view returns(
        uint initDeposit, uint totalReward, uint healthFactor);

    function deposit(address platformToken, uint amount) external payable;
    function withdraw(address platformToken, uint amount) external;
    function claimReward() external;
    function start() external;
    function stop() external;
    function monitor(bytes memory) external view returns(uint action, bytes memory data);
    function execute(uint action, bytes calldata data) external;
    function underlying(address platformToken) external view returns(address asset);
}