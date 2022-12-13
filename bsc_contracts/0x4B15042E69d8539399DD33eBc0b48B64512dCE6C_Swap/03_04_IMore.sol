// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

interface IMore is IERC20 {
    function setModifiers(address account, uint32 reflections, uint32 isAddition, uint32 buyDiscount, uint32 sellDiscount) external;
    function setModifiers(address account1, address account2,
                             uint32 reflections,
                             uint32 buyDiscount1, uint32 sellDiscount1,
                             uint32 buyDiscount2, uint32 sellDiscount2) external;
    function getModifiers(address account1, address account2) external view returns(uint32, uint32, uint32, uint32);
    function getModifiers(address account) external view returns(uint32, uint32);

    function addShares(address account, uint256 difference, uint256 isAddition) external;
    function setBuyTaxReduction(address account, uint256 value) external;
    function setSellTaxReduction(address account, uint256 value) external;

    function buybackAndBurn() external payable;
    function buybackAndLockToLiquidity() external payable;
    function addBNBToLiquidityPot() external payable;

    function isAuthorized(address) external view returns(uint256);

    function prepareReferralSwap(address, uint32, uint16) external returns(uint32, uint16);
    function referrerSystemData() external view returns(uint16, uint16, uint16, uint16, uint96, uint96);
    function lastReferrerTokensAmount() external view returns(uint96);

    function lightningTransfer(address, uint256) external;
}