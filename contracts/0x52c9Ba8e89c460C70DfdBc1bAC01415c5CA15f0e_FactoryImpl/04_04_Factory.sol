// LICENSE Notice
//
// This License is NOT an Open Source license. Copyright 2022. Ozy Co.,Ltd. All rights reserved.
// Licensor: Ozys. Co.,Ltd.
// Licensed Work / Source Code : This Source Code, Intella X DEX Project
// The Licensed Work is (c) 2022 Ozys Co.,Ltd.
// Detailed Terms and Conditions for Use Grant: Defined at https://ozys.io/LICENSE.txt
pragma solidity 0.5.6;

import "./EIP2771Recipient.sol";

contract Factory is EIP2771Recipient {
    // ======== Construction & Init ========
    address public owner;
    address public nextOwner;
    address payable public implementation;
    address payable public exchangeImplementation;
    address payable public WETH;
    address public router;
    address public treasury;
    address public buyback;

    uint public feeShareRate;

    // ======== Pool Info ========
    address[] public pools;
    mapping(address => bool) public poolExist;

    mapping(address => mapping(address => address)) public tokenToPool;

    // ======== Administration ========

    bool public entered;
    uint public chainId;
    bool public emergencyPaused;

    constructor(
        address payable _implementation,
        address payable _exchangeImplementation,
        address payable _WETH,
        address _buyback,
        uint _chainId
    ) public {
        owner = msg.sender;
        implementation = _implementation;
        exchangeImplementation = _exchangeImplementation;

        WETH = _WETH;
        buyback = _buyback;
        chainId = _chainId;
    }

    function _setImplementation(address payable _newImp) public {
        require(msg.sender == owner);
        require(implementation != _newImp);
        implementation = _newImp;
    }

    function _setExchangeImplementation(address payable _newExImp) public {
        require(msg.sender == owner);
        require(exchangeImplementation != _newExImp);
        exchangeImplementation = _newExImp;
    }

    function getExchangeImplementation() public view returns (address) {
        return exchangeImplementation;
    }

    function () payable external {
        address impl = implementation;
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