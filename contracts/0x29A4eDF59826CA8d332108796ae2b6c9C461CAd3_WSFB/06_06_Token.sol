// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// WWWWWWWW                           WWWWWWWW   SSSSSSSSSSSSSSS FFFFFFFFFFFFFFFFFFFFFFBBBBBBBBBBBBBBBBB   
// W::::::W                           W::::::W SS:::::::::::::::SF::::::::::::::::::::FB::::::::::::::::B  
// W::::::W                           W::::::WS:::::SSSSSS::::::SF::::::::::::::::::::FB::::::BBBBBB:::::B 
// W::::::W                           W::::::WS:::::S     SSSSSSSFF::::::FFFFFFFFF::::FBB:::::B     B:::::B
//  W:::::W           WWWWW           W:::::W S:::::S              F:::::F       FFFFFF  B::::B     B:::::B
//   W:::::W         W:::::W         W:::::W  S:::::S              F:::::F               B::::B     B:::::B
//    W:::::W       W:::::::W       W:::::W    S::::SSSS           F::::::FFFFFFFFFF     B::::BBBBBB:::::B 
//     W:::::W     W:::::::::W     W:::::W      SS::::::SSSSS      F:::::::::::::::F     B:::::::::::::BB  
//      W:::::W   W:::::W:::::W   W:::::W         SSS::::::::SS    F:::::::::::::::F     B::::BBBBBB:::::B 
//       W:::::W W:::::W W:::::W W:::::W             SSSSSS::::S   F::::::FFFFFFFFFF     B::::B     B:::::B
//        W:::::W:::::W   W:::::W:::::W                   S:::::S  F:::::F               B::::B     B:::::B
//         W:::::::::W     W:::::::::W                    S:::::S  F:::::F               B::::B     B:::::B
//          W:::::::W       W:::::::W         SSSSSSS     S:::::SFF:::::::FF           BB:::::BBBBBB::::::B
//           W:::::W         W:::::W          S::::::SSSSSS:::::SF::::::::FF           B:::::::::::::::::B 
//            W:::W           W:::W           S:::::::::::::::SS F::::::::FF           B::::::::::::::::B  
//             WWW             WWW             SSSSSSSSSSSSSSS   FFFFFFFFFFF           BBBBBBBBBBBBBBBBB   

/*
 * https://twitter.com/WSFBeth
 * https://t.me/wsfbeth
*/

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract WSFB is ERC20("We are so fucking back","WSFB"), Ownable {
	address public LP;
	address public ROUTER;
	address public immutable DEPLOYER;

	uint public MAX_BALANCE_PERCENTAGE = 400; // 4%
	uint public constant DENOMINATOR = 10000;

	mapping(address => bool) public isMEV;

	constructor() {
		_mint(msg.sender, 69_420_000_000 ether);
		DEPLOYER = msg.sender;
	}

	function _transfer(address _from, address _to, uint _amount) internal override {
		require(!isMEV[_from], "Banned MEV bot");

		super._transfer(_from, _to, _amount);

		if (_to != LP && _to != ROUTER && _to != DEPLOYER) {
			uint maxBalance = totalSupply() * MAX_BALANCE_PERCENTAGE / DENOMINATOR;
			require(balanceOf(_to) <= maxBalance, "Receiver balance is too big");
		}
	}

	function init(address lp, address router) external onlyOwner {
		assert(LP == address(0) && ROUTER == address(0));
		LP = lp;
		ROUTER = router;
	}

	function setMaxBalancePercentage(uint maxBalancePercentage) external onlyOwner {
		assert(maxBalancePercentage > 0);
		MAX_BALANCE_PERCENTAGE = maxBalancePercentage;
	}

	function banMEV(address _mev) external onlyOwner {
		isMEV[_mev] = true;
	}
	
	function unbanMEV(address _mev) external onlyOwner {
		isMEV[_mev] = false;
	}
}