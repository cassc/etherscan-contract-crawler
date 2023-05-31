pragma solidity ^0.5.8;

import "./ierc20.sol";
import "./safemath.sol";
import "./erc20.sol";
import "./burnable.sol";
import "./ownable.sol";
import "./timelocks.sol";

contract ContractFallbacks {
    function receiveApproval(address from, uint256 _amount, address _token, bytes memory _data) public;
	function onTokenTransfer(address from, uint256 amount, bytes memory data) public returns (bool success);
}

contract Wolfs is IERC20, ERC20, ERC20Burnable, Ownable, Timelocks {
	using SafeMath for uint256;

	string public name;
	string public symbol;
	uint8 public decimals;

	/**
	*	@dev Token constructor
	*/
	constructor () public {
		name = "Wolfs Group AG";
		symbol = "WLF";
		decimals = 0;

		owner = 0x7fd429DBb710674614A35e967788Fa3e23A5c1C9;
		emit OwnershipTransferred(address(0), owner);

		_mint(0xc7eEef150818b5D3301cc93a965195F449603805, 15000000);
		_mint(0x7fd429DBb710674614A35e967788Fa3e23A5c1C9, 135000000);
	}

	/**
	 * @dev function that allow to approve for transfer and call contract in one transaction
	 * @param _spender contract address
	 * @param _amount amount of tokens
	 * @param _extraData optional encoded data to send to contract
	 * @return True if function call was succesfull
	 */
    function approveAndCall(address _spender, uint256 _amount, bytes calldata _extraData) external returns (bool success)
	{
        require(approve(_spender, _amount), "ERC20: Approve unsuccesfull");
        ContractFallbacks(_spender).receiveApproval(msg.sender, _amount, address(this), _extraData);
        return true;
    }

    /**
     * @dev function that transer tokens to diven address and call function on that address
     * @param _to address to send tokens and call
     * @param _value amount of tokens
     * @param _data optional extra data to process in calling contract
     * @return success True if all succedd
     */
	function transferAndCall(address _to, uint _value, bytes calldata _data) external returns (bool success)
  	{
  	    _transfer(msg.sender, _to, _value);
		ContractFallbacks(_to).onTokenTransfer(msg.sender, _value, _data);
		return true;
  	}

}
