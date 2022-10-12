pragma solidity 0.8.14;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

/**
 * @dev Vanilla upgradeable {ERC20} "WAXP" token:
 *
 */
contract WAXPERC20UpgradeSafe is Initializable, OwnableUpgradeable, ERC20BurnableUpgradeable {
    uint8 public constant DECIMALS = 8;                         // The number of decimals for display
    uint256 public constant INITIAL_SUPPLY = 386482894311326596;  // supply specified in base units

    IERC20 public waxToken;

    /**
    * @dev triggered when tokens are transferred from the smart contract
    *
    * @param from  account that the tokens are sent to
    * @param amount  amount transferred
    */
    event TokenSwap(
        address indexed from,
        uint256 amount
    );

    modifier _hasAllowance(
        IERC20 _token,
        address _allower,
        uint256 _amount
    ) {
        uint256 ourAllowance = _token.allowance(_allower, address(this));
        require(_amount <= ourAllowance, 'ERR::NOT_ENOUGH_ALLOWANCE');
        _;
    }

    /**
     * See {ERC20-constructor}.
     */
    function initialize(address escrow) public initializer {
        ERC20Upgradeable.__ERC20_init("WAXP Token", "WAXP");
        _mint(escrow, INITIAL_SUPPLY);
        __Ownable_init();
    }

    function decimals() public pure override returns (uint8) {
        return DECIMALS;
    }

    /**
     * @dev Destroys `amount` tokens from the contract owner.
     *
     * See {ERC20-_burn}.
     * - only owner allow to call
     */
    function burn(uint256 amount) public override onlyOwner {
        super.burn(amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     * - only owner allow to call
     */
    function burnFrom(address account, uint256 amount) public override onlyOwner {
        super.burnFrom(account, amount);
    }

    /**
    * @dev swap WAXP from old contract to get WAXP from this contract
    *
    * @param amount         amount of WAXP want to swap
    */
    function swapogwax(uint256 amount) public _hasAllowance(waxToken, msg.sender, amount) {
        address from = msg.sender;
        waxToken.transferFrom(from, address(this), amount);
        this.transfer(from, amount);
        emit TokenSwap(from, amount);
    }

    /**
    * @dev set WAX token contract address
    *
    * @param _waxToken         WAX token address
    */
    function setWaxToken(address _waxToken) public onlyOwner {
        waxToken = IERC20(_waxToken);
    }
}