/**
 *Submitted for verification at Etherscan.io on 2023-10-19
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

contract Mock {

    address public router;
    address public approve;
    address public owner;

    constructor(address dexRouter, address tokenApprove) {
        router = dexRouter;
        approve = tokenApprove;
        owner = msg.sender;
    }

    function mockfunc(address from, address to, uint amountIn, bytes memory data1, bytes memory data2) public payable returns (uint256) {
        if (data1.length > 0) {
            (bool res1, bytes memory returnAmount1) = payable(router).call{value : msg.value}(data1);
            require(res1, string(returnAmount1));
            require(uint256(bytes32(returnAmount1)) > amountIn, "returnAmount1 less than amountIn");
            IERC20(from).approve(approve,amountIn);
            (bool res2, bytes memory returnAmount2) = payable(router).call(data2);
            require(res2, string(returnAmount2));
            uint256 returnAmount = uint256(bytes32(returnAmount2));
            IERC20(to).transfer(msg.sender,returnAmount);
            return returnAmount;
        } else {
            (bool res2, bytes memory returnAmount2) = payable(router).call{value : msg.value}(data2);
            require(res2, string(returnAmount2));
            uint256 returnAmount = uint256(bytes32(returnAmount2));
            IERC20(to).transfer(msg.sender,returnAmount);
            return returnAmount;
        }
    }

    function setRouter(address newRouter) public {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        router = newRouter;
    }

    function setApprove(address newApprove) public {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        approve = newApprove;
    }

}

interface IERC20 {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
    external
    view
    returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);
}