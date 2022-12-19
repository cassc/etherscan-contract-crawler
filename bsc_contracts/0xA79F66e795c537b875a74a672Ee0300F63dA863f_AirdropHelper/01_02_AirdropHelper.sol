pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract AirdropHelper {
    function multisendToken(address _tokenAddress, address[] memory _to, uint256[] memory _value) external {
        require(_to.length == _value.length, "length not equal");
	    for (uint256 i = 0; i < _to.length; i++) {
            IERC20(_tokenAddress).transferFrom(msg.sender, _to[i], _value[i]);
		}
    }
}