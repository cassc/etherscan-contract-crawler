// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./OwnableUpgradeable.sol";
import "hardhat/console.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
// import {UnifarmAccountsUpgradeable} from "./UnifarmAccountsUpgradeable.sol";
import "./sdkInterFace/unifarmAccountsI.sol";

contract GasRestrictor is Initializable, OwnableUpgradeable {
    uint256 public initialGasLimitInNativeCrypto; // i.e matic etc
    dappsSubscriptionI public unifarmAccount;
    struct GaslessData {
        address userSecondaryAddress;
        address userPrimaryAddress;
        uint256 gasBalanceInNativeCrypto;
    }

    // primary to gaslessData
    mapping(address => GaslessData) public gaslessData;

// mapping of contract address who are allowed to do changes
    mapping(address=>bool) public isDappsContract;

    
      modifier isDapp(address dapp) {
      
        require(
                isDappsContract[dapp] == true,
                "Not_registred_dapp"
        );
          _;

        
    }
   
    function init_Gasless_Restrictor(
        address _unifarmAccounts,
        uint256 _gaslimit
    ) public initializer {
        initialGasLimitInNativeCrypto = _gaslimit;
        unifarmAccount = dappsSubscriptionI(_unifarmAccounts);
        isDappsContract[_unifarmAccounts] = true;
    }
    

    function updateInitialGasLimit(uint256 _gaslimit) public onlyOwner {
        initialGasLimitInNativeCrypto = _gaslimit;
    }

    function getGaslessData(address _user) view virtual external returns(GaslessData memory) {
      return  gaslessData[_user];
    }

    function initUser(address primary, address secondary) external isDapp(msg.sender){
        gaslessData[primary]
            .gasBalanceInNativeCrypto = initialGasLimitInNativeCrypto;
        gaslessData[primary].userPrimaryAddress = primary;
        gaslessData[primary].userSecondaryAddress = secondary;
    }

    function _updateGaslessData(address user, uint initialGasLeft) external isDapp(msg.sender){
      address primary = unifarmAccount.getPrimaryFromSecondary(user);
        if (primary == address(0)) {
            return;
        } else {
            gaslessData[primary].gasBalanceInNativeCrypto =
                gaslessData[primary].gasBalanceInNativeCrypto -
                (initialGasLeft - gasleft()) *
                tx.gasprice;
         
        }
    }

   function addDapp(address dapp) external onlyOwner {
    isDappsContract[dapp] = true;
   }

    function addGas(address userPrimaryAddress) external payable{ 
      require(msg.value> 0 , "gas should be more than 0");
      gaslessData[userPrimaryAddress].gasBalanceInNativeCrypto =   gaslessData[userPrimaryAddress].gasBalanceInNativeCrypto + msg.value;

    }

     function withdrawGasFunds(uint amount, address to) external onlyOwner {
     require(amount <= address(this).balance);
      payable(to).transfer(amount);
    }

    
}