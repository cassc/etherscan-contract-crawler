// SPDX-License-Identifier: MIT
pragma solidity >=0.8.16;

interface IBooster {
  function acceptPendingOwner (  ) external;
  function addPool ( address _implementation, address _stakingAddress, address _stakingToken ) external;
  function addProxyOwner ( address _proxy, address _owner ) external;
  function checkpointFeeRewards ( address _distroContract ) external;
  function claimFees ( address _distroContract, address _token ) external;
  function claimOperatorRoles (  ) external;
  function createVault ( uint256 _pid ) external returns ( address );
  function deactivatePool ( uint256 _pid ) external;
  function feeClaimMap ( address, address ) external view returns ( bool );
  function feeQueue (  ) external view returns ( address );
  function feeRegistry (  ) external view returns ( address );
  function feeclaimer (  ) external view returns ( address );
  function fxs (  ) external view returns ( address );
  function isShutdown (  ) external view returns ( bool );
  function owner (  ) external view returns ( address );
  function pendingOwner (  ) external view returns ( address );
  function poolManager (  ) external view returns ( address );
  function poolRegistry (  ) external view returns ( address );
  function proxy (  ) external view returns ( address );
  function proxyOwners ( address ) external view returns ( address );
  function recoverERC20 ( address _tokenAddress, uint256 _tokenAmount, address _withdrawTo ) external;
  function recoverERC20FromProxy ( address _tokenAddress, uint256 _tokenAmount, address _withdrawTo ) external;
  function rewardManager (  ) external view returns ( address );
  function setDelegate ( address _delegateContract, address _delegate, bytes32 _space ) external;
  function setFeeClaimPair ( address _claimAddress, address _token, bool _active ) external;
  function setFeeClaimer ( address _claimer ) external;
  function setFeeQueue ( address _queue ) external;
  function setPendingOwner ( address _po ) external;
  function setPoolFeeDeposit ( address _deposit ) external;
  function setPoolFees ( uint256 _cvxfxs, uint256 _cvx, uint256 _platform ) external;
  function setPoolManager ( address _pmanager ) external;
  function setPoolRewardImplementation ( address _impl ) external;
  function setRewardActiveOnCreation ( bool _active ) external;
  function setRewardManager ( address _rmanager ) external;
  function setVeFXSProxy ( address _vault, address _newproxy ) external;
  function shutdownSystem (  ) external;
  function voteGaugeWeight ( address _controller, address[] memory _gauge, uint256[] memory _weight ) external;
}