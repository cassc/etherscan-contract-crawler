// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

interface IAaveLending {
    function deposit(
        address asset,
        uint256 amount,
        address onBehalfOf,
        uint16 referralCode
    ) external;
    function withdraw(
        address asset,
        uint256 amount,
        address to
    ) external returns (uint256);
}

interface IYieldManager {
    function setAffiliate(address client, address sponsor) external;
    function getUserFactors(
        address user,
        uint typer
    ) external view returns (uint, uint, uint, uint);

    function getAffiliate(address client) external view returns (address);
}

interface IAaveProtocolDataProvider {
    function getUserReserveData(address asset, address user)
    external
    view
    returns (
        uint256 currentATokenBalance,
        uint256 currentStableDebt,
        uint256 currentVariableDebt,
        uint256 principalStableDebt,
        uint256 scaledVariableDebt,
        uint256 stableBorrowRate,
        uint256 liquidityRate,
        uint40 stableRateLastUpdated,
        bool usageAsCollateralEnabled
    );
}

contract AaveLendingImplementation is ReentrancyGuard {
    event Staked(address indexed staker, uint amount);
    event Unstaked(address indexed spender, uint amount);
    event NewOwner(address indexed owner);
    event SponsorFee(address indexed sponsor, uint amount);
    event MgmtFee(address indexed factory, uint amount);
    event PerformanceFee(address indexed factory, uint amount);
    event SponsorPerformanceFee(address indexed sponsor, uint amount);
    event ERC20Recovered(address indexed owner, uint amount);

    using SafeERC20 for IERC20;
    address public owner;
    IAaveStakingFactory public factoryAddress;
    uint public stakedAmount;

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
        factoryAddress = IAaveStakingFactory(factoryAddress_);

        emit NewOwner(owner);
    }

    // only stake function needed
    function deposit(
        uint256 amount
    )
    external onlyOwner nonReentrant {
        require(amount > 0, "Cannot stake 0 token");
        stakedAmount += amount;

        IERC20(IAaveStakingFactory(factoryAddress).getStakingToken()).safeTransferFrom(
            owner,
            address(this),
            amount
        );

        IERC20(IAaveStakingFactory(factoryAddress).getStakingToken()).safeApprove(IAaveStakingFactory(factoryAddress).getStakingContract(), amount);

        IAaveLending(IAaveStakingFactory(factoryAddress).getStakingContract()).deposit(IAaveStakingFactory(factoryAddress).getStakingToken(), amount, address(this), 0);
        emit Staked(owner, amount);
    }

    function withdraw() external onlyOwner nonReentrant {

        (uint256 currentATokenBalance,,,,,,,,) = IAaveProtocolDataProvider(IAaveStakingFactory(factoryAddress).getLendingViews()).getUserReserveData(IAaveStakingFactory(factoryAddress).getStakingToken(), address(this));
        uint rewardAmount = currentATokenBalance - stakedAmount;

        // get user stats
        (,uint val2, uint val3,) = IYieldManager(factoryAddress.getYieldManager()).getUserFactors(
            msg.sender,
            0
        );

        uint mgmtFee = (val3 * stakedAmount) / 100 / 100;
        uint sponsorFee;
        uint perfFee = (val2 * rewardAmount) / 100 / 100;
        uint sPerfFee;

        stakedAmount = 0;

        // get sponsor
        address sponsor = IYieldManager(factoryAddress.getYieldManager()).getAffiliate(owner);
        // get sponsor stats
        if (sponsor != address(0)) {
            (uint sval1, uint sval2,, ) = IYieldManager(factoryAddress.getYieldManager())
            .getUserFactors(sponsor, 1);
            sponsorFee = (mgmtFee * sval2) / 100 / 100;
            mgmtFee -= sponsorFee;

            sPerfFee = (perfFee * sval1)  / 100 / 100;
            perfFee -= sPerfFee;
        }

        uint totalFees = mgmtFee + sponsorFee + perfFee + sPerfFee;

        //withdraw
        IAaveLending(IAaveStakingFactory(factoryAddress).getStakingContract()).withdraw(IAaveStakingFactory(factoryAddress).getStakingToken(), currentATokenBalance, address(this));

        // send tokens
        IERC20(IAaveStakingFactory(factoryAddress).getStakingToken()).safeTransfer(
            owner,
            currentATokenBalance - totalFees
        );

        if (sponsor != address(0) && sponsorFee != 0) {
            IERC20(IAaveStakingFactory(factoryAddress).getStakingToken()).safeTransfer(sponsor, sponsorFee);
            emit SponsorFee(sponsor, sponsorFee);
        }

        if (mgmtFee != 0) {
            IERC20(IAaveStakingFactory(factoryAddress).getStakingToken()).safeTransfer(address(factoryAddress), mgmtFee);
            emit MgmtFee(address(factoryAddress), mgmtFee);
        }

        if (perfFee != 0) {
            IERC20(IAaveStakingFactory(factoryAddress).getRewardToken()).safeTransfer(address(factoryAddress), perfFee);
            emit PerformanceFee(address(factoryAddress), perfFee);
        }

        if (sponsor != address(0) && sPerfFee != 0) {
            IERC20(IAaveStakingFactory(factoryAddress).getRewardToken()).safeTransfer(sponsor, sPerfFee);
            emit SponsorPerformanceFee(sponsor, sPerfFee);
        }

        emit Unstaked(owner, currentATokenBalance);
    }

    function recoverERC20(address token, uint amount) public onlyOwner {
        require(factoryAddress.getRecoverOpen(), "recover not open");
        IERC20(token).safeTransfer(owner, amount);
        emit ERC20Recovered(owner, amount);
    }
}

interface IAaveStakingFactory {
    function getYieldManager() external view returns(address);
    function getRewardToken() external view returns (address);
    function getStakingToken() external view returns (address);
    function getStakingContract() external view returns (address);
    function getLendingViews() external view returns (address);
    function getRecoverOpen() external view returns (bool);
}