pragma solidity ^0.8.0;


/// Openzeppelin imports
import '@openzeppelin/contracts/access/AccessControl.sol';
import '@openzeppelin/contracts/token/ERC20/ERC20.sol';

/// Local imports
import './DirectToken.sol';



/**
 * @title Direct token initial distribution
 *
 */
contract DirectDistribution is AccessControl {

    /// Constant member variables
    bytes32 public constant DISTRIBUTOR_ROLE = keccak256('DISTRIBUTOR_ROLE');

    uint256 private constant DECIMALFACTOR = 10 ** 18;
    uint256 public constant INITIALSUPPLY = 1200000000 * DECIMALFACTOR;


    /// Public variables
    DirectToken public token;
    uint256 public availableTotalSupply = INITIALSUPPLY;

    /// Types of available supplies
    uint256 public availableSeedSupply                 = 108000000 * DECIMALFACTOR;  // 9%
    uint256 public availablePrivateSupply              = 288000000 * DECIMALFACTOR;  // 24%
    uint256 public availablePublicSupply               = 24000000 * DECIMALFACTOR;   // 2%
    uint256 public availableTreasurySupply             = 180000000 * DECIMALFACTOR;  // 15%
    uint256 public availableTeamSupply                 = 108000000 * DECIMALFACTOR;  // 9%
    uint256 public availableAdvisorsSupply             = 48000000 * DECIMALFACTOR;   // 4%
    uint256 public availablePartnersSupply             = 84000000 * DECIMALFACTOR;   // 7%
    uint256 public availableLiquiditySupply            = 120000000 * DECIMALFACTOR;  // 10%
    uint256 public availableRewardsSupply              = 240000000 * DECIMALFACTOR;  // 20%

    uint256 public grandTotalClaimed = 0;


    // Private variables
    mapping (address => Allocation) private _allocations;
    address[] private _allocatedAddresses;


    /// Allocation Types
    enum AllocationType {
        Seed,
        Private,
        Public,
        Treasury,
        Team,
        Advisors,
        Partners,
        Liquidity,
        Rewards
    }

    /// Allocation State
    enum State {
        NotAllocated,
        Allocated,
        Canceled
    }

    /// Allocation with vesting information
    struct Allocation {

        AllocationType allocationType;          // Type of allocation
        uint256 allocationTime;                 // Locking calculated from this time
        uint256 lockupPeriod;                   // After this period tokens will released monthly
        uint256 releasedImmediately;            // Percentage of tokens that will be released immediately
        uint256 releasedMonthly;                // Percentage of tokens that will be released monthly
        uint256 totalAllocated;                 // Total tokens allocated
        uint256 amountClaimed;                  // Total tokens claimed
        State state;                            // Allocation state
    }


    /// Events
    event NewAllocation(address indexed recipient, AllocationType indexed allocationType, uint256 amount);
    event TokenClaimed(address indexed recipient, AllocationType indexed allocationType, uint256 amountClaimed);
    event CancelAllocation(address indexed recipient);


    /// Constructor
    constructor() {

        require(availableTotalSupply == availableSeedSupply
                                            + availablePrivateSupply
                                            + availablePublicSupply
                                            + availableTreasurySupply
                                            + availableTeamSupply
                                            + availableAdvisorsSupply
                                            + availablePartnersSupply
                                            + availableLiquiditySupply
                                            + availableRewardsSupply);
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        token = new DirectToken(_msgSender());
    }

    /// Gets allocated addresses array
    function getAllocatedAddresses()
        view
        external
        returns(address[] memory) {

        return _allocatedAddresses;
    }

    /// Allow the owner of the contract to assign a new allocation
    function getAllocation(address address_)
        view
        external
        returns(AllocationType allocationType,
                uint256 allocationTime,
                uint256 lockupPeriod,
                uint256 releasedImmediately,
                uint256 releasedMonthly,
                uint256 totalAllocated,
                uint256 amountClaimed,
                State state) {

        allocationType = _allocations[address_].allocationType;
        allocationTime = _allocations[address_].allocationTime;
        lockupPeriod = _allocations[address_].lockupPeriod;
        releasedImmediately = _allocations[address_].releasedImmediately;
        releasedMonthly = _allocations[address_].releasedMonthly;
        totalAllocated = _allocations[address_].totalAllocated;
        amountClaimed = _allocations[address_].amountClaimed;
        state = _allocations[address_].state;
    }

    /// Allow distributor of the contract to assign a new allocation
    function setAllocation (address recipient_, uint256 amount_, AllocationType allocationType_)
        external {

        require(hasRole(DISTRIBUTOR_ROLE, _msgSender()), 'Must have distrubutor role to distribute');
        require(address(0x0) != recipient_, 'Recipient address cannot be 0x0');
        require(0 < amount_, 'Allocated amount must be greater than 0');
        require(AllocationType.Seed <= allocationType_
                    && AllocationType.Rewards >= allocationType_,
                        'Invalid allocation type');
        Allocation storage a = _allocations[recipient_];
        if (State.NotAllocated == a.state) {
            a.allocationTime = block.timestamp;
            a.totalAllocated = amount_;
            _allocatedAddresses.push(recipient_);
        } else if (State.Canceled == a.state) {
            a.allocationTime = block.timestamp;
            a.totalAllocated = amount_;
        } else {
            require(allocationType_ == a.allocationType, 'Cannot change already allocated allocation type');
            a.totalAllocated += amount_;
        }
        a.state = State.Allocated;
        a.allocationType = allocationType_;
        if (AllocationType.Seed == allocationType_) {
            availableSeedSupply -= amount_;
            a.lockupPeriod = 0;
            a.releasedImmediately = 250;
            a.releasedMonthly = 188;
        } else if (AllocationType.Private == allocationType_) {
            availablePrivateSupply -= amount_;
            a.lockupPeriod = 0;
            a.releasedImmediately = 500;
            a.releasedMonthly = 250;
        } else if (AllocationType.Public == allocationType_) {
            availablePublicSupply -= amount_;
            a.lockupPeriod = 0;
            a.releasedImmediately = 1000;
            a.releasedMonthly = 0;
        } else if (AllocationType.Treasury == allocationType_) {
            availableTreasurySupply -= amount_;
            a.lockupPeriod = 30 days;
            a.releasedImmediately = 0;
            a.releasedMonthly = 42;
        } else if (AllocationType.Team == allocationType_) {
            availableTeamSupply -= amount_;
            a.lockupPeriod = 6 * 30 days;
            a.releasedImmediately = 0;
            a.releasedMonthly = 42;
        } else if (AllocationType.Advisors == allocationType_) {
            availableAdvisorsSupply -= amount_;
            a.lockupPeriod = 3 * 30 days;
            a.releasedImmediately = 0;
            a.releasedMonthly = 42;
        } else if (AllocationType.Partners == allocationType_) {
            availablePartnersSupply -= amount_;
            a.lockupPeriod = 0;
            a.releasedImmediately = 5;
            a.releasedMonthly = 17;
        } else if (AllocationType.Liquidity == allocationType_) {
            availableLiquiditySupply -= amount_;
            a.lockupPeriod = 0;
            a.releasedImmediately = 1000;
            a.releasedMonthly = 0;
        } else { // Rewards
            availableRewardsSupply -= amount_;
            a.lockupPeriod = 3 * 30 days;
            a.releasedImmediately = 0;
            a.releasedMonthly = 20;
        }
        availableTotalSupply -= amount_;
        emit NewAllocation(recipient_, allocationType_, amount_);
    }

    /// Cancels allocation for given recipient
    function cancelAllocation (address recipient_)
        external {

        require(hasRole(DISTRIBUTOR_ROLE, _msgSender()), 'Must have distrubutor role to cancel');
        Allocation storage a = _allocations[recipient_];
        require(State.Allocated == a.state, 'There is no allocation');
        require(0 == a.amountClaimed, 'Cannot canceled allocation with claimed tokens');
        a.state = State.Canceled;

        availableTotalSupply += a.totalAllocated;
        if (AllocationType.Seed == a.allocationType) {
            availableSeedSupply += a.totalAllocated;
        } else if (AllocationType.Private == a.allocationType) {
            availablePrivateSupply += a.totalAllocated;
        } else if (AllocationType.Public == a.allocationType) {
            availablePublicSupply += a.totalAllocated;
        } else if (AllocationType.Treasury == a.allocationType) {
            availableTreasurySupply += a.totalAllocated;
        } else if (AllocationType.Team == a.allocationType) {
            availableTeamSupply += a.totalAllocated;
        } else if (AllocationType.Advisors == a.allocationType) {
            availableAdvisorsSupply += a.totalAllocated;
        } else if (AllocationType.Partners == a.allocationType) {
            availablePartnersSupply += a.totalAllocated;
        } else if (AllocationType.Liquidity == a.allocationType) {
            availableLiquiditySupply += a.totalAllocated;
        } else { // Rewards
            availableRewardsSupply += a.totalAllocated;
        }
        emit CancelAllocation(recipient_);
    }

    /// Transfer a recipient's available allocation to their address
    function claimTokens (address recipient_)
        external {

        Allocation storage a = _allocations[recipient_];
        require(State.Allocated == a.state, 'There is no allocation for the recipient');
        require(a.amountClaimed < a.totalAllocated, 'Allocations have already been transferred');
        uint256 newPercentage = 0;
        if (0 < a.lockupPeriod) {
            newPercentage = a.releasedImmediately;
        } else {
            newPercentage = 0 < a.releasedImmediately ? a.releasedImmediately : a.releasedMonthly;
        }
        if (block.timestamp > a.allocationTime + a.lockupPeriod) {
            newPercentage += a.releasedMonthly
                                * ((block.timestamp - (a.allocationTime + a.lockupPeriod)) / 30 days);
        }
        uint256 newAmountClaimed = a.totalAllocated;
        if (newPercentage < 1000) {
            newAmountClaimed = a.totalAllocated * newPercentage / 1000;
        }
        require(newAmountClaimed > a.amountClaimed, 'Tokens for this period are already transferred');
        uint256 tokensToTransfer = newAmountClaimed - a.amountClaimed;
        require(token.transfer(recipient_, tokensToTransfer), 'Cannot transfer tokens');
        grandTotalClaimed += tokensToTransfer;
        a.amountClaimed = newAmountClaimed;
        emit TokenClaimed(recipient_, a.allocationType, tokensToTransfer);
    }

    /// Allow transfer of accidentally sent ERC20 tokens
    function refundTokens(address recipientAddress_, address erc20Address_)
        external {

        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), 'Must have admin role to transfer');
        require(erc20Address_ != address(token), 'Cannot refund DirectToken');
        ERC20 erc20 = ERC20(erc20Address_);
        uint256 balance = erc20.balanceOf(address(this));
        require(erc20.transfer(recipientAddress_, balance), 'Cannot transfer tokens');
    }
}