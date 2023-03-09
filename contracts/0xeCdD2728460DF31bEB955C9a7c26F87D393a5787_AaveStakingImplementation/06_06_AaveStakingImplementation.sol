// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

interface IAaveStaking {
    function stake(address onBehalfOf, uint256 amount) external;
    function claimRewards(address to, uint256 amount) external;
    function redeem(address to, uint256 amount) external;
    function cooldown() external;
}

interface IYieldManager {
    function setAffiliate(address client, address sponsor) external;
    function getUserFactors(
        address user,
        uint typer
    ) external view returns (uint, uint, uint, uint);

    function getAffiliate(address client) external view returns (address);
}

contract AaveStakingImplementation is ReentrancyGuard {
    event Staked(address indexed staker, uint amount);
    event Unstaked(address indexed spender, uint amount);
    event ClaimRewards(address indexed spender, uint amount);
    event Deposited(address indexed sender, uint amount);
    event NewOwner(address indexed owner);
    event SponsorFee(address indexed sponsor, uint amount);
    event MgmtFee(address indexed factory, uint amount);
    event PerformanceFee(address indexed factory, uint amount);
    event SponsorPerformanceFee(address indexed sponsor, uint amount);
    event CooldownTriggered();
    event ERC20Recovered(address indexed owner, uint amount);

    using SafeERC20 for IERC20;
    address public owner;
    IAaveStakingFactory public factoryAddress;

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
    function stake(uint256 amount) external onlyOwner nonReentrant {
        require(amount > 0, "Cannot stake 0 token");

        IERC20(IAaveStakingFactory(factoryAddress).getStakingToken()).safeTransferFrom(
            owner,
            address(this),
            amount
        );

        IERC20(IAaveStakingFactory(factoryAddress).getStakingToken()).approve(IAaveStakingFactory(factoryAddress).getStakingContract(), amount);

        IAaveStaking(IAaveStakingFactory(factoryAddress).getStakingContract()).stake(address(this), amount);
        emit Staked(owner, amount);
    }

    function redeem(uint amount) external onlyOwner nonReentrant {
        require(amount > 0, "Cannot withdraw 0");

        // get user stats
        (, , uint val3,) = IYieldManager(factoryAddress.getYieldManager()).getUserFactors(
            msg.sender,
            0
        );

        uint mgmtFee = (val3 * amount) / 100 / 100;
        uint sponsorFee;

        // get sponsor
        address sponsor = IYieldManager(factoryAddress.getYieldManager()).getAffiliate(owner);
        // get sponsor stats
        if (sponsor != address(0)) {
            (, uint sval2,, ) = IYieldManager(factoryAddress.getYieldManager())
            .getUserFactors(sponsor, 1);
            sponsorFee = (mgmtFee * sval2) / 100 / 100;
            mgmtFee -= sponsorFee;
        }

        IAaveStaking(IAaveStakingFactory(factoryAddress).getStakingContract()).redeem(address(this), amount);

        // send tokens
        IERC20(IAaveStakingFactory(factoryAddress).getStakingToken()).transfer(
            owner,
            amount - mgmtFee - sponsorFee
        );

        if (sponsor != address(0) && sponsorFee != 0) {
            IERC20(IAaveStakingFactory(factoryAddress).getStakingToken()).transfer(sponsor, sponsorFee);
            emit SponsorFee(sponsor, sponsorFee);
        }

        if (mgmtFee != 0) {
            IERC20(IAaveStakingFactory(factoryAddress).getStakingToken()).transfer(address(factoryAddress), mgmtFee);
            emit MgmtFee(address(factoryAddress), mgmtFee);
        }

        emit Unstaked(owner, amount);
    }

    // we need this as a public function callable by everyone
    function claimRewards(uint amount) external onlyOwner {

        (, uint val2,,) = IYieldManager(factoryAddress.getYieldManager()).getUserFactors(
            msg.sender,
            0
        );

        uint perfFee = (val2 * amount) / 100 / 100;
        uint sPerfFee;

        address sponsor = IYieldManager(factoryAddress.getYieldManager()).getAffiliate(owner);

        // get sponsor stats
        if (sponsor != address(0)) {
            (uint sval1,,,) = IYieldManager(factoryAddress.getYieldManager())
            .getUserFactors(sponsor, 1);
            sPerfFee = (perfFee * sval1)  / 100 / 100;
            perfFee -= sPerfFee;
        }

        // get reward
        IAaveStaking(IAaveStakingFactory(factoryAddress).getStakingContract()).claimRewards(address(this), amount);

        // send tokens
        IERC20(IAaveStakingFactory(factoryAddress).getRewardToken()).transfer(owner, amount - perfFee - sPerfFee);

        if (perfFee != 0) {
            IERC20(IAaveStakingFactory(factoryAddress).getRewardToken()).transfer(address(factoryAddress), perfFee);
            emit PerformanceFee(address(factoryAddress), perfFee);
        }

        if (sponsor != address(0) && sPerfFee != 0) {
            IERC20(IAaveStakingFactory(factoryAddress).getRewardToken()).transfer(sponsor, sPerfFee);
            emit SponsorPerformanceFee(sponsor, sPerfFee);
        }

        emit ClaimRewards(owner, amount);
    }

    function cooldown() public onlyOwner {
        IAaveStaking(IAaveStakingFactory(factoryAddress).getStakingContract()).cooldown();
        emit CooldownTriggered();
    }

    function recoverERC20(address token, uint amount) public onlyOwner {
        IERC20(token).transfer(owner, amount);
        emit ERC20Recovered(owner, amount);
    }
}

interface IAaveStakingFactory {
    function getYieldManager() external view returns(address);
    function getRewardToken() external view returns (address);
    function getStakingToken() external view returns (address);
    function getStakingContract() external view returns (address);
}