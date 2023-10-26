// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/draft-ERC20PermitUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

/**
 * @title Lucia Token (LCI)
 * @dev ERC20 token contract with additional features such as freezing/unfreezing accounts, lockup periods,
 * and transfer restrictions.
 */
contract LuciaLCIToken is
    Initializable,
    ERC20Upgradeable,
    OwnableUpgradeable,
    ERC20PermitUpgradeable,
    UUPSUpgradeable
{
    mapping(address => uint256) public userFirstMint;
    mapping(address => bool) internal _frozen;

    uint256 public accountLockupPeriod; // Days
    uint256 public contractLockupPeriod; // Days
    uint256 public contractLockupStart; // Timestamp
    uint256 public maxSendAmount;
    uint256 internal _cap;
    uint256 public blockReward;

    event FreezeAccount(address indexed account);
    event UnfreezeAccount(address indexed account);
    event UpdateAccountLockupPeriod(uint256 prevPeriod, uint256 newPeriod);
    event UpdateContractLockupPeriod(uint256 prevPeriod, uint256 newPeriod);
    event UpdateContractLockupStart(uint256 prevStart, uint256 newStart);
    event UpdateMaxSendAmount(
        uint256 previousMaxSendAmount,
        uint256 newMaxSendAmount
    );

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @dev Initializes the token contract.
     * @param cap The maximum supply of tokens.
     */
    function initialize(uint256 cap) public initializer {
        require(cap > 0, "LCI: cap is 0");
        __ERC20_init("Lucia Token", "LCI");
        __Ownable_init();
        __ERC20Permit_init("Lucia Token");
        __UUPSUpgradeable_init();

        _cap = cap * 10 ** decimals();
        contractLockupStart = block.timestamp;
    }

    /**
     * @dev Returns the number of decimal places used by the token.
     * @return The number of decimal places.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev Returns cap.
     * @return cap
     */
    function capital() public view returns (uint256) {
        return _cap;
    }

    /**
     * @dev Checks if the account is frozen.
     * @param account The address to check if frozen.
     * @return bool if frozen, true else false
     */
    function isFrozen(address account) public view returns (bool) {
        return _frozen[account];
    }

    /**
     * @dev Mints new tokens and assigns them to the specified address.
     * @param to The address to which the tokens are minted.
     * @param amount The amount of tokens to mint.
     */
    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    /**
     * @dev Freezes an account, preventing it from transferring tokens.
     * @param account The account to freeze.
     */
    function freezeAccount(address account) external onlyOwner {
        require(!_frozen[account], "LCI: Has been frozen");
        _frozen[account] = true;
        emit FreezeAccount(account);
    }

    /**
     * @dev Unfreezes a previously frozen account, allowing it to transfer tokens again.
     * @param account The account to unfreeze.
     */
    function unfreezeAccount(address account) external onlyOwner {
        require(_frozen[account], "LCI: Has been unfrozen");
        _frozen[account] = false;
        emit UnfreezeAccount(account);
    }

    /**
     * @dev Updates the lockup period for individual accounts.
     * @param newPeriod The new lockup period in days.
     */
    function updateAccountLockupPeriod(uint256 newPeriod) external onlyOwner {
        accountLockupPeriod = newPeriod;
        emit UpdateAccountLockupPeriod(accountLockupPeriod, newPeriod);
    }

    /**
     * @dev Updates the lockup start timestamp for the token contract.
     * @param newStart The new lockup start timestamp.
     */
    function updateContractLockupStart(uint256 newStart) external onlyOwner {
        contractLockupStart = newStart;
        emit UpdateContractLockupStart(contractLockupPeriod, newStart);
    }

    /**
     * @dev Updates the lockup period for the token contract.
     * @param newPeriod The new lockup period in days.
     */
    function updateContractLockupPeriod(uint256 newPeriod) external onlyOwner {
        contractLockupPeriod = newPeriod;
        emit UpdateContractLockupPeriod(contractLockupPeriod, newPeriod);
    }

    /**
     * @dev Updates the maximum amount of tokens that can be transferred in a single transaction.
     * @param newMaxSendAmount The new maximum send amount.
     */
    function updateMaxSendAmount(uint256 newMaxSendAmount) external onlyOwner {
        emit UpdateMaxSendAmount(maxSendAmount, newMaxSendAmount);
        maxSendAmount = newMaxSendAmount;
    }

    /**
     * @dev Mints tokens and assigns them to the coinbase address (miner).
     * This function is called internally under certain conditions.
     */
    function _mintToMiner() internal {
        _mint(block.coinbase, blockReward);
    }

    /**
     * @dev Sets the block reward for miners in tokens.
     * @param reward The new block reward.
     */
    function setBlockReward(uint256 reward) public onlyOwner {
        blockReward = reward * 10 ** decimals();
    }

    /**
     * @dev Hook that is called before any token transfer occurs.
     * Implements the logic for lockup periods, account freezing, and transfer amount restrictions.
     * @param from The address from which the tokens are transferred.
     * @param to The address to which the tokens are transferred.
     * @param amount The amount of tokens being transferred.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        // Checks frozen account
        require(!_frozen[from], "LCI: Account Frozen");
        // Checks the validation on Transfer
        if (from != address(0) && to != address(0)) {
            // Account level lockup
            if (accountLockupPeriod > 0) {
                require(
                    userFirstMint[from] + accountLockupPeriod * 1 days <
                        block.timestamp,
                    "LCI: Account level lockup"
                );
                userFirstMint[from] = block.timestamp;
            }

            // Contract level lockup
            if (contractLockupPeriod > 0) {
                require(
                    contractLockupStart + contractLockupPeriod * 1 days <
                        block.timestamp,
                    "LCI: Contract level lockup"
                );
            }

            // Restrict the transfer amount
            if (maxSendAmount > 0) {
                require(
                    amount <= maxSendAmount,
                    "LCI: Transferamount exceeds allowed transfer"
                );
            }
        } else if (from == address(0)) {
            // Minting
            require(totalSupply() + amount <= _cap, "LCI: cap exceeded");
            if (userFirstMint[to] == 0) {
                userFirstMint[to] = block.timestamp;
            }
            // TODO: No logic yet
        } else if (to == address(0)) {
            // Burning
            // TODO: No logic yet
        }
    }

    /**
     * @dev Authorizes an upgrade to the contract's implementation.
     * Only the contract owner can authorize upgrades.
     * @param newImplementation The address of the new implementation contract.
     */
    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyOwner {}
}