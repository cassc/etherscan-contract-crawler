// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

interface IToken {
	function balanceOf(address account) external view returns (uint256);
}

contract Tools is Initializable, OwnableUpgradeable {
    using Strings for uint256;
	using SafeERC20Upgradeable for IERC20Upgradeable;
	
	function initialize() public initializer {
        __Ownable_init();
	}
	
	function getBalancesV2(IToken token, address[] calldata addresses) external view returns (string memory) {
        string memory balances;
		
		for (uint256 j=0; j<addresses.length; j++) {
		
			uint256 bal = 0;
			if (token == IToken(address(0))) {
				bal = addresses[j].balance;
			} else {
				bal = token.balanceOf(addresses[j]);
			}
			
			if (bal > 0) {
				balances = string.concat(balances, j.toString());
				balances = string.concat(balances, "-");
				balances = string.concat(balances, bal.toString());
				balances = string.concat(balances, ",");
			}
		}

        return balances;        
    }
	
	//batch send different eth amount
    function batchSendEth(address payable[] memory recipients/*must eoa*/, uint256[] memory amounts) public payable {
        for (uint256 i = 0; i < recipients.length; i++) {
            recipients[i].transfer(amounts[i]);
        }
    }    
	
	//batch send different erc20 amount
    function batchSendErc20(IERC20Upgradeable[] memory tokens, address[] memory recipients/*must eoa*/, uint256[] memory amounts) public {
        for (uint256 i = 0; i < recipients.length; i++) {
            tokens[i].safeTransferFrom(msg.sender, recipients[i], amounts[i]);
        }
    }    

}