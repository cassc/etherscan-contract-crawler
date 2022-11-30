// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/access/Ownable.sol";

interface IERC20 {

    function transfer(address _to, uint256 _value) external returns (bool);

    function balanceOf(address account) external view returns (uint256);
}

contract Payments is Ownable {
    IERC20 usdt;

    constructor() {
        usdt = IERC20(address(0x55d398326f99059fF775485246999027B3197955)); //USDT BSC Mainnet
    }

    function getContractBalance() public view onlyOwner returns (uint256) {
        return usdt.balanceOf(address(this));
    }

    function pays(address payable[] memory _addr, uint256[] memory _amount)
        public
        payable
        onlyOwner
    {
        for (uint256 i = 0; i < _addr.length; i++) {
            address payable addrLocal = _addr[i];
            uint256 amountLocal2 = _amount[i];

            usdt.transfer(addrLocal, amountLocal2);
        }
    }

    function withdraw(address payable _addr, uint256 _amount)
        public
        payable
        onlyOwner
    {
        usdt.transfer(_addr, _amount);
    }
}