// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "../interfaces/IStrategy.sol";
import "../interfaces/IZaynReferrerV2.sol";

/**
 * @dev Implementation of a vault to deposit funds for yield optimizing.
 * This is the contract that receives funds and that users interface with.
 * The yield optimizing strategy itself is implemented in a separate 'Strategy.sol' contract.
 */
contract ZaynVaultV2 is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    struct StratCandidate {
        address implementation;
        uint proposedTime;
    }

    // Info of each user.
    struct UserInfo {
        uint256 amount; // How many LP tokens the user has provided.
        address referrer; // When can the user harvest again.
    }

    mapping(address => UserInfo) public userInfo;
    // The last proposed strategy to switch to.
    StratCandidate public stratCandidate;
    // The strategy currently in use by the vault.
    IStrategy public strategy;
    // The minimum time it has to pass before a strat candidate can be approved.
    uint256 public immutable approvalDelay;

    uint256 public totalSupply;

    event NewStratCandidate(address implementation);
    event UpgradeStrat(address implementation);
    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);


    address public zapAddress;
    bool public zapEnabled = false;

    address public revShareAddress;
    bool public revShareEnabled = false;

    modifier onlyZap() {
        require(
            zapAddress == msg.sender,
            "Only zap can call"
        );
        _;
    }

    /**
     * @dev Sets the value of {token} to the token that the vault will
     * hold as underlying value. It initializes the vault's own 'moo' token.
     * This token is minted when someone does a deposit. It is burned in order
     * to withdraw the corresponding portion of the underlying assets.
     * @param _strategy the address of the strategy.
     * @param _approvalDelay the delay before a new strat can be approved.
     */
    constructor (
        IStrategy _strategy,
        uint256 _approvalDelay
    ) public {
        strategy = _strategy;
        approvalDelay = _approvalDelay;
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

    function balanceOf(address user) public view returns (uint) {
        UserInfo storage user = userInfo[user];
        return user.amount;
    }

    /**
     * @dev Custom logic in here for how much the vault allows to be borrowed.
     * We return 100% of tokens for block.timestamp. Under certain conditions we might
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
        return totalSupply == 0 ? 1e18 : balance().mul(1e18).div(totalSupply);
    }

    /**
     * @dev A helper function to call deposit() with all the sender's funds.
     */
    function depositAll(address _referrer) external {
        deposit(want().balanceOf(msg.sender), _referrer);
    }

    function deposit(uint _amount, address _referrer) public nonReentrant {
        _deposit(_amount, msg.sender, msg.sender, _referrer);
    }

    /**
     * @dev The entrypoint of funds into the system. People deposit with this function
     * into the vault. The vault is then in charge of sending funds into the strategy.
     */
    function _deposit(uint _amount, address _user, address _payer, address _referrer) internal {
        UserInfo storage user = userInfo[_user];

        strategy.beforeDeposit();

        uint256 _pool = balance();
        want().safeTransferFrom(_payer, address(this), _amount);
        earn();
        uint256 _after = balance();
        _amount = _after.sub(_pool); // Additional check for deflationary tokens
        uint256 shares = 0;
        if (totalSupply == 0) {
            shares = _amount;
        } else {
            shares = (_amount.mul(totalSupply)).div(_pool);
        }
        user.amount = user.amount.add(shares);
        user.referrer = _referrer;
        totalSupply = totalSupply.add(shares);
        emit Deposit(_user, shares);
        _recordDepositRevShare(_referrer, shares);
    }

    /**
     * @dev Function to send funds into the strategy and put them to work. It's primarily called
     * by the vault's deposit() function.
     */
    function earn() public {
        uint _bal = available();
        want().safeTransfer(address(strategy), _bal);
        strategy.deposit();
    }

    /**
     * @dev A helper function to call withdraw() with all the sender's funds.
     */
    function withdrawAll() external {
        UserInfo storage user = userInfo[msg.sender];
        withdraw(user.amount);
    }

    /**
     * @dev Function to exit the system. The vault will withdraw the required tokens
     * from the strategy and pay up the token holder. A proportional number of IOU
     * tokens are burned in the process.
     */
    function withdraw(uint256 _shares) public nonReentrant {
        _withdraw(_shares, msg.sender, msg.sender);
    }

    function _withdraw(uint256 _shares, address _user, address _receiver) internal {
        uint256 r = (balance().mul(_shares)).div(totalSupply);
        UserInfo storage user = userInfo[_user];
        require(user.amount >= _shares, "withdraw: not enough balance");
        user.amount = user.amount.sub(_shares);
        totalSupply = totalSupply.sub(_shares);
        uint b = want().balanceOf(address(this));
        if (b < r) {
            uint _withdrawAmount = r.sub(b);
            strategy.withdraw(_withdrawAmount);
            uint _after = want().balanceOf(address(this));
            uint _diff = _after.sub(b);
            if (_diff < _withdrawAmount) {
                r = b.add(_diff); // CHECK THIS
            }
        }
        _recordWithdrawRevShare(user.referrer, _shares);
        emit Withdraw(_user, _shares);
        want().safeTransfer(_receiver, r);
    }

    /** 
     * @dev Sets the candidate for the new strat to use with this vault.
     * @param _implementation The address of the candidate strategy.  
     */
    function proposeStrat(address _implementation) public onlyOwner {
        require(address(this) == IStrategy(_implementation).vault(), "Proposal not valid for this Vault");
        stratCandidate = StratCandidate({
            implementation: _implementation,
            proposedTime: block.timestamp
         });

        emit NewStratCandidate(_implementation);
    }

    /** 
     * @dev It switches the active strat for the strat candidate. After upgrading, the 
     * candidate implementation is set to the 0x00 address, and proposedTime to a time 
     * happening in +100 years for safety. 
     */

    function upgradeStrat() public onlyOwner {
        require(stratCandidate.implementation != address(0), "There is no candidate");
        require(stratCandidate.proposedTime.add(approvalDelay) < block.timestamp, "Delay has not passed");

        emit UpgradeStrat(stratCandidate.implementation);
        IERC20 oldWant = strategy.want();
        strategy.retireStrat();
        strategy = IStrategy(stratCandidate.implementation);
        uint256 wantBal = oldWant.balanceOf(address(this));
        oldWant.safeTransfer(address(strategy), wantBal);
        strategy.migrate();
        stratCandidate.implementation = address(0);
        stratCandidate.proposedTime = 5000000000;

        earn();
    }

    /**
     * @dev Rescues random funds stuck that the strat can't handle.
     * @param _token address of the token to rescue.
     */
    function rescueTokens(address _token) external onlyOwner {
        require(_token != address(want()), "!token");
        if (_token == address(0)) {
            (bool sent, ) = msg.sender.call{value: address(this).balance}("");
            require(sent, "failed to send");
        } else {
            uint256 amount = IERC20(_token).balanceOf(address(this));
            IERC20(_token).safeTransfer(msg.sender, amount);
        }
    }

    // @dev Ability to change the zap address
    function setZapAddress(address _zapAddress) external onlyOwner {
        require(_zapAddress != address(0), "New zap address is zero address");
        zapAddress = _zapAddress;
        zapEnabled = true;
    }

    function toggleZap(bool _toggle) external onlyOwner {
        zapEnabled = _toggle;
    }

    function depositZap(uint _amount, address _user, address _referrer) public nonReentrant onlyZap {
        require(zapEnabled, "Zap not enabled");
        _deposit(_amount, _user, msg.sender, _referrer);
    }

    function withdrawZap(uint256 _shares, address _user) public onlyZap {
        require(zapEnabled, "Zap not enabled");
        _withdraw(_shares, _user, msg.sender);
    }

    // @dev Ability to change the zap address
    function setRevShareAddress(address _revShareAddress) external onlyOwner {
        require(_revShareAddress != address(0), "Rev share address is zero address");
        revShareAddress = _revShareAddress;
        revShareEnabled = true;
    }

    function toggleRevShare(bool _toggle) external onlyOwner {
        revShareEnabled = _toggle;
    }

    function _recordDepositRevShare(address referrer, uint256 amount) internal {
        if (revShareEnabled) {
            IZaynReferrerV2(revShareAddress).recordDeposit(referrer, amount);
        }
    }

    function _recordWithdrawRevShare(address referrer, uint256 amount) internal {
        if (revShareEnabled) {
            IZaynReferrerV2(revShareAddress).recordWithdraw(referrer, amount);
        }
    }

}