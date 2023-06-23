// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { SafeMath } from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title TokenPreTimeLock Contract
 */

contract TokenPreTimelock is Ownable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    // boolean to prevent reentrancy
    bool internal locked;

    // Contract owner access
    bool public allIncomingDepositsFinalised;

    // Timestamp related variables
    bool public timestampSet;
    uint256 public initialTimestamp;
    uint256 public timePeriod;

    address public tokenSale;

    // address of the token
    IERC20 private immutable _token;

    // Token amount variables
    mapping(address => uint256) public alreadyWithdrawn;
    mapping(address => uint256) public balances;

    // Events
    event TokensDeposited(address from, uint256 amount);
    event AllocationPerformed(address recipient, uint256 amount);
    event TokensUnlocked(address recipient, uint256 amount);

    constructor(address token_) {
        require(token_ != address(0x0), "TokenPreTimelock: _erc20_contract_address address can not be zero");
        _token = IERC20(token_);
        allIncomingDepositsFinalised = false;
        timestampSet = false;
        locked = false;
    }

    /**
     * @dev Prevents reentrancy
     */
    modifier noReentrant() {
        require(!locked, "TokenPreTimelock: No re-entrancy");
        locked = true;
        _;
        locked = false;
    }

    /**
     * @dev Throws if allIncomingDepositsFinalised is true.
     */
    modifier incomingDepositsStillAllowed() {
        require(allIncomingDepositsFinalised == false, "TokenPreTimelock: Incoming deposits have been finalised.");
        _;
    }

    /**
     * @dev Throws if msg.sender is not token sale contract.
     */
    modifier onlyTokenSale() {
        require(msg.sender == tokenSale, "TokenPreTimelock: Incoming deposits have been finalised.");
        _;
    }

    /**
     * @dev Throws if timestamp already set.
     */
    modifier timestampNotSet() {
        require(timestampSet == false, "TokenPreTimelock: The time stamp has already been set.");
        _;
    }

    /**
     * @dev Throws if timestamp not set.
     */
    modifier timestampIsSet() {
        require(timestampSet == true, "TokenPreTimelock: Please set the time stamp first, then try again.");
        _;
    }

    /**
     * @dev Returns the address of the ERC20 token managed by the vesting contract.
     */
    function getToken() external view returns (address) {
        return address(_token);
    }

    /**
     * @dev Sets the initial timestamp and calculates locking period variables i.e. twelveMonths etc.
     *      setting the time stamp will also finalize deposits
     * @param _timePeriodInSeconds amount of seconds to add to the initial timestamp i.e. we are essemtially creating the lockup period here
     */
    function setTimestamp(uint256 _timePeriodInSeconds) public onlyOwner timestampNotSet {
        timestampSet = true;
        allIncomingDepositsFinalised = true;
        initialTimestamp = block.timestamp;
        timePeriod = initialTimestamp.add(_timePeriodInSeconds);
    }

    /**
     * @dev Sets contract address of token sale
     * @param _tokenSale token sale contract address
     */
    function setTokenSale(address _tokenSale) public onlyOwner {
        tokenSale = _tokenSale;
    }

    /**
     * @dev Allows the contract owner to allocate official ERC20 tokens to each future recipient (only one at a time).
     * @param recipient, address of recipient.
     * @param amount to allocate to recipient.
     */
    function depositTokens(address recipient, uint256 amount) public onlyTokenSale incomingDepositsStillAllowed {
        require(recipient != address(0), "TokenPreTimelock: ERC20: transfer to the zero address");
        balances[recipient] = balances[recipient].add(amount);
        emit AllocationPerformed(recipient, amount);
    }

    /**
     * @dev Allows the contract owner to allocate official ERC20 tokens to multiple future recipient in bulk.
     * @param recipients, an array of addresses of the many recipient.
     * @param amounts to allocate to each of the many recipient.
     */
    function bulkDepositTokens(address[] calldata recipients, uint256[] calldata amounts)
        external
        onlyTokenSale
        incomingDepositsStillAllowed
    {
        require(
            recipients.length == amounts.length,
            "TokenPreTimelock: The recipients and amounts arrays must be the same size in length"
        );
        for (uint256 i = 0; i < recipients.length; i++) {
            require(recipients[i] != address(0), "TokenPreTimelock: ERC20: transfer to the zero address");
            balances[recipients[i]] = balances[recipients[i]].add(amounts[i]);
            emit AllocationPerformed(recipients[i], amounts[i]);
        }
    }

    /**
     * @dev Allows recipient to claim tokens after time period has elapsed
     * @param token - address of the official ERC20 token which is being unlocked here.
     * @param receiver - the recipient's account address.
     * @param amount - the amount to unlock (in wei)
     */
    function transferTimeLockedTokensAfterTimePeriod(
        IERC20 token,
        address receiver,
        uint256 amount
    ) public timestampIsSet noReentrant {
        require(receiver != address(0), "ERC20: transfer to the zero address");
        require(balances[msg.sender] >= amount, "Insufficient token balance, try lesser amount");
        require(
            token == _token,
            "TokenPreTimelock: Token parameter must be the same as the erc20 contract address which was passed into the constructor"
        );
        if (block.timestamp >= timePeriod) {
            alreadyWithdrawn[msg.sender] = alreadyWithdrawn[msg.sender].add(amount);
            balances[msg.sender] = balances[msg.sender].sub(amount);
            token.safeTransfer(receiver, amount);
            emit TokensUnlocked(receiver, amount);
        } else {
            revert("TokenPreTimelock: Tokens are only available after correct time period has elapsed");
        }
    }

    /**
     * @dev Transfer accidentally locked ERC20 tokens.
     * @param token - ERC20 token address.
     * @param amount of ERC20 tokens to remove.
     */
    function transferAccidentallyLockedTokens(IERC20 token, uint256 amount) public onlyOwner noReentrant {
        require(address(token) != address(0), "TokenPreTimelock: Token address can not be zero");
        // This function can not access the official timelocked tokens; just other random ERC20 tokens that may have been accidently sent here
        require(
            token != _token,
            "TokenPreTimelock: Token address can not be ERC20 address which was passed into the constructor"
        );
        // Transfer the amount of the specified ERC20 tokens, to the owner of this contract
        token.safeTransfer(msg.sender, amount);
    }

    function getCurrentTime() public view virtual returns (uint256) {
        return block.timestamp;
    }
}