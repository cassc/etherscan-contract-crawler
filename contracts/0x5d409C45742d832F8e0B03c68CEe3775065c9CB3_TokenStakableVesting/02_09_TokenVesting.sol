// SPDX-License-Identifier: MIT

pragma solidity =0.8.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

/**
 * @title TokenVesting
 * @dev Vesting for BEP20 compatible token.
 */
contract TokenVesting is Ownable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    bool private _locked;

    IERC20 public token;
    address public vault;
    uint256 public immutable stopTime;
    uint256 public immutable initTime;
    uint256 public immutable startPercent;
    uint256 public immutable maxPenalty;

    mapping(address => uint256) public currentBalances;
    mapping(address => uint256) public initialBalances;

    event Released(address indexed from, address indexed user, address indexed token, uint256 amount);
    event TokenAddressChanged(address indexed token);
    event VaultAddressChanged(address indexed vault);
    event BeneficiariesChanged();

    constructor(uint128 _initTime, uint128 _stopTime, uint128 _startPercent, uint128 _maxPenalty) {
        require(_startPercent <= 100, "TokenVesting: Percent of tokens available after initial time cannot be greater than 100");
        require(_stopTime > _initTime, "TokenVesting: End time must be greater than start time");

        stopTime = _stopTime;
        initTime = _initTime;
        startPercent = _startPercent;
        maxPenalty = _maxPenalty;
    }

    /**
     * @dev Sets token address.
     * @param _token IERC20 address.
     */
    function setTokenAddress(IERC20 _token) public onlyOwner {
        require(address(_token) != address(0), 'TokenVesting: Token address needs to be different than zero!');
        require(address(token) == address(0), 'TokenVesting: Token already set!');
        token = _token;
        emit TokenAddressChanged(address(token));
    }

    /**
     * @dev Sets vault address.
     * @param _vault IERC20 address.
     */
    function setVaultAddress(address _vault) public onlyOwner {
        require(_vault != address(0), 'TokenVesting: Vault address needs to be different than zero!');
        require(vault == address(0), 'TokenVesting: Vault already set!');
        vault = _vault;
        emit VaultAddressChanged(vault);
    }

    /**
     * @dev Add beneficiaries
     */
    function addBeneficiaries(address[] memory beneficiaries, uint256[] memory balances) public onlyOwner {
        require(beneficiaries.length == balances.length, "TokenVesting: Beneficiaries and amounts must have the same length");
        require(!isLocked(), "TokenVesting: Contract has already been locked");

        for (uint256 i = 0; i < beneficiaries.length; ++i) {
            currentBalances[beneficiaries[i]] = balances[i];
            initialBalances[beneficiaries[i]] = balances[i];
        }
        emit BeneficiariesChanged();
    }

    /**
     * @dev Lock the contract
     */
    function lock() public onlyOwner {
        _locked = true;
    }

    /**
     * @dev Check if contract is locked
     */
    function isLocked() public view returns (bool) {
        return _locked;
    }

    /**
     * @dev Sends specific amount of released tokens and send it to sender
     */
    function release() public {
        _release(msg.sender, msg.sender, currentBalance(msg.sender), 0);
    }

    /**
     * @dev Sends specific amount of released tokens and send it to sender
     */
    function release(uint256 amount) public {
        _release(msg.sender, msg.sender, amount, 0);
    }

    /**
     * @dev Sends specific amount of released tokens and send it to sender
     */
    function release(uint256 amount, uint256 flag) public {
        _release(msg.sender, msg.sender, amount, flag & 1);
    }

    /**
     * @dev Sends specific amount of released tokens and send it to sender
     */
    function _release(address from, address addr, uint256 amount, uint256 flag) internal returns (uint256) {
        require(address(token) != address(0), "TokenVesting: Not configured yet");
        require(isLocked(), "TokenVesting: Not locked yet");
        require(block.timestamp >= initTime, "TokenVesting: Cannot release yet");
        require(initialBalances[from] > 0, "TokenVesting: Invalid beneficiary");
        require(currentBalances[from] > 0, "TokenVesting: Balance was already emptied");

        bool addFeeToAmount = 1 == flag & 1;
        bool excludeFromFee = 2 == flag & 2;
        bool excludeDeliver = 4 == flag & 4;

        uint256 feeval = 0;
        uint256 penalty = excludeFromFee ? 0 : currentPenalty();
        uint256 neededAmount = 0;

        if (!addFeeToAmount && penalty != 0) {
            feeval = amount.mul(penalty).div(1000);
            amount = amount.sub(feeval);
        }
        if ( addFeeToAmount && penalty != 0) {
            feeval = amount.mul(1000).div(penalty).sub(amount);
        }
        neededAmount = amount + feeval;

        require(neededAmount > 0, "TokenVesting: Nothing to withdraw at this time");
        require(currentBalances[from] >= neededAmount, "TokenVesting: Invalid amount");
        currentBalances[from] = currentBalances[from].sub(neededAmount);

        if (amount > 0 && !excludeDeliver) {
            token.safeTransfer(addr, amount);
            emit Released(from, addr, address(token), amount);
        }
        if (feeval > 0 && !excludeDeliver) {
            token.safeTransfer(vault, feeval);
            emit Released(from, vault, address(token), feeval);
        }

        return neededAmount;
    }

    /**
     * @dev Returns current balance for given address.
     * @param beneficiary Address to check.
     */
    function currentBalance(address beneficiary) public view returns (uint256) {
        return currentBalances[beneficiary];
    }

    /**
     * @dev Returns initial balance for given address.
     * @param beneficiary Address to check.
     */
    function initialBalance(address beneficiary) public view returns (uint256) {
        return initialBalances[beneficiary];
    }

    /**
     * @dev Returns total withdrawn for given address.
     * @param beneficiary Address to check.
     */
    function releaseBalance(address beneficiary) public view returns (uint256) {
        return (initialBalances[beneficiary].sub(currentBalances[beneficiary]));
    }

    /**
     * @dev Returns withdrawal limit for given address.
     * @param beneficiary Address to check.
     */
    function allowedBalance(address beneficiary) public view returns (uint256) {
        return currentBalance(beneficiary).mul(1000 - currentPenalty()).div(1000);
    }

    function currentPenalty() public view returns (uint256) {
        return timeboundPenalty(block.timestamp);
    }

    /**
     * @dev Returns timebound penalty
     */
    function timeboundPenalty(uint256 timer) public view returns (uint256) {
        if (address(token) == address(0) || timer < initTime) {
            return 1000;
        }
        if (timer >= stopTime) {
            return 0;
        }
        uint256 curTimeDiff = timer.sub(initTime);
        uint256 maxTimeDiff = stopTime.sub(initTime);

        uint256 beginPromile = startPercent.mul(10);
        uint256 otherPromile = curTimeDiff.mul(uint256(1000).sub(beginPromile)).div(maxTimeDiff);
        uint256 promile = beginPromile.add(otherPromile);
        if (promile >= 1000) promile = 1000;

        return uint256(1000).sub(promile).mul(maxPenalty).div(100);
    }

    /**
     * @dev Returns current token balance.
     */
    function balance() public view returns (uint256) {
        return (address(token) == address(0)) ? 0 : token.balanceOf(address(this));
    }
}