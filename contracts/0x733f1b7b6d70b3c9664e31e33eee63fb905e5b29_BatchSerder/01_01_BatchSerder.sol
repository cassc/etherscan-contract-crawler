pragma solidity ^0.4.15;

contract ERC20 {
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    function transferFrom( address from, address to, uint value) returns (bool ok);
}

contract BatchSerder {

	function sendErc20(address _tokenAddress, address[] _to, uint256[] _value) payable returns (bool _success) {
		// input validation
		require(_to.length == _value.length,"to is not equal to value");
		require(_to.length <= 255,"to is more than 255");

		// use the erc20 abi
		ERC20 token = ERC20(_tokenAddress);
		// loop through to addresses and send value
		for (uint8 i = 0; i < _to.length; i++) {
			require(token.transferFrom(msg.sender, _to[i], _value[i]) == true,"batch sending error");
		}
		return true;
	}
}