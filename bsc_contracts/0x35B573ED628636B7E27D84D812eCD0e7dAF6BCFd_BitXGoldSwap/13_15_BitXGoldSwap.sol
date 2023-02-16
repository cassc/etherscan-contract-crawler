// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./IBitXGoldSwap.sol";
import "./IBitXStaking.sol";

contract BitXGoldSwap is
    OwnableUpgradeable,
    AccessControlUpgradeable,
    IBitXGoldSwap
{
    using SafeMath for uint256;
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant TRANSFER_ROLE = keccak256("TRANSFER_ROLE");

    IERC20 BXG;
    IERC20 USDT;
    IBitXStaking Stake;
    bool initialized;
    uint256 ratio;
    uint256 commissionRate;
    address private _owner;
    mapping(address => bool) public ReferralStatus;
    mapping(address => address) public Referral;

    event Buy(uint256 amount);
    event Sell(uint256 amount);
    event AddReferrals(address referral, address referrer);
    event AddMoreRewardToken(uint256 amount);
    event DepositBitx(uint256 amount);
    event StopTrade();
    event Claim(IERC20 token, uint256 amount);

    /**
     * @dev BitXSwap Upgradable initializer
     * @param _ratio ratio USDT & BXG ratio
     */

    function __BitXSwap_init(
        uint256 _ratio,
        IERC20 _USDT,
        IERC20 _BXG
    ) external initializer {
        __Ownable_init();
        __AccessControl_init();
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        grantRole(ADMIN_ROLE, _msgSender());
        ratio = _ratio;
        BXG = _BXG;
        USDT = _USDT;
        initialized = true;
        commissionRate = 10e18;
    }

    /**
     * @dev add referral
     * @param _referral address of referral
     */

    function addReferral(address[] memory _referrals, address _referral) public {
        require(Referral[msg.sender] == address(0), "Already reffered");
        Stake.addReferral(_referrals,msg.sender);
        Referral[msg.sender] = _referral;
        ReferralStatus[msg.sender] = false;
        emit AddReferrals(_referral, msg.sender);
    }

    /**
     * @dev Swap USDT and BXG
     * @param _amount Amount to be transfered in contract
     */

    function swapBuy(uint256 _amount) public returns (bool) {
        require(initialized == true, "Trade is not started yet");
        require(
            (BXG.balanceOf(address(this)) > _amount),
            "Insufficient Amount in contract"
        );

        uint256 usdt_amount = _amount.mul(ratio) / 1e18;
        require(
            USDT.balanceOf(msg.sender) >= usdt_amount,
            "You have Insufficient USDT"
        );
        if (
            ReferralStatus[msg.sender] == false &&
            Referral[msg.sender] != address(0)
        ) {
            uint256 referralReward = (commissionRate * usdt_amount) / 100e18;
            usdt_amount = usdt_amount - referralReward;

            USDT.transferFrom(msg.sender, Referral[msg.sender], referralReward);
            ReferralStatus[msg.sender] = true;
        }
        USDT.transferFrom(msg.sender, owner(), usdt_amount);
        BXG.transfer(msg.sender, _amount);
        emit Buy(_amount);
        return true;
    }

    /**
     * @dev Swap BXG and USDT
     * @param _amount Amount to be transfered in contract
     */

    function swapSell(uint256 _amount) public returns (bool) {
        require(initialized == true, "Trade is not started yet");
        require(
            (BXG.balanceOf(address(this)) > _amount),
            "Insufficient Amount in contract"
        );
        uint256 rewardamount = _amount.mul(ratio) / 1e18;
        BXG.transferFrom(msg.sender, owner(), _amount);
        USDT.transfer(msg.sender, rewardamount);
        emit Sell(_amount);
        return true;
    }

    /**
     * @dev transfer bitx tokens to contract
     * @param _amount amount to be transfered
     */

    function depositBitXToken(uint256 _amount) public onlyOwner {
        BXG.transferFrom(msg.sender, address(this), _amount);
        emit DepositBitx(_amount);
    }

    /**
     * @dev transfer USDT tokens to contract
     * @param _amount amount to be transfered
     */

    function depositUSDTToken(uint256 _amount) public onlyOwner {
        USDT.transferFrom(msg.sender, address(this), _amount);
        emit DepositBitx(_amount);
    }

    /**
     * @dev Contract balance of BXG Token
     */

    function getBitXTokenBalance() public view returns (uint256 balance) {
        return BXG.balanceOf(address(this));
    }

    /**
     * @dev Contract balance of USDT Token
     */

    function getUSDTTokenBalance() public view returns (uint256 balance) {
        return USDT.balanceOf(address(this));
    }

    /**
     * @dev Withdraw BXG all the tokens from the contract
     * @param _BXG contract address of BXG Token
     */

    function withdrawBitX(IERC20 _BXG) public onlyOwner returns (bool) {
        require(_BXG.balanceOf(address(this)) > 0, "balance is zero");
        _BXG.transferFrom(
            address(this),
            msg.sender,
            _BXG.balanceOf(address(this))
        );
        emit Claim(_BXG, _BXG.balanceOf(address(this)));
        return true;
    }

    /**
     * @dev Withdraw USDT all the tokens from the contract
     * @param _USDT contract address of BXG Token
     */

    function withdrawUSDT(IERC20 _USDT) public onlyOwner returns (bool) {
        require(_USDT.balanceOf(address(this)) > 0, "balance is zero");
        _USDT.transferFrom(
            address(this),
            msg.sender,
            BXG.balanceOf(address(this))
        );
        emit Claim(_USDT, _USDT.balanceOf(address(this)));
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
     * @param _ratio USDT & BXG ratio
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
     * @param _commissionRate USDT & BXG ratio
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

    function transferReward(address _to, uint256 _amount)
        external
        override
        onlyRole(TRANSFER_ROLE)
    {
        BXG.transfer(_to, _amount);
    }

    function setStakingContract(IBitXStaking _staking) public onlyOwner{
        Stake=_staking;
    }
}