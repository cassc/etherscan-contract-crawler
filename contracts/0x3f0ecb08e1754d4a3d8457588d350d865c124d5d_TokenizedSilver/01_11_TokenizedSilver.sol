// contracts/TokenizedSilver.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";

contract TokenizedSilver is ERC20PausableUpgradeable, OwnableUpgradeable {
    using SafeMathUpgradeable for uint256;

    modifier onlyMinter() {
        require(
            minterAddress == msg.sender,
            "TokenizedSilver: Only the minter contract can call this function"
        );
        _;
    }
    event ForceTransfer(address indexed from, address indexed to, uint256 value, bytes32 details);
    event MinterAddressChanged(address indexed minterAddress);
    event FeeCollectionAddressChanged(address indexed feeCollectionAddress);
    event MaximumTransferFeeChanged(uint256 maximumTransferFee);
    event AddressWhitelisted(address indexed account, uint256 level);
    event ReceiverAddressWhitelisted(address indexed account, uint256 level);

    /*
     * feeAdded
     * 0 = deducted from the amount (receiver gets less)
     * 1 = added to the amount
     */
    struct TransferFeeData { 
        uint256 feeInMpip;
        uint feeAdded;
    }
    
    uint256 private constant MPIP_DIVIDER = 10000000;
    uint constant public LOCKED = 100;

    address public minterAddress;
    address public feeCollectionAddress;
    mapping(address => uint256) private _balances;     
    mapping (address => mapping (uint => uint256)) public whitelist;
    mapping (uint256 => TransferFeeData) public transferFee;
    uint256 public maximumTransferFee;

    /*
     * Initialize upgradeable contract. Can only call once
     */
    function initialize(string memory name_, string memory symbol_) public initializer {
        __ERC20_init(name_, symbol_);
        __Ownable_init_unchained();
    }

    
    /*
     * Set the minter (contract) address
     */
    function setMinterAddress(address minterAddress_) external onlyOwner {
        require(minterAddress_ != address(0), "Cannot set the minter address to null");
        minterAddress = minterAddress_;
        emit MinterAddressChanged(minterAddress_);
    }            

    /*
     * Whitelist account to a level. Applies for sender or receiver as following:
     * direction = 0 (sender)
     * direction = 1 (receiver)
     */
    function whitelistAddress(address account_, uint256 level_, uint direction_) external onlyOwner {
        whitelist[account_][direction_] = level_;
        emit ReceiverAddressWhitelisted(account_, level_);
    }

    /*
     * Set a fee level. The fee is in MPIP_DIVIDER and and feeAdded is as following:
     * 0 = fee is deducted from the amount (recipient receives less than amount)
     * 1 = fee is added to the amount (sender pays more than amount)
     */
    function setFeeForLevel(uint256 level_, uint256 fee_, uint feeAdded_) external onlyOwner {
        transferFee[level_] = TransferFeeData(
            fee_,
            feeAdded_
        );
    } 

    /*
     * Set the fee collection address
     */
    function setFeeCollectionAddress(address feeCollectionAddress_) external onlyOwner {
        require(feeCollectionAddress_ != address(0), "Cannot set the fee collection wallet to null");
        feeCollectionAddress = feeCollectionAddress_;
        emit FeeCollectionAddressChanged(feeCollectionAddress_);
    }

    /*
     * Retrieve the fee collection address
     */
    function getFeeCollectionAddress() external view returns (address) {
        return feeCollectionAddress;
    }

    /*
     * Set the maximum transfer fee. If is 0, then no maximum transfer fee is used.
     */
    function setMaximumTransferFee(uint256 maximumTransferFee_) external onlyOwner {
        maximumTransferFee = maximumTransferFee_;
        emit MaximumTransferFeeChanged(maximumTransferFee_);
    }

    /*
     * Pause transfers
     */
    function pauseTransfers() external onlyOwner {
        _pause();
    }    

    /*
     * Resume transfers
     */
    function resumeTransfers() external onlyOwner {
        _unpause();
    }  

    /*
     * Force transfer callable by owner (governance).
     */ 
    function forceTransfer(address sender_, address recipient_, uint256 amount_, bytes32 details_) external onlyOwner {
        _burn(sender_,amount_);
        _mint(recipient_,amount_);
        emit ForceTransfer(sender_, recipient_, amount_, details_);
    }

    /*
     * Mint tokens, callable by minter
     */
    function mintTokens(uint256 amount_) external onlyMinter {
        _mint(minterAddress, amount_);
    }

    /*
     * Burn tokens, callable by minter
     */
    function burnTokens(uint256 amount_) external onlyMinter {
        _burn(minterAddress, amount_);
    }

    /*
     * Override _transfer function to add transfer fee.
     */
    function _transfer(address sender, address recipient, uint256 amount) override (ERC20Upgradeable) internal whenNotPaused {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        uint256 senderLevel = whitelist[sender][0];
        uint256 recipientLevel = whitelist[recipient][1];
        require(senderLevel != LOCKED && recipientLevel != LOCKED, "Sender or recipient is blacklisted");

        if (recipientLevel != 0) { // Fee is based on receiver level. He pays the fee
            TransferFeeData memory recipientFeeData = transferFee[recipientLevel];
            uint256 feeAmount = recipientFeeData.feeInMpip.mul(amount).div(MPIP_DIVIDER);
            if (feeAmount > maximumTransferFee && maximumTransferFee > 0) {
                feeAmount = maximumTransferFee;
            }

            super._transfer(sender, recipient, amount);
            if (feeAmount > 0) {
                super._transfer(recipient, feeCollectionAddress, feeAmount);
            }
        } else {
            TransferFeeData memory senderFeeData = transferFee[senderLevel];
            uint256 feeAmount = transferFee[senderLevel].feeInMpip.mul(amount).div(MPIP_DIVIDER);
            if (feeAmount > maximumTransferFee && maximumTransferFee > 0) {
                feeAmount = maximumTransferFee;
            }

            if (senderFeeData.feeAdded == 0) { // fee is deducted from the tranfer amount
                super._transfer(sender, recipient, amount.sub(feeAmount));                
            } else if (senderFeeData.feeAdded == 1) { // fee is added to the transfer amount
                super._transfer(sender, recipient, amount);                
            }

            if (feeAmount > 0) { 
                super._transfer(sender, feeCollectionAddress, feeAmount);
            }
        }
    }    
}