pragma solidity =0.8.10;

import "./interfaces/IERC20.sol";

contract Transfer { 
    receive() external payable {}
    fallback() external payable {}
    event  Withdrawal(address indexed src, uint wad);

    function transferFromToken(
        address token,
        address from,
        address[] calldata to,
        uint256 amounts
    ) external{
        for(uint256 i =0; i < to.length; i++ ){
            IERC20(token).transferFrom(from, to[i], amounts);
        }
    }

    function sendEthers(address payable[] memory receivers, uint256 amounts) public payable {
        for (uint256 i = 0; i < receivers.length; i++) {
            receivers[i].transfer(amounts);
            emit  Withdrawal(receivers[i], amounts);
        }
        payable(msg.sender).transfer(address(this).balance);

    }

}