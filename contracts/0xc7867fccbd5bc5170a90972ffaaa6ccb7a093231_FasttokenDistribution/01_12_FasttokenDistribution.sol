// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;


/// Openzeppelin imports
import '@openzeppelin/contracts/access/AccessControl.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

/// Local imports
import './Fasttoken.sol';


/**
 * Fasttoken initial distribution
 */
contract FasttokenDistribution is AccessControl {

    /// Constant private member variables
    uint256 private constant MONTH = 30 days;
    uint256 private constant YEAR = 12 * MONTH;
    uint256 private constant DECIMAL_FACTOR = 10 ** 18;
    uint256 private constant SIZE_OF_ALLOCATIONS = 10;

    /// Constant public member variables
    uint256 public constant SUPPLY = 1000000000 * DECIMAL_FACTOR;
    uint256 public constant CANCELATION_PERIOD = 1 days;

    bytes32 public constant FOUNDERS_DISTRIBUTOR_ROLE = keccak256('FOUNDERS_DISTRIBUTOR_ROLE');
    bytes32 public constant ADVISORS_DISTRIBUTOR_ROLE = keccak256('ADVISORS_DISTRIBUTOR_ROLE');
    bytes32 public constant TOKEN_SALE_DISTRIBUTOR_ROLE = keccak256('TOKEN_SALE_DISTRIBUTOR_ROLE');
    bytes32 public constant MARKETING_PR_DISTRIBUTOR_ROLE = keccak256('MARKETING_PR_DISTRIBUTOR_ROLE');
    bytes32 public constant ECOSYSTEM_DISTRIBUTOR_ROLE = keccak256('ECOSYSTEM_DISTRIBUTOR_ROLE');
    bytes32 public constant BLOCKCHAIN_BURN_ROLE = keccak256('BLOCKCHAIN_BURN_ROLE');

    /// Public variables
    Fasttoken public fasttoken;
    uint256 public availableAmount = SUPPLY;
    uint256 public grandTotalClaimed = 0;

    // Private variables
    AllocationStructure[SIZE_OF_ALLOCATIONS] private _allocationTypes;
    mapping(address => Allocation) private _allocations;
    address[] private _allocatedAddresses;


    /// Allocation State
    enum AllocationState {
        NotAllocated,
        Allocated,
        Canceled
    }

    /// Allocation Type
    enum AllocationType {
        Founders,
        Advisors,
        Private1,
        Private2,
        Marketing,
        Partners,
        Ecosystem,
        Public,
        Presale,
        Blockchain
    }

    /// Allocation Structure
    struct AllocationStructure {
        uint256 lockupPeriod;
        uint256 vesting;
        uint256 totalAmount;
        uint256 availableAmount;
    }

    /// Allocation with vesting information
    struct Allocation {
        AllocationType allocationType;          // Type of allocation
        uint256 allocationTime;                 // Locking calculated from this time
        uint256 amount;                         // Total tokens allocated
        uint256 amountClaimed;                  // Total tokens claimed
        AllocationState state;                  // Allocation state
    }


    /// Events
    event NewAllocation(address indexed recipient, AllocationType indexed allocationType, uint256 amount);
    event TokenClaimed(address indexed recipient, AllocationType indexed allocationType, uint256 amountClaimed);
    event CancelAllocation(address indexed recipient);
    event BurnAllocation(AllocationType indexed allocationType, uint256 amount);


    /// Constructor
    constructor() {

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _initAllocationTypes();
        _checkAllocations();
        fasttoken = new Fasttoken();
    }

    /// Sets allocation for the given recipient with corresponding amount.
    function setAllocation(address recipient_, uint256 amount_, AllocationType allocationType_) public {

        require(address(0x0) != recipient_, 'Recipient address cannot be 0x0');
        require(0 < amount_, 'Allocated amount must be greater than 0');
        //require(AllocationType.Blockchain != allocationType_, 'Cannot set allocation for blockchain type');
        _checkRole(_msgSender(), allocationType_);
        Allocation storage a = _allocations[recipient_];
        require(AllocationState.Allocated != a.state, 'Recipient already has allocation');
        if (AllocationState.NotAllocated == a.state) {
            _allocatedAddresses.push(recipient_);
        }
        a.allocationType = allocationType_;
        a.allocationTime = block.timestamp;
        a.amount = amount_;
        a.state = AllocationState.Allocated;
        _allocationTypes[uint256(allocationType_)].availableAmount -= amount_;
        availableAmount -= amount_;
        emit NewAllocation(recipient_, allocationType_, amount_);
    }

    /// Sets allocation for the given recipient with corresponding amount.
    function burn(AllocationType allocationType_) public {

        require(AllocationType.Presale == allocationType_
                || AllocationType.Private1 == allocationType_
                || AllocationType.Private2 == allocationType_
                || AllocationType.Public == allocationType_
                || AllocationType.Blockchain == allocationType_,
                'Burnable only Presale, Private1, Private2, Public, Blockchain allocations');
        _checkRole(_msgSender(), allocationType_);
        uint256 i = uint256(allocationType_);
        if (0 != _allocationTypes[i].availableAmount) {
            fasttoken.burn(_allocationTypes[i].availableAmount);
            availableAmount -= _allocationTypes[i].availableAmount;
            emit BurnAllocation(allocationType_, _allocationTypes[i].availableAmount);
            _allocationTypes[i].availableAmount = 0;
        }
    }

    /// Cancels allocation for the given recipient
    function cancelAllocation(address recipient_) public {

        Allocation storage a = _allocations[recipient_];
        _checkRole(_msgSender(), a.allocationType);
        require(AllocationState.Allocated == a.state, 'There is no allocation');
        require(0 == a.amountClaimed, 'Cannot cancel allocation with claimed tokens');
        require(block.timestamp < a.allocationTime + CANCELATION_PERIOD, 'Cancellation period expired');
        a.state = AllocationState.Canceled;
        availableAmount += a.amount;
        _allocationTypes[uint256(a.allocationType)].availableAmount += a.amount;
        emit CancelAllocation(recipient_);
    }

    /// Transfers a recipient's available allocation to their address
    function claimTokens(address recipient_) public {

        Allocation storage a = _allocations[recipient_];
        require(AllocationState.Allocated == a.state, 'There is no allocation for the recipient');
        require(a.amountClaimed < a.amount, 'Allocations have already been transferred');
        AllocationStructure storage at = _allocationTypes[uint256(a.allocationType)];

        uint256 newPercentage = 0;
        if (block.timestamp > a.allocationTime + at.lockupPeriod) {
            if (block.timestamp > a.allocationTime + at.lockupPeriod + at.vesting) {
                newPercentage = 100;
            } else {
                uint256 n = at.vesting / MONTH; // at.vesting % MONTH == 0
                newPercentage = (((block.timestamp - (a.allocationTime + at.lockupPeriod)) / MONTH) * 100) / n;
            }
        }
        uint256 newAmountClaimed = a.amount;
        if (newPercentage < 100) {
            newAmountClaimed = a.amount * newPercentage / 100;
        }
        require(newAmountClaimed > a.amountClaimed, 'Tokens for this period are already transferred');
        uint256 tokensToTransfer = newAmountClaimed - a.amountClaimed;
        require(fasttoken.transfer(recipient_, tokensToTransfer), 'Cannot transfer tokens');
        grandTotalClaimed += tokensToTransfer;
        a.amountClaimed = newAmountClaimed;
        emit TokenClaimed(recipient_, a.allocationType, tokensToTransfer);
    }

    /// Allows transfer of accidentally sent ERC20 tokens
    function refundTokens(address recipientAddress_, address erc20Address_) external {

        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), 'Must have admin role to refund');
        require(erc20Address_ != address(fasttoken), 'Cannot refund Fasttoken');
        ERC20 erc20 = ERC20(erc20Address_);
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

    /// Gets array of allocation types
    function allocationTypes() view external returns(AllocationStructure[SIZE_OF_ALLOCATIONS] memory) {

        return _allocationTypes;
    }

    /// Gets allocation properties for the given address
    function allocation(address address_)
        view
        external
        returns(AllocationType allocationType,
                uint256 allocationTime,
                uint256 amount,
                uint256 amountClaimed,
                AllocationState state) {

        allocationType = _allocations[address_].allocationType;
        allocationTime = _allocations[address_].allocationTime;
        amount = _allocations[address_].amount;
        amountClaimed = _allocations[address_].amountClaimed;
        state = _allocations[address_].state;
    }

    /// Helper member functions

    function _initAllocationTypes() private {

        _allocationTypes[uint256(AllocationType.Founders)] = AllocationStructure(
            2 * YEAR,
            10 * MONTH,
            200000000 * DECIMAL_FACTOR,
            200000000 * DECIMAL_FACTOR
        ); // 20%
        _allocationTypes[uint256(AllocationType.Advisors)] = AllocationStructure(
            YEAR,
            10 * MONTH,
            30000000 * DECIMAL_FACTOR,
            30000000 * DECIMAL_FACTOR
        ); // 3%
        _allocationTypes[uint256(AllocationType.Private1)] = AllocationStructure(
            YEAR,
            10 * MONTH,
            80000000 * DECIMAL_FACTOR,
            80000000 * DECIMAL_FACTOR
        ); // 8%
        _allocationTypes[uint256(AllocationType.Private2)] = AllocationStructure(
            YEAR,
            10 * MONTH,
            100000000 * DECIMAL_FACTOR,
            100000000 * DECIMAL_FACTOR
        ); // 10%
        _allocationTypes[uint256(AllocationType.Marketing)] = AllocationStructure(
            0,
            0,
            50000000 * DECIMAL_FACTOR,
            50000000 * DECIMAL_FACTOR
        ); // 5%
        _allocationTypes[uint256(AllocationType.Partners)] = AllocationStructure(
            0,
            0,
            60000000 * DECIMAL_FACTOR,
            60000000 * DECIMAL_FACTOR
        ); // 6%
        _allocationTypes[uint256(AllocationType.Ecosystem)] = AllocationStructure(
            0,
            0,
            240000000 * DECIMAL_FACTOR,
            240000000 * DECIMAL_FACTOR
        ); // 24%
        _allocationTypes[uint256(AllocationType.Public)] = AllocationStructure(
            0,
            0,
            60000000 * DECIMAL_FACTOR,
            60000000 * DECIMAL_FACTOR
        ); // 6%
        _allocationTypes[uint256(AllocationType.Presale)] = AllocationStructure(
            0,
            0,
            60000000 * DECIMAL_FACTOR,
            60000000 * DECIMAL_FACTOR
        ); // 6%
        _allocationTypes[uint256(AllocationType.Blockchain)] = AllocationStructure(
            0,
            0,
            120000000  * DECIMAL_FACTOR,
            120000000  * DECIMAL_FACTOR
        ); // 12% TODO
    }

    function _checkAllocations() view private {

        uint256 sum = 0;
        for (uint256 i = 0; i < SIZE_OF_ALLOCATIONS; ++i) {
            sum += _allocationTypes[i].totalAmount;
        }
        require(SUPPLY == sum, 'Invalid allocation types');
    }

    function _checkRole(address sender_, AllocationType allocationType_) view private {

        if (AllocationType.Founders == allocationType_) {
            require(hasRole(FOUNDERS_DISTRIBUTOR_ROLE, sender_), 'Must have founders distribution role');
        } else if (AllocationType.Advisors == allocationType_) {
            require(hasRole(ADVISORS_DISTRIBUTOR_ROLE, sender_), 'Must have advisors distribution role');
        } else if (AllocationType.Private1 == allocationType_
                        || AllocationType.Private2 == allocationType_
                        || AllocationType.Public == allocationType_
                        || AllocationType.Presale == allocationType_) {
            require(hasRole(TOKEN_SALE_DISTRIBUTOR_ROLE, sender_), 'Must have token sale distribution role');
        } else if (AllocationType.Marketing == allocationType_
                        || AllocationType.Partners == allocationType_) {
            require(hasRole(MARKETING_PR_DISTRIBUTOR_ROLE, sender_), 'Must have marketing and pr distribution role');
        } else if (AllocationType.Ecosystem == allocationType_) {
            require(hasRole(ECOSYSTEM_DISTRIBUTOR_ROLE, sender_), 'Must have ecosystem distribution role');
        } else if (AllocationType.Blockchain == allocationType_) {
            require(hasRole(BLOCKCHAIN_BURN_ROLE, sender_), 'Must have blockchain burn role to burn Blockchain tokens');
        } else {
            require(false, 'Unsupported allocation type');
        }
    }
}