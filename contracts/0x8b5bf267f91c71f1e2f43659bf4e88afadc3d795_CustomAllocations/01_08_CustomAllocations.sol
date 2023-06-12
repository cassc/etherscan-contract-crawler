// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;


/// Openzeppelin imports
import '@openzeppelin/contracts/access/AccessControl.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';


contract CustomAllocations is AccessControl {

    /// Constant private member variables
    uint256 private constant MONTH = 30 days;

    /// Constant public member variables
    uint256 public constant CANCELATION_PERIOD = 1 days;

    /// Public variables
    address public tokenAddress;
    uint256 public allocatedAmount = 0;
    uint256 public grandTotalClaimed = 0;

    // Private variables
    mapping(address => Allocation) private _allocations;
    address[] private _allocatedAddresses;


    /// Allocation State
    enum AllocationState {
        NotAllocated,
        Allocated,
        Canceled
    }

    /// Allocation with vesting information
    struct Allocation {
        uint256 allocationTime;                 // Locking calculated from this time
        uint256 amount;                         // Total tokens allocated
        uint256 amountClaimed;                  // Total tokens claimed
        uint256 lockupPeriod;                   // Lockup period
        uint256 vesting;                        // Vesting
        AllocationState state;                  // Allocation state
        bool cancelation;                       // Cancelation
    }


    /// Events
    event NewAllocation(address indexed recipient, uint256 amount, uint256 lockupPeriod, uint256 vesting);
    event TokenClaimed(address indexed recipient, uint256 amountClaimed);
    event CancelAllocation(address indexed allocatedAddress, address indexed recipient);


    /// Constructor
    constructor(address tokenAddress_) {

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        tokenAddress = tokenAddress_;
    }

    /// Sets allocation for the given recipient with corresponding amount.
    function setAllocation(address recipient_,
                           uint256 amount_,
                           uint256 lockupPeriod_,
                           uint256 vesting_,
                           bool cancelation_) public {

        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), 'Must have admin role to allocate');
        require(address(0x0) != recipient_, 'Recipient address cannot be 0x0');
        require(0 < amount_, 'Allocated amount must be greater than 0');
        require(0 == vesting_ % MONTH, 'vesting_ % MONTH must be 0');
        require(allocatedAmount + amount_ <= IERC20(tokenAddress).balanceOf(address(this)), 'Insufficient funds');

        Allocation storage a = _allocations[recipient_];
        require(AllocationState.Allocated != a.state, 'Recipient already has allocation');
        if (AllocationState.NotAllocated == a.state) {
            _allocatedAddresses.push(recipient_);
        }
        a.allocationTime = block.timestamp;
        a.lockupPeriod = lockupPeriod_;
        a.vesting = vesting_;
        a.amount = amount_;
        a.state = AllocationState.Allocated;
        a.cancelation = cancelation_;
        allocatedAmount += amount_;
        emit NewAllocation(recipient_, amount_, lockupPeriod_, vesting_);
    }

    /// Cancels allocation for the given recipient
    function cancelAllocation(address allocatedAddress_, address recipient_) public {

        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), 'Must have admin role to cancel allocation');
        Allocation storage a = _allocations[allocatedAddress_];
        require(block.timestamp < a.allocationTime + CANCELATION_PERIOD || a.cancelation, 'Allocation cannot be canceled');
        require(AllocationState.Allocated == a.state, 'There is no allocation');
        require(0 == a.amountClaimed, 'Cannot cancel allocation with claimed tokens');
        a.state = AllocationState.Canceled;
        allocatedAmount -= a.amount;
        require(IERC20(tokenAddress).transfer(recipient_, a.amount), 'Cannot transfer tokens');
        emit CancelAllocation(allocatedAddress_, recipient_);
    }

    /// Transfers a recipient's available allocation to their address
    function claimTokens(address recipient_) public {

        Allocation storage a = _allocations[recipient_];
        require(AllocationState.Allocated == a.state, 'There is no allocation for the recipient');
        require(a.amountClaimed < a.amount, 'Allocations have already been transferred');

        uint256 newPercentage = 0;
        if (block.timestamp > a.allocationTime + a.lockupPeriod) {
            if (block.timestamp > a.allocationTime + a.lockupPeriod + a.vesting) {
                newPercentage = 100;
            } else {
                uint256 n = a.vesting / MONTH; // a.vesting % MONTH == 0
                newPercentage = (((block.timestamp - (a.allocationTime + a.lockupPeriod)) / MONTH) * 100) / n;
            }
        }
        uint256 newAmountClaimed = a.amount;
        if (newPercentage < 100) {
            newAmountClaimed = a.amount * newPercentage / 100;
        }
        require(newAmountClaimed > a.amountClaimed, 'Tokens for this period are already transferred');
        uint256 tokensToTransfer = newAmountClaimed - a.amountClaimed;
        require(IERC20(tokenAddress).transfer(recipient_, tokensToTransfer), 'Cannot transfer tokens');
        grandTotalClaimed += tokensToTransfer;
        allocatedAmount -= tokensToTransfer;
        a.amountClaimed = newAmountClaimed;
        emit TokenClaimed(recipient_, tokensToTransfer);
    }

    /// Allows transfer of accidentally sent ERC20 tokens
    function refundTokens(address recipientAddress_, address erc20Address_) external {

        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), 'Must have admin role to refund');
        require(erc20Address_ != tokenAddress, 'Cannot refund native token');
        IERC20 erc20 = IERC20(erc20Address_);
        uint256 balance = erc20.balanceOf(address(this));
        require(erc20.transfer(recipientAddress_, balance), 'Cannot transfer tokens');
    }

    /// Allows transfer of accidentally sent Ethers
    function refund(address payable recipientAddress_) external payable {

        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), 'Must have admin role to refund');
        (bool success, ) = recipientAddress_.call{value: address(this).balance}('');
        require(success, "Failed to send Ether");
    }

    /// Gets array of allocated addresses array
    function allocatedAddresses() view external returns(address[] memory) {

        return _allocatedAddresses;
    }

    /// Gets allocation properties for the given address
    function allocation(address address_)
        view
        external
        returns(uint256 allocationTime,
                uint256 lockupPeriod,
                uint256 vesting,
                uint256 amount,
                uint256 amountClaimed,
                AllocationState state,
                bool cancelation) {

        allocationTime = _allocations[address_].allocationTime;
        lockupPeriod = _allocations[address_].lockupPeriod;
        vesting = _allocations[address_].vesting;
        amount = _allocations[address_].amount;
        amountClaimed = _allocations[address_].amountClaimed;
        state = _allocations[address_].state;
        cancelation = _allocations[address_].cancelation;
    }
}