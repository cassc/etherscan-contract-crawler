// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

import "./libs/SafeMath.sol";
import "./libs/Ownable.sol";
import "./libs/SafeERC20.sol";
import "./interfaces/IERC20.sol";
import "./interfaces/IStaking.sol";
import "./interfaces/IsPSI.sol";
import "./interfaces/IWarmup.sol";
import "./interfaces/IDistributor.sol";

contract Staking is Ownable {

    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    address public immutable PSI;
    address public immutable sPSI;

    struct Epoch {
        uint length;
        uint number;
        uint endBlock;
        uint distribute;
    }

    Epoch public epoch;

    address public distributor;

    address public locker;
    uint public totalBonus;

    address public warmupContract;
    uint public warmupPeriod;

    constructor (
        address _PSI,
        address _sPSI,
        uint _epochLength
    ) {
        require(_PSI != address(0));
        PSI = _PSI;
        require(_sPSI != address(0));
        sPSI = _sPSI;

        epoch = Epoch({
        length : _epochLength,
        number : 1,
        endBlock : block.number,
        distribute : 0
        });
    }

    struct Claim {
        uint deposit;
        uint gons;
        uint expiry;
        bool lock; // prevents malicious delays
    }

    mapping(address => Claim) public warmupInfo;

    /**
        @notice stake PSI to enter warmup
        @param _amount uint
        @return bool
     */
    function stake(uint _amount, address _recipient) external returns (bool) {
        rebase();

        IERC20(PSI).safeTransferFrom(msg.sender, address(this), _amount);

        Claim memory info = warmupInfo[_recipient];
        require(!info.lock, "Deposits for account are locked");

        warmupInfo[_recipient] = Claim({
        deposit : info.deposit.add(_amount),
        gons : info.gons.add(IsPSI(sPSI).gonsForBalance(_amount)),
        expiry : epoch.number.add(warmupPeriod),
        lock : false
        });

        IERC20(sPSI).safeTransfer(warmupContract, _amount);
        return true;
    }

    /**
        @notice retrieve sPSI from warmup
        @param _recipient address
     */
    function claim(address _recipient) public {
        Claim memory info = warmupInfo[_recipient];
        if (epoch.number >= info.expiry && info.expiry != 0) {
            delete warmupInfo[_recipient];
            IWarmup(warmupContract).retrieve(_recipient, IsPSI(sPSI).balanceForGons(info.gons));
        }
    }

    /**
        @notice forfeit sPSI in warmup and retrieve PSI
     */
    function forfeit() external {
        Claim memory info = warmupInfo[msg.sender];
        delete warmupInfo[msg.sender];

        IWarmup(warmupContract).retrieve(address(this), IsPSI(sPSI).balanceForGons(info.gons));
        IERC20(PSI).safeTransfer(msg.sender, info.deposit);
    }

    /**
        @notice prevent new deposits to address (protection from malicious activity)
     */
    function toggleDepositLock() external {
        warmupInfo[msg.sender].lock = !warmupInfo[msg.sender].lock;
    }

    /**
        @notice redeem sPSI for PSI
        @param _amount uint
        @param _trigger bool
     */
    function unstake(uint _amount, bool _trigger) external {
        if (_trigger) {
            rebase();
        }
        IERC20(sPSI).safeTransferFrom(msg.sender, address(this), _amount);
        IERC20(PSI).safeTransfer(msg.sender, _amount);
    }

    /**
        @notice returns the sPSI index, which tracks rebase growth
        @return uint
     */
    function index() public view returns (uint) {
        return IsPSI(sPSI).index();
    }

    /**
        @notice trigger rebase if epoch over
     */
    function rebase() public {
        if (epoch.endBlock <= block.number) {
            IsPSI(sPSI).rebase(epoch.distribute, epoch.number);

            epoch.endBlock = epoch.endBlock.add(epoch.length);
            epoch.number++;

            if (distributor != address(0)) {
                IDistributor(distributor).distribute();
            }

            uint balance = contractBalance();
            uint staked = IsPSI(sPSI).circulatingSupply();

            if (balance <= staked) {
                epoch.distribute = 0;
            } else {
                epoch.distribute = balance.sub(staked);
            }
        }
    }

    /**
        @notice returns contract PSI holdings, including bonuses provided
        @return uint
     */
    function contractBalance() public view returns (uint) {
        return IERC20(PSI).balanceOf(address(this)).add(totalBonus);
    }

    /**
        @notice provide bonus to locked staking contract
        @param _amount uint
     */
    function giveLockBonus(uint _amount) external {
        require(msg.sender == locker);
        totalBonus = totalBonus.add(_amount);
        IERC20(sPSI).safeTransfer(locker, _amount);
    }

    /**
        @notice reclaim bonus from locked staking contract
        @param _amount uint
     */
    function returnLockBonus(uint _amount) external {
        require(msg.sender == locker);
        totalBonus = totalBonus.sub(_amount);
        IERC20(sPSI).safeTransferFrom(locker, address(this), _amount);
    }

    enum CONTRACTS {DISTRIBUTOR, WARMUP, LOCKER}

    /**
        @notice sets the contract address for LP staking
        @param _contract address
     */
    function setContract(CONTRACTS _contract, address _address) external onlyManager() {
        if (_contract == CONTRACTS.DISTRIBUTOR) {// 0
            distributor = _address;
        } else if (_contract == CONTRACTS.WARMUP) {// 1
            require(warmupContract == address(0), "Warmup cannot be set more than once");
            warmupContract = _address;
        } else if (_contract == CONTRACTS.LOCKER) {// 2
            require(locker == address(0), "Locker cannot be set more than once");
            locker = _address;
        }
    }

    /**
     * @notice set warmup period for new stakers
     * @param _warmupPeriod uint
     */
    function setWarmup(uint _warmupPeriod) external onlyManager() {
        warmupPeriod = _warmupPeriod;
    }
}