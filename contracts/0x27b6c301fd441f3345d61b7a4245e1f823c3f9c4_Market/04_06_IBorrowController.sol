pragma solidity ^0.8.13;

interface IBorrowController {
    //public variables
    function operator() external view returns(address);
    //public mappings
    function contractAllowlist(address nonEOA) external view returns(bool);
    function dailyLimits(address market) external view returns(uint);
    function dailyBorrows(address market, uint day) external view returns(uint);
    //public functions
    function borrowAllowed(address msgSender, address borrower, uint amount) external returns(bool);
    function onRepay(uint amount) external;
}