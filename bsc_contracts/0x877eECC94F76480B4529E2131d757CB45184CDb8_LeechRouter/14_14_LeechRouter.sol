// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/ILeechTransporter.sol";
import "./interfaces/ILeechSwapper.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

interface ILeechStrategy {
    function deposit() external;

    function withdraw(uint256 amount) external returns (uint256);
}

contract LeechRouter is AccessControl {
    using SafeERC20 for IERC20;

    ///@dev Struct for the strategy instance
    struct Strategy {
        uint256 id;
        uint256 poolId;
        uint256 chainId;
        address strategyAddress;
        bool isLp;
    }

    ///@dev Struct for the Vault instance
    struct Pool {
        uint256 id;
        string name;
    }

    ///@dev Struct for the Router instance
    struct Router {
        uint256 id;
        uint256 chainId;
        address routerAddress;
    }

    ILeechTransporter public transporter;
    ILeechSwapper public swapper;

    IERC20 public immutable baseToken;

    uint256 public immutable chainId;

    bytes32 public constant SERVER_ROLE = keccak256("SERVER_ROLE");
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant UNPAUSER_ROLE = keccak256("UNPAUSER_ROLE");

    bool public paused;

    mapping(address => bool) private _banned;

    mapping(uint256 => Strategy) public poolIdtoActiveStrategy;
    mapping(uint256 => Router) public chainIdToRouter;

    modifier enabled(address user) {
        if (paused) revert("Paused");
        if (_banned[user]) revert("Banned");
        _;
    }

    event BaseBridged(
        uint256 amount,
        uint256 poolId,
        uint256 activeStratChainId,
        uint256 activeStratId,
        uint256 FromChainId
    );
    event Deposited(address user, uint256 poolId, uint256 baseAmount);
    event PlacedToFarm(
        uint256 amount,
        uint256 poolId,
        uint256 activeStratid,
        uint256 chainId
    );
    event WithdrawalRequested(
        uint256 poolId,
        uint256 amount,
        uint256 chainId,
        address tokenOut,
        address user
    );
    event WithdrawCompleted(
        uint256 poolId,
        uint256 targetChainId,
        address user,
        uint256 baseAmountWithdrew
    );
    event CrosschainWithdrawCompleted(
        uint256 poolId,
        uint256 targetChainId,
        address user,
        uint256 baseAmountWithdrew
    );

    constructor(address _baseToken) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(SERVER_ROLE, msg.sender);

        baseToken = IERC20(_baseToken);

        uint256 _chainId;
        assembly {
            _chainId := chainid()
        }
        chainId = _chainId;
    }

    function deposit(
        uint16 poolId,
        IERC20 depositToken,
        uint256 amount,
        address[] calldata pathToBase
    ) external enabled(msg.sender) {
        //Init state
        uint256 balanceBefore = baseToken.balanceOf(address(this));
        uint256 receivedAmount = amount;

        //Need custom revert for safeERC20
        if (
            depositToken.balanceOf(msg.sender) < amount ||
            depositToken.allowance(msg.sender, address(this)) < amount
        ) revert("Wrong balance or allowance");

        //Take token from user
        depositToken.safeTransferFrom(msg.sender, address(this), amount);

        //swap to base if needed
        if (address(depositToken) != address(baseToken)) {
            _approveIfNeeded(depositToken, address(swapper));
            uint256[] memory swapedAmounts = swapper.swap(amount, pathToBase);

            receivedAmount = swapedAmounts[swapedAmounts.length - 1];
        }

        uint256 balanceAfter = baseToken.balanceOf(address(this));

        //additional check for received base amount
        if (balanceAfter - balanceBefore != receivedAmount)
            revert("Amounts missmatch");
        emit Deposited(msg.sender, poolId, receivedAmount);

        //init strategy struct
        Strategy storage activeStrat = poolIdtoActiveStrategy[poolId];

        if (chainId == activeStrat.chainId) {
            // if current chain active, deposit to strategy
            baseToken.safeTransfer(activeStrat.strategyAddress, receivedAmount);
            ILeechStrategy(activeStrat.strategyAddress).deposit();

            emit PlacedToFarm(receivedAmount, poolId, activeStrat.id, chainId);
            return;
        } else {
            Router memory router = chainIdToRouter[activeStrat.chainId];
            transporter.sendTo(
                activeStrat.chainId,
                router.routerAddress,
                receivedAmount
            );

            emit BaseBridged(
                receivedAmount,
                poolId,
                activeStrat.chainId,
                activeStrat.id,
                chainId
            );
            return;
        }
    }

    //amount in base token
    function withdraw(
        uint16 poolId,
        address tokenOut,
        uint256 amount
    ) external enabled(msg.sender) {
        //share tokens are located in the DB

        emit WithdrawalRequested(poolId, amount, chainId, tokenOut, msg.sender);
    }

    //After bridging completed we need to place tokens to farm
    function placeToFarm(
        uint256 amount,
        uint256 poolId
    ) external onlyRole(SERVER_ROLE) {
        Strategy storage activeStrat = poolIdtoActiveStrategy[poolId];
        baseToken.safeTransfer(activeStrat.strategyAddress, amount);
        ILeechStrategy(activeStrat.strategyAddress).deposit();

        emit PlacedToFarm(amount, poolId, activeStrat.id, chainId);
    }

    //BE calls after WithdrawalRequested event was catched
    //Should be called on chain with active strategy
    //amount - amount in want token on strategy: LP or single token
    //path path from base token to tokeOut
    function initWithdrawal(
        uint256 poolId,
        uint256 amount,
        address user,
        address[] calldata baseToTokenOut,
        uint256 targetChainId
    ) external onlyRole(SERVER_ROLE) {
        //Take strat instance by pool id
        Strategy storage activeStrat = poolIdtoActiveStrategy[poolId];

        //Withdraw base token from strategy and receive uint256 amount of received baseToken
        uint256 baseAmountWithdrew = ILeechStrategy(activeStrat.strategyAddress)
            .withdraw(amount);
        uint256 amountOut;
        IERC20 tokeOut = IERC20(baseToTokenOut[baseToTokenOut.length - 1]);

        //swap to requested tokenOut if needed
        if (baseToTokenOut.length > 1) {
            _approveIfNeeded(baseToken, address(swapper));
            uint256[] memory swapedAmounts = swapper.swap(
                baseAmountWithdrew,
                baseToTokenOut
            );

            amountOut = swapedAmounts[swapedAmounts.length - 1];
        } else {
            amountOut = baseAmountWithdrew;
        }

        //sending tokens to user directly or via bridge
        if (targetChainId == chainId) {
            //if requested on current chain, send tokens
            tokeOut.safeTransfer(user, amountOut);
            emit WithdrawCompleted(
                poolId,
                targetChainId,
                user,
                baseAmountWithdrew
            );
            return;
        } else {
            //if requested on another chain, use bridge
            _approveIfNeeded(tokeOut, address(swapper));
            transporter.bridgeOut(
                address(tokeOut),
                amountOut,
                targetChainId,
                user
            );
            emit CrosschainWithdrawCompleted(
                poolId,
                targetChainId,
                user,
                baseAmountWithdrew
            );
            return;
        }
    }

    function isBanned(address user) external view returns (bool) {
        return _banned[user];
    }

    function addStrategy(
        uint256 poolId,
        Strategy calldata _strategy
    ) external onlyRole(ADMIN_ROLE) {
        poolIdtoActiveStrategy[poolId] = _strategy;
    }

    function addRouter(
        uint256 _chainId,
        Router calldata _router
    ) external onlyRole(ADMIN_ROLE) {
        chainIdToRouter[_chainId] = _router;
    }

    function setRouterOrTransporter(
        address _swapper,
        address _transporter
    ) external onlyRole(ADMIN_ROLE) {
        if (_swapper != address(0)) {
            swapper = ILeechSwapper(_swapper);
        }

        if (_transporter != address(0)) {
            transporter = ILeechTransporter(_transporter);
        }
    }

    function _approveIfNeeded(IERC20 token, address to) private {
        if (token.allowance(address(this), to) == 0) {
            token.safeApprove(address(swapper), type(uint256).max);
        }
    }
}