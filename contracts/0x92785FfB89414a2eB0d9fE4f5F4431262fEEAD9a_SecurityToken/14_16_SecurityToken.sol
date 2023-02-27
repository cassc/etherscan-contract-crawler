// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "oz-upgradeable/contracts/token/ERC20/ERC20Upgradeable.sol";
import "oz-upgradeable/contracts/security/PausableUpgradeable.sol";
import "oz-upgradeable/contracts/access/AccessControlUpgradeable.sol";
import "./utils/Freezable.sol";
import "./utils/TokenInfo.sol";

contract SecurityToken is
    Initializable,
    ERC20Upgradeable,
    PausableUpgradeable,
    AccessControlUpgradeable,
    FreezableUpgradeable,
    SecurityTokenInfoUpgradeable
{
    uint256 public constant INITIAL_SUPPLY = 1_000_000;
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");
    bytes32 public constant FREEZER_ROLE = keccak256("FREEZER_ROLE");
    bytes32 public constant TAINTER_ROLE = keccak256("TAINTER_ROLE");
    bytes32 public constant DOC_MANAGER = keccak256("DOC_MANAGER");
    bytes32 public constant NOTIFIER_ROLE = keccak256("NOTIFIER_ROLE");

    mapping(address => uint256) private tainted;
    mapping(address => bool) private dividends;

    //this overrides the default ERC20 transfer event to facilitate the tracking of balances
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 value,
        uint256 balanceFromBefore,
        uint256 balanceFromAfter,
        uint256 balanceToBefore,
        uint256 balanceToAfter
    );
    event Tainted(
        address indexed account,
        uint256 prevTaintedAmt,
        uint256 newTaintedAmt,
        string reason
    );
    event Untainted(
        address indexed account,
        uint256 prevTaintedAmt,
        uint256 newTaintedAmt,
        string reason
    );
    event DividendsOptedIn(address indexed account);
    event DividendsOptedOut(address indexed account);
    event Notification(string indexed topic, string message);

    error AccountFrozen(address account);
    error CannotTransferTaintedTokens(address account, uint256 amountTainted, uint256 amountToTransfer);

    constructor() {
        _disableInitializers();
    }

    function initialize(address initialSharesHolder, address administrator) initializer public {
        __ERC20_init("BinarySwap Holding Token-Share", "BNCH");
        __Pausable_init();
        __AccessControl_init();
        __SecurityTokenInfo_init();
        __Freezable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender); //will be revoked later - needed to set the terms
        _grantRole(DEFAULT_ADMIN_ROLE, administrator);
        _grantRole(PAUSER_ROLE, administrator);
        _grantRole(MINTER_ROLE, administrator);
        _grantRole(BURNER_ROLE, administrator);
        _grantRole(FREEZER_ROLE, administrator);
        _grantRole(TAINTER_ROLE, administrator);
        _grantRole(DOC_MANAGER, administrator);
        _grantRole(NOTIFIER_ROLE, administrator);

        //intial supply
        _mint(initialSharesHolder, INITIAL_SUPPLY * 10 ** decimals());
    }

    /**
     * @notice Allows a pauser to disable transfers
     */
    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    /**
     * @notice Allows a pauser to re-enable transfers
     */
    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    /**
     * @notice Allows a minter to mint tokens to an account
     * @param to the account to mint tokens to
     * @param amount the amount of tokens to mint
     */
    function mint(address to, uint256 amount) public onlyRole(MINTER_ROLE) {
        _mint(to, amount);
    }

    /**
     * @notice Allows a burner to burn tokens from an account
     * @param from the account from which to burn tokens
     * @param amount the amount of tokens to burn
     */
    function burn(address from, uint256 amount) public onlyRole(BURNER_ROLE) {
        _burn(from, amount);
    }

    // Security token => 0 decimals
    function decimals() public pure override returns (uint8) {
        return 0;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override whenNotPaused {
        //check if accounts are frozen
        if (frozen(from)) {
            revert AccountFrozen(from);
        }
        if (frozen(to)) {
            revert AccountFrozen(to);
        }
        //check if tokens are tainted
        if (amount > availableTokens(from)) {
            revert CannotTransferTaintedTokens(from, tainted[from], amount);
        }
        super._beforeTokenTransfer(from, to, amount);
    }

    /**
     * @notice This overrides the default ERC20 transfer event to facilitate the tracking of balances
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        uint256 balanceFromBefore = balanceOf(from);
        uint256 balanceToBefore = balanceOf(to);
        super._transfer(from, to, amount); //inherited from ERC20
        uint256 balanceFromAfter = balanceOf(from);
        uint256 balanceToAfter = balanceOf(to);
        emit Transfer(
            from,
            to,
            amount,
            balanceFromBefore,
            balanceFromAfter,
            balanceToBefore,
            balanceToAfter
        );
    }

    /**
     * @notice Freezes an address
     * @param account The account to freeze
     * @param reason Indicate why the account was frozen
     */
    function freezeAccount(
        address account,
        string calldata reason
    ) public onlyRole(FREEZER_ROLE) returns (bool) {
        return _freeze(account, reason);
    }

    /**
     * @notice Unfreezes an address
     * @param account The account to unfreeze
     * @param reason Indicate why the account was unfrozen
     */
    function unfreezeAccount(
        address account,
        string calldata reason
    ) public onlyRole(FREEZER_ROLE) returns (bool) {
        return _unfreeze(account, reason);
    }

    /**
     * @notice Returns the amount of tainted tokens for an account
     * @param account the account to check 
     */
    function taintedTokens(address account) public view returns (uint256) {
        return tainted[account];
    }


    /** 
     * @notice Allows a tainter to taint tokens for an account
     * @param account  the account for which to taint tokens
     * @param amount the amount of tokens to taint
     * @param reason the reason for tainting the tokens
     */
    function taintTokens(
        address account,
        uint256 amount,
        string calldata reason
    ) public onlyRole(TAINTER_ROLE) returns (uint256) {
        if (account == address(0)) {
            revert InvalidAccount(account);
        }
        uint256 prevTaintedAmt = tainted[account];
        uint256 newTaintedAmt = tainted[account] += amount;
        emit Tainted(account, prevTaintedAmt, newTaintedAmt, reason);
        return newTaintedAmt;
    }

    /**
     * @notice Allows a tainter to untaint tokens for an account
     * @param account the account for which to untaint tokens
     * @param amount the amount of tokens to untaint
     * @param reason the reason for untainting the tokens
     */
    function untaintTokens(
        address account,
        uint256 amount,
        string calldata reason
    ) public onlyRole(TAINTER_ROLE) returns (uint256) {
        if (amount > tainted[account]) {
            //cannot untaint more than previously tainted
            amount = tainted[account];
        }
        uint256 prevTaintedAmt = tainted[account];
        uint256 newTaintedAmount = tainted[account] -= amount;
        emit Untainted(account, prevTaintedAmt, newTaintedAmount, reason);
        return newTaintedAmount;
    }

    /**
    * @notice Allows the admin to set the terms
    * @param termsURI_ the URI corresponding to the terms of the token
    * @param termsHash_ the SHA-256 hash of the terms
    */
    function setTerms(string calldata termsURI_, bytes32 termsHash_) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _setTerms(termsURI_,termsHash_);
    }

    /**
     * @notice Allows a document manger to set a document
     * @param documentName the name of the document
     * @param uri the uri of the document
     * @param documentHash the SHA-256 hash of the document
     */
    function setDocument(
        bytes32 documentName,
        string calldata uri,
        bytes32 documentHash
    ) external onlyRole(DOC_MANAGER) {
        _setDocument(documentName, uri, documentHash);
    }

    /**
     * @notice Allows a document manager to remove a document
     * @param documentName the name of the document to remove
     */
    function removeDocument(
        bytes32 documentName
    ) external onlyRole(DOC_MANAGER) {
        _removeDocument(documentName);
    }

    /**
     * @notice Returns the amount of transferable tokens for an account 
     * @param account the account to check 
     */
    function availableTokens(address account) public view returns (uint256) {
        if (account == address(0)) {
            //mint / burn 
            return type(uint256).max;
        }
        if (tainted[account] >= balanceOf(account)) {
            return 0;
        } else {
            return balanceOf(account) - tainted[account];
        }
    }

    /**
     * @notice Allows an address to opt in for dividends
     */
    function optInDividends() public {
        dividends[msg.sender] = true;
        emit DividendsOptedIn(msg.sender);
    }

    /**
     * @notice Allows an address to opt out of dividends
     */
    function optOutDividends() public {
        dividends[msg.sender] = false;
        emit DividendsOptedOut(msg.sender);
    }

    /**
     * @notice Returns whether an address has opted in for dividends
     * @param account the account to check
     */
    function isOptedInDividends(address account) public view returns (bool) {
        return dividends[account];
    }

    function notify(string calldata topic, string calldata message) external onlyRole(NOTIFIER_ROLE) {
        emit Notification(topic, message);
    }
}