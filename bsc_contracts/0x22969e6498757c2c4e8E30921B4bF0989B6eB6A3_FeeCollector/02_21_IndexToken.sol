// SPDX-License-Identifier: ISC
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interfaces/IIndexToken.sol";
import "./Modular.sol";

contract IndexToken is IIndexToken, ERC20("", ""), Ownable, Initializable, Modular {
  struct InitParams {
    string name;
    string symbol;
    Asset[] assets;
    address feeReceiver;
  }

  string _name;
  string _symbol;

  Asset[] assets;
  address feeReceiver;
  
  constructor() {
    _disableInitializers();
  }

  function initialize(InitParams calldata params) external initializer {
    _name = params.name;
    _symbol = params.symbol;
    for (uint256 i = 0; i < params.assets.length; i++) {
      assets.push(params.assets[i]);
    }
    // assets = params.assets;
    feeReceiver = params.feeReceiver;
    _transferOwnership(msg.sender);
  }

  function name() public view override(ERC20, IERC20Metadata) returns (string memory) {
    return _name;
  }

  function symbol() public view override(ERC20, IERC20Metadata) returns (string memory) {
    return _symbol;
  }

  // compatibility with BEP20 spec
  function getOwner() public view returns (address) {
    return owner();
  }

  function getAssets() public view returns (Asset[] memory) {
    return assets;
  }

  function setAssets(Asset[] memory newAssets) public onlyModule {
    while (assets.length > newAssets.length) {
      assets.pop();
    }
    // now assets.length <= newAssets.length
    for (uint256 i = 0; i < assets.length; i++) {
      assets[i] = newAssets[i];
    }
    for (uint256 i = assets.length; i < newAssets.length; i++) {
      assets.push(newAssets[i]);
    }
  }

  function mint(address to, uint256 amount) external onlyModule {
    _mint(to, amount);
  }

  function burn(address from, uint256 amount) external onlyModule {
    _burn(from, amount);
  }

  function transferAsset(address asset, address to, uint256 amount) external onlyModule {
    SafeERC20.safeTransfer(IERC20(asset), to, amount);
  }

  function addModule(address module) external onlyOwner {
    _addModule(module);
  }

  function removeModule(address module) external onlyOwner {
    _removeModule(module);
  }

  function getFeeReceiver() public view returns (address) {
    return feeReceiver;
  }

  function setFeeReceiver(address newFeeReceiver) public onlyOwner {
    feeReceiver = newFeeReceiver;
  }
}