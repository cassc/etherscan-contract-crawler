/**
 *Submitted for verification at Etherscan.io on 2023-04-17
*/

pragma solidity 0.8.1;

interface ISablier { 
	
	function createStream(
		address recipent, 
		uint256 deposit, 
		address tokenAddress, 
		uint256 startTime, 
		uint256 stopTime
	) external  returns (uint256);

}	

interface IERC20 { 
	
	function transfer(address to, uint256 amount) external returns (bool);

	function transferFrom(address from, address to, uint256 amount) external returns (bool);

	function balanceOf(address owner) external returns (uint256);

	function approve(address spender, uint256 amount) external;
	
}

contract Proposal {

    function executeProposal() external {
        uint256 FISCAL_Q_DURATION = 91 days;
        uint256 RENUMERATION_START_TS = block.timestamp;
        uint256 RENUMERATION_AMOUNT = 8131 ether;
        uint256 RENUMERATION_NORMALISED_AMOUNT = RENUMERATION_AMOUNT - (RENUMERATION_AMOUNT % FISCAL_Q_DURATION);

        address RENUMERATION_ADDRESS = 0x40d16C473CB7bF5fAB9713b27A4562EAa6f915d1;

        uint256 AUDIT_REMMINBURSEMENT_AMOUNT = 1802 ether;

        address _tokenAddress = 0x77777FeDdddFfC19Ff86DB637967013e6C6A116C;
        address _sablierAddress = 0xCD18eAa163733Da39c232722cBC4E8940b1D8888;

        IERC20(_tokenAddress).transfer(RENUMERATION_ADDRESS, AUDIT_REMMINBURSEMENT_AMOUNT);

        IERC20(_tokenAddress).approve(_sablierAddress, RENUMERATION_NORMALISED_AMOUNT);

        ISablier(_sablierAddress).createStream(
            RENUMERATION_ADDRESS,
            RENUMERATION_NORMALISED_AMOUNT,
            _tokenAddress,
            RENUMERATION_START_TS,
            RENUMERATION_START_TS + FISCAL_Q_DURATION
        );
    }

}