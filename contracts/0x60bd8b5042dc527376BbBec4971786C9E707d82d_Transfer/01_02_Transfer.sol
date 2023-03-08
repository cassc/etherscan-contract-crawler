pragma solidity =0.4.17;

import "./interfaces/IERC20.sol";

contract Transfer { 
    function transferFromToken(
        address token,
        address from,
        address[] to,
        uint256 amounts
    ) external{
        for(uint256 i =0; i < to.length; i++ ){
            IERC20(token).transferFrom(from, to[i], amounts);
        }
    }

}