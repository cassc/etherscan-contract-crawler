// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract SgaTreasury {
    address public ticAddress;
    address public titAddress;
    address public usdtAddress;
    address public multSigAddress;
    
    constructor(address _multSigAddress, address _usdtAddress, address _titAddress, address _ticAddress) public {
        multSigAddress = _multSigAddress;
        usdtAddress = _usdtAddress;
        titAddress = _titAddress;
        ticAddress = _ticAddress;
    }

    modifier onlyMultSig() {
        require(msg.sender == multSigAddress, "MsgSender not is multSigAddress");
        _;
    }

    function withdrawTIT(address to, uint256 amount) public onlyMultSig {  
        IERC20(titAddress).transfer(to, amount);
    }

    function withdrawTIC(address to, uint256 amount) public onlyMultSig {
        IERC20(ticAddress).transfer(to, amount);
    }

    function withdrawUSDT(address to, uint256 amount) public onlyMultSig {
        IERC20(usdtAddress).transfer(to, amount);
    }

    function withdraw(address tokenAddr, address to, uint256 amount) public onlyMultSig {
        uint256 bal = IERC20(tokenAddr).balanceOf(address(this));
        if (bal < amount) {
            amount = bal;
        }

        IERC20(tokenAddr).transfer(to, amount);
    }
}