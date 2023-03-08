// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import "./tokens/ERC20.sol";
import "./utils/Ownable.sol";
import "./utils/SafeERC20.sol";
import "./utils/SafeMath.sol";
import "./utils/ReentrancyGuard.sol";
import "./interfaces/IGalaxyStrategy.sol";

contract GalaxyYieldVault is ERC20, Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    // The last proposed strategy to switch to.
    address public strategyCandidate;
    // The strategy currently in use by the vault.
    IGalaxyStrategy public strategy;

    event NewStrategyCandidate(address implementation);
    event UpgradeStrategy(address implementation);

    /**
     * @dev Sets the value of {token} to the token that the vault will
     * hold as underlying value. It initializes the vault's own token.
     * This token is minted when someone does a deposit. It is burned in order
     * to withdraw the corresponding portion of the underlying assets.
     * @param _name the name of the vault token.
     * @param _symbol the symbol of the vault token.
     */
    constructor(
        IGalaxyStrategy _strategy,
        string memory _name,
        string memory _symbol
    ) ERC20(
        _name,
        _symbol
    ) {
        strategy = _strategy;
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
        return want().balanceOf(address(this)).add(IGalaxyStrategy(strategy).balanceOf());
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
        return totalSupply() == 0 ? 1e18 : balance().mul(1e18).div(totalSupply());
    }

    /**
     * @dev A helper function to call deposit() with all the sender's funds.
     */
    function depositAll() external {
        deposit(want().balanceOf(msg.sender));
    }

    /**
     * @dev The entrypoint of funds into the system. People deposit with this function
     * into the vault. The vault is then in charge of sending funds into the strategy.
     */
    function deposit(uint _amount) public nonReentrant {
        strategy.beforeDeposit();
        uint256 _pool = balance();
        want().safeTransferFrom(msg.sender, address(this), _amount);
        earn();
        uint256 _after = balance();
        _amount = _after.sub(_pool); // Additional check for deflationary tokens
        uint256 shares = 0;
        if (totalSupply() == 0) {
            shares = _amount;
        } else {
            shares = (_amount.mul(totalSupply())).div(_pool);
        }
        _mint(msg.sender, shares);
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
        withdraw(balanceOf(msg.sender));
    }

    /**
     * @dev Function to exit the system. The vault will withdraw the required tokens
     * from the strategy and pay up the token holder. A proportional number of IOU
     * tokens are burned in the process.
     */
    function withdraw(uint256 _shares) public {
        uint256 r = (balance().mul(_shares)).div(totalSupply());
        _burn(msg.sender, _shares);
        uint b = want().balanceOf(address(this));
        if (b < r) {
            uint _withdraw = r.sub(b);
            strategy.withdraw(_withdraw);
            uint _after = want().balanceOf(address(this));
            uint _diff = _after.sub(b);
            if (_diff < _withdraw) {
                r = b.add(_diff);
            }
        }
        want().safeTransfer(msg.sender, r);
    }

    /** 
     * @dev Sets the candidate for the new strat to use with this vault.
     * @param newStrategy The address of the candidate strategy.  
     */
    function setStrategy(address newStrategy) public onlyOwner {
        require(address(this) == IGalaxyStrategy(newStrategy).vault(), "Proposal not valid for this Vault");
        strategyCandidate = newStrategy;
        emit NewStrategyCandidate(newStrategy);
    }

    /** 
     * @dev Switches the active strategy for the strategy candidate.
     */

    function upgradeStrategy() public onlyOwner {
        require(strategyCandidate != address(0), "Candidate address invalid");
        emit UpgradeStrategy(strategyCandidate);
        strategy.retireStrategy();
        strategy = IGalaxyStrategy(strategyCandidate);
        strategyCandidate = address(0);
        earn();
    }

    /**
     * @dev Rescues any random token that the strat can't handle.
     * @param _token address of the token to rescue.
     */
    function retreiveOtherToken(address _token) external onlyOwner {
        require(_token != address(want()), "cannot be want token");
        uint256 amount = IERC20(_token).balanceOf(address(this));
        IERC20(_token).safeTransfer(msg.sender, amount);
    }
}