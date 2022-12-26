// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

import "../strategies/common/interfaces/IStrategy.sol";

/**
 * @dev Implementation of a vault to deposit funds for yield optimizing.
 * This is the contract that receives funds and that users interface with.
 * The yield optimizing strategy itself is implemented in a separate 'Strategy.sol' contract.
 */

struct StratCandidate {
        address implementation;
        uint proposedTime;
    }

contract RiveraAutoCompoundingVaultV1 is ERC20, Ownable, ReentrancyGuard, Initializable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    // The last proposed strategy to switch to.
    StratCandidate public stratCandidate;
    // The strategy currently in use by the vault.
    IStrategy public strategy;
    // The minimum time it has to pass before a strat candidate can be approved.
    uint256 public immutable approvalDelay;

    event NewStratCandidate(address implementation);
    event UpgradeStrat(address implementation);
    event Deposit(address indexed user, uint256 amount, uint256 tvl);
    event Withdraw(address indexed user, uint256 amount, uint256 tvl);

    /*
     * @dev Sets the value of {token} to the token that the vault will
     * hold as underlying value. It initializes the vault's own 'moo' token.
     * This token is minted when someone does a deposit. It is burned in order
     * to withdraw the corresponding portion of the underlying assets.
     * @param _strategy the address of the strategy.
     * @param _name the name of the vault token.
     * @param _symbol the symbol of the vault token.
     * @param _approvalDelay the delay before a new strat can be approved.
     */
    constructor (
        string memory _name,
        string memory _symbol,
        uint256 _approvalDelay
    ) ERC20(
        _name,
        _symbol
    ) {
        approvalDelay = _approvalDelay;
    }

    function init(IStrategy _strategy) public initializer {
        strategy = _strategy;
    }

    function stake() public view returns (IERC20) {
        return IERC20(strategy.stake());
    }

    /**
     * @dev It calculates the total underlying value of {token} held by the system.
     * It takes into account the vault contract balance, the strategy contract balance
     *  and the balance deployed in other contracts as part of the strategy.
     */
    function balance() public view returns (uint) {
        return stake().balanceOf(address(this)).add(IStrategy(strategy).balanceOf());
    }

    /**
     * @dev Custom logic in here for how much the vault allows to be borrowed.
     * We return 100% of tokens for now. Under certain conditions we might
     * stake to keep some of the system funds at hand in the vault, instead
     * of putting them to work.
     */
    function available() public view returns (uint256) {
        return stake().balanceOf(address(this));
    }

    /**
     * @dev Function for various UIs to display the current value of one of our yield tokens.
     * Returns an uint256 with 18 decimals of how much underlying asset one vault share represents.
     */
    function getPricePerFullShare() public view returns (uint256) {
        return totalSupply() == 0 ? 1e18 : balance().mul(1e18).div(totalSupply());
    }

    /**
     * @dev A helper function to call deposit() with all the sender's funds.
     */
    function depositAll() external {
        deposit(stake().balanceOf(msg.sender));
    }

    /**
     * @dev The entrypoint of funds into the system. People deposit with this function
     * into the vault. The vault is then in charge of sending funds into the strategy.
     */
    function deposit(uint _amount) public nonReentrant {
        _checkOwner();
        strategy.beforeDeposit();

        uint256 _pool = balance(); //Entire balance of the vault
        stake().safeTransferFrom(msg.sender, address(this), _amount); //Transfer the amout the user stakes to deposit from the user to the vault contract. User should have approved before
        earn();
        uint256 _after = balance();
        _amount = _after.sub(_pool); // Additional check for deflationary tokens. Yeah right for deflationary tokens amount will change
        uint256 shares = 0;
        if (totalSupply() == 0) {
            shares = _amount; //If no funds are there in the vault then shares minted is same as amount
        } else {
            shares = (_amount.mul(totalSupply())).div(_pool); //If there are funds already then the user's share needs to be scaled
        }
        _mint(msg.sender, shares);
        emit Deposit(msg.sender, _amount, balance());
    }

    /**
     * @dev Function to send funds into the strategy and put them to work. It's primarily called
     * by the vault's deposit() function.
     */
    function earn() public { //Transfers all available funds to the strategy and deploys it to AAVE 
        _checkOwner();
        uint _bal = available();
        stake().safeTransfer(address(strategy), _bal);
        strategy.deposit();
    }

    /**
     * @dev A helper function to call withdraw() with all the sender's funds.
     */
    function withdrawAll() external { //balanceOf(msg.sender) would give the user's mooToken balance
        withdraw(balanceOf(msg.sender));
    }

    /**
     * @dev Function to exit the system. The vault will withdraw the required tokens
     * from the strategy and pay up the token holder. A proportional number of IOU
     * tokens are burned in the process.
     */
    function withdraw(uint256 _shares) public onlyOwner {
        uint256 r = (balance().mul(_shares)).div(totalSupply()); //How much of total asset under management needs to be withdrawn? total Balance * shares/totalSupply
        _burn(msg.sender, _shares); //Check Effect Interactions smart contract code pattern. This is effect.

        uint b = stake().balanceOf(address(this)); //Balance of this vault contract address
        if (b < r) { //If balance is greater than the amout that has to be sent to user can send directly no need to even touch strategy
            uint _withdraw = r.sub(b); //Extra amout that has to be withdrawn from strategy
            strategy.withdraw(_withdraw);
            uint _after = stake().balanceOf(address(this)); //Inside the withdraw method strategy has already transfered the withdraw amount to vault
            uint _diff = _after.sub(b);
            if (_diff < _withdraw) { //For a normal token diff and withdraw should be same. For deflationary tokens we redifine r.
                r = b.add(_diff);
            }
        }

        stake().safeTransfer(msg.sender, r); //Finally we transfer r to the user
        emit Withdraw(msg.sender, r, balance());
    }

    /** 
     * @dev Sets the candidate for the new strat to use with this vault.
     * @param _implementation The address of the candidate strategy.  
     */
    function proposeStrat(address _implementation) public {
        _checkOwner();
        require(address(this) == IStrategy(_implementation).vault(), "!proposal"); //Stratey also holds the address of the vault hence equality should hold
        stratCandidate = StratCandidate({
            implementation: _implementation,
            proposedTime: block.timestamp
         }); //Sets the variable and emits event

        emit NewStratCandidate(_implementation);
    }

    function getStratProposal() public view returns (StratCandidate memory) {
        return stratCandidate;
    }

    /** 
     * @dev It switches the active strat for the strat candidate. After upgrading, the 
     * candidate implementation is set to the 0x00 address, and proposedTime to a time 
     * happening in +100 years for safety. 
     */

    function upgradeStrat() public { //Only owner can update strategy
        _checkOwner();
        require(stratCandidate.implementation != address(0), "!candidate"); //Strategy implementation has to be set before calling the method
        require(stratCandidate.proposedTime.add(approvalDelay) < block.timestamp, "!delay"); //Approval delay should have been passed since proposal time

        emit UpgradeStrat(stratCandidate.implementation);

        strategy.retireStrat();
        strategy = IStrategy(stratCandidate.implementation);
        stratCandidate.implementation = address(0); //Setting these values means that there is no proposal for new strategy
        stratCandidate.proposedTime = 5000000000;

        earn();
    }

    /**
     * @dev Rescues random funds stuck that the strat can't handle.
     * @param _token address of the token to rescue.
     */
    function inCaseTokensGetStuck(address _token) external {
        _checkOwner();
        require(_token != address(stake()), "!token"); //Token must not be equal to address of stake currency

        uint256 amount = IERC20(_token).balanceOf(address(this)); //Just finding the balance of this vault contract address in the the passed token and transfers
        IERC20(_token).safeTransfer(msg.sender, amount);
    }
}