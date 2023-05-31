// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.7.0;

import "../../vendor/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";


interface ICUTLib is IERC20 {

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);

    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);
    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool);
    function signalRetireIntent(uint256 retirementAmount) external;
}

interface ICUTImpl {
    event InternalTransfer(address indexed from, address indexed to, uint256 amount);
    event InternalApproval(address indexed owner, address indexed spender, uint256 amount);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);

    function balanceOf(address account) external view returns (uint256);
    function totalSupply() external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    /* Proxy specific implementation to pass actual sender through to do their own work.
     * this is here to avoid using tx.origin which is a known security smell, and can
     * hijack admin calls. msgSender on CUT will always be the Proxy contract, so context
     * is lost when using the public ERC interface.
     */
    function approve(address proxySender, address spender, uint256 amount) external returns (bool);
    function transfer(address proxySender, address recipient, uint256 amount) external returns (bool);
    function transferFrom(address proxySender, address sender, address recipient, uint256 amount) external returns (uint256);
    function increaseAllowance(address proxySender, address spender, uint256 addedValue) external returns (uint256);
    function decreaseAllowance(address proxySender, address spender, uint256 subtractedValue) external returns (uint256);
    function signalRetireIntent(address proxySender, uint256 retirementAmount) external;
}