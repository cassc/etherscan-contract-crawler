// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

interface IUniV2Router {
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
}

interface IYieldManager {
    function setAffiliate(address client, address sponsor) external;
    function getUserFactors(
        address user,
        uint typer
    ) external view returns (uint, uint, uint, uint);

    function getAffiliate(address client) external view returns (address);
}

contract UniV2LPETHImplementation is ReentrancyGuard {
    event Staked(address indexed staker, uint amountA, uint amountB);
    event Unstaked(address indexed spender, uint amountA, uint amountB);
    event NewOwner(address indexed owner);
    event SponsorFee(address indexed sponsor, uint amount);
    event MgmtFee(address indexed factory, uint amount);
    event ERC20Recovered(address indexed owner, uint amount);

    event LPStake(uint amount);
    event LPWithdraw(uint amount);
    event LPReStake();
    event LPGetRewards();

    using SafeERC20 for IERC20;
    address public owner;
    IUniV2LPFactory public factoryAddress;

    // only owner modifier
    modifier onlyOwner {
        _onlyOwner();
        _;
    }

    // only owner view
    function _onlyOwner() private view {
        require(msg.sender == owner || msg.sender == address(factoryAddress), "Only the contract owner may perform this action");
    }

    constructor() {
        // Don't allow implementation to be initialized.
        owner = address(1);
    }

    function initialize(
        address owner_,
        address factoryAddress_
    ) external
    {
        require(owner == address(0), "already initialized");
        require(factoryAddress_ != address(0), "factory can not be null");
        require(owner_ != address(0), "owner cannot be null");

        owner = owner_;
        factoryAddress = IUniV2LPFactory(factoryAddress_);

        emit NewOwner(owner);
    }

    // we need approval token a and b before doing it
    function addLiquidityETH(
        uint amountTokenDesired,
        uint deadline,
        uint slippagePercent
    )
    external payable nonReentrant {
        require(amountTokenDesired > 0, "Cannot stake 0 token");
        require(msg.value > 0, "Cannot stake 0 eth");

        address stakingTokenA = IUniV2LPFactory(factoryAddress).getStakingTokenA();

        IERC20(stakingTokenA).safeTransferFrom(
            msg.sender,
            address(this),
            amountTokenDesired
        );

        IERC20(stakingTokenA).safeApprove(IUniV2LPFactory(factoryAddress).getStakingContract(), 0);
        IERC20(stakingTokenA).safeApprove(IUniV2LPFactory(factoryAddress).getStakingContract(), amountTokenDesired);

        uint tokenMin = amountTokenDesired - (amountTokenDesired * slippagePercent / 10000);
        uint ethMin = msg.value - (msg.value * slippagePercent / 10000);

        (uint amountToken, uint amountETH,) = IUniV2Router(IUniV2LPFactory(factoryAddress).getStakingContract()).addLiquidityETH{ value: msg.value}(
                stakingTokenA,
                amountTokenDesired,
                tokenMin,
                ethMin,
                address(this),
                deadline
        );

        // if leftover send back
        if (IERC20(stakingTokenA).balanceOf(address(this)) > 0) {
            IERC20(stakingTokenA).safeTransfer(owner, IERC20(stakingTokenA).balanceOf(address(this)));
        }
        if (address(this).balance > 0) {
            payable(address(owner)).transfer(address(this).balance);
        }

        emit Staked(owner, amountToken, amountETH);
    }

    function removeLiquidityETH(
        uint liquidity,
        uint deadline,
        uint tokenAMin,
        uint tokenBMin
    ) external onlyOwner nonReentrant {
        require(liquidity > 0, "Cannot withdraw 0");

        IERC20(IUniV2LPFactory(factoryAddress).getLPToken()).safeIncreaseAllowance(IUniV2LPFactory(factoryAddress).getStakingContract(), 0);
        IERC20(IUniV2LPFactory(factoryAddress).getLPToken()).safeIncreaseAllowance(IUniV2LPFactory(factoryAddress).getStakingContract(), liquidity);

        // get user stats
        (,,,uint val4) = IYieldManager(factoryAddress.getYieldManager()).getUserFactors(
            owner,
            0
        );

        uint mgmtFee = (val4 * liquidity) / 100 / 100;
        uint sponsorFee;

        // get sponsor
        address sponsor = IYieldManager(factoryAddress.getYieldManager()).getAffiliate(owner);
        // get sponsor stats
        if (sponsor != address(0)) {
            (,uint sval2,, ) = IYieldManager(factoryAddress.getYieldManager())
            .getUserFactors(sponsor, 1);
            sponsorFee = (mgmtFee * sval2) / 100 / 100;
            mgmtFee -= sponsorFee;
        }

        liquidity = liquidity - mgmtFee - sponsorFee;
        (uint amountA, uint amountETH) = IUniV2Router(IUniV2LPFactory(factoryAddress).getStakingContract()).removeLiquidityETH(
            IUniV2LPFactory(factoryAddress).getStakingTokenA(),
            liquidity,
            tokenAMin,
            tokenBMin,
            address(this),
            deadline
        );

        // send tokens to client
        IERC20(IUniV2LPFactory(factoryAddress).getStakingTokenA()).safeTransfer(
            owner,
            IERC20(IUniV2LPFactory(factoryAddress).getStakingTokenA()).balanceOf(address(this))
        );
        payable(address(owner)).transfer(address(this).balance);

        // send sponsor and mgmt fee
        if (sponsor != address(0) && sponsorFee != 0) {
            IERC20(IUniV2LPFactory(factoryAddress).getLPToken()).safeTransfer(sponsor, sponsorFee);
            emit SponsorFee(sponsor, sponsorFee);
        }

        if (mgmtFee != 0) {
            IERC20(IUniV2LPFactory(factoryAddress).getLPToken()).safeTransfer(address(factoryAddress), mgmtFee);
            emit MgmtFee(address(factoryAddress), mgmtFee);
        }
        emit Unstaked(owner, amountA, amountETH);
    }

    function recoverERC20(address token, uint amount) public onlyOwner {
        require(factoryAddress.getRecoverOpen(), "recover not open");
        IERC20(token).safeTransfer(owner, amount);
        emit ERC20Recovered(owner, amount);
    }

    function stake(uint amount) public onlyOwner {
        IERC20(IUniV2LPFactory(factoryAddress).getLPToken()).safeIncreaseAllowance(IUniV2LPFactory(factoryAddress).getRewardStakingContract(), 0);
        IERC20(IUniV2LPFactory(factoryAddress).getLPToken()).safeIncreaseAllowance(IUniV2LPFactory(factoryAddress).getRewardStakingContract(), amount);
        ILockedStakingrewards(IUniV2LPFactory(factoryAddress).getRewardStakingContract()).stake(amount);
        emit LPStake(amount);
    }

    function withdraw(uint amount) public onlyOwner {
        ILockedStakingrewards(IUniV2LPFactory(factoryAddress).getRewardStakingContract()).withdraw(amount);
        emit LPWithdraw(amount);
    }

    function reStake() public onlyOwner {
        ILockedStakingrewards(IUniV2LPFactory(factoryAddress).getRewardStakingContract()).reStake();
        emit LPReStake();
    }

    function getReward() public onlyOwner {
        ILockedStakingrewards(IUniV2LPFactory(factoryAddress).getRewardStakingContract()).getReward();
        IERC20(IUniV2LPFactory(factoryAddress).getRewardStakingToken()).safeTransfer(owner, IERC20(IUniV2LPFactory(factoryAddress).getRewardStakingToken()).balanceOf(address(this)));
        emit LPGetRewards();
    }

    /**
     * receive function to receive funds
    */
    receive() external payable {}
}

interface IUniV2LPFactory {
    function getYieldManager() external view returns(address);
    function getLPToken() external view returns (address);
    function getStakingTokenA() external view returns (address);
    function getStakingContract() external view returns (address);
    function getRewardStakingContract()  external view returns (address);
    function getRewardStakingToken() external view returns (address);
    function getRecoverOpen() external view returns (bool);
}

interface ILockedStakingrewards {
    function getReward() external;
    function withdraw(uint256 amount) external;
    function stake(uint256 amount) external;
    function reStake() external;
}