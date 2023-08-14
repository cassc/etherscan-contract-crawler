/**
 *Submitted for verification at Etherscan.io on 2020-05-27
*/

pragma solidity ^0.5.16;


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }

    function max64(uint64 a, uint64 b) internal pure returns (uint64) {
        return a >= b ? a : b;
    }

    function min64(uint64 a, uint64 b) internal pure returns (uint64) {
        return a < b ? a : b;
    }

    function max256(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    function min256(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
    uint256 public totalSupply;

    function balanceOf(address _owner) public view returns (uint256 balance);

    function transfer(address _to, uint256 _value)
        public
        returns (bool success);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
}

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
    function allowance(address _owner, address _spender)
        public
        view
        returns (uint256 remaining);

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public returns (bool success);

    function approve(address _spender, uint256 _value)
        public
        returns (bool success);

    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    );
}

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address public owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor() public {
        owner = msg.sender;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner, "only owner can access");
        _;
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "address cannot be zero");
        address previousOwner = owner;
        owner = newOwner;
        emit OwnershipTransferred(previousOwner, owner);
    }
}

/**
 * @title The MDTExchangeLockup contract
 * @dev Lock up MDT tokens for exchange launching
 * @author MDT Team
 */
contract MDTExchangeLockup is Ownable {
    using SafeMath for uint256;

    ERC20 public token; // MDT contract address
    address public holderAddress; // wallet address for unlocking tokens
    uint256 public startTime; // start time of the tokens lockup
    uint256 public installmentLength; // installment length in seconds
    uint256 public totalInstallments; // total number of installments
    uint256 public totalTokensLocked; // total tokens locked in this contract
    uint256 public totalTokensUnlocked; // total tokens unlocked by the holder
    uint256 public lastUnlockedTime; // last time of unlocking tokens

    // Events
    event TokensUnlocked(
        address indexed _to,
        uint256 _amount,
        uint256 _unlockedTime
    );
    event HolderAddressChanged(
        address indexed previousHolder,
        address indexed newholder
    );

    /// @dev Reverts if address is 0x0 or token address or this contract address.
    modifier validRecipient(address _recipient) {
        require(
            validAddress(_recipient),
            "recipient cannot be zero address, the token address or the contract address"
        );
        _;
    }

    /**
     * @dev Throws if called by any account other than the token holder.
     */
    modifier onlyHolder() {
        require(msg.sender == holderAddress, "only holder can access");
        _;
    }

    /**
     * @dev MDTExchangeLockup contract constructor.
     * @param _tokenAddress address The MDT contract address.
     * @param _holderAddress address The wallet address used to unlock tokens.
     * @param _startTime uint256 the lockup start time.
     * @param _installmentLength uint256 the length of each installment in seconds.
     * @param _totalInstallments uint256 total number of installments.
     * @param _lockupAmount address Amount of tokens to be locked up in the contract.
     */
    constructor(
        address _tokenAddress,
        address _holderAddress,
        uint256 _startTime,
        uint256 _installmentLength,
        uint256 _totalInstallments,
        uint256 _lockupAmount
    ) public {
        require(_tokenAddress != address(0), "token address cannot be zero");
        require(
            _holderAddress != address(0) && _holderAddress != _tokenAddress,
            "holder address cannot be zero or equal to the token address"
        );
        require(_startTime > now, "start time must be later than now");
        require(
            _installmentLength > 0,
            "installment length must be greater than 0"
        );
        require(
            _totalInstallments >= 1,
            "total number of installments must be greater than or equal to 1"
        );
        require(_lockupAmount > 0, "lockup amounts must be greater than 0");

        token = ERC20(_tokenAddress);
        holderAddress = _holderAddress;
        startTime = _startTime;
        installmentLength = _installmentLength;
        totalInstallments = _totalInstallments;
        totalTokensLocked = _lockupAmount;
    }

    /**
     * @dev Changes token holder to a new holder. (contract owner only)
     * @param newHolderAddress The address to transfer tokens ownership to.
     */
    function changeHolderAddress(address newHolderAddress)
        public
        onlyOwner
        validRecipient(newHolderAddress)
    {
        address previousHolder = holderAddress;
        holderAddress = newHolderAddress;
        emit HolderAddressChanged(previousHolder, holderAddress);
    }

    /// @dev Calculate the total amount of unlocked tokens at a given time.
    /// @param _time uint256 The specific time to calculate against.
    /// @return uint256 Total amount of tokens available to unlock.
    function calculateUnlockedTokens(uint256 _time)
        public
        view
        returns (uint256)
    {
        // if passed in time is before the lockup start time, return 0.
        if (_time < startTime) {
            return 0;
        }

        // Calculate number of installments pasted until now.
        uint256 installmentsPast = _time.sub(startTime).div(installmentLength);

        // If number of installments pasted is greater than or equal to the total number of installments, all tokens are unlocked.
        if (installmentsPast >= totalInstallments) {
            return totalTokensLocked;
        }

        // Calculate and return the number of tokens unlocked accordings to the number of installments that has been passed.
        return installmentsPast.mul(totalTokensLocked).div(totalInstallments);
    }

    /// @dev Calculate the total amount of unlocked tokens at current time.
    /// @return uint256 Total amount of tokens available to unlock now.
    function currentUnlockedTokens() public view returns (uint256) {
        return calculateUnlockedTokens(now);
    }

    /**
     * @dev Unlock tokens. (tokens holder only)
     * @return amount of tokens unlocked.
     */
    function unlockTokens() public onlyHolder returns (uint256) {
        require(contractTokenBalance() > 0, "no tokens are locked");

        // Get the total amount of unlocked tokens.
        uint256 unlockedAmount = calculateUnlockedTokens(now);
        if (unlockedAmount == 0) {
            return 0;
        }

        // Make sure the holder doesn't transfer more than what he unlocked.
        uint256 availableAmount = unlockedAmount.sub(totalTokensUnlocked);
        if (availableAmount == 0) {
            return 0;
        }

        // Update total unlocked amounts.
        totalTokensUnlocked = totalTokensUnlocked.add(availableAmount);

        // Update last unlocked time.
        lastUnlockedTime = now;

        // Send tokens to the sender.
        require(
            token.transfer(msg.sender, availableAmount),
            "failed to transfer tokens"
        );

        // Emit tokens unlocked event.
        emit TokensUnlocked(msg.sender, availableAmount, now);
    }

    /**
     * @dev Transfer to owner any tokens send by mistake to this contract. (contract owner only)
     * @param _token ERC20 The address of the token to transfer.
     * @param amount uint256 The amount to be transferred.
     */
    function emergencyERC20Drain(ERC20 _token, uint256 amount)
        public
        onlyOwner
    {
        _token.transfer(owner, amount);
    }

    /**
     * @dev Get token balance of a wallet address.
     * @param _address address Address to be queried.
     * @return the token balance of a wallet address.
     */
    function tokenBalanceOf(address _address) public view returns (uint256) {
        return token.balanceOf(_address);
    }

    /**
     * @dev Get token balance of this contract.
     * @return the token balance of this contract.
     */
    function contractTokenBalance() public view returns (uint256) {
        return token.balanceOf(address(this));
    }

    /**
     * @dev Check if address is valid.
     * @param _address address Wallet address.
     * @return true if the address is valid.
     */
    function validAddress(address _address) private view returns (bool) {
        return
            _address != address(0) &&
            _address != address(this) &&
            _address != address(token);
    }
}