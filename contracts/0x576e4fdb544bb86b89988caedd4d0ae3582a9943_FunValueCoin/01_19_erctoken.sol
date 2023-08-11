// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract FunValueCoin is ERC20, Ownable, ReentrancyGuard, Pausable, AccessControl {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    using Address for address payable;

    bytes32 public constant UPDATE_TAX_ROLE = keccak256("UPDATE_TAX_ROLE");
    bytes32 public constant RECOVER_TOKEN_ROLE = keccak256("RECOVER_TOKEN_ROLE");
    bytes32 public constant WITHDRAW_ETHER_ROLE = keccak256("WITHDRAW_ETHER_ROLE");
    bytes32 public constant TAX_EXEMPTION_ROLE = keccak256("TAX_EXEMPTION_ROLE");

    // Constants
    uint256 constant MAX_TAX = 5;
    uint256 constant PERCENT_DENOMINATOR = 100;

    // Tax flag
    bool public isTaxEnabled = true;

    // Tax rates
    uint256 public rewardTax = 1;
    uint256 public marketingTax = 1;
    uint256 public burnTax = 1;

    // Reward and marketing addresses
    address public rewardAddress;
    address public marketingAddress;

    // Tax-exempt addresses
    mapping(address => bool) public isTaxExempt;

    // Total supply of tokens
    uint256 private _totalSupply = 1000000000 * 10**18;

    // Events
    event TaxTransferred(address indexed to, uint256 value);
    event AddressesUpdated(address indexed rewardAddress, address indexed marketingAddress);
    event TaxRatesUpdated(uint256 rewardTax, uint256 marketingTax, uint256 burnTax);
    event EtherWithdrawn(address to, uint256 value);
    event TokensRecovered(address tokenAddress, uint256 amount);
    event TaxStatusToggled(bool isTaxEnabled);
    event TaxExemptionChanged(address indexed account, bool isTaxExempt);

    constructor(address _rewardAddress, address _marketingAddress) ERC20("FunValueCoin", "FVC") {
        require(_rewardAddress != address(0) && _marketingAddress != address(0), "Cannot use zero address");
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(UPDATE_TAX_ROLE, msg.sender);
        _setupRole(RECOVER_TOKEN_ROLE, msg.sender);
        _setupRole(WITHDRAW_ETHER_ROLE, msg.sender);
        _setupRole(TAX_EXEMPTION_ROLE, msg.sender);

        // Assign addresses
        rewardAddress = _rewardAddress;
        marketingAddress = _marketingAddress;

        // Mint total supply to the contract's owner
        _mint(msg.sender, _totalSupply);
    }

    function addTaxExemptAddress(address _address) external onlyRole(TAX_EXEMPTION_ROLE) {
        require(_address != address(0), "Cannot use zero address");
        require(!isTaxExempt[_address], "Address is already tax exempt");

        isTaxExempt[_address] = true;
        emit TaxExemptionChanged(_address, true);
    }

    function removeTaxExemptAddress(address _address) external onlyRole(TAX_EXEMPTION_ROLE) {
        require(_address != address(0), "Cannot use zero address");
        require(isTaxExempt[_address], "Address is not tax exempt");

        isTaxExempt[_address] = false;
        emit TaxExemptionChanged(_address, false);
    }

    function pause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

    function _transfer(address sender, address recipient, uint256 amount) internal override nonReentrant whenNotPaused {
        require(sender != address(0) && recipient != address(0), "Cannot transfer from/to zero address");
        require(rewardTax.add(marketingTax).add(burnTax) <= MAX_TAX, "Sum of taxes must not exceed 5");
        
        uint256 sendAmount = amount;
        
        if (isTaxEnabled && !isTaxExempt[sender]) {
            uint256 taxSum = rewardTax.add(marketingTax).add(burnTax);
            uint256 taxAmount = amount.mul(taxSum).div(PERCENT_DENOMINATOR);

            sendAmount = amount.sub(taxAmount);
        
            uint256 rewardTaxAmount = taxAmount.mul(rewardTax).div(taxSum);
            uint256 marketingTaxAmount = taxAmount.mul(marketingTax).div(taxSum);
            uint256 burnTaxAmount = taxAmount.mul(burnTax).div(taxSum);

            // Reward Tax
            super._transfer(sender, rewardAddress, rewardTaxAmount);
            emit TaxTransferred(rewardAddress, rewardTaxAmount);

            // Marketing Tax
            super._transfer(sender, marketingAddress, marketingTaxAmount);
            emit TaxTransferred(marketingAddress, marketingTaxAmount);

            // Burn Tax
            _burn(sender, burnTaxAmount);
        }

        super._transfer(sender, recipient, sendAmount);
    }

    function recoverERC20Tokens(address tokenAddress, uint256 tokenAmount) external onlyRole(RECOVER_TOKEN_ROLE) whenNotPaused {
        require(tokenAddress != address(this), "Cannot withdraw the contract's own tokens");
        uint256 contractBalance = IERC20(tokenAddress).balanceOf(address(this));
        require(tokenAmount <= contractBalance, "Cannot withdraw more tokens than the contract's balance");

        IERC20(tokenAddress).safeTransfer(msg.sender, tokenAmount);

        emit TokensRecovered(tokenAddress, tokenAmount);
    }

    function withdrawEther(address payable recipient, uint256 amount) external onlyRole(WITHDRAW_ETHER_ROLE) whenNotPaused {
        require(address(this).balance >= amount, "Not enough Ether in contract to perform withdrawal");
        recipient.sendValue(amount);
        emit EtherWithdrawn(recipient, amount);
    }

    function toggleTax() external onlyRole(DEFAULT_ADMIN_ROLE) {
        isTaxEnabled = !isTaxEnabled;
        emit TaxStatusToggled(isTaxEnabled);
    }

    // Function to receive Ether. msg.data must be empty
    receive() external payable {}
}