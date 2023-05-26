// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.10;

import "openzeppelin-contracts/contracts/access/Ownable.sol";
import "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

//import "forge-std/console.sol";

contract BLUSDToken is ERC20, Ownable {

    constructor(string memory name_, string memory symbol_) ERC20(name_, symbol_) {}
  
    address public chickenBondManagerAddress;

    function setAddresses(address _chickenBondManagerAddress) external onlyOwner {
        chickenBondManagerAddress = _chickenBondManagerAddress;
        renounceOwnership();
    }

    function mint(address _to, uint256 _bLUSDAmount) external {
        _requireCallerIsChickenBondsManager();
        _mint(_to, _bLUSDAmount);
    }

    function burn(address _from, uint256 _bLUSDAmount) external {
        _requireCallerIsChickenBondsManager();
        _burn(_from, _bLUSDAmount);
    }

    function _requireCallerIsChickenBondsManager() internal view {
        require(msg.sender == chickenBondManagerAddress, "BLUSDToken: Caller must be ChickenBondManager");
    }
}