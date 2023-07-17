// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.19;

interface IXfaiV0Core {
  function lpFee() external view returns (uint);

  function changeLpFee(uint _newFee) external;

  function infinityNFTFee() external view returns (uint);

  function changeInfinityNFTFee(uint _newFee) external;

  function getTotalFee() external view returns (uint);

  function pause(bool _p) external;

  function swap(
    address _token0,
    address _token1,
    address _to
  ) external returns (uint input, uint output);

  function flashLoan(address _token, uint _amount, address _to, bytes calldata _data) external;

  function mint(address _token, address _to) external returns (uint liquidity);

  function burn(
    address _token0,
    address _token1,
    address _to
  ) external returns (uint amount0, uint amount1);

  function skim(address _token, address _to) external;

  function sync(address _token) external;

  event ChangedOwner(address indexed owner);
  event Mint(address indexed sender, uint liquidity);
  event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
  event Swap(address indexed sender, uint input, uint output, address indexed to);
  event FlashLoan(address indexed sender, uint amount);
  event LpFeeChange(uint newFee);
  event InfinityNFTFeeChange(uint newFee);
  event Paused(bool p);
}