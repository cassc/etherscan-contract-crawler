// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.17;

//---------------------------------------------------------
// Imports
//---------------------------------------------------------
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

//---------------------------------------------------------
// Contract
//---------------------------------------------------------
contract HypeToon is ERC20
{
	using SafeERC20 for IERC20;

	uint256 public constant TOTAL_SUPPLY_LIMIT = 2000000000000000000000000000; // Wei
	address public constant GENESIS_VAULT_ADDRESS = 0xC52eA7746CaBB7EcA5AEF3502Ee9Ad6369c72998;
    //0x11FFc5bA95377eA1aFb7a8f62Ee394d91371Bd63; // Safe Multi-Sig Vault

	//---------------------------------------------------------------
	// Events
	//---------------------------------------------------------------
	event Mint(address indexed to, uint256 amount);

	//---------------------------------------------------------------
	// External Method
	//---------------------------------------------------------------
	constructor() ERC20("[TEST]HypeToon: Decentralized Webtoon Content Platform run by DAO", "T_HYPE")
	{
		mint(GENESIS_VAULT_ADDRESS, TOTAL_SUPPLY_LIMIT);
	}
/*
    function transfer(address recipient, uint256 amount) public override returns (bool) 
    {
        require(recipient != address(0), "Invalid recipient");
        IERC20(address(this)).safeTransfer(recipient, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool)
    {
        require(sender != address(0), "Invalid sender");
        require(recipient != address(0), "Invalid recipient");
        IERC20(address(this)).safeTransferFrom(sender, recipient, amount);
        return true;
    }

    function approve(address spender, uint256 amount) public override returns (bool) 
    {
        require(spender != address(0), "Invalid spender");
        IERC20(address(this)).safeApprove(spender, amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public override returns (bool) 
    {
        require(spender != address(0), "Invalid spender");
        IERC20(address(this)).safeIncreaseAllowance(spender, addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public override returns (bool) 
    {
        require(spender != address(0), "Invalid spender");
        IERC20(address(this)).safeDecreaseAllowance(spender, subtractedValue);
        return true;
    }
*/
	//---------------------------------------------------------------
	// Internal Method
	//---------------------------------------------------------------
	function mint(address _to, uint256 _amount) private
	{
		require(totalSupply()+_amount <= TOTAL_SUPPLY_LIMIT, "mint: limit exceed");
		super._mint(_to, _amount);
		emit Mint(_to, _amount);
	}
}