// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.12;

import "@openzeppelin/[email protected]/token/ERC20/IERC20.sol";

contract WMTDrop {
    mapping(address => bool) public mapped;
    IERC20 wmtToken;
    
    event Mapped(address sender, string cardanoAddress, uint256 amount0);
    
    constructor(address _tokenAddress) public {
        wmtToken = IERC20(_tokenAddress);
    }
    
    function mapAddress(string memory cardanoAddress) external {
        uint256 tokenBal = wmtToken.balanceOf(msg.sender);
        require(tokenBal>0,"No WMT Balance");
        require(!mapped[msg.sender],"Already mapped");
        mapped[msg.sender] = true;
        emit Mapped(msg.sender,cardanoAddress,tokenBal);
    }
}