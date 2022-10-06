//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.10;

interface PlanetDiscount{
    
    function changeUserSupplyDiscount(address minter) external returns(uint _totalSupply,uint _accountTokens);
    
    function changeUserBorrowDiscount(address borrower) external returns(uint ,uint , uint);
        
    function changeLastBorrowAmountDiscountGiven(address borrower,uint borrowAmount) external;
        
    function returnSupplyUserArr(address market) external view returns(address[] memory);
    
    function returnBorrowUserArr(address market) external view returns(address[] memory);
    
    function supplyDiscountSnap(address market,address user) external view returns(bool,uint,uint,uint);
    
    function borrowDiscountSnap(address market,address user) external view returns(bool,uint,uint,uint,uint);
    
    function totalDiscountGiven(address market) external view returns(uint);

    function listMarket(address market) external returns(bool);

    //delete later
     function changeAddress(address _newgGammaAddress,address _newGammatroller,address _newOracle,address _newInfinityVault) external returns(bool);
}