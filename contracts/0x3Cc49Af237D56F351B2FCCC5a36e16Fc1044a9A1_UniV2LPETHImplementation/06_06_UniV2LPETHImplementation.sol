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
        uint deadline
    )
    external payable onlyOwner nonReentrant {
        require(amountTokenDesired > 0, "Cannot stake 0 token");
        require(msg.value > 0, "Cannot stake 0 eth");

        IERC20(IUniV2LPFactory(factoryAddress).getStakingTokenA()).safeTransferFrom(
            owner,
            address(this),
            amountTokenDesired
        );

        IERC20(IUniV2LPFactory(factoryAddress).getStakingTokenA()).approve(IUniV2LPFactory(factoryAddress).getStakingContract(), amountTokenDesired);

        IUniV2Router(IUniV2LPFactory(factoryAddress).getStakingContract()).addLiquidityETH{ value: msg.value}(
                IUniV2LPFactory(factoryAddress).getStakingTokenA(),
                amountTokenDesired,
                0,
                0,
                address(this),
                deadline
        );

        emit Staked(owner, amountTokenDesired, msg.value);
    }

    function removeLiquidityETH(
        uint liquidity,
        uint deadline
    ) external onlyOwner nonReentrant {
        require(liquidity > 0, "Cannot withdraw 0");

        IERC20(IUniV2LPFactory(factoryAddress).getLPToken()).approve(IUniV2LPFactory(factoryAddress).getStakingContract(), liquidity);

        // get user stats
        (,,,uint val4) = IYieldManager(factoryAddress.getYieldManager()).getUserFactors(
            msg.sender,
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
        payable(address(owner)).transfer(address(this).balance);

        // send sponsor and mgmt fee
        if (sponsor != address(0) && sponsorFee != 0) {
            IERC20(IUniV2LPFactory(factoryAddress).getLPToken()).transfer(sponsor, sponsorFee);
            emit SponsorFee(sponsor, sponsorFee);
        }

        if (mgmtFee != 0) {
            IERC20(IUniV2LPFactory(factoryAddress).getLPToken()).transfer(address(factoryAddress), mgmtFee);
            emit MgmtFee(address(factoryAddress), mgmtFee);
        }
        emit Unstaked(owner, amountA, amountETH);
    }

    function recoverERC20(address token, uint amount) public onlyOwner {
        IERC20(token).transfer(owner, amount);
        emit ERC20Recovered(owner, amount);
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
}