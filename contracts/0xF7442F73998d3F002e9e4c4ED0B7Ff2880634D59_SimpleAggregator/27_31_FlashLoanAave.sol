//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../lib/UniversalERC20.sol";
import "../interface/IHolder.sol";
import "../interface/aave/IFlashLoanReceiver.sol";

import "hardhat/console.sol";

contract FlashLoanAave {
    using UniversalERC20 for IERC20;

    address public provider = 0xB53C1a33016B2DC2fF3653530bfF1848a515c8c5;
    ILendingPool public immutable LENDING_POOL;

    constructor() {
        LENDING_POOL = ILendingPool(ILendingPoolAddressesProvider(provider).getLendingPool());
    }

    function executeOperation(
        address[] calldata assets,
        uint256[] calldata amounts,
        uint256[] calldata premiums,
        address, /*initiator*/
        bytes calldata params
    ) external returns (bool) {
        require(msg.sender == address(LENDING_POOL), "Access denied, only pool alowed");

        uint256 amountOwing = amounts[0] + premiums[0];

        // Approve the LendingPool contract allowance to *pull* the owed amount
        IERC20(assets[0]).approve(address(LENDING_POOL), amountOwing);

        bytes memory encodeParams;

        {
            (
                bytes4 selector,
                address collateral,
                address debt,
                uint256 amount,
                uint256 leverageRatio,
                bytes memory _exchange
            ) = abi.decode(params, (bytes4, address, address, uint256, uint256, bytes));

            encodeParams = abi.encodeWithSelector(selector, collateral, debt, amount, leverageRatio, _exchange, amountOwing);
        }

        (bool success, bytes memory data) = address(this).call(encodeParams);

        require(success, string(abi.encodePacked("External call failed: ", data)));

        return true;
    }

    function _flashLoanAave(bytes calldata _flashLoanParams, uint256 _borrowAmount) public {
        (
            address[] memory assets,
            uint256[] memory amounts,
            uint256[] memory modes,
            uint16 referralCode,
            bytes memory _exchange
        ) = abi.decode(_flashLoanParams, (address[], uint256[], uint256[], uint16, bytes));

        if (_borrowAmount != 0) {
            amounts[0] = _borrowAmount;
        }

        LENDING_POOL.flashLoan(address(this), assets, amounts, modes, address(this), _exchange, referralCode);
    }
}