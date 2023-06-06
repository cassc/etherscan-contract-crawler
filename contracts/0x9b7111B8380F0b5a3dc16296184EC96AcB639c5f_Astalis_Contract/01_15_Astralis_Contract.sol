// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Astalis_Contract is ERC20Burnable, Pausable, AccessControl, Ownable {
    bytes32 public constant EMERGENCY_STOP_ROLE = keccak256("EMERGENCY_STOP_ROLE");
    uint256 private constant MAX_SUPPLY = 3141592653589 * (10**18);
    address private taxationWallet;
    uint256 private taxationPercentage;
    uint256 private burnPercentage;
    mapping(address => mapping(address => uint256)) private allowances;
    IERC20 private token;

    event TaxationWalletUpdated(address indexed previousWallet, address indexed newWallet);
    event TaxationPercentageUpdated(uint256 previousPercentage, uint256 newPercentage);
    event BurnPercentageUpdated(uint256 previousPercentage, uint256 newPercentage);
    event Pause();
    event Unpause();
    event EmergencyStop();
    event TokensBurned(address indexed burner, uint256 value);

constructor() ERC20("Astralis Finance", "AF") {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(EMERGENCY_STOP_ROLE, _msgSender());
        taxationWallet = 0x5cf38aD5b4776DfC4A64e14AB453233c865EF01E; 
        taxationPercentage = 30;   // 0.3%
        burnPercentage = 20;       // 0.2%
        
        uint256 initialSupply = 3141592653589 * (10**18); // Total supply with 18 decimals
        _mint(_msgSender(), initialSupply);
    }

//Modifiers
        modifier onlyAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Caller is not an admin");
        _;
        }

        modifier notEmergencyStopped() {
            require(!paused(), "Contract is stopped");
            _;
        }

        modifier onlyEmergencyStopper() {
            require(hasRole(EMERGENCY_STOP_ROLE, _msgSender()), "Caller is not an emergency stopper");
            _;
        }
    
// Pause and Emergency stop Functions
    function emergencyStop() external onlyEmergencyStopper {
    _pause();
    emit EmergencyStop();
    }

    function resume() external onlyEmergencyStopper {
        _unpause();
        emit Unpause();
    }

// Admins now can change the taxation percentage
    function setTaxationPercentage(uint256 percentage) external onlyAdmin {
        require(percentage <= 10000, "Taxation percentage must be less than or equal to 10000");
        emit TaxationPercentageUpdated(taxationPercentage, percentage);
        taxationPercentage = percentage;
    }

// Admins now can change the burning percentage
    function setBurnPercentage(uint256 percentage) external onlyAdmin {
        require(percentage <= 10000, "Burn percentage must be less than or equal to 10000");
        emit BurnPercentageUpdated(burnPercentage, percentage);
        burnPercentage = percentage;
    }

// The taxation/burning mechanism formula
function transfer(address to, uint256 amount) public override notEmergencyStopped returns (bool) {
    uint256 taxationAmount = (amount * taxationPercentage) / 10000;
    uint256 burnAmount = (amount * burnPercentage) / 10000;

    uint256 transferAmount = amount - taxationAmount - burnAmount;

    _transfer(_msgSender(), to, transferAmount);
    _transfer(_msgSender(), taxationWallet, taxationAmount);
    _burn(_msgSender(), burnAmount);

    emit Transfer(_msgSender(), to, transferAmount);
    emit Transfer(_msgSender(), taxationWallet, taxationAmount);
    emit TokensBurned(_msgSender(), burnAmount);

    return true;
    }

//Changing the taxation wallet
function setTaxationWallet(address wallet) external {
        require(wallet != address(0), "Taxation wallet cannot be the zero address");
        require(_msgSender() == taxationWallet, "Only the current taxation wallet can set a new wallet");
        taxationWallet = wallet;
    }

//Checking whether the contract is stopped or not before the token's transfer
function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);

        if (from != address(0) && to != address(0)) {
            require(!paused(), "Token transfer while paused");
        }
    }
}