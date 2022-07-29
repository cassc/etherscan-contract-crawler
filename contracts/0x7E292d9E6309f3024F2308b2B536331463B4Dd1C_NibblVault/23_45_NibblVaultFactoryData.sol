// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.10;

contract NibblVaultFactoryData {
    uint256 public constant UPDATE_TIME = 2 days;
    uint256 public constant MAX_ADMIN_FEE = 20_000; //2%

    address public vaultImplementation;
    address public pendingVaultImplementation;
    uint256 public vaultUpdateTime; //Cooldown period

    address public feeTo;
    address public pendingFeeTo;
    uint256 public feeToUpdateTime; //Cooldown period  

    uint256 public feeAdmin = 3_000; //.3%
    uint256 public pendingFeeAdmin;
    uint256 public feeAdminUpdateTime; //Cooldown period

    address public basketImplementation;
    address public pendingBasketImplementation;
    uint256 public basketUpdateTime; //Cooldown period    

}