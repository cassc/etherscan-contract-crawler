// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.15;

///@title LaserProxy - Proxy contract that delegates all calls to a master copy.
contract LaserProxy {
    // The singleton always needs to be at storage slot 0.
    address internal singleton;

    ///@param _singleton Singleton address.
    constructor(address _singleton) {
        // The proxy creation is done through the LaserProxyFactory.
        // The singleton is created at the factory's creation, so there is no need to do checks here.
        singleton = _singleton;
    }

    ///@dev Fallback function forwards all transactions and returns all received return data.
    fallback() external payable {
        address _singleton = singleton;
        assembly {
            calldatacopy(0, 0, calldatasize())
            let success := delegatecall(gas(), _singleton, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            if eq(success, 0) {
                revert(0, returndatasize())
            }
            return(0, returndatasize())
        }
    }
}