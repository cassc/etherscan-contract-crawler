// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

interface IPool is IERC20 {
  // https://github.com/maple-labs/maple-core/blob/main/contracts/token/interfaces/IBaseFDT.sol
  function withdrawableFundsOf(address owner) external view returns (uint256);

  // https://github.com/maple-labs/maple-core/blob/main/contracts/token/interfaces/IExtendedFDT.sol
  function recognizableLossesOf(address) external view returns (uint256);

  function poolDelegate() external view returns (address);

  function poolAdmins(address) external view returns (bool);

  function deposit(uint256) external;

  function increaseCustodyAllowance(address, uint256) external;

  function transferByCustodian(
    address,
    address,
    uint256
  ) external;

  function poolState() external view returns (uint256);

  function deactivate() external;

  function finalize() external;

  function claim(address, address) external returns (uint256[7] memory);

  function setLockupPeriod(uint256) external;

  function setStakingFee(uint256) external;

  function setPoolAdmin(address, bool) external;

  function fundLoan(
    address,
    address,
    uint256
  ) external;

  function withdraw(uint256) external;

  function superFactory() external view returns (address);

  function triggerDefault(address, address) external;

  function isPoolFinalized() external view returns (bool);

  function setOpenToPublic(bool) external;

  function setAllowList(address, bool) external;

  function allowedLiquidityProviders(address) external view returns (bool);

  function openToPublic() external view returns (bool);

  function intendToWithdraw() external;

  function DL_FACTORY() external view returns (uint8);

  function liquidityAsset() external view returns (IERC20);

  function liquidityLocker() external view returns (address);

  function stakeAsset() external view returns (address);

  function stakeLocker() external view returns (address);

  function stakingFee() external view returns (uint256);

  function delegateFee() external view returns (uint256);

  function principalOut() external view returns (uint256);

  function liquidityCap() external view returns (uint256);

  function lockupPeriod() external view returns (uint256);

  function depositDate(address) external view returns (uint256);

  function debtLockers(address, address) external view returns (address);

  function withdrawCooldown(address) external view returns (uint256);

  function setLiquidityCap(uint256) external;

  function cancelWithdraw() external;

  function reclaimERC20(address) external;

  function BPTVal(
    address,
    address,
    address,
    address
  ) external view returns (uint256);

  function isDepositAllowed(uint256) external view returns (bool);

  function getInitialStakeRequirements()
    external
    view
    returns (
      uint256,
      uint256,
      bool,
      uint256,
      uint256
    );
}