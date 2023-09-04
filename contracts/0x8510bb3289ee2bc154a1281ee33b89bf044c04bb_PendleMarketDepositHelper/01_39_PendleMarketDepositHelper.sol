// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { ReentrancyGuardUpgradeable } from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import { PausableUpgradeable } from "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "hardhat/console.sol";

import { IPendleMarketDepositHelper } from "../interfaces/pendle/IPendleMarketDepositHelper.sol";
import { IBaseRewardPool } from "../interfaces/IBaseRewardPool.sol";
import { IPendleStaking } from "../interfaces/IPendleStaking.sol";
import { IMasterPenpie } from "../interfaces/IMasterPenpie.sol";


/// @title PendlePoolHelper
/// @author Magpie Team
/// @notice This contract is the main contract that user will intreact with in order to depoist Pendle Market Lp token on Penpie. This
///         Helper will be shared among all markets on Pendle to deposit on Penpie.

contract PendleMarketDepositHelper is
    Initializable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    PausableUpgradeable,
    IPendleMarketDepositHelper
{
    using SafeERC20 for IERC20;

    /* ============ Structs ============ */

    struct PoolInfo {
        address rewarder;
        bool isActive;
    }

    /* ============ State Variables ============ */

    IPendleStaking public pendleStaking;

    mapping(address => PoolInfo) public poolInfo;
    mapping(address => bool) private operator;

    address public masterpenpie;

    /* ============ Events ============ */

    event NewDeposit(
        address indexed _user,
        address indexed _market,
        uint256 _amount
    );
    event NewWithdraw(
        address indexed _user,
        address indexed _market,
        uint256 _amount
    );

    /* ============ Errors ============ */

    error DeactivatePool();
    error OnlyOperator();
    error NullAddress();

    /* ============ Constructor ============ */

    constructor() {
        _disableInitializers();
    }

    function __PendleMarketDepositHelper_init(
        address _pendleStaking
    ) public initializer {
        __Ownable_init();
        __ReentrancyGuard_init();
        __Pausable_init();
        pendleStaking = IPendleStaking(_pendleStaking);
        setOperator(_pendleStaking, true);
    }

    /* ============ Modifiers ============ */

    modifier _onlyOperator() {
        if (!operator[msg.sender]) revert OnlyOperator();
        _;
    }

    modifier onlyActivePool(address market) {
        if (!poolInfo[market].isActive) revert DeactivatePool();
        _;
    }

    /* ============ External Getters ============ */

    /// notice get the amount of total staked LP token in master magpie
    function totalStaked(address _market) external view returns (uint256) {
        address rewarder = poolInfo[_market].rewarder;
        return IBaseRewardPool(rewarder).totalStaked();
    }

    /// @notice get the total amount of shares of a user
    /// @param _market the Pendle Market token
    /// @param _address the user
    /// @return the amount of shares
    function balance(
        address _market,
        address _address
    ) external view returns (uint256) {
        address rewarder = poolInfo[_market].rewarder;
        return IBaseRewardPool(rewarder).balanceOf(_address);
    }

    /* ============ External Functions ============ */

    function depositMarket(address _market, uint256 _amount) external {
        _depositMarket(_market, msg.sender, msg.sender, _amount);
    }


    function depositMarketFor(
        address _market,
        address _for,
        uint256 _amount
    ) external {
        _depositMarket(_market, _for, msg.sender, _amount);
    }

    function withdrawMarket(address _market, uint256 _amount) external {
        _withdrawMarket(_market, msg.sender, _amount);
    }
 
    function withdrawMarketWithClaim(address _market, uint256 _amount, bool _doClaim) external {
        if(_doClaim)
           _withdrawMarketWithClaim(_market, msg.sender, _amount);
       else
           _withdrawMarket(_market, msg.sender, _amount);
    }

    function harvest(address _market) external {
        IPendleStaking(pendleStaking).harvestMarketReward(_market);
    }

    /* ============ Internal Functions ============ */

    function _depositMarket(
        address _market,
        address _for,
        address _from,
        uint256 _amount
    ) internal onlyActivePool(_market) nonReentrant {
        IPendleStaking(pendleStaking).depositMarket(
            _market,
            _for,
            _from,
            _amount
        );

        emit NewDeposit(_for, _market, _amount);
    }

    function _withdrawMarket(
        address _market,
        address _for,
        uint256 _amount
    ) internal onlyActivePool(_market) nonReentrant {
        IPendleStaking(pendleStaking).withdrawMarket(_market, _for, _amount);

        emit NewWithdraw(_for, _market, _amount);
    }

    function _withdrawMarketWithClaim(
        address _market,
        address _for,
        uint256 _amount
    ) internal onlyActivePool(_market) nonReentrant {

        IPendleStaking(pendleStaking).withdrawMarket(_market, _for, _amount);
       
        address[] memory lps = new address[](1);
        address[][] memory rewards = new address[][](1);
        lps[0] = _market;
        
        IMasterPenpie(masterpenpie).multiclaimFor( lps, rewards, msg.sender);

        emit NewWithdraw(_for, _market, _amount);   
    }

    /* ============ Admin Functions ============ */

    function setPoolInfo(
        address market,
        address rewarder,
        bool isActive
    ) external _onlyOperator {
        if (rewarder == address(0)) revert NullAddress();
        poolInfo[market] = PoolInfo(rewarder, isActive);
    }

    function setOperator(address _address, bool _value) public onlyOwner {
        operator[_address] = _value;
    }

    function setmasterPenpie(address _masterPenpie) external onlyOwner {
        masterpenpie = _masterPenpie;
    }
}