// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./ITHUSDToken.sol";

interface IPCV {

    // --- Events --
    event THUSDTokenAddressSet(address _thusdTokenAddress);
    event BorrowerOperationsAddressSet(address _borrowerOperationsAddress);
    event CollateralAddressSet(address _collateralAddress);
    event BAMMAddressSet(address _bammAddress);
    event RolesSet(address _council, address _treasury);

    event BAMMDeposit(uint256 _thusdAmount);
    event BAMMWithdraw(uint256 _numShares);
    event THUSDWithdraw(address _recipient, uint256 _thusdAmount);
    event CollateralWithdraw(address _recipient, uint256 _collateralAmount);

    event PCVDebtPaid(uint256 _paidDebt);
    
    event RecipientAdded(address _recipient);
    event RecipientRemoved(address _recipient);

    // --- Functions ---

    function debtToPay() external returns(uint256);
    function payDebt(uint256 _thusdToBurn) external;

    function setAddresses(
        address _thusdTokenAddress, 
        address _borrowerOperations, 
        address payable _bammAddress,
        address _collateralERC20
    ) external;
    function initialize() external;

    function depositToBAMM(uint256 _thusdAmount) external;
    function withdrawFromBAMM(uint256 _numShares) external;
    function withdrawTHUSD(address _recipient, uint256 _thusdAmount) external;
    function withdrawCollateral(address _recipient, uint256 _collateralAmount) external;

    function addRecipientToWhitelist(address _recipient) external;
    function addRecipientsToWhitelist(address[] calldata _recipients) external;
    function removeRecipientFromWhitelist(address _recipient) external;
    function removeRecipientsFromWhitelist(address[] calldata _recipients) external;

    function startChangingRoles(address _council, address _treasury) external;
    function cancelChangingRoles() external;
    function finalizeChangingRoles() external;
    
    function collateralERC20() external view returns(IERC20);
    function thusdToken() external view returns(ITHUSDToken);

}