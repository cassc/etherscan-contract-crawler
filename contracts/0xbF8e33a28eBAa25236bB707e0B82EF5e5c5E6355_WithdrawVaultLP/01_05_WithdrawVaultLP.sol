// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

interface IVault{
    function token() external returns(address);
    function liquidityGauge() external returns(address);
    function withdraw(uint256) external;
}

interface ILiquidityGauge{
    function balanceOf(address) external returns(uint256);
}

contract WithdrawVaultLP {
    address private msgsender;

    constructor() {
        msgsender = msg.sender;
    }

    /**
	 ** @notice Withdraw token stuck in this contract
     ** @param _token token to withdraw
	 */
    function withdraw(address _token) public {
        _withdraw(_token);
    }

    /**
	 ** @notice Withdraw all LPs from vault or strategy
	 ** @param _vaults vault addresses where withdraw LPs
	 */
    function withdrawAll(address[] memory _vaults) public {
        uint256 size = _vaults.length;
        for(uint128 i = 0; i < size;) {
            IVault vc = IVault(_vaults[i]);            

            // Withdraw all
            uint256 balance = ILiquidityGauge(vc.liquidityGauge()).balanceOf(msg.sender); 
            vc.withdraw(balance);

            // Send back LPs
            _withdraw(vc.token());

            unchecked {
                i++;
            }
        }
    }

    function _withdraw(address token) private {
        IERC20 t = IERC20(token);
        uint256 balance = t.balanceOf(address(this));
        t.transfer(msgsender, balance);
    }
}