// SPDX-License-Identifier: Unlicense

pragma solidity 0.7.6;

import "@openzeppelin/contracts/drafts/ERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Snapshot.sol";

contract Gamma is ERC20Permit, ERC20Snapshot {

    address public owner;
    modifier onlyOwner {
        require(msg.sender == owner, "only owner");
        _;
    }

    constructor(
        string memory name,
        string memory symbol,
        uint8 decimals
    ) ERC20Permit(name) ERC20(name, symbol){
      owner = msg.sender;
      _setupDecimals(decimals);
      _mint(owner, 100000000000000000000000000);
    }

    function snapshot() onlyOwner external {
      _snapshot();
    }

    function transferOwnership(address newOwner) external onlyOwner {
      owner = newOwner;
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal override(ERC20, ERC20Snapshot) {
      super._beforeTokenTransfer(from, to, amount);
    }

}