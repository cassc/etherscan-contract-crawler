// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import '@openzeppelin/contracts/finance/PaymentSplitter.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

contract NraeLabTreasury is PaymentSplitter, Ownable {
    /*///////////////////////////////////////////////////////////////
                                VARIABLES
    ///////////////////////////////////////////////////////////////*/

    /// @notice List of payees
    address[] PAYEES;
    address TOKEN;

    /*///////////////////////////////////////////////////////////////
                                CONSTRUCTOR
    ///////////////////////////////////////////////////////////////*/

    /// @notice Constructor of the contract
    /// @param _payees List of payees
    /// @param _shares Shares array corresponding to the payees
    /// @param _token Token address
    constructor(
        address[] memory _payees,
        uint256[] memory _shares,
        address _token
    ) PaymentSplitter(_payees, _shares) {
        PAYEES = _payees;
        TOKEN = _token;
    }

    /*///////////////////////////////////////////////////////////////
                                PAYMENT LOGIC
    ///////////////////////////////////////////////////////////////*/

    /// @notice Withdraw funds
    function withdraw() external onlyOwner {
        require(TOKEN != address(0), 'UNDEFINED_TOKEN');

        IERC20 _token = IERC20(TOKEN);
        for (uint256 i = 0; i < PAYEES.length; i++) {
            release(_token, PAYEES[i]);
        }
    }

    /*///////////////////////////////////////////////////////////////
                                SETTERS
    ///////////////////////////////////////////////////////////////*/

    /// @notice Setter for the payment token
    /// @param _token Address of the token to be used for payments
    function setToken(address _token) external onlyOwner {
        TOKEN = _token;
    }
}