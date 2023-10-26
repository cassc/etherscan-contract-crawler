// SPDX-License-Identifier: LGPL-3.0-only

pragma solidity ^0.8.0;

import "../../manifold/libraries-solidity/access/AdminControl.sol";
import "../../openzeppelin/finance/PaymentSplitter.sol";

/**
 * @title Splitter
 * @dev This contract allows to split Ether payments among a group of accounts. The sender does not need to be aware
 * that the Ether will be split in this way, since it is handled transparently by the contract.
 *
 * The split can be in equal parts or in any other arbitrary proportion. The way this is specified is by assigning each
 * account to a number of shares. Of all the Ether that this contract receives, each account will then be able to claim
 * an amount proportional to the percentage of total shares they were assigned. The distribution of shares is set at the
 * time of contract deployment and can't be updated thereafter.
 *
 * `Splitter` follows a _pull payment_ model. This means that payments are not automatically forwarded to the
 * accounts but kept in this contract, and the actual transfer is triggered as a separate step by calling the {release}
 * function or Admin must call releaseAll which triggers the release function for all recipients
 * configured in this contract.
 * 
 **/
contract Splitter is PaymentSplitter, AdminControl{
    // For holding share holder's count
    uint256 payeeCount;
    constructor(
        address[] memory _payees,
        uint256[] memory _shares)
        PaymentSplitter(_payees, _shares) payable {
            payeeCount = _payees.length;  
            uint256 totalShares;
            for(uint256 i=0;i<payeeCount;i++){
                totalShares += _shares[i];
            }
            require(totalShares == 10000,"Total shares must be equal to 10000");               
    }

    /*
    * @notice releaseAll function to release the shares to shares holders by admin
    * @param token ERC20 contract address or zero address if realase of ETH
    */
    function releaseAll(address token) external adminRequired{
        // For handling ETH Release
        if(token == address(0)){
            require(address(this).balance!=0,"Contract has no balance");
            for(uint256 i=0;i<payeeCount;i++){
                if(shares(payee(i)) > 0 && releasable(payee(i))!=0 ){
                    release(payable(payee(i)));
                }
            }   
        }
        //For handling ERC20 Release
        else{
            require(IERC20(token).balanceOf(address(this)) != 0,"Contract has no Token Balance");
            for(uint256 i=0;i<payeeCount;i++){
                if(shares(payee(i)) > 0 && releasable(IERC20(token), payee(i))!=0 ){
                    release(IERC20(token), payable(payee(i)));
                }
            } 

        }      
    }   
       
    fallback() external payable {}
}