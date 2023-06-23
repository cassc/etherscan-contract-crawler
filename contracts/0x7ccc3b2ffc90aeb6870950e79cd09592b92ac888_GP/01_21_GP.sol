// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

import "@openzeppelin/contracts-4.2.0/security/Pausable.sol";
import "@openzeppelin/contracts-4.2.0/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts-4.2.0/proxy/Clones.sol";
import "@openzeppelin/contracts-4.2.0/token/ERC20/extensions/ERC20VotesComp.sol";
import "./Vesting.sol";
import "./SimpleGovernance.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

/**
 * @title Geeky Punks token
 * @notice A token that is deployed with fixed amount and appropriate vesting contracts.
 * Transfer is blocked for a period of time until the governance can toggle the transferability.
 */
contract GP is ERC20Permit, Ownable, Pausable, SimpleGovernance {
    using SafeERC20 for IERC20;

    // Token max supply is 1,000,000,000,000 $GP
    uint256 public constant MAX_SUPPLY = 1e12 ether;
    uint256 public immutable govCanUnpauseAfter;
    uint256 public immutable anyoneCanUnpauseAfter;
    address public immutable vestingContractTarget;
    bool public limited;
    uint256 public maxAmountPerWallet;
    uint256 public minAmountPerWallet;
    address public uniswapV2Pair;
    mapping(address => bool) public blacklists;

    mapping(address => bool) public allowedTransferee;

    event Allowed(address indexed target);
    event Disallowed(address indexed target);
    event VestingContractDeployed(
        address indexed beneficiary,
        address vestingContract
    );

    struct Recipient {
        address to;
        uint256 amount;
        uint256 startTimestamp;
        uint256 cliffPeriod;
        uint256 durationPeriod;
    }

    /**
     * @notice Initializes GP token with specified governance address and recipients. For vesting
     * durations and amounts, please refer to our documentation on token distribution schedule.
     * @param governance_ address of the governance who will own this contract
     * @param pausePeriod_ time in seconds since the deployment. After this period, this token can be unpaused
     * by the owner / governance.
     * @param vestingContractTarget_ logic contract of Vesting.sol to use for cloning
     */
    constructor(
        address governance_,
        uint256 pausePeriod_,
        address vestingContractTarget_
    ) public ERC20("Geeky Punks", "GP") ERC20Permit("Geeky Punks") {
        require(governance_ != address(0), "GP: governance cannot be empty");
        require(
            vestingContractTarget_ != address(0),
            "GP: vesting contract target cannot be empty"
        );
        require(
            pausePeriod_ > 0 && pausePeriod_ <= 4 weeks,
            "GP: pausePeriod must be in between 0 and 4 weeks"
        );

        // Set state variables
        vestingContractTarget = vestingContractTarget_;
        governance = governance_;
        govCanUnpauseAfter = block.timestamp + pausePeriod_;
        anyoneCanUnpauseAfter = block.timestamp + 4 weeks;

        // Allow governance to transfer tokens
        allowedTransferee[governance_] = true;

        // Mint tokens to governance
        _mint(governance, MAX_SUPPLY);

        // Pause transfers at deployment
        if (pausePeriod_ > 0) {
            _pause();
        }

        emit SetGovernance(governance_);
    }

    function blacklist(address _address, bool _isBlacklisting)
        external
        onlyOwner
    {
        blacklists[_address] = _isBlacklisting;
    }

    function setRule(
        bool _limited,
        address _uniswapV2Pair,
        uint256 _maxAmountPerWallet,
        uint256 _minAmountPerWallet
    ) external onlyOwner {
        limited = _limited;
        uniswapV2Pair = _uniswapV2Pair;
        maxAmountPerWallet = _maxAmountPerWallet;
        minAmountPerWallet = _minAmountPerWallet;
    }

    /**
     * @notice Deploys a clone of the vesting contract for the given recipient. Details about vesting and token
     * release schedule can be found on https://docs.geekypunks.com
     * @param recipient Recipient of the token through the vesting schedule.
     */
    function deployNewVestingContract(Recipient memory recipient)
        public
        onlyGovernance
        returns (address)
    {
        require(
            recipient.durationPeriod > 0,
            "GP: duration for vesting cannot be 0"
        );

        // Deploy a clone rather than deploying a whole new contract
        Vesting vestingContract = Vesting(Clones.clone(vestingContractTarget));

        // Initialize the clone contract for the recipient
        vestingContract.initialize(
            address(this),
            recipient.to,
            recipient.startTimestamp,
            recipient.cliffPeriod,
            recipient.durationPeriod
        );

        // Send tokens to the contract
        IERC20(address(this)).safeTransferFrom(
            msg.sender,
            address(vestingContract),
            recipient.amount
        );

        // Add the vesting contract to the allowed transferee list
        allowedTransferee[address(vestingContract)] = true;
        emit Allowed(address(vestingContract));
        emit VestingContractDeployed(recipient.to, address(vestingContract));

        return address(vestingContract);
    }

    /**
     * @notice Changes the transferability of this token.
     * @dev When the transfer is not enabled, only those in allowedTransferee array can
     * transfer this token.
     */
    function enableTransfer() external {
        require(paused(), "GP: transfer is enabled");
        uint256 unpauseAfter = msg.sender == governance
            ? govCanUnpauseAfter
            : anyoneCanUnpauseAfter;
        require(
            block.timestamp > unpauseAfter,
            "GP: cannot enable transfer yet"
        );
        _unpause();
    }

    /**
     * @notice Add the given addresses to the list of allowed addresses that can transfer during paused period.
     * Governance will add auxiliary contracts to the allowed list to facilitate distribution during the paused period.
     * @param targets Array of addresses to add
     */
    function addToAllowedList(address[] memory targets)
        external
        onlyGovernance
    {
        for (uint256 i = 0; i < targets.length; i++) {
            allowedTransferee[targets[i]] = true;
            emit Allowed(targets[i]);
        }
    }

    /**
     * @notice Remove the given addresses from the list of allowed addresses that can transfer during paused period.
     * @param targets Array of addresses to remove
     */
    function removeFromAllowedList(address[] memory targets)
        external
        onlyGovernance
    {
        for (uint256 i = 0; i < targets.length; i++) {
            allowedTransferee[targets[i]] = false;
            emit Disallowed(targets[i]);
        }
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);
        require(!paused() || allowedTransferee[from], "GP: paused");
        require(to != address(this), "GP: invalid recipient");
        require(!blacklists[to] && !blacklists[from], "Blacklisted");

        if (uniswapV2Pair == address(0)) {
            require(
                from == owner() || to == owner(),
                "trading has not started"
            );
            return;
        }

        if (limited && from == uniswapV2Pair) {
            require(
                super.balanceOf(to) + amount <= maxAmountPerWallet &&
                    super.balanceOf(to) + amount >= minAmountPerWallet,
                "Forbid"
            );
        }
    }

    /**
     * @notice Transfers any stuck tokens or ether out to the given destination.
     * @dev Method to claim junk and accidentally sent tokens. This will be only used to rescue
     * tokens that are mistakenly sent by users to this contract.
     * @param token Address of the ERC20 token to transfer out. Set to address(0) to transfer ether instead.
     * @param to Destination address that will receive the tokens.
     * @param balance Amount to transfer out. Set to 0 to select all available amount.
     */
    function rescueTokens(
        IERC20 token,
        address payable to,
        uint256 balance
    ) external onlyGovernance {
        require(to != address(0), "GP: invalid recipient");

        if (token == IERC20(address(0))) {
            // for Ether
            uint256 totalBalance = address(this).balance;
            balance = balance == 0
                ? totalBalance
                : Math.min(totalBalance, balance);
            require(balance > 0, "GP: trying to send 0 ETH");
            // slither-disable-next-line arbitrary-send
            (bool success, ) = to.call{value: balance}("");
            require(success, "GP: ETH transfer failed");
        } else {
            // any other erc20
            uint256 totalBalance = token.balanceOf(address(this));
            balance = balance == 0
                ? totalBalance
                : Math.min(totalBalance, balance);
            require(balance > 0, "GP: trying to send 0 balance");
            token.safeTransfer(to, balance);
        }
    }
}