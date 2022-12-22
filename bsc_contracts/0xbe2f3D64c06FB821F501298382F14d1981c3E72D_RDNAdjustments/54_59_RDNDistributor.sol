// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IRDNRegistry} from "./RDNRegistry.sol";
import {IRDNFactors} from "./RDNFactors.sol";
import {WithdrawAnyERC20Token} from "../Utils/WithdrawAnyERC20Token.sol";

interface IRDNDistributor {
    
    function distribute(address _initAddress, uint _amount) external;

    function getToken() external view returns(address);
}

contract RDNDistributor is AccessControlEnumerable, WithdrawAnyERC20Token {

    IERC20 public immutable token;
    IRDNRegistry public immutable registry;

    event Distributed(uint indexed userId, address indexed userAddress, address indexed tokenAddress, uint initUserId, address initAddress, uint amount);

    constructor(address _token, address _registry, address _admin) WithdrawAnyERC20Token(_admin, true) {
        token = IERC20(_token);
        registry = IRDNRegistry(_registry);
    }

    // todo: refactor getting user before while to getUserByAddress
    // todo: user.parentId > 1. Root not to recieve distrs
    function distribute(address _initAddress, uint _amount) public {
        token.transferFrom(msg.sender, address(this), _amount);
        uint userId = registry.getUserIdByAddress(_initAddress);
        uint initUserId = userId;
        IRDNFactors factors = IRDNFactors(registry.factorsAddress());
        uint8 count;
        uint factor;
        uint maxFactor;
        uint bonus;
        uint amountRemained = _amount;
        IRDNRegistry.User memory user = registry.getUser(userId);
        while (user.parentId > 0 && count < 12) {
            count += 1;
            userId = user.parentId;
            user = registry.getUser(userId);
            factor = factors.getFactor(user.level, user.tariff, userId);
            if (factor > maxFactor) {
                bonus = (_amount * (factor - maxFactor))/ (10 ** factors.getDecimals());
                maxFactor = factor;
                amountRemained -= bonus;
                if (user.activeUntill > block.timestamp) {
                    token.transfer(user.userAddress, bonus);
                    emit Distributed(userId, user.userAddress, address(token), initUserId, _initAddress, bonus);
                }
            }
        }
    }

    function getToken() public view returns(address) {
        return address(token);
    }
    
}