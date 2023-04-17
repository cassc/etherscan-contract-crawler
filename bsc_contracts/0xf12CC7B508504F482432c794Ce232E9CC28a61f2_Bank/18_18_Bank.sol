// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";

contract Bank is Initializable, PausableUpgradeable, OwnableUpgradeable, ReentrancyGuardUpgradeable, UUPSUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    event AccountFrozen(address indexed account);
    event AccountUnfrozen(address indexed account);
    event Deposited(address indexed account, uint256 usdt);
    event WithdrawAuthorized(address indexed account, uint256 usdt, bytes auth_code);
    event Withdrawn(address indexed account, uint256 usdt);

    address constant public ZERO_ADDRESS = address(0);
    address constant public WITHDRAW_AUTH_SIGNER = 0xe056c19Fb83d63B7c182F528e0e888C5723AaF19;
    uint256 constant public WITHDRAW_AUTH_COOLDOWN = 30 minutes;
    uint256 constant public USDT_MIN_DEPOSIT = 1 ether;

    mapping(address => uint256) public accounts_usdt;
    mapping(address => uint256) public accounts_cooldown;
    mapping(address => bool) public accounts_frozen;
    mapping(bytes => address) public auth_codes_used;

    IERC20Upgradeable constant USDT = IERC20Upgradeable(0x55d398326f99059fF775485246999027B3197955);
    
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() initializer public {
        __Pausable_init();
        __Ownable_init();
        __ReentrancyGuard_init();
        __UUPSUpgradeable_init();
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function freeze(address account) public onlyOwner {
        require(accounts_frozen[account] == false, "ACCOUNT_FROZEN");

        accounts_frozen[account] = true;

        emit AccountFrozen(account);
    }

    function unfreeze(address account) public onlyOwner {
        require(accounts_frozen[account] == true, "ACCOUNT_NOT_FROZEN");

        accounts_frozen[account] = false;

        emit AccountUnfrozen(account);
    }

    function deposit(address account, uint256 amount) public nonReentrant whenNotPaused {
        _checkValidSender(account);

        require(amount >= USDT_MIN_DEPOSIT, "USDT_MIN_DEPOSIT");

        USDT.safeTransferFrom(account, address(this), amount);
        
        emit Deposited(account, amount);
    }

    function authorizeWithdraw(address account, uint256 amount, bytes calldata auth_code, bytes calldata auth_signature) public nonReentrant whenNotPaused {
        _checkValidSender(account);

        require(auth_codes_used[auth_code] == ZERO_ADDRESS, "AUTH_CODE_USED");

        bytes32 auth = ECDSAUpgradeable.toEthSignedMessageHash(keccak256(abi.encode(account, amount, auth_code)));
        address recovered = ECDSAUpgradeable.recover(auth, auth_signature);

        require(recovered == WITHDRAW_AUTH_SIGNER, "AUTH_SIGNATURE_INVALID");

        accounts_usdt[account] = accounts_usdt[account] + amount;
        accounts_cooldown[account] = block.timestamp + WITHDRAW_AUTH_COOLDOWN;
        auth_codes_used[auth_code] = account;

        emit WithdrawAuthorized(account, amount, auth_code);
    }

    function withdraw(address account, uint256 amount) public nonReentrant whenNotPaused {
        _checkValidSender(account);
        
        require(accounts_cooldown[account] <= block.timestamp, "ACCOUNT_IN_COOLDOWN");
        require(accounts_usdt[account] >= amount, "ACCOUNT_USDT_NOT_ENOUGH");

        accounts_usdt[account] = accounts_usdt[account] - amount;

        USDT.safeTransfer(account, amount);

        emit Withdrawn(account, amount);
    }

    function _checkValidSender(address account) internal view {
        require(_msgSender() == account, "SENDER_NOT_ACCOUNT");
        require(accounts_frozen[account] == false, "ACCOUNT_FROZEN");
    }
    
    function _authorizeUpgrade(address new_implementation) internal onlyOwner override {}
}