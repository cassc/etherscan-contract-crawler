// LICENSE Notice
//
// This License is NOT an Open Source license. Copyright 2022. Ozy Co.,Ltd. All rights reserved.
// Licensor: Ozys. Co.,Ltd.
// Licensed Work / Source Code : This Source Code, Intella X DEX Project
// The Licensed Work is (c) 2022 Ozys Co.,Ltd.
// Detailed Terms and Conditions for Use Grant: Defined at https://ozys.io/LICENSE.txt
pragma solidity 0.5.6;

interface ITreasuryImpl {
    function getDistributionImplementation() external view returns (address);
}

contract Distribution {

    // ===================      Index for Distribution      =======================
    address public token;
    address public lp;
    address public treasury;

    uint public totalAmount;
    uint public blockAmount;
    uint public distributableBlock;
    uint public distributedAmount;

    uint public lastDistributed;
    uint public distributionIndex;
    mapping(address => uint) public userLastIndex;
    mapping(address => uint) public userRewardSum;

    bool public entered = false;
    bool public isInitialized = false;

    constructor() public {
        treasury = msg.sender;
    }

    function () payable external {
        address impl = ITreasuryImpl(treasury).getDistributionImplementation();
        require(impl != address(0));
        assembly {
            let ptr := mload(0x40)
            calldatacopy(ptr, 0, calldatasize)
            let result := delegatecall(gas, impl, ptr, calldatasize, 0, 0)
            let size := returndatasize
            returndatacopy(ptr, 0, size)

            switch result
            case 0 { revert(ptr, size) }
            default { return(ptr, size) }
        }
    }
}