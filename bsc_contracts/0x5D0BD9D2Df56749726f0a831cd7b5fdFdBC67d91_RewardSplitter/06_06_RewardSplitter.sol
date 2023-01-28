pragma solidity 0.5.16;

import "../openzeppelin/IERC20.sol";
import "../openzeppelin/SafeMath.sol";
import "../openzeppelin/Address.sol";
import "../openzeppelin//SafeERC20.sol";
import "../openzeppelin//SafeMath.sol";
import "../interfaces/IPoolEscrow.sol";

contract RewardSplitter {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    address public token;
    address public governance;
    address[] public pools;

    modifier onlyGov() {
        require(msg.sender == governance, "only gov");
        _;
    }

    constructor(address _token) public {
        token = _token;
        governance = msg.sender;
    }

    function addPools(address[] memory _pools) public onlyGov {
        for (uint256 i = 0; i < _pools.length; i++) {
            pools.push(_pools[i]);
        }
    }

    function removePoolByIndex(uint256 index) public onlyGov returns (address) {
        require(index < pools.length);
        for (uint i = index; i < pools.length - 1; i++) {
            pools[i] = pools[i + 1];
        }
        address removedPool = pools[pools.length - 1];
        pools.pop();
        return removedPool;
    }

    function approve(
        address _token,
        address to,
        uint256 amount
    ) public onlyGov {
        IERC20(_token).safeApprove(to, 0);
        IERC20(_token).safeApprove(to, amount);
    }

    function transfer(
        address _token,
        address to,
        uint256 amount
    ) public onlyGov {
        IERC20(_token).safeTransfer(to, amount);
    }

    // This exists to mirror the interaction of how the perpetual staking pool would
    function notifySecondaryTokens(uint256 amount) external {
        IERC20(token).transferFrom(msg.sender, address(this), amount);
        for (uint i = 0; i < pools.length; i++) {
            uint256 rewardBudget = amount.div(pools.length);
            IERC20(token).safeApprove(pools[i], 0);
            IERC20(token).safeApprove(pools[i], rewardBudget);
            IPoolEscrow(pools[i]).notifySecondaryTokens(rewardBudget);
        }
    }

    function recoverTokens(
        address _token,
        address benefactor
    ) public onlyGov {
        uint256 tokenBalance = IERC20(_token).balanceOf(address(this));
        IERC20(_token).transfer(benefactor, tokenBalance);
    }

    function setGovernance(address account) external onlyGov {
        governance = account;
    }
}