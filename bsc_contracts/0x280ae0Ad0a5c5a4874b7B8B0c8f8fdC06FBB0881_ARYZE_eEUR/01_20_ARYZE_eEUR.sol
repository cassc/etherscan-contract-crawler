// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "./eEUR_AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

import "./WhitelistUpgradeable.sol";

/**
 * @dev ARYZE_eEUR token
 */
/// @custom:security-contact [email protected] /Jodi
 contract ARYZE_eEUR is
    Initializable,
    ERC20Upgradeable,
    ERC20BurnableUpgradeable,
    PausableUpgradeable,
    AccessControlUpgradeable,
    UUPSUpgradeable,
    WhitelistUpgradeable
{
    /**
     * @dev Define roles
     */
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    /**
     * @dev Default address for roles
     */
    address private multiSigTreasury;

    mapping(string => bool) private _transactions; // Bridge transactions for prevent recurrence of the transaction
    /**
     * @dev Emitted when the bridge transaction is triggered by BridgeOwner
     */
    event Reforged(address indexed account, uint256 amount);
    /**
     * @dev Emitted when the bridge transaction is triggered by `account`.
     */
    event SentToChain(address indexed account, uint256 amount, uint256 fromChainId, uint256 indexed destinationChainId);
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event BridgePaused(address account);
    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event BridgeUnpaused(address account);
    /**
     * @dev Define bridge owner role
     */
    bytes32 public constant BRIDGE_OWNER_ROLE = keccak256("BRIDGE_OWNER_ROLE");
    /**
     * @dev bridge owner. Should be payable to receive transaction fee
     */
    address payable private _bridgeOwner;
    /**
     * @dev Bridge transactions fee
     */
    uint256 private _minimumBridgeFee;
    /**
     * @dev Bridge transactions fee
     */
    bool private _bridgePaused;

    function initialize() public initializer {
        __ERC20_init("ARYZE eEUR", "eEUR");
        __ERC20Burnable_init();
        __Pausable_init();
        __AccessControl_init();
        __UUPSUpgradeable_init();

         multiSigTreasury = 0x427001B0783547D7B71DA4e9E6DFb09F7A621ca7;
    /**
     *  Deploying the contract requires msg.sender being admin, to create proxy adress while doing deployment.
     */
        _grantRole(ADMIN_eEUR, msg.sender);
        _grantRole(ADMIN_eEUR, multiSigTreasury);
        _grantRole(PAUSER_ROLE, multiSigTreasury);
        _grantRole(MINTER_ROLE, multiSigTreasury);
        _grantRole(UPGRADER_ROLE, multiSigTreasury);
        setBridgeOwner(payable(multiSigTreasury));
        setMinimumFee(0);
    }

    /**
     * @dev Pause functions that marked by "whenNotPaused" modificator
     */
    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    /**
     * @dev Unpause functions that marked by "whenNotPaused" modificator
     */
    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    /**
     * @dev Mint tokens to address
     * @param to address of recipient
     * @param amount amount of tokens for minting
     */
    function mint(address to, uint256 amount) public onlyRole(MINTER_ROLE) {
        require(_whitelist[to], "Address is not in whitelist");
        _mint(to, amount);
    }

    /**
     * @dev override hook that will be called before tranferring funds.
     * Added "whenNotPaused" modificator which is needed for pause/unpause functionality
     * @param from address of sender
     * @param to address of recipient
     * @param amount amount of tokens for transferring
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override whenNotPaused {
        super._beforeTokenTransfer(from, to, amount);
    }

    /**
     * @dev An upgradeability mechanism designed for UUPS proxies.
     * This function is overriden to include access restriction to the upgrade mechanism.
     */
    function _authorizeUpgrade(address newImplementation) internal override onlyRole(UPGRADER_ROLE) {}

    /**
     * @dev Function add address to whitelist, which is used for storing customers allowed to receive minted tokens
     * @param account address which will be added to whitelist
     */
    function addToWhitelist(address account) public onlyRole(ADMIN_eEUR) {
        _addToWhitelist(account);
    }

    /**
     * @dev Function remove address from whitelist, which is used for storing customers allowed to receive minted tokens
     * @param account address which will be removed to whitelist
     */
    function removeFromWhitelist(address account) public onlyRole(ADMIN_eEUR) {
        _removeFromWhitelist(account);
    }

    /**
     * @dev Mint tokens to account by Bridge
     * @param to `address`, token will be burned from
     * @param amount `amount` of token that will be burned
     */
    function reforge(
        address to,
        uint256 amount,
        uint256 fee,
        string memory transaction
    ) public onlyRole(BRIDGE_OWNER_ROLE) onlyRole(MINTER_ROLE) {
        require(_transactions[transaction] == false, "Already processed!");
        _mint(to, amount);
        _mint(_bridgeOwner, fee);
        _transactions[transaction] = true;
        emit Reforged(to, amount);
    }

    /**
     * @dev Burn tokens from account and emit event for Bridge
     * @param amount `amount` of token that will be burned
     * @param destinationChainId bridge will reforge token on this chain
     */
    function sendToChain(uint256 amount, uint256 destinationChainId) public payable {
        require(_bridgePaused == false, "Bridge paused");
        require(msg.value >= _minimumBridgeFee, "Fee too small");
        burn(amount);
        _bridgeOwner.transfer(msg.value);
        emit SentToChain(msg.sender, amount, block.chainid, destinationChainId);
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function bridgePaused() public view returns (bool) {
        return _bridgePaused;
    }

    /**
     * @dev Triggers stopped state.
     */
    function bridgePause() public onlyRole(ADMIN_eEUR) {
        require(_bridgePaused == false, "Bridge paused");
        _bridgePaused = true;
        emit BridgePaused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     */
    function bridgeUnpause() public onlyRole(ADMIN_eEUR) {
        require(_bridgePaused, "Bridge not paused");
        _bridgePaused = false;
        emit BridgeUnpaused(_msgSender());
    }

    /**
     * @dev set minimum value of bridge transaction fee
     */
    function setMinimumFee(uint256 fee) public onlyRole(ADMIN_eEUR) {
        _minimumBridgeFee = fee;
    }

    /**
     * @dev get minimum value of bridge transaction fee
     */
    function minimumFee() public view returns (uint256) {
        return _minimumBridgeFee;
    }

    /**
     * @dev Set up bridgeOwner
     * @param account address of new bridgeOwner
     */
    function setBridgeOwner(address payable account) public onlyRole(ADMIN_eEUR) {
        require(account != address(0));
        _revokeRole(BRIDGE_OWNER_ROLE, _bridgeOwner);
        _revokeRole(MINTER_ROLE, _bridgeOwner);
        _bridgeOwner = account;
        _grantRole(BRIDGE_OWNER_ROLE, _bridgeOwner);
        _grantRole(MINTER_ROLE, _bridgeOwner);
    }
    
}