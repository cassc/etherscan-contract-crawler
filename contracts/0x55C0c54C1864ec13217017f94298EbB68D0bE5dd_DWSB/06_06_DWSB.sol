// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract DWSB is ERC20("Doge of Wall Street Bets","DWSB"), Ownable {
    address public LP;
    address public ROUTER;
    address public immutable DEPLOYER;

    uint public MAX_BALANCE_PERCENTAGE = 400; // 4%
    uint public constant DENOMINATOR = 10000;

    mapping(address => bool) public isMEV;

    constructor() {
        _mint(msg.sender, 69_420_000_000 ether);
        DEPLOYER = msg.sender;
    }

    function _transfer(address _from, address _to, uint _amount) internal override {
        require(!isMEV[_from], "Banned MEV bot");

        super._transfer(_from, _to, _amount);

        if (_to != LP && _to != ROUTER && _to != DEPLOYER) {
            uint maxBalance = totalSupply() * MAX_BALANCE_PERCENTAGE / DENOMINATOR;
            require(balanceOf(_to) <= maxBalance, "Receiver balance is too big");
        }
    }

    function init(address lp, address router) external onlyOwner {
        assert(LP == address(0) && ROUTER == address(0));
        LP = lp;
        ROUTER = router;
    }

    function setMaxBalancePercentage(uint maxBalancePercentage) external onlyOwner {
        assert(maxBalancePercentage > 0);
        MAX_BALANCE_PERCENTAGE = maxBalancePercentage;
    }

    function banMEV(address[] calldata bans) external onlyOwner {
        for(uint i; i<bans.length;){
            isMEV[bans[i]] = true;
            unchecked {
                ++i;
            }
        }
    }
    
    function unbanMEV(address[] calldata bans) external onlyOwner {
        for(uint i; i<bans.length;){
            isMEV[bans[i]] = false;
            unchecked {
                ++i;
            }
        }
    }
}