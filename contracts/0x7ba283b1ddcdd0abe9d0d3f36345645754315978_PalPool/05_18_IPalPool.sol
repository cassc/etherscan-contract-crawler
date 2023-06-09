//██████╗  █████╗ ██╗      █████╗ ██████╗ ██╗███╗   ██╗
//██╔══██╗██╔══██╗██║     ██╔══██╗██╔══██╗██║████╗  ██║
//██████╔╝███████║██║     ███████║██║  ██║██║██╔██╗ ██║
//██╔═══╝ ██╔══██║██║     ██╔══██║██║  ██║██║██║╚██╗██║
//██║     ██║  ██║███████╗██║  ██║██████╔╝██║██║ ╚████║
//╚═╝     ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═════╝ ╚═╝╚═╝  ╚═══╝
                                                     

pragma solidity ^0.7.6;
pragma abicoder v2;
//SPDX-License-Identifier: MIT

/** @title palPool Interface  */
/// @author Paladin
interface IPalPool {

    //Events
    /** @notice Event when an user deposit tokens in the pool */
    event Deposit(address user, uint amount, address palPool);
    /** @notice Event when an user withdraw tokens from the pool */
    event Withdraw(address user, uint amount, address palPool);
    /** @notice Event when a loan is started */
    event NewLoan(
        address borrower,
        address delegatee,
        address underlying,
        uint amount,
        address palPool,
        address loanAddress,
        uint256 palLoanTokenId,
        uint startBlock);
    /** @notice Event when the fee amount in the loan is updated */
    event ExpandLoan(
        address borrower,
        address delegatee,
        address underlying,
        address palPool,
        uint newFeesAmount,
        address loanAddress,
        uint256 palLoanTokenId
    );
    /** @notice Event when the delegatee of the loan is updated */
    event ChangeLoanDelegatee(
        address borrower,
        address newDelegatee,
        address underlying,
        address palPool,
        address loanAddress,
        uint256 palLoanTokenId
    );
    /** @notice Event when a loan is ended */
    event CloseLoan(
        address borrower,
        address delegatee,
        address underlying,
        uint amount,
        address palPool,
        uint usedFees,
        address loanAddress,
        uint256 palLoanTokenId,
        bool wasKilled
    );

    /** @notice Reserve Events */
    event AddReserve(uint amount);
    event RemoveReserve(uint amount);
    event WithdrawFees(uint amount);


    //Functions
    function deposit(uint _amount) external returns(uint);
    function withdraw(uint _amount) external returns(uint);
    
    function borrow(address _delegatee, uint _amount, uint _feeAmount) external returns(uint);
    function expandBorrow(address _loanPool, uint _feeAmount) external returns(uint);
    function closeBorrow(address _loanPool) external;
    function killBorrow(address _loanPool) external;
    function changeBorrowDelegatee(address _loanPool, address _newDelegatee) external;

    function balanceOf(address _account) external view returns(uint);
    function underlyingBalanceOf(address _account) external view returns(uint);

    function isLoanOwner(address _loanAddress, address _user) external view returns(bool);
    function idOfLoan(address _loanAddress) external view returns(uint256);

    function getLoansPools() external view returns(address [] memory);
    function getLoansByBorrower(address _borrower) external view returns(address [] memory);
    function getBorrowData(address _loanAddress) external view returns(
        address _borrower,
        address _delegatee,
        address _loanPool,
        uint256 _palLoanTokenId,
        uint _amount,
        address _underlying,
        uint _feesAmount,
        uint _feesUsed,
        uint _startBlock,
        uint _closeBlock,
        bool _closed,
        bool _killed
    );

    function borrowRatePerBlock() external view returns (uint);
    function supplyRatePerBlock() external view returns (uint);

    function exchangeRateCurrent() external returns (uint);
    function exchangeRateStored() external view returns (uint);

    function minBorrowFees(uint _amount) external view returns (uint);

    function isKillable(address _loan) external view returns(bool);

    //Admin functions : 
    function setNewController(address _newController) external;
    function setNewInterestModule(address _interestModule) external;
    function setNewDelegator(address _delegator) external;

    function updateMinBorrowLength(uint _length) external;
    function updatePoolFactors(uint _reserveFactor, uint _killerRatio) external;

    function addReserve(uint _amount) external;
    function removeReserve(uint _amount) external;
    function withdrawFees(uint _amount, address _recipient) external;

}