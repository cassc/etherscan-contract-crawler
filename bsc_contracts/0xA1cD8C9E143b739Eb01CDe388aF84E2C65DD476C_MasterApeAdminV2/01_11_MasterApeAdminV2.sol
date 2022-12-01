// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

/*
  ______                     ______                                 
 /      \                   /      \                                
|  ▓▓▓▓▓▓\ ______   ______ |  ▓▓▓▓▓▓\__   __   __  ______   ______  
| ▓▓__| ▓▓/      \ /      \| ▓▓___\▓▓  \ |  \ |  \|      \ /      \ 
| ▓▓    ▓▓  ▓▓▓▓▓▓\  ▓▓▓▓▓▓\\▓▓    \| ▓▓ | ▓▓ | ▓▓ \▓▓▓▓▓▓\  ▓▓▓▓▓▓\
| ▓▓▓▓▓▓▓▓ ▓▓  | ▓▓ ▓▓    ▓▓_\▓▓▓▓▓▓\ ▓▓ | ▓▓ | ▓▓/      ▓▓ ▓▓  | ▓▓
| ▓▓  | ▓▓ ▓▓__/ ▓▓ ▓▓▓▓▓▓▓▓  \__| ▓▓ ▓▓_/ ▓▓_/ ▓▓  ▓▓▓▓▓▓▓ ▓▓__/ ▓▓
| ▓▓  | ▓▓ ▓▓    ▓▓\▓▓     \\▓▓    ▓▓\▓▓   ▓▓   ▓▓\▓▓    ▓▓ ▓▓    ▓▓
 \▓▓   \▓▓ ▓▓▓▓▓▓▓  \▓▓▓▓▓▓▓ \▓▓▓▓▓▓  \▓▓▓▓▓\▓▓▓▓  \▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓ 
         | ▓▓                                             | ▓▓      
         | ▓▓                                             | ▓▓      
          \▓▓                                              \▓▓         
 * App:             https://ApeSwap.finance
 * Medium:          https://ape-swap.medium.com
 * Twitter:         https://twitter.com/ape_swap
 * Telegram:        https://t.me/ape_swap
 * Announcements:   https://t.me/ape_swap_news
 * Discord:         https://discord.com/ApeSwap
 * Reddit:          https://reddit.com/r/ApeSwap
 * Instagram:       https://instagram.com/ApeSwap.finance
 * GitHub:          https://github.com/ApeSwapFinance
 */

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@ape.swap/contracts/contracts/v0.8/access/ContractWhitelist.sol";
import "./interfaces/IMasterApeV2.sol";
import "./interfaces/IOwnable.sol";
import "./interfaces/IRewarder.sol";

/// @title Admin MasterApe proxy contract used to add features to MasterApe admin functions
/// @dev This contract does NOT handle changing the dev address of the MasterApe because that can only be done
///  by the dev address itself
/// @author DeFiFoFum (Apetastic)
/// @notice Admin functions are separated into onlyOwner and onlyFarmAdmin to separate concerns
contract MasterApeAdminV2 is Ownable, ContractWhitelist {
    using SafeMath for uint256;

    struct FixedPercentFarmInfo {
        uint256 pid;
        uint256 allocationPercent;
        bool isActive;
    }

    /// @notice Farm admin can manage master ape farms and fixed percent farms
    address public farmAdmin;
    /// @notice MasterApeV2 Address
    IMasterApeV2 public immutable masterApeV2;
    /// @notice Address which is eligible to accept ownership of the MasterApe. Set by the current owner.
    address public pendingMasterApeOwner = address(0);
    /// @notice Array of MasterApe pids that are active fixed percent farms
    uint256[] public fixedPercentFarmPids;
    /// @notice mapping of MasterApe pids to FixedPercentFarmInfo
    mapping(uint256 => FixedPercentFarmInfo) public getFixedPercentFarmFromPid;
    /// @notice The percentages are divided by 10000
    uint256 public constant PERCENTAGE_PRECISION = 1e4;
    /// @notice Approaching max fixed farm percentage makes the fixed farm allocations go to infinity
    uint256 public constant MAX_FIXED_FARM_PERCENTAGE_BUFFER = PERCENTAGE_PRECISION / 10; // 10% Buffer
    /// @notice Percentage available to additional fixed percent farms
    uint256 public constant MAX_FIXED_FARM_PERCENTAGE =
        PERCENTAGE_PRECISION - MAX_FIXED_FARM_PERCENTAGE_BUFFER;
    /// @notice Total allocation percentage for fixed percent farms
    uint256 public totalFixedPercentFarmPercentage = 0;
    /// @notice Max multiplier which is possible to be set on the MasterApe
    uint256 public constant MAX_BONUS_MULTIPLIER = 4;

    event SetPendingMasterApeOwner(address pendingMasterApeOwner);
    event AddFarm(IERC20 indexed lpToken, uint256 allocation);
    event SetFarm(uint256 indexed pid, uint256 allocation);
    event SyncFixedPercentFarm(uint256 indexed pid, uint256 allocation);
    event AddFixedPercentFarm(uint256 indexed pid, uint256 allocationPercentage);
    event SetFixedPercentFarm(uint256 indexed pid, uint256 previousAllocationPercentage, uint256 allocationPercentage);
    event TransferredFarmAdmin(address indexed previousFarmAdmin, address indexed newFarmAdmin);
    event SweepWithdraw(address indexed to, IERC20 indexed token, uint256 amount);

    modifier onlyFarmAdmin() {
        require(msg.sender == farmAdmin, "must be called by farm admin");
        _;
    }

    constructor(IMasterApeV2 _masterApeV2, address _farmAdmin) {
        masterApeV2 = _masterApeV2;
        farmAdmin = _farmAdmin;
    }

    /** External Functions  */

    /// @notice Set an address as the pending admin of the MasterApe. The address must accept to take ownership.
    /// @param _pendingMasterApeOwner Address to set as the pending owner of the MasterApe.
    function setPendingMasterApeOwner(address _pendingMasterApeOwner) external onlyOwner {
        pendingMasterApeOwner = _pendingMasterApeOwner;
        emit SetPendingMasterApeOwner(pendingMasterApeOwner);
    }

    /// @notice The pendingMasterApeOwner takes ownership through this call
    /// @dev Transferring MasterApe ownership away from this contract renders this contract useless.
    function acceptMasterApeOwnership() external {
        require(msg.sender == pendingMasterApeOwner, "not pending owner");
        IOwnable(address(masterApeV2)).transferOwnership(pendingMasterApeOwner);
        pendingMasterApeOwner = address(0);
    }

    /// @notice Set an address as the pending admin of the MasterApeV1. The address must accept to take ownership.
    /// @param _pendingMasterApeV1Owner Address to set as the pending owner of the MasterApe.
    function setPendingMasterApeV1Owner(address _pendingMasterApeV1Owner) external onlyOwner {
        masterApeV2.setPendingMasterApeOwner(_pendingMasterApeV1Owner);
    }

    /// @notice Helper function to update MasterApe pools in batches
    /// @dev The MasterApe massUpdatePools function uses a for loop which in the future
    ///  could reach the block gas limit making it in-callable.
    /// @param pids Array of MasterApe pids to update
    function batchUpdateMasterApePools(uint256[] memory pids) external {
        for (uint256 pidIndex = 0; pidIndex < pids.length; pidIndex++) {
            masterApeV2.updatePool(pids[pidIndex]);
        }
    }

    /// @notice An external function to update MAv2 Emission rate.
    /// @param _bananaPerSecond how many BANANAs to mint per second
    /// @param _withUpdate flag to call massUpdatePool before update
    function updateEmissionRate(uint256 _bananaPerSecond, bool _withUpdate) external onlyOwner {
        masterApeV2.updateEmissionRate(_bananaPerSecond, _withUpdate);
    }

    /// @notice An external function to update the BANANA hard cap.
    /// @param _hardCap new BANANA hard cap
    function updateHardCap(uint256 _hardCap) external onlyOwner {
        masterApeV2.updateHardCap(_hardCap);
    }

     /// @notice enables smart contract whitelist on MAv2.
    function setWhitelistEnabled(bool _enabled) external override onlyOwner {
        masterApeV2.setWhitelistEnabled(_enabled);
    }

    /// @notice An external function to sweep accidental ERC20 transfers to this contract.
    ///   Tokens are sent to owner
    /// @param _tokens Array of ERC20 addresses to sweep
    /// @param _to Address to send tokens to
    function sweepTokens(IERC20[] memory _tokens, address _to) external onlyOwner {
        for (uint256 index = 0; index < _tokens.length; index++) {
            IERC20 token = _tokens[index];
            uint256 balance = token.balanceOf(address(this));
            token.transfer(_to, balance);
            emit SweepWithdraw(_to, token, balance);
        }
    }

    /// @notice Transfer the farmAdmin to a new address
    /// @param _newFarmAdmin Address of new farmAdmin
    function transferFarmAdminOwnership(address _newFarmAdmin) external onlyFarmAdmin {
        require(_newFarmAdmin != address(0), "cannot transfer farm admin to address(0)");
        address previousFarmAdmin = farmAdmin;
        farmAdmin = _newFarmAdmin;
        emit TransferredFarmAdmin(previousFarmAdmin, farmAdmin);
    }

    /// @notice Update pool allocations based on fixed percentage farm percentages
    function syncFixedPercentFarms() external onlyFarmAdmin {
        require(getNumberOfFixedPercentFarms() > 0, "no fixed farms added");
        _syncFixedPercentFarms();
    }

    /// @notice Add a batch of farms to the MasterApe contract
    /// @dev syncs fixed percentage farms after update
    /// @param _allocPoints Array of allocation points to set each address
    /// @param _stakeTokens Array of stake tokens
    /// @param _depositFeesBP Array of deposit fee basis points
    /// @param _rewarders Array of rewarders can be address(0) for no rewarder
    /// @param _withMassPoolUpdate Mass update pools before update
    /// @param _syncFixedPercentageFarms Sync fixed percentage farm allocations
    function addMasterApeFarms(
        uint256[] memory _allocPoints,
        IERC20[] memory _stakeTokens,
        uint16[] memory _depositFeesBP,
        IRewarder[] memory _rewarders,
        bool _withMassPoolUpdate,
        bool _syncFixedPercentageFarms
    ) external onlyFarmAdmin {
        require(
            _allocPoints.length == _stakeTokens.length &&
                _allocPoints.length == _depositFeesBP.length &&
                _allocPoints.length == _rewarders.length,
            "array length mismatch"
        );

        if (_withMassPoolUpdate) {
            masterApeV2.massUpdatePools();
        }

        for (uint256 index = 0; index < _allocPoints.length; index++) {
            masterApeV2.add(_allocPoints[index], _stakeTokens[index], false, _depositFeesBP[index], _rewarders[index]);
            emit AddFarm(_stakeTokens[index], _allocPoints[index]);
        }

        if (_syncFixedPercentageFarms) {
            _syncFixedPercentFarms();
        }
    }

    /// @notice Add a batch of farms to the MasterApe contract
    /// @dev syncs fixed percentage farms after update
    /// @param _pids Array of MasterApe pool ids to update
    /// @param _allocPoints Array of allocation points to set each pid
    /// @param _withMassPoolUpdate Mass update pools before update
    /// @param _syncFixedPercentageFarms Sync fixed percentage farm allocations
    function setMasterApeFarms(
        uint256[] memory _pids,
        uint256[] memory _allocPoints,
        uint16[] memory _depositFeesBP,
        IRewarder[] memory _rewarders,
        bool _withMassPoolUpdate,
        bool _syncFixedPercentageFarms
    ) external onlyFarmAdmin {
        require(_pids.length == _allocPoints.length, "array length mismatch");

        if (_withMassPoolUpdate) {
            masterApeV2.massUpdatePools();
        }

        uint256 pidIndexes = masterApeV2.poolLength();
        for (uint256 index = 0; index < _pids.length; index++) {
            require(_pids[index] < pidIndexes, "pid is out of bounds of MasterApe");
            // Set all pids with no update
            masterApeV2.set(_pids[index], _allocPoints[index], false, _depositFeesBP[index], _rewarders[index]);
            emit SetFarm(_pids[index], _allocPoints[index]);
        }

        if (_syncFixedPercentageFarms) {
            _syncFixedPercentFarms();
        }
    }

    /// @notice Add a new fixed percentage farm allocation
    /// @dev Must be a new MasterApe pid and below the max fixed percentage
    /// @param _pid MasterApe pid to create a fixed percentage farm for
    /// @param _allocPercentage Percentage based in PERCENTAGE_PRECISION
    /// @param _withMassPoolUpdate Mass update pools before update
    /// @param _syncFixedPercentageFarms Sync fixed percentage farm allocations
    function addFixedPercentFarmAllocation(
        uint256 _pid,
        uint256 _allocPercentage,
        bool _withMassPoolUpdate,
        bool _syncFixedPercentageFarms
    ) external onlyFarmAdmin {
        require(_pid < masterApeV2.poolLength(), "pid is out of bounds of MasterApe");
        require(!getFixedPercentFarmFromPid[_pid].isActive, "fixed percent farm already added");
        uint256 newTotalFixedPercentage = totalFixedPercentFarmPercentage.add(_allocPercentage);
        require(newTotalFixedPercentage <= MAX_FIXED_FARM_PERCENTAGE, "allocation out of bounds");

        totalFixedPercentFarmPercentage = newTotalFixedPercentage;
        getFixedPercentFarmFromPid[_pid] = FixedPercentFarmInfo(_pid, _allocPercentage, true);
        fixedPercentFarmPids.push(_pid);
        emit AddFixedPercentFarm(_pid, _allocPercentage);

        if (_withMassPoolUpdate) {
            masterApeV2.massUpdatePools();
        }

        if (_syncFixedPercentageFarms) {
            _syncFixedPercentFarms();
        }
    }

    /// @notice Update/disable a new fixed percentage farm allocation
    /// @dev If the farm allocation is 0, then the fixed farm will be disabled, but the allocation will be unchanged.
    /// @param _pid MasterApe pid linked to fixed percentage farm to update
    /// @param _allocPercentage Percentage based in PERCENTAGE_PRECISION
    /// @param _withMassPoolUpdate Mass update pools before update
    /// @param _syncFixedPercentageFarms Sync fixed percentage farm allocations
    function setFixedPercentFarmAllocation(
        uint256 _pid,
        uint256 _allocPercentage,
        bool _withMassPoolUpdate,
        bool _syncFixedPercentageFarms
    ) external onlyFarmAdmin {
        FixedPercentFarmInfo storage fixedPercentFarm = getFixedPercentFarmFromPid[_pid];
        require(fixedPercentFarm.isActive, "not a valid farm pid");
        uint256 newTotalFixedPercentFarmPercentage = _allocPercentage.add(totalFixedPercentFarmPercentage).sub(
            fixedPercentFarm.allocationPercent
        );
        require(newTotalFixedPercentFarmPercentage <= MAX_FIXED_FARM_PERCENTAGE, "new allocation out of bounds");

        totalFixedPercentFarmPercentage = newTotalFixedPercentFarmPercentage;
        uint256 previousAllocation = fixedPercentFarm.allocationPercent;
        fixedPercentFarm.allocationPercent = _allocPercentage;

        if (_allocPercentage == 0) {
            // Disable fixed percentage farm and MasterApe allocation
            fixedPercentFarm.isActive = false;
            // Remove fixed percent farm from pid array
            for (uint256 index = 0; index < fixedPercentFarmPids.length; index++) {
                if (fixedPercentFarmPids[index] == _pid) {
                    _removeFromArray(index, fixedPercentFarmPids);
                    break;
                }
            }
            // NOTE: The MasterApe pool allocation is left unchanged to not disable a fixed farm
            //  in case the creation was an accident.
        }
        emit SetFixedPercentFarm(_pid, previousAllocation, _allocPercentage);

        if (_withMassPoolUpdate) {
            masterApeV2.massUpdatePools();
        }

        if (_syncFixedPercentageFarms) {
            _syncFixedPercentFarms();
        }
    }

    /// @notice Obtain detailed allocation information regarding a MasterApe pool
    /// @param pid MasterApe pid to pull detailed information from
    /// @return lpToken Address of the stake token for this pool
    /// @return poolAllocationPoint Allocation points for this pool
    /// @return totalAllocationPoints Total allocation points across all pools
    /// @return poolAllocationPercentMantissa Percentage of pool allocation points to total multiplied by 1e18
    /// @return poolBananaPerSecond Amount of BANANA given to the pool per second
    /// @return poolBananaPerDay Amount of BANANA given to the pool per day
    /// @return poolBananaPerMonth Amount of BANANA given to the pool per month
    function getDetailedPoolInfo(uint256 pid)
        external
        view
        returns (
            address lpToken,
            uint256 poolAllocationPoint,
            uint256 totalAllocationPoints,
            uint256 poolAllocationPercentMantissa,
            uint256 poolBananaPerSecond,
            uint256 poolBananaPerDay,
            uint256 poolBananaPerMonth
        )
    {
        uint256 bananaPerSecond = masterApeV2.bananaPerSecond();
        (lpToken, poolAllocationPoint, , , , , ) = masterApeV2.getPoolInfo(pid);
        totalAllocationPoints = masterApeV2.totalAllocPoint();
        poolAllocationPercentMantissa = (poolAllocationPoint.mul(1e18)).div(totalAllocationPoints);
        poolBananaPerSecond = (bananaPerSecond.mul(poolAllocationPercentMantissa)).div(1e18);
        // Assumes a 3 second block time
        poolBananaPerDay = poolBananaPerSecond * 3600 * 24;
        poolBananaPerMonth = poolBananaPerDay * 30;
    }

    /** Public Functions  */

    /// @notice Get the number of registered fixed percentage farms
    /// @return Number of active fixed percentage farms
    function getNumberOfFixedPercentFarms() public view returns (uint256) {
        return fixedPercentFarmPids.length;
    }

    /// @notice Get the total percentage allocated to fixed percentage farms on the MasterApe
    /// @dev Adds the total percent allocated to fixed percentage farms
    /// with the percentage allocated to the BANANA pool.
    ///  The MasterApe manages the BANANA pool internally
    /// and we need to account for this when syncing fixed percentage farms.
    /// @return Total percentage based in PERCENTAGE_PRECISION
    function getTotalAllocationPercent() public view returns (uint256) {
        return totalFixedPercentFarmPercentage;
    }

    /** Internal Functions  */

    /// @notice Run through fixed percentage farm allocations and set MasterApe allocations to match the percentage.
    /// @dev The MasterApe contract manages the BANANA pool percentage on its own
    /// which is accounted for in the calculations below.
    function _syncFixedPercentFarms() internal {
        uint256 numberOfFixedPercentFarms = getNumberOfFixedPercentFarms();
        if (numberOfFixedPercentFarms == 0) {
            return;
        }
        uint256 masterApeV2TotalAllocation = masterApeV2.totalAllocPoint();
        uint256 currentTotalFixedPercentFarmAllocation = 0;
        // Define local vars that are used multiple times
        uint256 totalAllocationPercent = getTotalAllocationPercent();
        // Calculate the total allocation points of the fixed percent farms
        for (uint256 index = 0; index < numberOfFixedPercentFarms; index++) {
            (, uint256 fixedPercentFarmAllocation, , , , , ) = masterApeV2.getPoolInfo(fixedPercentFarmPids[index]);
            currentTotalFixedPercentFarmAllocation = currentTotalFixedPercentFarmAllocation.add(
                fixedPercentFarmAllocation
            );
        }
        // Calculate alloted allocations
        uint256 nonPercentageBasedAllocation = masterApeV2TotalAllocation.sub(currentTotalFixedPercentFarmAllocation);
        uint256 percentageIncrease = (PERCENTAGE_PRECISION * PERCENTAGE_PRECISION) /
            (PERCENTAGE_PRECISION.sub(totalAllocationPercent));
        uint256 finalAllocation = nonPercentageBasedAllocation.mul(percentageIncrease).div(PERCENTAGE_PRECISION);
        uint256 allotedFixedPercentFarmAllocation = finalAllocation.sub(nonPercentageBasedAllocation);
        // Update fixed percentage farm allocations
        for (uint256 index = 0; index < numberOfFixedPercentFarms; index++) {
            FixedPercentFarmInfo memory fixedPercentFarm = getFixedPercentFarmFromPid[fixedPercentFarmPids[index]];
            uint256 newFixedPercentFarmAllocation = allotedFixedPercentFarmAllocation
                .mul(fixedPercentFarm.allocationPercent)
                .div(totalAllocationPercent);
            (, , address rewarder, , , , uint16 depositFeeBP) = masterApeV2.getPoolInfo(fixedPercentFarmPids[index]);
            masterApeV2.set(
                fixedPercentFarm.pid,
                newFixedPercentFarmAllocation,
                false,
                depositFeeBP,
                IRewarder(rewarder)
            );
            emit SyncFixedPercentFarm(fixedPercentFarm.pid, newFixedPercentFarmAllocation);
        }
    }

    /// @notice Remove an index from an array by copying the last element to the index
    /// and then removing the last element.
    function _removeFromArray(uint256 index, uint256[] storage array) internal {
        require(index < array.length, "Incorrect index");
        array[index] = array[array.length - 1];
        array.pop();
    }

    /// @notice Enable or disable a contract address on the whitelist
    /// @param _address Address to update on whitelist
    /// @param _enabled Set if the whitelist is enabled or disabled
    function _setContractWhitelist(address _address, bool _enabled) internal override {
        masterApeV2.setContractWhitelist(_address, _enabled);
    }
}