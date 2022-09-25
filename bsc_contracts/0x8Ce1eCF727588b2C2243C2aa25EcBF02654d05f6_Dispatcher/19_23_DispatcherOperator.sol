//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import '../interface/IDispatcher.sol';
/**
 * Distribute funds to strategic contracts
 *
 */
contract DispatcherOperator is Ownable, ReentrancyGuard, IDispatcher {

    event Dispatch(address strategy, uint256 token0Amount, uint256 token1Amount);
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    address public dispatcher;

    constructor(address _dispatcher) {
        dispatcher = _dispatcher;
    }

    function setDispatcher(address _dispatcher) external onlyOwner{
        require(_dispatcher != address(0), "ChainBridgeOperator: ZERO_ADDRESS");
        dispatcher = _dispatcher;
    }

    /**
     * Transfer the funds from the deposit contract to Dispatcher
     */
    function treasuryWithdraw(address _from) external override onlyOwner {
        IDispatcher(dispatcher).treasuryWithdraw(_from);
    }

    /**
    * Transfer the funds from the deposit contract to Dispatcher
    */
    function treasuryWithdrawAndDispatch(address _from) external override onlyOwner {
        IDispatcher(dispatcher).treasuryWithdrawAndDispatch(_from);
    }

    function receiverWithdraw(uint256 pid, uint256 leaveAmount) external override onlyOwner {
        IDispatcher(dispatcher).receiverWithdraw(pid, leaveAmount);
    }

    function receiverHarvest(uint256 pid) external override onlyOwner {
        IDispatcher(dispatcher).receiverHarvest(pid);
    }

    function chainBridgeToWithdrawalAccount(uint256 pid, address token, address withdrawalAccount) external override onlyOwner {
        IDispatcher(dispatcher).chainBridgeToWithdrawalAccount(pid, token, withdrawalAccount);
    }

}