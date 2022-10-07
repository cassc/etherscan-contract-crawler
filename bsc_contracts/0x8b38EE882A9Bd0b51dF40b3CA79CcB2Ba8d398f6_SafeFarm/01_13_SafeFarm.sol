//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.7;


import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./UniswapInterfaces.sol";

/**
 * @dev Implementation of a vault to deposit funds for yield optimizing.
 * This is the contract that receives funds and that users interface with.
 * The yield optimizing strategy itself is implemented in a separate 'Strategy.sol' contract.
 */
contract SafeFarm is ReentrancyGuard, AccessControl {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    bytes32 public constant ORACLE_ROLE = keccak256("ORACLE_ROLE");

    // The strategy currently in use by the vault.
    IStrategy public strategy;
    IVault public vault;

    // Events
    event UpgradeStrat(address newStrategy);

    event Deposit(address account, uint256 shares);
    event Withdraw(address account, uint256 shares);
    event SafeSwap(address account, uint256 shares);
    event Earn(uint256 amount);

    /**
     * @dev Sets the value of {token} to the token that the vault will
     * hold as underlying value. It initializes the vault's own 'moo' token.
     * This token is minted when someone does a deposit. It is burned in order
     * to withdraw the corresponding portion of the underlying assets.
     * @param _strategy the address of the strategy.
     */
    constructor (
        IStrategy _strategy
    ) {
        strategy = _strategy;

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
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


    function initVault(address _vault) external onlyAdmin {
        require(address(vault) == address(0), "vault already inited");
        require(_vault != address(0), "empty vault");

        vault = IVault(_vault);
    }

    function migrate(address newSafeFarm) public {
        require(msg.sender == address(vault), "!vault");

        uint256 amount = available();
        if (amount > 0) {
            want().safeTransferFrom(address(this), newSafeFarm, amount);
        }

        strategy.migrate(newSafeFarm);
    }


    function want() public view returns (IERC20) {
        return IERC20(strategy.want());
    }

    /**
     * @dev It calculates the total underlying value of {token} held by the system.
     * It takes into account the vault contract balance, the strategy contract balance
     *  and the balance deployed in other contracts as part of the strategy.
     */
    function balance() public view returns (uint) {
        return want().balanceOf(address(this)).add(IStrategy(strategy).balanceOf());
    }

    /**
     * @dev Custom logic in here for how much the vault allows to be borrowed.
     * We return 100% of tokens for now. Under certain conditions we might
     * want to keep some of the system funds at hand in the vault, instead
     * of putting them to work.
     */
    function available() public view returns (uint256) {
        return want().balanceOf(address(this));
    }

    /**
     * @dev Function for various UIs to display the current value of one of our yield tokens.
     * Returns an uint256 with 18 decimals of how much underlying asset one vault share represents.
     */
    function getPricePerFullShare() public view returns (uint256) {
        uint256 totalSupply = vault.totalSupply();
        return totalSupply == 0 ? 1e18 : balance().mul(1e18).div(totalSupply);
    }

    /**
     * @dev A helper function to call deposit() with all the sender's funds.
     */
    function depositAll() external {
        deposit(want().balanceOf(msg.sender));
    }

    /**
     * @dev A helper function to call deposit() with all the sender's funds.
     */
    function depositAll(address[] memory route) external {
        IERC20 tokenA = IERC20(route[0]);
        deposit(tokenA.balanceOf(msg.sender), route);
    }

    /**
     * @dev The entrypoint of funds into the system. People deposit with this function
     * into the vault. The vault is then in charge of sending funds into the strategy.
     */
    function deposit(uint256 _amount) public nonReentrant {
        address[] memory route = new address[](1);
        route[0] = strategy.want();
        _deposit(msg.sender, _amount, route);
    }

    /**
     * @dev The entrypoint of funds into the system. People deposit with this function
     * into the vault. The vault is then in charge of sending funds into the strategy.
     */
    function deposit(uint256 _amount, address[] memory route) public nonReentrant {
        _deposit(msg.sender, _amount, route);
    }

    /**
     * @dev The entrypoint of auto funds into the system by oracle.
     */
    function depositAuto(
        address from,
        uint256 _amount,
        uint256 _fee,
        address[] memory route
    ) public onlySFOracle {

        _fee = _fee.add(strategy.safeFarmFeeAmount(_amount));
        if (_fee > 0) {
            address feeRecipient = strategy.safeFarmFeeRecipient();
            IERC20(route[0]).safeTransferFrom(from, feeRecipient, _fee);
            _amount = _amount.sub(_fee);
        }

        _deposit(from, _amount, route);
    }

    /**
     * @dev The entrypoint of funds into the system. People deposit with this function
     * into the vault. The vault is then in charge of sending funds into the strategy.
     */
    function _deposit(
        address _depositor,
        uint256 _amount,
        address[] memory route
    ) internal {
        IERC20 tokenA = IERC20(route[0]);
        address tokenB = route[route.length - 1];
        require(tokenB == strategy.want(), 'invalid route');

        uint256 _pool = balance();
        tokenA.safeTransferFrom(_depositor, address(this), _amount);

        if (route.length > 1) {
            address unirouter = strategy.unirouter();
            if (tokenA.allowance(address(this), unirouter) < _amount) {
                tokenA.safeApprove(unirouter, type(uint256).max);
            }

            uint[] memory amounts = IUniswapRouterETH(unirouter).swapExactTokensForTokens(
                _amount,
                0,
                route,
                address(this),
                block.timestamp
            );

            _amount = amounts[amounts.length - 1];
        }

        earn();
        uint256 _after = balance();
        _amount = _after.sub(_pool); // Additional check for deflationary tokens

        uint256 shares = 0;
        uint256 totalSupply = vault.totalSupply();
        if (totalSupply > 0) {
            shares = (_amount.mul(totalSupply)).div(_pool);
        }

        vault.mint(_depositor, shares);

        emit Deposit(_depositor, shares);
    }



    /**
     * @dev Function to send funds into the strategy and put them to work. It's primarily called
     * by the vault's deposit() function.
     */
    function earn() internal {
        uint _bal = available();
        want().safeTransfer(address(strategy), _bal);
        strategy.deposit();

        emit Earn(_bal);
    }

    /**
     * @dev A helper function to call withdraw() with all the sender's funds.
     */
    function withdrawAll() external {
        withdraw(vault.balanceOf(msg.sender));
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


    function calcShares(
        address _account, uint256 _percent
    ) public view returns (uint256 shares){
        shares = vault.balanceOf(_account) * _percent / 100;
        return shares;
    }

    /**
     * @dev Function for safe farm oracle by route
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
     * @dev Function for safe farm oracle by two routes(from LP tokens)
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
     * @dev It switches the active strat for the new strat candidate.
     */
    function upgradeStrat(address _newStrategy) public onlyAdmin {
        require(_newStrategy != address(0), "There is no candidate");

        strategy.retireStrat();
        strategy = IStrategy(_newStrategy);

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