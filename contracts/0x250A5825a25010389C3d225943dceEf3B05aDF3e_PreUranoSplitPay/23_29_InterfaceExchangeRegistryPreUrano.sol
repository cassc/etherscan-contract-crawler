// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface InterfaceExchangeRegistryPreUrano {
    function setRegistryOwner(address _owner) external;

    function getRegistryOwner() external view returns (address);

    function authorizeWithdrawalContract(address _newWithdrawalContract)
        external;

    function deauthorizeWithdrawalContract(address _oldWithdrawalContract)
        external;

    function authorizeDepositContract(address _newDepositContract) external;

    function deauthorizeDepositContract(address _oldDepositContract) external;

    function isAddressAuthorizedWithdrawer(address _contractAddress)
        external
        view
        returns (bool);

    function isAddressAuthorizedDepositer(address _contractAddress)
        external
        view
        returns (bool);

    function addAmountToDeposit(address _amountOwner, uint256 _amount) external;

    function removeAmountFromDeposit(address _amountOwner, uint256 _amount)
        external;

    function getDepositedAmount(address _depositOwner)
        external
        returns (uint256);

    function isDepositOwner(address _depositOwner) external view returns (bool);

    function listDepositOwners() external view returns(address[] memory);
}