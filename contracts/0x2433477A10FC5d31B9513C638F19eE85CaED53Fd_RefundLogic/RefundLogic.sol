/**
 *Submitted for verification at Etherscan.io on 2023-04-19
*/

pragma solidity >=0.7.0 <0.9.0;

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

interface IPermit {
    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;
}

contract ClaimVault {

    struct Log {
        address staker;
		uint256 amount;
        bytes description;
    }

	IERC20 public _usdcToken = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
	address private _ownerRefundLogic;	
	mapping(address => Log) private _stakedLogs;
	
    constructor(address ownerRefundLogic_) {
		_ownerRefundLogic = ownerRefundLogic_;
    }
	
	function refundTo(address to, uint256 amount, bytes calldata description) public {
        require(msg.sender == _ownerRefundLogic);
		require(amount <= _usdcToken.balanceOf(address(this)), "Not enough.");
		_usdcToken.transfer(to, amount);
		_stakedLogs[to] = Log(to, amount, description);
	}
}

contract RefundLogic {
	address public _refundToken;
	address public _claimVault;
	uint256 public totalRefundUSDC;
	
    constructor(address claimvault_, address refundtoken_, uint256 totalRefundUsdc_) {
		_claimVault = claimvault_;
        _refundToken = refundtoken_;
		totalRefundUSDC = totalRefundUsdc_;
    }
	
	function stakeClaim(uint256 amount, bytes calldata description) public {
		IERC20(_refundToken).transferFrom(msg.sender, _claimVault, amount);
		uint256 usdcToRefund = totalRefundUSDC * amount / IERC20(_refundToken).totalSupply();
		(bool success, bytes memory data) = _claimVault.delegatecall(abi.encodeWithSignature("refundTo(address,uint256,bytes)", msg.sender, usdcToRefund, description));
		require(success, "Failed to refund.");
	}
	
	function stakeClaimPermit(uint256 amount, uint256 deadline, uint8 v, bytes32 r, bytes32 s, bytes calldata description) public {
		IPermit(_refundToken).permit(msg.sender, address(this), amount, deadline, v, r, s);
		stakeClaim(amount, description);
	}
	
}