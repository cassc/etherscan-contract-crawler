// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.8.0;

import "./NmxSupplier.sol";
import "./RecoverableByOwner.sol";

contract FixedAmountNmxSupplier is NmxSupplier, RecoverableByOwner {
    address immutable nmx;
    mapping(address => uint256) public amounts;

    constructor(address _nmx) {
        nmx = _nmx;
    }

    function updateAmount(address spender, uint256 amount) onlyOwner external {
        amounts[spender] = amount;
    }

    function supplyNmx(uint40 maxTime) external override returns (uint256) {
        uint256 amount = amounts[msg.sender];
        amounts[msg.sender] = 0;
        bool transferred = IERC20(nmx).transfer(msg.sender, amount);
        require(transferred, "FixedAmountNmxSupplier: NMX_FAILED_TRANSFER");
        return amount;
    }

}