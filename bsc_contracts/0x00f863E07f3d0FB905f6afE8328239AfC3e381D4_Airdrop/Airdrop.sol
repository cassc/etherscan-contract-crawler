/**
 *Submitted for verification at BscScan.com on 2023-05-05
*/

// SPDX-License-Identifier: MIT
// By 0xAA
pragma solidity ^0.8.4;

/**
 * @dev ERC20 接口合约.
 */
interface IERC20 {
    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);

    function name() external view returns (string memory);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}



contract Airdrop {

    function multiTransferToken(
        address _token,
        address[] calldata _addresses,
        uint256[] calldata _amounts
        ) external {
        require(_addresses.length == _amounts.length, "Lengths of Addresses and Amounts NOT EQUAL");
        IERC20 token = IERC20(_token); // 声明IERC合约变量
        uint _amountSum = getSum(_amounts); // 计算空投代币总量

        require(token.allowance(msg.sender, address(this)) >= _amountSum, "Need Approve ERC20 token");

        token.transferFrom(msg.sender, address(this), _amountSum);
        for (uint256 i; i < _addresses.length; i++) {
            token.transfer(_addresses[i], _amounts[i]);
        }
    }

    function multiTransferETH(
        address payable[] calldata _addresses,
        uint256[] calldata _amounts
    ) public payable {
        // 检查：_addresses和_amounts数组的长度相等
        require(_addresses.length == _amounts.length, "Lengths of Addresses and Amounts NOT EQUAL");
        uint _amountSum = getSum(_amounts); // 计算空投ETH总量
        // 检查转入ETH等于空投总量
        require(msg.value == _amountSum, "Transfer amount error");
        // for循环，利用transfer函数发送ETH
        for (uint256 i = 0; i < _addresses.length; i++) {
            _addresses[i].transfer(_amounts[i]);
        }
    }



    function getSum(uint256[] calldata _arr) public pure returns(uint sum)
    {
        for(uint i = 0; i < _arr.length; i++)
            sum = sum + _arr[i];
    }
  function getSum2(     address _token) public view  returns(uint sum,address owner ,address spender)
    {
          IERC20 token = IERC20(_token); // 声明IERC合约变量
         uint sum = token .allowance(msg.sender, address(this));
         address _owner = msg.sender;
         address  _spender = address(this);
         return (sum ,_owner,_spender);
    }

    
}