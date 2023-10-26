//██████╗  █████╗ ██╗      █████╗ ██████╗ ██╗███╗   ██╗
//██╔══██╗██╔══██╗██║     ██╔══██╗██╔══██╗██║████╗  ██║
//██████╔╝███████║██║     ███████║██║  ██║██║██╔██╗ ██║
//██╔═══╝ ██╔══██║██║     ██╔══██║██║  ██║██║██║╚██╗██║
//██║     ██║  ██║███████╗██║  ██║██████╔╝██║██║ ╚████║
//╚═╝     ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═════╝ ╚═╝╚═╝  ╚═══╝
                                                     

pragma solidity ^0.7.6;
//SPDX-License-Identifier: MIT

import "./ControllerProxy.sol";

/** @title Paladin Controller Interface  */
/// @author Paladin
interface IPaladinController {
    
    //Events

    /** @notice Event emitted when a new token & pool are added to the list */
    event NewPalPool(address palPool, address palToken);
    /** @notice Event emitted when a token & pool are removed from the list */
    event RemovePalPool(address palPool, address palToken);

    event Deposit(address indexed user, address palToken, uint amount);
    event Withdraw(address indexed user, address palToken, uint amount);

    event ClaimRewards(address indexed user, uint amount);

    event PoolRewardsUpdated(address palPool, uint newSupplySpeed, uint newBorrowRatio, bool autoBorrowReward);


    //Functions
    function isPalPool(address pool) external view returns(bool);
    function getPalTokens() external view returns(address[] memory);
    function getPalPools() external view returns(address[] memory);
    function setInitialPools(address[] memory palTokens, address[] memory palPools) external returns(bool);
    function addNewPool(address palToken, address palPool) external returns(bool);
    function removePool(address palPool) external returns(bool);

    function withdrawPossible(address palPool, uint amount) external view returns(bool);
    function borrowPossible(address palPool, uint amount) external view returns(bool);

    function depositVerify(address palPool, address dest, uint amount) external returns(bool);
    function withdrawVerify(address palPool, address dest, uint amount) external returns(bool);
    function borrowVerify(address palPool, address borrower, address delegatee, uint amount, uint feesAmount, address loanAddress) external returns(bool);
    function expandBorrowVerify(address palPool, address loanAddress, uint newFeesAmount) external returns(bool);
    function closeBorrowVerify(address palPool, address borrower, address loanAddress) external returns(bool);
    function killBorrowVerify(address palPool, address killer, address loanAddress) external returns(bool);

    // PalToken Deposit/Withdraw functions
    function deposit(address palToken, uint amount) external returns(bool);
    function withdraw(address palToken, uint amount) external returns(bool);

    // Rewards functions
    function totalSupplyRewardSpeed() external view returns(uint);
    function claimable(address user) external view returns(uint);
    function estimateClaimable(address user) external view returns(uint);
    function updateUserRewards(address user) external;
    function claim(address user) external;
    function claimableLoanRewards(address palPool, address loanAddress) external view returns(uint);
    function claimLoanRewards(address palPool, address loanAddress) external;

    //Admin functions
    function becomeImplementation(ControllerProxy proxy) external;
    function updateRewardToken(address newRewardTokenAddress) external;
    function withdrawRewardToken(uint256 amount, address recipient) external;
    function updatePoolRewards(address palPool, uint newSupplyspeed, uint newBorrowRatio, bool autoBorrowReward) external;
    function setPoolsNewController(address newController) external returns(bool);
    function withdrawFromPool(address pool, uint amount, address recipient) external returns(bool);

}