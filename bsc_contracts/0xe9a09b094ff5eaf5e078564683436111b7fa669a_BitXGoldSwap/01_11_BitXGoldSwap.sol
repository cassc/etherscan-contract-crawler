// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract BitXGoldSwap is OwnableUpgradeable, AccessControlUpgradeable {
    using SafeMath for uint256;
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    IERC20 BitX;
    IERC20 USDT;
    bool initialized;
    uint256 ratio;
    uint256 commissionRate;
    address private _owner;
    mapping(address => bool) public referrals;

    event Trade(uint256 amount);
    event AddMoreRewardToken(uint256 amount);
    event DepositBitx(uint256 amount);
    event StopTrade();
    event Claim(IERC20 token, uint256 amount);

    /**
     * @dev BitXSwap Upgradable initializer
     * @param _ratio _ratio USDT & BitX ratio
     */

    function __BitXSwap_init(
        uint256 _ratio,
        IERC20 _USDT,
        IERC20 _BitX
    ) external initializer {
        __Ownable_init();
        __AccessControl_init();
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        grantRole(ADMIN_ROLE, _msgSender());
        ratio = _ratio;
        BitX = _BitX;
        USDT = _USDT;
        initialized = true;
    }

    /**
     * @dev add referral
     * @param _referral address of referral
     */

    function addReferral(address _referral) public onlyOwner {
        referrals[_referral] = true;
    }

    /**
     * @dev Swap USDT and BitX
     * @param _affliator affiliator's address
     * @param _amount Amount to be transfered in contract
     */

    function swap(address _affliator, uint256 _amount) public returns (bool) {
        require(initialized == true, "Trade is not started yet");
        require(referrals[_affliator] == true, "Invalid referral's address");
        require(
            (BitX.balanceOf(address(this)) > _amount),
            "Insufficient Amount in contract"
        );
        uint256 rewardamount = _amount.mul(ratio);
        uint256 usdt_amount = (commissionRate * _amount) / 100;
        USDT.transferFrom(msg.sender, _affliator, usdt_amount);
        _amount = _amount - usdt_amount;
        USDT.transferFrom(msg.sender, owner(), _amount);
        BitX.transfer(msg.sender, rewardamount);
        emit Trade(_amount);
        return true;
    }

    /**
     * @dev Swap USDT and BitX
     * @param _amount Amount to be transfered in contract
     */

    function swap(uint256 _amount) public returns (bool) {
        require(initialized == true, "Trade is not started yet");
        require(
            (BitX.balanceOf(address(this)) > _amount),
            "Insufficient Amount in contract"
        );
        uint256 rewardamount = _amount.mul(ratio);
        USDT.transferFrom(msg.sender, owner(), _amount);
        BitX.transfer(msg.sender, rewardamount);
        emit Trade(_amount);
        return true;
    }

    /**
     * @dev transfer bitx tokens to contract
     * @param _amount amount to be transfered
     */

    function depositBitXToken(uint256 _amount) public onlyOwner {
        BitX.transferFrom(msg.sender, address(this), _amount);
        emit DepositBitx(_amount);
    }

    /**
     * @dev Contract balance of BitX Token
     */

    function getBitXTokenBalance() public view returns (uint256 balance) {
        return BitX.balanceOf(address(this));
    }

    /**
     * @dev Withdraw BitX all the tokens from the contract
     * @param _BitX contract address of BitX Token
     */

    function withdrawBitX(IERC20 _BitX) public onlyOwner returns (bool) {
        require(_BitX.balanceOf(address(this)) > 0, "balance is zero");
        _BitX.transferFrom(
            address(this),
            msg.sender,
            _BitX.balanceOf(address(this))
        );
        emit Claim(_BitX, _BitX.balanceOf(address(this)));
        return true;
    }

    /**
     * @dev Stop trading
     */

    function stopTrading() public onlyOwner {
        initialized = false;
        emit StopTrade();
    }

    /**
     * @dev change the ratio
     * @param _ratio USDT & BitX ratio
     */

    function changeRatio(uint256 _ratio) public onlyRole(ADMIN_ROLE) {
        ratio = _ratio;
    }

    /**
     * @dev Get the ratio
     */

    function getRatio() public view returns (uint256) {
        return ratio;
    }

    /**
     * @dev change the comission ratio
     * @param _commissionRate USDT & BitX ratio
     */

    function changeComission(uint256 _commissionRate) public onlyOwner {
        commissionRate = _commissionRate;
    }

    /**
     * @dev Get the commission Rate
     */

    function getComission() public view returns (uint256) {
        return commissionRate;
    }
}