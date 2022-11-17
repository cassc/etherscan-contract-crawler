// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "./Interfaces.sol";
import "@openzeppelin/contracts-0.8/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-0.8/access/Ownable.sol";
import { SafeERC20 } from "@openzeppelin/contracts-0.8/token/ERC20/utils/SafeERC20.sol";

/**
 * @title   WomDepositor
 * @notice  Deposit WOM in staker contract once in smartLockPeriod.
            Have customLockDays mapping for instant custom deposits with specific days count.
 */
contract WomSwapDepositor is Ownable {
    using SafeERC20 for IERC20;

    address public wom;
    address public wmxWom;
    address public pool;
    address public swapRouter;

    event Deposit(address indexed account, address stakeAddress, uint256 amount);

    /**
     * @param _wom              WOM Token address
     * @param _wmxWom           wmxWom Token address
     * @param _swapRouter       Swap router
     */
    constructor(
        address _wom,
        address _wmxWom,
        address _pool,
        address _swapRouter
    ) public {
        wom = _wom;
        wmxWom = _wmxWom;
        pool = _pool;
        swapRouter = _swapRouter;

        IERC20(wom).safeApprove(swapRouter, type(uint256).max);
    }

    /**
     * @notice  Deposit tokens into the VeWom and mint WmxWom to depositors.
     * @param _amount  Amount WOM to deposit
     * @param _stakeAddress  Staker to deposit WmxWom
     */
    function deposit(uint256 _amount, address _stakeAddress, uint256 _minAmountOut, uint256 _deadline) public returns (bool) {
        require(_deadline >= block.timestamp, "deadline");

        IERC20(wom).safeTransferFrom(msg.sender, address(this), _amount);

        address[] memory tokens = new address[](2);
        tokens[0] = wom;
        tokens[1] = wmxWom;

        address[] memory pools = new address[](1);
        pools[0] = pool;

        uint256 wmxWomAmount = ISwapRouter(swapRouter).swapExactTokensForTokens(tokens, pools, _amount, _minAmountOut, address(this), _deadline);

        //stake for to
        IERC20(wmxWom).safeApprove(_stakeAddress, 0);
        IERC20(wmxWom).safeApprove(_stakeAddress, wmxWomAmount);
        IRewards(_stakeAddress).stakeFor(msg.sender, wmxWomAmount);

        emit Deposit(msg.sender, _stakeAddress, wmxWomAmount);
        return true;
    }

    /**
     * @notice  Rescue all tokens but wom from contract
     * @param _tokens       Tokens addresses
     * @param _recipient    Recipient address
     */
    function rescueTokens(address[] memory _tokens, address _recipient) public onlyOwner {
        for (uint256 i; i < _tokens.length; i++) {
            require(_tokens[i] != wom, "!wom");
            IERC20(_tokens[i]).safeTransfer(_recipient, IERC20(_tokens[i]).balanceOf(address(this)));
        }
    }
}