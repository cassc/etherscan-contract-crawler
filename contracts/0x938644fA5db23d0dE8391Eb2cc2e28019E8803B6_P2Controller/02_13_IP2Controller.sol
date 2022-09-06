// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

interface IP2Controller {

    function mintAllowed(address xToken, address minter, uint256 mintAmount) external;

    function mintVerify(address xToken, address account) external;

    function redeemAllowed(address xToken, address redeemer, uint256 redeemTokens, uint256 redeemAmount) external;

    function redeemVerify(address xToken, address redeemer) external;
    
    function borrowAllowed(address xToken, uint256 orderId, address borrower, uint256 borrowAmount) external;

    function borrowVerify(uint256 orderId, address xToken, address borrower) external;

    function repayBorrowAllowed(address xToken, uint256 orderId, address borrower, address payer, uint256 repayAmount) external;

    function repayBorrowVerify(address xToken, uint256 orderId, address borrower, address payer, uint256 repayAmount) external;

    function repayBorrowAndClaimVerify(address xToken, uint256 orderId) external;

    function liquidateBorrowAllowed(address xToken, uint256 orderId, address borrower, address liquidator) external;

    function liquidateBorrowVerify(address xToken, uint256 orderId, address borrower, address liquidator, uint256 repayAmount)external;
    
    function transferAllowed(address xToken, address src, address dst, uint256 transferTokens) external;

    function transferVerify(address xToken, address src, address dst) external;

    function getOrderBorrowBalanceCurrent(uint256 orderId) external returns(uint256);

    // admin function

    function addPool(address xToken, uint256 _borrowCap, uint256 _supplyCap) external;

    function addCollateral(address _collection, uint256 _collateralFactor, uint256 _liquidateFactor, address[] calldata _pools) external;

    function setPriceOracle(address _oracle) external;

    function setXNFT(address _xNFT) external;
    
}