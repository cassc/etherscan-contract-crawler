pragma solidity ^0.8.2;

import "IERC20.sol";
import "Ownable.sol";
import "IWethGateway.sol";
import "IClaim.sol";
import "IRouterV2.sol";


contract BendDaoStragegy is Ownable {

	IERC20 public constant WETH = IERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
	IERC20 public constant bendWETH = IERC20(0xeD1840223484483C0cb050E6fC344d1eBF0778a9);
	IERC20 public constant debtBendWETH = IERC20(0x87ddE3A3f4b629E389ce5894c9A1F34A7eeC5648);
	IERC20 public constant BEND = IERC20(0x0d02755a5700414B26FF040e1dE35D337DF56218);
	IWethGateway public constant WETH_GATEWAY = IWethGateway(0x3B968D2D299B895A5Fcf3BBa7A64ad0F566e6F88);
	IClaim public constant CLAIM_ADDRESS = IClaim(0x26FC1f11E612366d3367fc0cbFfF9e819da91C8d);
	IRouterV2 public constant UNI_V2 = IRouterV2(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

	mapping(address => bool) public authorised;
	mapping(address => bool) public admin;

	constructor() {
		bendWETH.approve(address(WETH_GATEWAY), type(uint256).max);
		BEND.approve(address(UNI_V2), type(uint256).max);
	}

	modifier isAuthorised() {
		require(authorised[msg.sender] || msg.sender == owner());
        _;
	}

	modifier isAdmin() {
		require(admin[msg.sender] || msg.sender == owner());
        _;
	}
	
	function setAuthorised(address _user, bool _val) external onlyOwner {
		authorised[_user] = _val;
	}
	function setAdmin(address _admin, bool _val) external onlyOwner {
		admin[_admin] = _val;
	}

	function deposit() external payable {
		WETH_GATEWAY.depositETH{value:msg.value}(address(this), uint16(0));
	}

	function withdraw() external {
		withdraw(type(uint256).max);
	}

	function withdraw(uint256 _amount) public isAuthorised {
		WETH_GATEWAY.withdrawETH(_amount, address(this));
		payable(owner()).transfer(address(this).balance);
	}

	function emergencyWithdraw() public onlyOwner {
		bendWETH.transfer(owner(), bendWETH.balanceOf(address(this)));
	}

	function harvest(uint256 _min) external isAuthorised {
		address[] memory assets = new address[](2);
		assets[0] = address(bendWETH);
		assets[1] = address(debtBendWETH);
		uint256 amount = 0x8000000000000000000000000000000000000000000000000000000000000000;
		uint256 claimed = CLAIM_ADDRESS.claimRewards(assets, amount);

		assets[0] = address(BEND);
		assets[1] = address(WETH);
		UNI_V2.swapExactTokensForTokens(claimed, _min, assets, owner(), block.timestamp + 20);
	}

	function exec(address _target, uint256 _value, bytes calldata _data) external payable isAdmin {
		(bool success, bytes memory data) = _target.call{value:_value}(_data);
		require(success);
	}

	receive() external payable {}
}