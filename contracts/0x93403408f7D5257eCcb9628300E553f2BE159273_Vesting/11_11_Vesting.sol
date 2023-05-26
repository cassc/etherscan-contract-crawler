// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import "./access/AccessControlEnumerable.sol";
import "./token/ERC20/IERC20.sol";

/** 
 * @dev {Vesting} contract handles the contributions for ERC20 token. Including:
 *
 *  - an admin role that allows add contributions for particular contributor.
 *  - ability for contributors to claim their tokens
 * 
 * The account that deploys the contract will be granted the `admin`
 * role, as well as the `default admin` role, which will let it grant `admin` role to other accounts.
*/
contract Vesting is AccessControlEnumerable {
    using EnumerableSet for EnumerableSet.AddressSet;

    /**
     * @dev Emitted when tokens are deposited for `contributor` by admin.
     */
    event Deposit(address indexed contributor, uint256 amount, uint256 bonus, uint256 start);

    /**
     * @dev Emitted when tokens are withdrawn by `contributor`.
     */
    event Withdraw(address indexed contributor, uint256 amount, uint256 bonus, uint256 start, uint256 outcome, uint256 leftovers);

    /* Contribution data */
    struct ContributionData {
        uint256 amount;
        uint256 bonus;
        uint256 outcome;
        uint256 start;
        uint256 timestamp;
        bool executed;
    }

    /** Role to add contributions */
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    /** HardLock duration */
    uint256 public constant HARDLOCK = 120 days;

    /** SoftLock stage duration */
    uint256 public constant SOFTLOCK = 30 days;

    /* The denominator for rates */
    uint96 public constant DENOMINATOR = 10000;

    /* The APY numerator is expressed in basis points. Defaults to 6.66% (20% APY). */
    uint96 public constant APY = 666;

    /* SoftLock first stage numerator is expressed in basis points. Defaults to 30%. */
    uint96 public constant FIRST_PENALTY = 3000;

    /* SoftLock second stage numerator is expressed in basis points. Defaults to 20%. */
    uint96 public constant SECOND_PENALTY = 2000;
    
    /* SoftLock third stage numerator is expressed in basis points. Defaults to 10%. */
    uint96 public constant THIRD_PENALTY = 1000;

    /** Contributors list */
    EnumerableSet.AddressSet _contributors;
    
    /** Contributions for particular contributor */
    mapping (address => ContributionData[]) private _contributions;

     /* Penalty leftovers vault */
    address private immutable _vault;

     /* Contribution token */
    address private immutable _token;    

    /**
     * @dev Grants `DEFAULT_ADMIN_ROLE` and `ADMIN_ROLE` to the account that deploys the contract.
     */
    constructor(address token_, address vault_) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);

        require(token_ != address(0), "Vesting: token is the zero address");
        require(vault_ != address(0), "Vesting: vault is the zero address");

        _token = token_;
        _vault = vault_;
    }

    /**
     * @dev Returns version of the contract instance.
     */
    function version() public pure returns (string memory) {
        return "1.0.0";
    }

    /**
     * @dev Returns contribution token address.
     */
    function token() public view returns (address) {
        return _token;
    }

    /**
     * @dev Returns the penalty leftovers vault address.
     */
    function vault() public view returns (address) {
        return _vault;
    }

    /**
     * @dev Return the entire contributors set in an array.
     */
    function getContributors() external view returns(address[] memory) {
        return _contributors.values();
    }

    /**
     * @dev Returns contributor by `id` (index).
     */
    function getContributorById(uint id) external view returns(address) {
        return _contributors.at(id);
    }

    /**
     * @dev Returns the number of contributors.
     */
    function getContributorCount() external view returns(uint256) {
        return _contributors.length();
    }

    /**
     * @dev Return the entire contributions set in an array by `contributor` address.
     */
    function getContributions(address contributor) external view returns(ContributionData[] memory contributions) {
        return _contributions[contributor];
    }

    /**
     * @dev Returns contribution of particular `contributor` by `id` (index).
     */
    function getContributionById(address contributor, uint id) external view returns(ContributionData memory contribution) {
        return _contributions[contributor][id];
    }

    /**
     * @dev Returns the number of contributions of particular `contributor`.
     */
    function getContributionCount(address contributor) external view returns(uint256) {
        return _contributions[contributor].length;
    }

    /**
     * @dev Add new contribution.
     * 
     * Requirements:
     *
     * - the caller must have the `ADMIN_ROLE`.
     * 
     * Emits a {Deposit} event.
     */
    function addContribution(address contributor, uint256 amount, uint256 start) external onlyRole(ADMIN_ROLE) {
        uint256 bonus = amount * APY / DENOMINATOR;
        
        IERC20(_token).transferFrom(msg.sender, address(this), amount + bonus);

        _contributions[contributor].push(ContributionData(amount, bonus, 0, start, block.timestamp, false));

        _contributors.add(contributor);

        emit Deposit(contributor, amount, bonus, start);
    }

    /**
     * @dev Withdraw contributor tokens by contribution `id` (index), `amount` & `start` date.
     * 
     * Emits a {Withdraw} event.
     */
    function claimContribution(uint256 id, uint256 amount, uint256 start) external {
        ContributionData storage contribution = _contributions[msg.sender][id];

        uint256 hardlock = contribution.start + HARDLOCK;

        require(hardlock < block.timestamp, "Vesting: current time is before hardlock");
        require(!contribution.executed, "Vesting: contribution is already executed");
        require(contribution.amount == amount, "Vesting: contribution amount is not equal");
        require(contribution.start == start, "Vesting: contribution start date is not equal");
        
        uint256 outcome;
        uint256 total = contribution.amount + contribution.bonus;

        if (contribution.start + HARDLOCK + 3 * SOFTLOCK < block.timestamp) {
            outcome = total;
        } else if (contribution.start + HARDLOCK + 2 * SOFTLOCK < block.timestamp) {
            outcome = total - total * THIRD_PENALTY / DENOMINATOR;
        } else if (contribution.start + HARDLOCK + SOFTLOCK < block.timestamp) {
            outcome = total - total * SECOND_PENALTY / DENOMINATOR;
        } else {
            outcome = total - total * FIRST_PENALTY / DENOMINATOR;
        }

        uint256 leftovers = total - outcome;

        contribution.outcome = outcome;
        contribution.executed = true;

        IERC20(_token).transfer(msg.sender, outcome);
        IERC20(_token).transfer(_vault, leftovers);

        emit Withdraw(msg.sender, contribution.amount, contribution.bonus, contribution.start, contribution.outcome, leftovers);
    }
}