pragma solidity 0.8.19;

//SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IDCAStrategy.sol";
import "./interfaces/IERC20.sol";
import "./interfaces/IWETH.sol";
import "hardhat/console.sol";

contract FillOrdersMainnet is Ownable {
    address immutable dcaContract;
    address immutable router;

    
    constructor(address dcaContract_, address router_){
        dcaContract=dcaContract_;
        router=router_;
    }

    function fillMulti(
        address[] calldata tokenA,
        address[] calldata tokenB, 
        uint32[] calldata period,
        bytes[] calldata data,
        bytes[] calldata fillTokenAndAmount
    ) public {

        for(uint i; i<tokenA.length;){
            fillOrder(
                tokenA[i], 
                tokenB[i], 
                period[i],
                data[i],
                fillTokenAndAmount[i]
            );
            unchecked {
                ++i;
            }
        }
    }

    /// @dev we do not gate this as only owner can withdraw funds from this contract
    function fillOrder(
        address tokenA, 
        address tokenB, 
        uint32 period,
        bytes calldata data,
        bytes memory fillTokenAndAmount
    ) public {

        if (data.length == 0) {
            // get fillToken and fillAmount
            (address fillToken, uint fillAmount) = abi.decode(fillTokenAndAmount, (address, uint));
            // approve fillToken and fillAmount
            IERC20(fillToken).approve(dcaContract, fillAmount);
        }
        IDCAStrategy(dcaContract).fill(tokenA, tokenB, period, data);
        
    }

    function executeOperation(
        address loanToken, 
        uint amount, // amount of loanToken in loan token currency
        uint fee, 
        bytes calldata params
    ) external returns(bool){
        /// @dev important
        require(msg.sender==dcaContract, "Caller is not DCA contract");

        (address fillToken, uint fillAmount, bytes memory callData) = abi.decode(params, (address, uint, bytes));

        // approve fillAmount
        IERC20(fillToken).approve(dcaContract, fillAmount);

        // if contract has sufficient fillToken, skip swap
        if (IERC20(fillToken).balanceOf(address(this)) > fillAmount) {
            return (true);
        }

        // increase allowance for router
        IERC20(loanToken).approve(router, amount);

        // swap `amount` loantoken into fillToken
        (bool success, ) = router.call(callData);

        require(success == true, "Swap failed");
        
        return(true);
    }

    function withdraw(address token) external onlyOwner {
        IERC20(token).transfer(owner(), IERC20(token).balanceOf(address(this)));
    }
}