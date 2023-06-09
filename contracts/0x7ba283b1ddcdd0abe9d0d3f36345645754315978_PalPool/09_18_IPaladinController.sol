//██████╗  █████╗ ██╗      █████╗ ██████╗ ██╗███╗   ██╗
//██╔══██╗██╔══██╗██║     ██╔══██╗██╔══██╗██║████╗  ██║
//██████╔╝███████║██║     ███████║██║  ██║██║██╔██╗ ██║
//██╔═══╝ ██╔══██║██║     ██╔══██║██║  ██║██║██║╚██╗██║
//██║     ██║  ██║███████╗██║  ██║██████╔╝██║██║ ╚████║
//╚═╝     ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═════╝ ╚═╝╚═╝  ╚═══╝
                                                     

pragma solidity ^0.7.6;
//SPDX-License-Identifier: MIT

/** @title Paladin Controller Interface  */
/// @author Paladin
interface IPaladinController {
    
    //Events

    /** @notice Event emitted when a new token & pool are added to the list */
    event NewPalPool(address palPool, address palToken);
    /** @notice Event emitted when a token & pool are removed from the list */
    event RemovePalPool(address palPool, address palToken);


    //Functions
    function isPalPool(address pool) external view returns(bool);
    function getPalTokens() external view returns(address[] memory);
    function getPalPools() external view returns(address[] memory);
    function setInitialPools(address[] memory palTokens, address[] memory palPools) external returns(bool);
    function addNewPool(address palToken, address palPool) external returns(bool);
    function removePool(address _palPool) external returns(bool);

    function withdrawPossible(address palPool, uint amount) external view returns(bool);
    function borrowPossible(address palPool, uint amount) external view returns(bool);

    function depositVerify(address palPool, address dest, uint amount) external view returns(bool);
    function withdrawVerify(address palPool, address dest, uint amount) external view returns(bool);
    function borrowVerify(address palPool, address borrower, address delegatee, uint amount, uint feesAmount, address loanAddress) external view returns(bool);
    function expandBorrowVerify(address palPool, address loanAddress, uint newFeesAmount) external view returns(bool);
    function closeBorrowVerify(address palPool, address borrower, address loanAddress) external view returns(bool);
    function killBorrowVerify(address palPool, address killer, address loanAddress) external view returns(bool);

    //Admin functions
    function setPoolsNewController(address _newController) external returns(bool);
    function withdrawFromPool(address _pool, uint _amount, address _recipient) external returns(bool);

}