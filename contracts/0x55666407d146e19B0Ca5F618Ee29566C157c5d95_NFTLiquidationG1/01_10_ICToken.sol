// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface ICErc20 {
    function symbol() external view returns (string memory);

    function underlying() external view returns (address);

    /*** User Interface ***/

    function transfer(address dst, uint amount) external returns (bool);
    function transferFrom(address src, address dst, uint amount) external returns (bool);
    function approve(address spender, uint amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function balanceOfUnderlying(address owner) external returns (uint);
    function getAccountSnapshot(address account) external view returns (uint, uint, uint, uint);
    function borrowRatePerBlock() external view returns (uint);
    function supplyRatePerBlock() external view returns (uint);
    function totalBorrowsCurrent() external returns (uint);
    function borrowBalanceCurrent(address account) external returns (uint);

    function isCToken() external view returns (bool);
    function accrueInterest() external returns (uint);


    /*** User Interface ***/

    function mint(uint tokenId) external returns (uint);
    function redeem(uint redeemTokens) external returns (uint);
    function mints(uint[] calldata tokenIds) external returns (uint[] memory);
    function redeems(uint[] calldata redeemTokenIds) external returns (uint[] memory);
    function redeemUnderlying(uint redeemAmount) external returns (uint);
    function borrow(uint borrowAmount) external returns (uint);
    function repayBorrow(uint repayAmount) external returns (uint);
    function repayBorrowBehalf(address borrower, uint repayAmount) external returns (uint);
    function liquidateBorrow(address borrower, uint repayAmount, address cTokenCollateral) external returns (uint);
}

interface ICErc721 is ICErc20{
    /*** storage ***/
    function userTokens(address user, uint tokenIndex) external view returns (uint);
}

interface ICEther {
    function symbol() external view returns (string memory);

    function underlying() external view returns (address);

    function liquidateBorrow(address borrower, address cTokenCollateral) external payable;

    function repayBorrowBehalf(address borrower) external payable;

    function isCToken() external view returns (bool);

    function mint() external payable;
}