// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.0;
import "./utils/Context.sol";
import "./utils/Ownable.sol";
import "./interface/IOceanPool.sol";
import "./interface/IERC20.sol";

import "./utils/SafeMath.sol";
import "./utils/EnumerableSet.sol";
import "./utils/Address.sol";

contract OceanPool is IOceanPool, Context, Ownable  {
    address public oceanGodAddress;
    string public name;
    IERC20 public ocashToken;

    event UpdatedOceanGodAddress(address account);
    event MsgSender(address account);

    constructor () {
        name = "OceanPool";
    }

    receive() external payable {}

    function setOceanGodAddress(address account) external onlyOwner {
        oceanGodAddress = account;
        emit UpdatedOceanGodAddress(account);
    }

    function setOcashTokenContract(address tokenAddress) public onlyOwner {
        ocashToken = IERC20(tokenAddress);
    }

    function claimOCash(address account, uint256 amount) external override {
        require(_msgSender() == oceanGodAddress, "You are not allowed to call this function");

        require(amount <= ocashToken.balanceOf(address(this)), "Amount is exceeded");
        ocashToken.transfer(account, amount);
    }
}