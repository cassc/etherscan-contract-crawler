// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;


// interface sdk for using dapps through smart contract
interface dappsSubscription {


// function to check whether a user _user has subscribe a particular dapp with dapp id _dappId or not
  function isSubscribed(bytes32 _dappId, address _user) view external returns (bool);
  


//   function subscribeToDapp(bytes32 _dappId, address _user) view external returns (bool);


}