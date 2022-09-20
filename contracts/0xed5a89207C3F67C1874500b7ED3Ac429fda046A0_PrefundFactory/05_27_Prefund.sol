// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableMap.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

    error InvalidAddress();
    error Unauthorized();
    error AcceptedTokensLimitExceeded();
    error EndTimeMustBeGreaterThanStartTime();
    error NotAcceptedToken();
    error PrefundClosed();
    error PrefundNotFinished();
    error DepositsNotReleased();
    error DepositsAlreadyReleased();
    error NotEnoughDeposit();
    error OnlyTokensAccepted();
    error OnlyEtherAccepted();
    error NothingToWithdraw();
    error InvalidAcceptedTokenDecimals();

/**
 * @title Prefund
 */
contract Prefund is AccessControlUpgradeable {
    using SafeERC20Upgradeable for ERC20Upgradeable;
    using SafeMathUpgradeable for uint256;
    using EnumerableMap for EnumerableMap.AddressToUintMap;

    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");
    uint8 private constant _ACCEPTED_TOKENS_LIMIT = 5;

    uint256 public startTime;
    uint256 public endTime;
    uint256 public minimumDeposit;
    address[] public _acceptedTokens;
    address public propertyToken;
    bool public depositsReleased;
    uint256 public totalAmountOfPropertyTokens;
    bool public isEtherPrefund;

    // The fraction is used to calculate the left amount in deposits after paying for property tokens
    uint256 private _fractionN;
    uint256 private _fractionD;

    struct TokenDeposit {
        EnumerableMap.AddressToUintMap perToken;
        uint256 total;
    }

    mapping(address => TokenDeposit) private _deposits;
    TokenDeposit private _totalDeposit;

    event DepositFunds(address indexed account, address indexed token, uint256 amount);
    event PayForPropertyTokens(address indexed propertyToken, uint256 amount, uint256 tokenPrice, address recipient);
    event ReleaseDeposits();
    event WithdrawDeposit(address indexed account, address[] tokens, uint256[] amounts);
    event WithdrawPropertyTokens(address indexed account, address indexed propertyToken, uint256 amount);

    function initialize(
        address admin,
        address operator,
        uint256 startTimeValue,
        uint256 endTimeValue,
        uint256 minimumDepositValue,
        bool isEtherPrefundValue,
        address[] memory acceptedTokensValue
    ) public initializer {
        if (!_addressIsValid(admin) || !_addressIsValid(operator))
            revert InvalidAddress();
        if (endTimeValue < startTimeValue)
            revert EndTimeMustBeGreaterThanStartTime();
        if (_acceptedTokens.length > _ACCEPTED_TOKENS_LIMIT)
            revert AcceptedTokensLimitExceeded();

        startTime = startTimeValue;
        endTime = endTimeValue;
        minimumDeposit = minimumDepositValue;
        isEtherPrefund = isEtherPrefundValue;
        if (!isEtherPrefund) {
            _assertAcceptedTokens(acceptedTokensValue);
            _acceptedTokens = acceptedTokensValue;
        }

        _setupRole(OPERATOR_ROLE, operator);
        _setupRole(DEFAULT_ADMIN_ROLE, admin);
    }

    function setStartTime(uint256 newStartTime) external onlyRole(OPERATOR_ROLE) {
        if (endTime < newStartTime)
            revert EndTimeMustBeGreaterThanStartTime();

        startTime = newStartTime;
    }

    function setEndTime(uint256 newEndTime) external onlyRole(OPERATOR_ROLE) {
        if (newEndTime < startTime)
            revert EndTimeMustBeGreaterThanStartTime();

        endTime = newEndTime;
    }

    function setMinimumDeposit(uint256 newMinimumDeposit) external onlyRole(OPERATOR_ROLE) {
        minimumDeposit = newMinimumDeposit;
    }

    function setAcceptedTokens(address[] memory newAcceptedTokens) external onlyRole(OPERATOR_ROLE) {
        _assertAcceptedTokens(newAcceptedTokens);
        _acceptedTokens = newAcceptedTokens;
    }

    receive() external payable {
        if (!isEtherPrefund)
            revert OnlyTokensAccepted();
        if (!isOpen())
            revert PrefundClosed();
        if (msg.value < minimumDeposit)
            revert NotEnoughDeposit();

        _depositFunds(_msgSender(), address(0), msg.value);
    }

    function depositFunds(address token, uint256 amount) external {
        if (isEtherPrefund)
            revert OnlyEtherAccepted();
        if (!isAcceptedToken(token))
            revert NotAcceptedToken();
        if (!isOpen())
            revert PrefundClosed();
        if (_normalize(token, _deposits[_msgSender()].total + amount) < minimumDeposit)
            revert NotEnoughDeposit();

        // Transfer sent tokens to the contract
        ERC20Upgradeable(token).safeTransferFrom(_msgSender(), address(this), amount);

        _depositFunds(_msgSender(), address(token), amount);
    }

    function payForPropertyTokensAndReleaseDeposits(
        address propertyTokenAddress,
        uint256 amountOfTokens,
        uint256 tokenPrice,
        address payable recipient
    ) external onlyRole(OPERATOR_ROLE) {
        if (!isFinished())
            revert PrefundNotFinished();
        if (!_addressIsValid(recipient) || !_addressIsValid(address(propertyTokenAddress)))
            revert InvalidAddress();
        if (depositsReleased)
            revert DepositsAlreadyReleased();

        // Transfer property tokens to the prefund contract
        ERC20Upgradeable(propertyTokenAddress).safeTransferFrom(_msgSender(), address(this), amountOfTokens);

        // Calculate amount to pay for property tokens to the recipient
        uint256 amountToPay = amountOfTokens.mul(tokenPrice).div(10 ** 18);

        // Set divider parameter,
        _fractionN = _totalDeposit.total.sub(amountToPay);
        _fractionD = _totalDeposit.total;

        totalAmountOfPropertyTokens = amountOfTokens;
        propertyToken = propertyTokenAddress;

        // Transfer tokens from deposit proportionally for every token type and update deposit state
        for (uint i = 0; i < _totalDeposit.perToken.length(); i++) {
            (address token, uint256 depositAmount) = _totalDeposit.perToken.at(i);
            uint256 amount = depositAmount.mul(amountToPay).div(_totalDeposit.total);
            _totalDeposit.perToken.set(token, depositAmount.sub(amount));
            _totalDeposit.total = _totalDeposit.total.sub(amount);

            if (token == address(0)) {
                recipient.transfer(amount);
            } else {
                ERC20Upgradeable(token).safeTransfer(recipient, amount);
            }
        }

        _releaseDeposits();
        emit PayForPropertyTokens(address(propertyTokenAddress), amountOfTokens, tokenPrice, recipient);
    }

    function releaseDeposits() public onlyRole(OPERATOR_ROLE) {
        if (!isFinished())
            revert PrefundNotFinished();
        if (depositsReleased)
            revert DepositsAlreadyReleased();

        _releaseDeposits();
    }

    function withdrawAll() external {
        if (!depositsReleased)
            revert DepositsNotReleased();
        if (!canWithdraw(_msgSender()))
            revert NothingToWithdraw();

        _withdrawAll(_msgSender());
    }

    function withdrawAllForAccount(address account) external {
        if (!_addressIsValid(account))
            revert InvalidAddress();
        if (!depositsReleased)
            revert DepositsNotReleased();
        if (!canWithdraw(account))
            revert NothingToWithdraw();

        _withdrawAll(account);
    }

    /**
     * @dev Remember that only admin can call so be careful when use on contracts generated from other contracts.
     * @param token The token contract address
     * @param amount Number of tokens to be sent
     */
    function recoverERC20(address token, uint256 amount) public virtual onlyRole(DEFAULT_ADMIN_ROLE) {
        ERC20Upgradeable(token).transfer(_msgSender(), amount);
    }

    function isAcceptedToken(address token) public view returns (bool) {
        for (uint i = 0; i < _acceptedTokens.length; i++) {
            if (_acceptedTokens[i] == token)
                return true;
        }
        return false;
    }

    function isOpen() public view returns (bool) {
        return !(block.timestamp < startTime || block.timestamp > endTime);
    }

    function isFinished() public view returns (bool) {
        return block.timestamp > endTime;
    }

    function accountDeposit(address account) public view returns (uint256, address[] memory, uint256[] memory) {
        address[] memory tokens = new address[](_deposits[account].perToken.length());
        uint256[] memory amounts = new uint256[](_deposits[account].perToken.length());

        uint256 total = 0;

        for (uint i = 0; i < tokens.length; i++) {
            (address token, uint256 depositAmount) = _deposits[account].perToken.at(i);
            tokens[i] = token;
            if (totalAmountOfPropertyTokens != 0) {
                amounts[i] = depositAmount.mul(_fractionN).div(_fractionD);
            } else {
                amounts[i] = depositAmount;
            }
            total = total.add(amounts[i]);
        }

        return (total, tokens, amounts);
    }

    function totalDeposit() public view returns (uint256, address[] memory, uint256[] memory) {
        address[] memory tokens = new address[](_totalDeposit.perToken.length());
        uint256[] memory amounts = new uint256[](_totalDeposit.perToken.length());

        for (uint i = 0; i < tokens.length; i++) {
            (address token, uint256 depositAmount) = _totalDeposit.perToken.at(i);
            tokens[i] = token;
            amounts[i] = depositAmount;
        }

        return (_totalDeposit.total, tokens, amounts);
    }

    function amountOfPropertyTokens(address account) public view returns (uint256) {
        return totalAmountOfPropertyTokens.mul(_deposits[account].total).div(_fractionD);
    }

    function acceptedTokens() public view returns (address[] memory) {
        return _acceptedTokens;
    }

    function canWithdraw(address account) public view returns (bool) {
        (uint256 total,,) = accountDeposit(account);
        if (depositsReleased && total > 0)
            return true;
        if (_addressIsValid(address(propertyToken)) && amountOfPropertyTokens(account) > 0)
            return true;
        return false;
    }

    function _depositFunds(address account, address token, uint256 amount) internal {
        // Increase account deposit
        _deposits[account].total += amount;

        // Increase account deposit per token
        (, uint256 accountDepositPerToken) = _deposits[account].perToken.tryGet(token);
        _deposits[account].perToken.set(token, accountDepositPerToken.add(amount));

        // Increase total deposit
        _totalDeposit.total += amount;

        // Increase total deposit per token
        (,uint256 totalDepositPerToken) = _totalDeposit.perToken.tryGet(token);
        _totalDeposit.perToken.set(token, totalDepositPerToken.add(amount));

        emit DepositFunds(account, token, amount);
    }

    function _withdrawAll(address account) internal {
        _transferPropertyTokens(account);

        (uint256 total, address[] memory tokens, uint256[] memory amounts) = accountDeposit(account);

        _deposits[account].total = 0;
        _totalDeposit.total = _totalDeposit.total.sub(total);

        // Transfer all tokens from deposit
        for (uint i = 0; i < tokens.length; i++) {
            _deposits[account].perToken.set(tokens[i], 0);
            uint256 totalDepositPerToken = _totalDeposit.perToken.get(address(tokens[i])).sub(amounts[i]);
            _totalDeposit.perToken.set(tokens[i], totalDepositPerToken);

            if (tokens[i] == address(0) && amounts[i] > 0) {
                payable(account).transfer(amounts[i]);
            } else if (amounts[i] > 0) {
                ERC20Upgradeable(tokens[i]).safeTransfer(account, amounts[i]);
            }
        }

        emit WithdrawDeposit(account, tokens, amounts);
    }

    function _releaseDeposits() internal {
        depositsReleased = true;
        emit ReleaseDeposits();
    }

    function _transferPropertyTokens(address account) internal {
        if (_addressIsValid(address(propertyToken))) {
            uint256 amount = amountOfPropertyTokens(account);
            if (amount != 0) {
                ERC20Upgradeable(propertyToken).safeTransfer(account, amount);
                emit WithdrawPropertyTokens(account, address(propertyToken), amount);
            }
        }
    }

    function _addressIsValid(address addr) internal pure returns (bool) {
        return addr != address(0);
    }

    function _normalize(address token, uint256 amount) internal view returns (uint256) {
        return amount.mul(10 ** 18).div(10 ** ERC20Upgradeable(token).decimals());
    }

    function _assertAcceptedTokens(address[] memory tokens) internal view {
        if (tokens.length > _ACCEPTED_TOKENS_LIMIT)
            revert AcceptedTokensLimitExceeded();
        for (uint i = 0; i < tokens.length; i++) {
            if (ERC20(tokens[i]).decimals() != ERC20(tokens[0]).decimals())
                revert InvalidAcceptedTokenDecimals();
        }
    }
}