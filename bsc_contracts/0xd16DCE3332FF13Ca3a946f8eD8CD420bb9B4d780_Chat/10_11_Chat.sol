// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./Claimable.sol";

contract Chat is OwnableUpgradeable, Claimable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    IERC20 private token;
    uint256 private earnings;
    address private beneficiary;
    mapping(uint256 => uint256) private expiretionTimes;
    mapping(address => ChatInfo) private chats;

    event NewChat(
        address _account,
        bool _isPledge,
        uint256 _amount,
        uint256 _expiretionDate
    );
    event Withdraw(address _receive, uint256 _amount);
    event UnlockPledge(address _receive, uint256 _amount);

    struct ChatInfo {
        address account;
        bool isPledge;
        uint256 amount;
        uint256 expiretionDate;
        bool isUnlocked;
    }

    function initialize(
        address _tokenAddress,
        address _beneficiary
    ) public initializer {
        token = IERC20(_tokenAddress);
        beneficiary = _beneficiary;
        __Ownable_init();
    }

    fallback() external payable virtual {}

    receive() external payable virtual {}

    /**
     * @notice get token address
     */
    function getToken() public virtual returns (IERC20) {
        return token;
    }

    /**
     * @dev Throws if called by any account other than the beneficiary.
     */
    modifier onlyBeneficiary() {
        require(
            msg.sender == getBeneficiary(),
            "Ownable: caller is not the beneficiary"
        );
        _;
    }

    /**
     * @notice Returns the address of the current beneficiary.
     */
    function getBeneficiary() public view virtual returns (address) {
        return beneficiary;
    }

    /**
     * @notice change beneficiary
     * @param _newBeneficiary new beneficiary
     */
    function changeBeneficiary(
        address _newBeneficiary
    ) public virtual onlyOwner {
        beneficiary = _newBeneficiary;
    }

    /**
     * @notice set expiretion time for amount
     * @param _amount receive amount
     * @param _expiretionTime expiretionTime
     */
    function setExpiretionTime(
        uint256 _amount,
        uint256 _expiretionTime
    ) public virtual onlyOwner {
        expiretionTimes[_amount] = _expiretionTime;
    }

    /**
     * @notice get expiretionTime with amount
     * @param _amount receive amount
     */
    function getExpiretionTime(
        uint256 _amount
    ) public view virtual returns (uint256) {
        return expiretionTimes[_amount];
    }

    /**
     * @dev increace earnings
     * @param _amount amount
     */
    function _increaseEarnings(uint256 _amount) internal {
        earnings = earnings.add(_amount);
    }

    /**
     * @dev reduce Earnings
     * @param _amount amount
     */
    function _reduceEarnings(uint256 _amount) internal {
        earnings = earnings.sub(_amount);
    }

    /**
     * @notice get earnings
     */
    function getEarnings() public view virtual returns (uint256) {
        return earnings;
    }

    /**
     * @notice get chat with account
     * @param _account account
     */
    function getChat(
        address _account
    ) public view virtual returns (ChatInfo memory) {
        return chats[_account];
    }

    /**
     * @notice new pledge for user
     */
    function newPledge(uint256 _amount) public virtual {
        address account = _msgSender();
        _newChat(account, _amount, true);
    }

    /**
     * @notice new consume for user
     */
    function newConsume(uint256 _amount) public virtual {
        address account = _msgSender();
        _newChat(account, _amount, false);
        _increaseEarnings(_amount);
    }

    /**
     * @dev new Chat
     * @param _account sender
     * @param _amount amount
     * @param _isPledge isPledge
     */
    function _newChat(
        address _account,
        uint256 _amount,
        bool _isPledge
    ) internal {
        bool exist = chats[_account].amount != 0;
        if (exist) {
            ChatInfo memory ci = chats[_account];
            if (ci.isPledge) {
                require(
                    ci.isUnlocked,
                    "the stake has not expired or been unlocked"
                );
            } else {
                require(
                    ci.expiretionDate < block.timestamp,
                    "the consumption has not expired, please do not make repeated purchases"
                );
            }
        }
        require(_amount > 0, "amount must be greater than 0");
        uint256 expiretionTime = getExpiretionTime(_amount);
        require(
            expiretionTime > 0,
            "there is no matching value for the amount"
        );
        uint256 expiretionDate = block.timestamp.add(expiretionTime);
        token.safeTransferFrom(_account, address(this), _amount);
        ChatInfo memory c = ChatInfo(
            _account,
            _isPledge,
            _amount,
            expiretionDate,
            false
        );
        chats[_account] = c;
        emit NewChat(_account, _isPledge, _amount, expiretionDate);
    }

    /**
     * @dev terminate the contract
     */
    function unlockPledge() external {
        address account = _msgSender();
        require(chats[account].amount != 0, "the account is not exist");
        ChatInfo memory c = chats[account];
        require(c.isPledge, "the account is not pledged");
        require(!c.isUnlocked, "contract has already been unlocked");
        require(
            c.expiretionDate < block.timestamp,
            "the account pledge unlock time has not yet arrived"
        );
        require(
            token.balanceOf(address(this)) >= c.amount,
            "contract: insufficient balance"
        );
        token.safeTransfer(account, c.amount);
        delete chats[account];
        emit UnlockPledge(account, c.amount);
    }

    /**
     * @notice claimValues
     * @param token_ token
     * @param to_ to
     */
    function claimValues(address token_, address to_) public virtual onlyOwner {
        require(token_ != address(token), "invalid address");
        _claimValues(token_, to_);
    }

    /**
     * @notice withdraw
     */
    function withdraw(uint256 _amount) public virtual onlyBeneficiary {
        require(earnings > 0, "no amount available for withdrawal");
        require(_amount <= earnings, "not enough withdrawal amount");
        token.safeTransfer(_msgSender(), _amount);
        _reduceEarnings(_amount);
        emit Withdraw(_msgSender(), _amount);
    }
}