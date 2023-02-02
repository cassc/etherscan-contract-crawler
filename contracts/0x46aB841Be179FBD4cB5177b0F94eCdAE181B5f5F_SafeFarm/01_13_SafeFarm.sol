//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.7;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./UniswapInterfaces.sol";

/**
 * @dev Implementation of a SafeFarm contract to deposit funds for yield optimizing.
 * This is the contract that receives funds and that users interface with.
 * The yield optimizing strategy itself is implemented in a separate 'Strategy.sol' contract.
 */
contract SafeFarm is ReentrancyGuard, AccessControl {
    using SafeERC20 for IERC20;

    bytes32 public constant ORACLE_ROLE = keccak256("ORACLE_ROLE");

    struct LPToken {
      uint256 amount;
      address token;
    }

    // The strategy currently in use by the vault.
    IStrategy public strategy;
    IVault public vault;

    // Events
    event UpgradeStrat(address newStrategy);

    event Deposit(address indexed account, uint256 shares);
    event Withdraw(address indexed account, uint256 shares);
    event SafeSwap(address indexed account, uint256 shares);
    event Earn(uint256 amount);

    /**
     * @dev Sets the strategy of yield optimizing and initialize the admin account.
     * @param _strategy the address of the strategy.
     */
    constructor (
        address _strategy
    ) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

        strategy = IStrategy(_strategy);

        emit UpgradeStrat(_strategy);
    }

    /**
     * @notice Strict access by admin role
     */
    modifier onlyAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "sender doesn't have admin role");
        _;
    }

    /**
     * @notice Strict access by safe farming oracle role
     */
    modifier onlySFOracle() {
        require(hasRole(ORACLE_ROLE, msg.sender), "sender doesn't have oracle role");
        _;
    }

    /**
     * @notice Removes admin role from {msg.sender} and grants it to {newAdmin}.
     * @notice Only callable by an address that currently has the admin role.
     * @param newAdmin Address that admin role will be granted to.
    */
    function renounceAdmin(address newAdmin) external onlyAdmin {
        grantRole(DEFAULT_ADMIN_ROLE, newAdmin);
        renounceRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /**
     * @notice Grants {oracleAddress} the relayer role and increases {_totalOracles} count.
     * @notice Only callable by an address that currently has the admin role.
     * @param oracleAddress Address of safe farm to be added.
    */
    function adminAddOracle(address oracleAddress) external onlyAdmin {
        require(!hasRole(ORACLE_ROLE, oracleAddress), "addr already has oracle role!");
        grantRole(ORACLE_ROLE, oracleAddress);
    }

    /**
     * @notice Removes oracle role for {oracleAddress} and decreases {_totalOracles} count.
     * @notice Only callable by an address that currently has the admin role.
     * @param oracleAddress Address of safe farm to be removed.
    */
    function adminRemoveOracle(address oracleAddress) external onlyAdmin {
        require(hasRole(ORACLE_ROLE, oracleAddress), "addr doesn't have oracle role!");
        revokeRole(ORACLE_ROLE, oracleAddress);
    }

    /**
     * @notice Initialize vault address.
     * @notice Only callable by an address that currently has the admin role.
     * @param _vault Address of vault contract.
    */
    function initVault(address _vault) external onlyAdmin {
        require(address(vault) == address(0), "vault already inited");
        require(_vault != address(0), "empty vault");

        vault = IVault(_vault);
    }

    /**
     * @dev It switches the active strat for the new strat candidate.
     * @param _newStrategy Address of new strategy contract.
     */
    function upgradeStrat(address _newStrategy) external onlyAdmin {
        require(_newStrategy != address(0), "There is no candidate");
        require(strategy.want() == IStrategy(_newStrategy).want(), "Want Token doesn't same");

        IStrategy prevStrategy = strategy;
        strategy = IStrategy(_newStrategy);

        prevStrategy.retireStrat();

        earn();

        emit UpgradeStrat(_newStrategy);
    }

    /**
     * @dev Rescues random funds stuck that the strat can't handle.
     * @param _token address of the token to rescue.
     */
    function inCaseTokensGetStuck(address _token) external onlyAdmin {
        require(_token != address(want()), "!token");

        uint256 amount = IERC20(_token).balanceOf(address(this));
        IERC20(_token).safeTransfer(msg.sender, amount);
    }


    /**
     * @notice A migration function to the new SafeFarm contract
     * @dev Funds will be moved to new contract.
     * @dev Only callable by vault contract
     * @param newSafeFarm Address of new SafeFarm contract.
    */
    function migrate(address newSafeFarm) external {
        require(msg.sender == address(vault), "!vault");

        uint256 amount = available();
        if (amount > 0) {
            want().safeTransfer(newSafeFarm, amount);
        }

        strategy.migrate(newSafeFarm);
    }



    /**
     * @dev Function for various UIs to display the current value of one of our yield tokens.
     * Returns an uint256 with 18 decimals of how much underlying asset one vault share represents.
     */
    function getPricePerFullShare() external view returns (uint256) {
        uint256 totalSupply = vault.totalSupply();
        return totalSupply == 0 ? 1e18 : (balance() * 1e18 / totalSupply);
    }

    /**
     * @dev A helper function to call deposit() with all the sender's funds.
     */
    function depositAll(uint256 _amountOutMin) external {
        deposit(want().balanceOf(msg.sender), _amountOutMin);
    }

    /**
     * @dev A helper function to call deposit() with all the sender's funds.
     * @param route Swap route
     */
    function depositAll(address[] memory route, uint256 _amountOutMin) external {
        IERC20 tokenA = IERC20(route[0]);
        deposit(tokenA.balanceOf(msg.sender), route, _amountOutMin);
    }


    /**
     * @dev A helper function to call withdraw() with all the sender's funds.
     */
    function withdrawAll() external {
        withdraw(vault.balanceOf(msg.sender));
    }

    /**
     * @dev The entrypoint of safe swap from the system by oracle.
     * @param _account Address of account
     * @param _percent Percent of funds
     * @param _fee Additional fee amount for gas compensation
     * @param _route Swap route
     */
    function safeSwap(
        address _account, uint256 _percent,
        uint256 _fee,
        address[] memory _route
    ) external onlySFOracle {
        uint256 shares = calcShares(_account, _percent);
        uint256 totalShares = vault.totalSupply();
        vault.burn(_account, shares);
        strategy.safeSwap(_account, shares, totalShares, _fee, _route);

        emit SafeSwap(_account, shares);
    }


    /**
     * @dev The entrypoint of safe swap from the system by oracle with multi routes.
     * @param _account Address of account
     * @param _percent Percent of funds
     * @param _fee Additional fee amount for gas compensation
     * @param _route0 Swap route
     * @param _route1 Second swap route
     */
    function safeSwap(
        address _account, uint256 _percent,
        uint256 _fee,
        address[] memory _route0, address[] memory _route1
    ) external onlySFOracle {
        uint256 shares = calcShares(_account, _percent);
        uint256 totalShares = vault.totalSupply();
        vault.burn(_account, shares);
        strategy.safeSwap(_account, shares, totalShares, _fee, _route0, _route1);

        emit SafeSwap(_account, shares);
    }


    /**
     * @dev The entrypoint of funds into the system. People deposit with this function
     * into the vault. The vault is then in charge of sending funds into the strategy.
     * @param _amount Amount of funds
     */
    function deposit(uint256 _amount, uint256 _amountOutMin) public nonReentrant {
        address[] memory route = new address[](1);
        route[0] = strategy.want();
        _deposit(msg.sender, _amount, 0, route, _amountOutMin);
    }

    /**
     * @dev The entrypoint of funds into the system. People deposit with this function
     * into the vault. The vault is then in charge of sending funds into the strategy.
     * @param _amount Amount of funds
     * @param route Swap route
     * @param _amountOutMin Minimum swap amount
     */
    function deposit(uint256 _amount, address[] memory route,
        uint256 _amountOutMin
    ) public nonReentrant {
        _deposit(msg.sender, _amount, 0, route, _amountOutMin);
    }

    /**
     * @dev The entrypoint of funds into the system. People deposit with this function
     * into the vault. The vault is then in charge of sending funds into the strategy.
     * @param _amount Amount of funds
     * @param route0 Swap route to lpToken0
     * @param route1 Swap route to lpToken1
     * @param _amountOutMin Minimum amounts for swap by routes and addLiquidity
     *   _amountOutMin[0] - min swap amount by route0
     *   _amountOutMin[1] - min swap amount by route1
     *   _amountOutMin[2] - amountAMin for addLiquidity lpToken
     *   _amountOutMin[3] - amountBMin for addLiquidity lpToken
     */
    function depositLP(uint256 _amount,
        address[] memory route0, address[] memory route1,
        uint256[] memory _amountOutMin
    ) external nonReentrant {
        _depositLP(msg.sender, _amount, 0, route0, route1,
            _amountOutMin
        );
    }


    /**
     * @dev Function to exit the system. The vault will withdraw the required tokens
     * from the strategy and pay up the token holder. A proportional number of IOU
     * tokens are burned in the process.
     */
    function withdraw(uint256 _shares) public nonReentrant {
        uint256 totalShares = vault.totalSupply();
        vault.burn(msg.sender, _shares);
        strategy.withdraw(msg.sender, _shares, totalShares);

        emit Withdraw(msg.sender, _shares);
    }

    /**
     * @dev The entrypoint of auto funds into the system by oracle.
     * @param from Address of account
     * @param _amount Amount of funds
     * @param _fee Additional fee amount for gas compensation
     * @param route Swap route
     * @param _amountOutMin Minimum swap out amount
     */
    function depositAuto(
        address from,
        uint256 _amount,
        uint256 _fee,
        address[] memory route,
        uint256 _amountOutMin
    ) external onlySFOracle {
        _fee+= strategy.safeFarmFeeAmount(_amount);

        _deposit(from, _amount, _fee, route, _amountOutMin);
    }

    /**
     * @dev The entrypoint of auto funds into the system by oracle.
     * @param from Address of account
     * @param _amount Amount of funds
     * @param _fee Additional fee amount for gas compensation
     * @param route0 Swap route to lpToken0
     * @param route1 Swap route to lpToken1
     * @param _amountOutMin min amounts for swap by routes and addLiquidity
     *   _amountOutMin[0] - min swap amount by route0
     *   _amountOutMin[1] - min swap amount by route1
     *   _amountOutMin[2] - amountAMin for addLiquidity lpToken
     *   _amountOutMin[3] - amountBMin for addLiquidity lpToken
     */
    function depositAutoLP(
        address from,
        uint256 _amount,
        uint256 _fee,
        address[] memory route0, address[] memory route1,
        uint256[] memory _amountOutMin
    ) external onlySFOracle {
        _fee+= strategy.safeFarmFeeAmount(_amount);

        _depositLP(from, _amount, _fee, route0, route1, _amountOutMin);
    }


    // it calculates account shares by percent
    function calcShares(
        address _account, uint256 _percent
    ) public view returns (uint256 shares) {
        shares = vault.balanceOf(_account) * _percent / 100;
        return shares;
    }

    function want() public view returns (IERC20) {
        return IERC20(strategy.want());
    }

    /**
     * @dev It calculates the total underlying value of {token} held by the system.
     * It takes into account the vault contract balance, the strategy contract balance
     *  and the balance deployed in other contracts as part of the strategy.
     */
    function balance() public view returns (uint256) {
        return available() + strategy.balanceOf();
    }


    /**
     * @dev Custom logic in here for how much the contract allows to be borrowed.
     * We return 100% of tokens for now. Under certain conditions we might
     * want to keep some of the system funds at hand in the vault, instead
     * of putting them to work.
     */
    function available() public view returns (uint256) {
        return want().balanceOf(address(this));
    }


    /**
     * @dev The entrypoint of funds into the system. People deposit with this function
     * into the vault. The vault is then in charge of sending funds into the strategy.
     */
    function _deposit(
        address _depositor,
        uint256 _amount,
        uint256 _fee,
        address[] memory route,
        uint256 _amountOutMin
    ) internal {
        IERC20 tokenA = IERC20(route[0]);
        address tokenB = route[route.length - 1];
        require(tokenB == strategy.want(), 'invalid route');

        strategy.harvest();
        uint256 _before = balance();

        _amount = _receiveDeposit(tokenA, _depositor, _amount, _fee);

        if (route.length > 1) {
            address unirouter = strategy.unirouter();
            if (tokenA.allowance(address(this), unirouter) < _amount) {
                tokenA.safeApprove(unirouter, type(uint256).max);
            }

            uint256[] memory amounts = IUniswapRouterETH(unirouter).swapExactTokensForTokens(
                _amount,
                _amountOutMin,
                route,
                address(this),
                block.timestamp
            );

            _amount = amounts[amounts.length - 1];
        }

        earn();

        uint256 _after = strategy.balanceOfPool();
        uint256 shares = _after - _before; // Additional check for deflationary tokens
        if (shares > _amount) {
            shares = _amount;
        }

        uint256 totalSupply = vault.totalSupply();
        if (totalSupply > 0) {
            shares = (shares * totalSupply / _before);
        }

        require(shares > 0, 'ZERRO ST');

        vault.mint(_depositor, shares);

        emit Deposit(_depositor, shares);
    }

    function _depositLP(
        address _depositor,
        uint256 _amount,
        uint256 _fee,
        address[] memory _route0, address[] memory _route1,
        uint256[] memory _amountOutMin
    ) internal {
        require(_amountOutMin.length == 4, 'invalid _amountOutMin');

        IERC20 tokenA = IERC20(_checkRoutesLP(_route0, _route1));

        _amount = _receiveDeposit(tokenA, _depositor, _amount, _fee);

        address unirouter = strategy.unirouter();

        if (tokenA.allowance(address(this), unirouter) < _amount) {
            tokenA.safeApprove(unirouter, type(uint256).max);
        }

        uint256 amountHalf = _amount / 2;

        LPToken memory lpt0 = _swapLPToken(unirouter, amountHalf, _route0, _amountOutMin[0]);
        LPToken memory lpt1 = _swapLPToken(unirouter, (_amount - amountHalf), _route1, _amountOutMin[1]);

        strategy.harvest();
        uint256 _pool = balance();

        _amount = _addLpLiquidity(_depositor, unirouter, lpt0, lpt1, _amountOutMin);

        earn();

        uint256 shares = (strategy.balanceOfPool() - _pool); // Additional check for deflationary tokens
        if (shares > _amount) {
            shares = _amount;
        }

        uint256 totalSupply = vault.totalSupply();
        if (totalSupply > 0) {
            shares = (shares * totalSupply / _pool);
        }

        require(shares > 0, 'ZERRO ST');

        vault.mint(_depositor, shares);

        emit Deposit(_depositor, shares);
    }


    function _receiveDeposit(
        IERC20 _token,
        address _depositor,
        uint256 _amount,
        uint256 _fee
    ) internal virtual returns (uint256) {
        _token.safeTransferFrom(_depositor, address(this), _amount);

        if (_fee > 0) {
            address feeRecipient = strategy.safeFarmFeeRecipient();
            _token.safeTransfer(feeRecipient, _fee);
            _amount-= _fee;
        }

        return _amount;
    }

    function _swapLPToken(
        address unirouter,
        uint256 _amount,
        address[] memory route,
        uint256 _amountOutMin
    ) internal virtual returns (LPToken memory)
    {
        address tokenB = route[route.length - 1];

        if (route.length > 1) {
            uint256[] memory amounts = IUniswapRouterETH(unirouter).swapExactTokensForTokens(
                _amount,
                _amountOutMin,
                route,
                address(this),
                block.timestamp
            );

            _amount = amounts[amounts.length - 1];
        }

        return LPToken(_amount, tokenB);
    }

    function _addLpLiquidity(
        address _depositor,
        address unirouter,
        LPToken memory lpt0,
        LPToken memory lpt1,
        uint256[] memory _lptOutMin
    ) internal returns (uint256 _liquidity) {
        (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        ) = _addLiquidity(unirouter, lpt0, lpt1, _lptOutMin);

        if (lpt0.amount > amountA) {
            IERC20(lpt0.token).safeTransfer(_depositor, (lpt0.amount - amountA));
        }

        if (lpt1.amount > amountB) {
            IERC20(lpt1.token).safeTransfer(_depositor, (lpt1.amount - amountB));
        }

        return liquidity;
    }

    function _addLiquidity(
        address unirouter,
        LPToken memory lpt0,
        LPToken memory lpt1,
        uint256[] memory _lptOutMin
    ) internal virtual returns (
        uint256 amountA,
        uint256 amountB,
        uint256 liquidity
    ) {
        if (IERC20(lpt0.token).allowance(address(this), unirouter) < lpt0.amount) {
            IERC20(lpt0.token).safeApprove(unirouter, type(uint256).max);
        }

        if (IERC20(lpt1.token).allowance(address(this), unirouter) < lpt1.amount) {
            IERC20(lpt1.token).safeApprove(unirouter, type(uint256).max);
        }

        return IUniswapRouterETH(unirouter).addLiquidity(
            lpt0.token,
            lpt1.token,
            lpt0.amount,
            lpt1.amount,
            _lptOutMin[2],
            _lptOutMin[3],
            address(this),
            block.timestamp
        );
    }


    function _checkRoutesLP(
        address[] memory _route0,
        address[] memory _route1
    ) internal view returns (address tokenA){
        require(_route0[0] == _route1[0], 'different source tokens at routes');

        IUniswapV2Pair LP = IUniswapV2Pair(strategy.want());

        require(LP.token0() == _route0[_route0.length - 1], 'route0 don`t path to lpt0');
        require(LP.token1() == _route1[_route1.length - 1], 'route1 don`t path to lpt1');

        return _route0[0];
    }



    /**
     * @dev Function to send funds into the strategy and put them to work.
     */
    function earn() internal {
        uint256 _bal = available();
        want().safeTransfer(address(strategy), _bal);
        strategy.deposit();

        emit Earn(_bal);
    }

}

interface IVault {
    function totalSupply() external view returns (uint256);
    function balanceOf(address _owner) external view returns (uint256);
    function mint(address _recipient, uint256 _amount) external;
    function burn(address _owner, uint256 _amount) external;
}

interface IStrategy {
    function migrate(address newSafeFarm) external;

    function want() external view returns (address);
    function unirouter() external view returns (address);

    function balanceOf() external view returns (uint256);
    function balanceOfPool() external view returns (uint256);

    function deposit() external;
    function withdraw(address account, uint256 share, uint256 totalShares) external;
    function harvest() external;
    function retireStrat() external;

    function safeSwap(address account,
        uint256 share, uint256 totalShares,
        uint256 fee,
        address[] memory route) external;
    function safeSwap(address account,
        uint256 share, uint256 totalShares,
        uint256 fee,
        address[] memory route0, address[] memory route1) external;

    function safeFarmFeeRecipient() external returns (address);
    function safeFarmFeeAmount(uint256 amount) external returns (uint256);
}