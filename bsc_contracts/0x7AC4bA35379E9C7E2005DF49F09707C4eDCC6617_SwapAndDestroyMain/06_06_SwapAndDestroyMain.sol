// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma abicoder v2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

interface IPancakeRouter02 {
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

/**
 * @title Swap and burn
 * @notice For the exchange of A tokens and the destruction of B tokens
 * @dev The method call sequence of the contract is to transfer A token into the contract,
 *      Call the depositTokens method passing in the array on that method and check the order with the getTokenAddresses method
 *      Execute the exchangeAndDestroy method to destroy
 */
contract SwapAndDestroyMain is Ownable {
    IERC20[] public swapTokenArray;
    // @notice main net address
    IPancakeRouter02 public constant iPancakeRouter02 = IPancakeRouter02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
    // @notice destroy address
    address public constant destroyAddress = 0x000000000000000000000000000000000000dEaD;

    /**
    * @notice Set token order
    * @param _swapTokenArray Sequence of Token Swaps
    * @dev Enter the following array to achieve
    *      A=>usdt=>wbnb=>B
    *      [0xB8e1776d25cCc6dbc723B08708d3341CAa9217FC,0x55d398326f99059fF775485246999027B3197955,
    *      0xbb4cdb9cbd36b01bd1cbaebf2de08d9173bc095c,0x42f36906ea8aa610bf3552ee1457b9b2ff820fd2]
    */
    function depositTokens(IERC20[] memory _swapTokenArray) external onlyOwner {
        swapTokenArray = new IERC20[](0);
        for (uint256 i; i < _swapTokenArray.length; ++i) {
            swapTokenArray.push(_swapTokenArray[i]);
        }
    }

    /**
    * @notice Precise Transaction and Destruction
    * @dev This method executes the exchange and destruction guarantee that there are tokens in the contract and all are destroyed
    */
    function exchangeAndDestroy() external onlyOwner {
        uint256 swapInTokenAmount = swapTokenArray[0].balanceOf(address(this));
        require(swapInTokenAmount > 0, "Insufficient number of tokens");
        swapTokenArray[0].approve(address(iPancakeRouter02), swapInTokenAmount);
        iPancakeRouter02.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            swapInTokenAmount,
            1,
            getTokenAddresses(),
            destroyAddress,
            block.timestamp + 300
        );
    }

    /**
    * @notice Get an array of addresses for tokens
    * @dev Check whether the sequence is correct after calling depositTokens
    */
    function getTokenAddresses() public view returns (address[] memory) {
        address[] memory tokenAddresses = new address[](swapTokenArray.length);
        for (uint i = 0; i < swapTokenArray.length; i++) {
            tokenAddresses[i] = address(swapTokenArray[i]);
        }
        return tokenAddresses;
    }

    /**
    * @notice Emergency refund
    * @dev Emergency refund when the contract is abnormal Transfer all the tokens in the deposit Tokens method to the input address
    * @param _userAddress Payee Address
    */
    function emergencyRefund(address payable _userAddress) external onlyOwner {
        for (uint256 i; i < swapTokenArray.length; ++i) {
            uint256 tokenAmount = swapTokenArray[i].balanceOf(address(this));
            if (tokenAmount > 0) {
                swapTokenArray[i].transfer(_userAddress, tokenAmount);
            }
        }
        uint256 gasToken = address(this).balance;
        if (gasToken > 0) {
            _userAddress.transfer(gasToken);
        }
    }

    // ==========================
    receive() external payable {}

    fallback() external payable {}
    // ==========================
}