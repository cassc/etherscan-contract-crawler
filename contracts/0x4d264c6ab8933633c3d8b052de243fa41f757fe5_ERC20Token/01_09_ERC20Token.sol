// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/**
 * @title ERC20 token
 * @dev Basic ERC20 Implementation, Inherits the OpenZepplin ERC20 implentation.
 */
contract ERC20Token is Initializable, ERC20Upgradeable, PausableUpgradeable, OwnableUpgradeable {
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    mapping (address => bool) internal isBlackListed;
    event Mint(address indexed minter, address indexed to, uint256 amount);
    event Burn(address indexed burner, uint256 amount);
    event AddedBlackList(address indexed _user);
    event RemovedBlackList(address indexed _user);

    /**
     * @notice Contract initialize.
     * @dev Initialize can only be called once.
     * @param name_ Name of the token.
     * @param symbol_ Symbol of the token
     * @param initialAccount The address to transfer ownership to.
     * @param initialBalance The amount to mint to initialAccount.
     */
    function initialize(
        string memory name_,
        string memory symbol_,
        address initialAccount,
        uint256 initialBalance
    ) public initializer {
        __ERC20_init(name_, symbol_);
        __Pausable_init();
        __Ownable_init();
        _transferOwnership(initialAccount);
        _mint(initialAccount, initialBalance * 10 ** decimals());
    }

    /**
     * @notice Throw if argument _addr is blacklisted.
     * @param _addr The address to check
     */
    modifier notBlacklisted(address _addr) {
        require(
            !isBlackListed[_addr],
            "Blacklistable: account is blacklisted"
        );
        _;
    }

    /**
     * @notice pause
     * @dev pause the contract
     */
    function pause() onlyOwner external {
        _pause();
    }

    /**
     * @notice unpause
     * @dev unpause the contract
     */
    function unpause() onlyOwner external {
        _unpause();
    }

    /**
     * @notice Mint amount of tokens.
     * @dev Function to mint tokens to specific account.
     * @param account The address that will receive the minted tokens
     * @param amount The amount of tokens to mint
     * Emits an {Mint} event.
     */
    function mint(address account, uint256 amount) onlyOwner whenNotPaused notBlacklisted(account) public {
        _mint(account, amount * 10 ** decimals());
        emit Mint(_msgSender(), account, amount * 10 ** decimals());
    }

    /**
     * @notice Burn amount of tokens.
     * @dev Function to burn tokens.
     * @param amount The amount of tokens to mint
     * Emits an {Burn} event.
     */
    function burn(uint256 amount) onlyOwner whenNotPaused public {
        _burn(_msgSender(), amount);
        emit Burn(_msgSender(), amount);
    }

    /**
     * @notice Override _transfer to add whenNotPaused and notBlacklisted check.
     * @dev Make a function callable only when the contract is not paused
     * and account is not blacklisted.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) whenNotPaused notBlacklisted(sender) notBlacklisted(recipient) internal virtual override {
        super._transfer(sender, recipient, amount);
    }

    /**
     * @notice Add suspicious account to blacklist.
     * @dev Function to add suspicious account to blacklist, 
     * Only callable by contract owner.
     * @param _evilUser The address that will add to blacklist
     * Emits an {AddedBlackList} event.
     */
    function addBlackList(address _evilUser) public onlyOwner {
        isBlackListed[_evilUser] = true;
        emit AddedBlackList(_evilUser);
    }

    /**
     * @notice Remove suspicious account from blacklist.
     * @dev Function to remove suspicious account from blacklist, 
     * Only callable by contract owner.
     * @param _clearedUser The address that will remove from blacklist
     * Emits an {RemovedBlackList} event.
     */
    function removeBlackList(address _clearedUser) public onlyOwner {
        isBlackListed[_clearedUser] = false;
        emit RemovedBlackList(_clearedUser);
    }

    /**
     * @notice Address blacklisted check.
     * @dev Function to check address whether get blacklisted, 
     * Only callable by contract owner.
     * @param addr The address that will check whether get blacklisted
     */
    function getBlacklist(address addr) public onlyOwner view returns(bool) {
        return isBlackListed[addr];
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}