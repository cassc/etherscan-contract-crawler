// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./Itoken.sol";
import "./FailSafeWallet.sol";

/**
 * @dev Fees used by the FailSafeOrchestrator to
 * compensate the Interceptor key fleet for the 
 * gas spent defending the targeted wallet.
 * 
 */
abstract contract Fees {
    using SafeERC20 for IERC20;
    // Warning upgradability: do not delete
	// e.g., WETH or WMATIC
	address public gasToken;
	// Not deleting unusued vars 
	// to preserve proxy state
	address public feeWallet;
	uint public gasOverhead;

    function initFees(address _gasToken) internal {
        require(_gasToken != address(0), "invalid gasToken");
        gasToken = _gasToken;
    }

	function payFees(uint gasBill, address payer, address payerFSWallet) internal  {
        if (gasBill == 0) {
            return;
        }
 		require(gasToken != address(0), "invalid gasToken");
        require(payerFSWallet != address(0), "invalid payer addr");

 		IERC20 tok =  IERC20(gasToken);

        uint256 allowance = tok.allowance(payer, address(this));
        uint256 payerBal = tok.balanceOf(payer);
      

        if ((allowance >= gasBill)  && (payerBal >= gasBill)){
        	 // ACL enforced via merkle root
       		 //slither-disable-next-line arbitrary-send-erc20 before the issue
       		 tok.safeTransferFrom(payer, address(this), gasBill);   
        } else if ((payerFSWallet.code.length > 0) &&  (tok.balanceOf(payerFSWallet)  >=gasBill)){
 			 FailSafeWallet _contract = FailSafeWallet(payerFSWallet);

 			 _contract.payGasBill(gasBill);

        } else {
        	 require (allowance >= gasBill, "insufficient allowance to pay gas bill!");
        	 require (payerBal >= gasBill, "insufficient balance to pay gas bill"); 
        }

        // conpensate the fleet key back in native currency 
        // first get it in native to the orchestrator,
        // then back to the fleet key
        Erc20Extended _tok =  Erc20Extended(gasToken);

        _tok.withdraw(gasBill);

        address payable gasPayee = payable(msg.sender);
        gasPayee.transfer(gasBill);      
	}
}