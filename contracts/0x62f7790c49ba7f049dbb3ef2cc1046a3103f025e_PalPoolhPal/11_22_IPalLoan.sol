//██████╗  █████╗ ██╗      █████╗ ██████╗ ██╗███╗   ██╗
//██╔══██╗██╔══██╗██║     ██╔══██╗██╔══██╗██║████╗  ██║
//██████╔╝███████║██║     ███████║██║  ██║██║██╔██╗ ██║
//██╔═══╝ ██╔══██║██║     ██╔══██║██║  ██║██║██║╚██╗██║
//██║     ██║  ██║███████╗██║  ██║██████╔╝██║██║ ╚████║
//╚═╝     ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═════╝ ╚═╝╚═╝  ╚═══╝
                                                     

pragma solidity ^0.7.6;
//SPDX-License-Identifier: MIT

/** @title Interface for PalLoan contract  */
/// @author Paladin
interface IPalLoan {

    // Variables
    function underlying() external view returns(address);
    function amount() external view returns(uint);
    function borrower() external view returns(address);
    function delegatee() external view returns(address);
    function motherPool() external view returns(address);
    function feesAmount() external view returns(uint);

    // Functions
    function initiate(
        address _motherPool,
        address _borrower,
        address _underlying,
        address _delegatee,
        uint _amount,
        uint _feesAmount
    ) external returns(bool);
    function expand(uint _newFeesAmount) external returns(bool);
    function closeLoan(uint _usedAmount, address _currentBorrower) external;
    function killLoan(address _killer, uint _killerRatio) external;
    function changeDelegatee(address _delegatee) external returns(bool);
}