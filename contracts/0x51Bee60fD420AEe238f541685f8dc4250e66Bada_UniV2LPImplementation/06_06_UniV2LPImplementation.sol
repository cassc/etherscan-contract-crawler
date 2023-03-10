// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

interface IUniV2Router {
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
}

interface IYieldManager {
    function setAffiliate(address client, address sponsor) external;
    function getUserFactors(
        address user,
        uint typer
    ) external view returns (uint, uint, uint, uint);

    function getAffiliate(address client) external view returns (address);
}

contract UniV2LPImplementation is ReentrancyGuard {
    event Staked(address indexed staker, uint amountA, uint amountB);
    event Unstaked(address indexed spender, uint amountA, uint amountB);
    event NewOwner(address indexed owner);
    event SponsorFee(address indexed sponsor, uint amount);
    event MgmtFee(address indexed factory, uint amount);
    event ERC20Recovered(address indexed owner, uint amount);

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
    function addLiquidity(
        uint amountADesired,
        uint amountBDesired,
        uint deadline
    )
    external onlyOwner nonReentrant {
        require(amountADesired > 0, "Cannot stake 0 token");
        require(amountBDesired > 0, "Cannot stake 0 token");

        IERC20(IUniV2LPFactory(factoryAddress).getStakingTokenA()).safeTransferFrom(
            owner,
            address(this),
            amountADesired
        );

        IERC20(IUniV2LPFactory(factoryAddress).getStakingTokenB()).safeTransferFrom(
            owner,
            address(this),
            amountBDesired
        );

        IERC20(IUniV2LPFactory(factoryAddress).getStakingTokenA()).approve(IUniV2LPFactory(factoryAddress).getStakingContract(), amountADesired);
        IERC20(IUniV2LPFactory(factoryAddress).getStakingTokenB()).approve(IUniV2LPFactory(factoryAddress).getStakingContract(), amountBDesired);

        IUniV2Router(IUniV2LPFactory(factoryAddress).getStakingContract()).addLiquidity(
                IUniV2LPFactory(factoryAddress).getStakingTokenA(),
                IUniV2LPFactory(factoryAddress).getStakingTokenB(),
                amountADesired,
                amountBDesired,
                0,
                0,
                address(this),
                deadline
        );

        emit Staked(owner, amountADesired, amountBDesired);
    }

    function removeLiquidity(
        uint liquidity,
        uint deadline
    ) external onlyOwner nonReentrant {
        require(liquidity > 0, "Cannot withdraw 0");

        IERC20(IUniV2LPFactory(factoryAddress).getLPToken()).approve(IUniV2LPFactory(factoryAddress).getStakingContract(), liquidity);

        // get user stats
        (,,, uint val4) = IYieldManager(factoryAddress.getYieldManager()).getUserFactors(
            msg.sender,
            0
        );

        uint mgmtFee = (val4 * liquidity) / 100 / 100;
        uint sponsorFee;

        // get sponsor
        address sponsor = IYieldManager(factoryAddress.getYieldManager()).getAffiliate(owner);
        // get sponsor stats
        if (sponsor == address(0)) {
            (,uint sval2,, ) = IYieldManager(factoryAddress.getYieldManager())
            .getUserFactors(sponsor, 1);
            sponsorFee = (mgmtFee * sval2) / 100 / 100;
            mgmtFee -= sponsorFee;
        }

        liquidity = liquidity - mgmtFee - sponsorFee;
        (uint amountA, uint amountB) = IUniV2Router(IUniV2LPFactory(factoryAddress).getStakingContract()).removeLiquidity(
            IUniV2LPFactory(factoryAddress).getStakingTokenA(),
            IUniV2LPFactory(factoryAddress).getStakingTokenB(),
            liquidity,
            0,
            0,
            address(this),
            deadline
        );

        // send tokens to client
        IERC20(IUniV2LPFactory(factoryAddress).getStakingTokenA()).transfer(
            owner,
            IERC20(IUniV2LPFactory(factoryAddress).getStakingTokenA()).balanceOf(address(this))
        );
        IERC20(IUniV2LPFactory(factoryAddress).getStakingTokenB()).transfer(
            owner,
            IERC20(IUniV2LPFactory(factoryAddress).getStakingTokenB()).balanceOf(address(this))
        );

        // send sponsor and mgmt fee
        if (sponsor != address(0) && sponsorFee != 0) {
            IERC20(IUniV2LPFactory(factoryAddress).getLPToken()).transfer(sponsor, sponsorFee);
            emit SponsorFee(sponsor, sponsorFee);
        }

        if (mgmtFee != 0) {
            IERC20(IUniV2LPFactory(factoryAddress).getLPToken()).transfer(address(factoryAddress), mgmtFee);
            emit MgmtFee(address(factoryAddress), mgmtFee);
        }

        emit Unstaked(owner, amountA, amountB);
    }

    function recoverERC20(address token, uint amount) public onlyOwner {
        IERC20(token).transfer(owner, amount);
        emit ERC20Recovered(owner, amount);
    }
}

interface IUniV2LPFactory {
    function getYieldManager() external view returns(address);
    function getLPToken() external view returns (address);
    function getStakingTokenA() external view returns (address);
    function getStakingTokenB() external view returns (address);
    function getStakingContract() external view returns (address);
}