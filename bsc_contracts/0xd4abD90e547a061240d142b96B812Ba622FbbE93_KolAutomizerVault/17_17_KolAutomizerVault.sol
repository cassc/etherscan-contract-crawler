// SPDX-License-Identifier: MIT
// A product of https://keyoflife.fi
pragma solidity ^0.8.13;
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import "./AuthUpgradeable.sol";
import "./IStrategy.sol";

/**
 * @dev Implementation of a vault to deposit funds for yield optimizing.
 * This is the contract that receives funds and that users interface with.
 * The yield optimizing strategy itself is implemented in a separate 'Strategy.sol' contract.
 */
contract KolAutomizerVault is Initializable, UUPSUpgradeable, ERC20Upgradeable, AuthUpgradeable, ReentrancyGuardUpgradeable {
    function _authorizeUpgrade(address) internal override onlyOwner {}
    using SafeERC20Upgradeable for IERC20Upgradeable;


    IERC20Upgradeable public want;

    // The strategy currently in use by the vault.
    IStrategy public strategy;
    mapping(address => uint256) public totalDeposit;
    mapping(address => uint256) public totalWithdrawn;

    event Earn(uint256 amount);
    event Deposit(address from, uint256 shares, uint256 amount);
    event Withdraw(address to, uint256 shares, uint256 amount);
    event RescuesTokenStuck(address token, uint256 amount);

    /**
     * @dev Sets the value of {token} to the token that the vault will
     * hold as underlying value. It initializes the vault's own 'moo' token.
     * This token is minted when someone does a deposit. It is burned in order
     * to withdraw the corresponding portion of the underlying assets.
     */
    function initialize() public initializer {
        __UUPSUpgradeable_init();
        __AuthUpgradeable_init();
        __ERC20_init("Kol Automizer Receipient", "KOL_ETS-USD+");
        IStrategy _strategy = IStrategy(0x9d9F42BBBca0ADC9717D72bbA2837985298F5987);
        strategy = _strategy;
        want = IERC20Upgradeable(_strategy.want());
    }
    /*
        constructor(
            IStrategy _strategy,
            string memory _name,
            string memory _symbol
        ) ERC20Upgradeable(_name, _symbol) {

            //build strategy first, then
            strategy = _strategy;
            want = IERC20Upgradeable(_strategy.want());
        }
    */
    /**
     * @dev It calculates the total underlying value of {token} held by the system.
     * It takes into account the vault contract balance, the strategy contract balance
     *  and the balance deployed in other contracts as part of the strategy.
     */
    function balance() public view returns (uint) {
        return want.balanceOf(address(this))+(strategy.balanceOf());
    }

    /**
     * @dev Custom logic in here for how much the vault allows to be borrowed.
     * We return 100% of tokens for now. Under certain conditions we might
     * want to keep some of the system funds at hand in the vault, instead
     * of putting them to work.
     */
    function available() public view returns (uint256) {
        return want.balanceOf(address(this));
    }

    /**
     * @dev Function for various UIs to display the current value of one of our yield tokens.
     * Returns an uint256 with 18 decimals of how much underlying asset one vault share represents.
     */
    function getPricePerFullShare() public view returns (uint256) {
        return
        totalSupply() == 0 ? 1e18 : balance()*(1e18)/(totalSupply());
    }

    /**
     * @dev A helper function to call deposit() with all the sender's funds.
     */
    function depositAll() external {
        deposit(want.balanceOf(msg.sender));
    }

    /**
     * @dev The entrypoint of funds into the system. People deposit with this function
     * into the vault. The vault is then in charge of sending funds into the strategy.
     */
    function deposit(uint _amount) public {
        depositFor(msg.sender, _amount);
    }

    /**
     * @dev The entrypoint of funds into the system. People deposit with this function
     * into the vault. The vault is then in charge of sending funds into the strategy.
     */
    function depositFor(address user, uint _amount) public nonReentrant {
        //if (msg.sender == tx.origin)
        strategy.beforeDeposit();

        uint256 _pool = balance();
        want.safeTransferFrom(msg.sender, address(this), _amount);
        earn();
        uint256 _after = balance();
        _amount = _after-(_pool); // Additional check for deflationary tokens
        totalDeposit[user] += _amount;
        uint256 shares = 0;
        if (totalSupply() == 0) {
            shares = _amount;
        } else {
            shares = (_amount*(totalSupply()))/(_pool);
        }
        _mint(user, shares);
        emit Deposit(msg.sender, shares, _amount);
    }
    /**
     * @dev Function to send funds into the strategy and put them to work. It's primarily called
     * by the vault's deposit() function.
     */
    function earn() public {
        uint _bal = available();
        want.safeTransfer(address(strategy), _bal);
        strategy.deposit();
        emit Earn(_bal);
    }

    /**
     * @dev A helper function to call withdraw() with all the sender's funds.
     */
    function withdrawAll() external {
        withdraw(balanceOf(msg.sender));
    }

    /**
     * @dev Function assisting front-end to calculate how much _share from a _lp number
     */
    function calcShares(uint256 _lp) public view returns (uint256 _shares) {
        _shares = _lp * totalSupply() / balance();
    }

    function calcLp(uint256 _shares) public view returns (uint256 _lp) {
        if (totalSupply()==0) return 0;
        _lp = _shares * balance() / totalSupply();
    }

    function depositedLpOf(address user) public view returns (uint256 _lp) {
        return calcLp(balanceOf(user));
    }

    function withdrawLp(uint256 _lp) public {
        withdraw(calcShares(_lp));
    }

    /**
     * @dev Function to exit the system. The vault will withdraw the required tokens
     * from the strategy and pay up the token holder. A proportional number of IOU
     * tokens are burned in the process.
     */

    function withdraw(uint256 _shares) public {
        uint256 r = (balance()*(_shares))/(totalSupply());
        _burn(msg.sender, _shares);

        uint b = want.balanceOf(address(this));
        if (b < r) {
            uint _withdraw = r-(b);
            strategy.withdraw(_withdraw);
            uint _after = want.balanceOf(address(this));
            uint _diff = _after-(b);
            if (_diff < _withdraw) {
                r = b+(_diff);
            }
        }
        want.safeTransfer(msg.sender, r);
        totalWithdrawn[msg.sender] +=r;
        emit Withdraw(msg.sender, _shares, r);
    }

    /**
     * @dev Rescues random funds stuck that the strat can't handle.
     * @param _token address of the token to rescue.
     */
    function inCaseTokensGetStuck(address _token) external onlyOwner {
        require(_token != address(want), "KolVault: STUCK_TOKEN_ONLY");
        uint256 amount = IERC20Upgradeable(_token).balanceOf(address(this));
        IERC20Upgradeable(_token).safeTransfer(msg.sender, amount);
        emit RescuesTokenStuck(_token, amount);
    }
}