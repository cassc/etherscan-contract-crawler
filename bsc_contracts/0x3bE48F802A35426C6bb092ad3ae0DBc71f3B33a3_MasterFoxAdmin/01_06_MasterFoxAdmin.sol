// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

/*
// FOX BLOCKCHAIN \\

FoxChain works to connect all Blockchains in one platform with one click access to any network.

Website     : https://foxchain.app/
Dex         : https://foxdex.finance/
Telegram    : https://t.me/FOXCHAINNEWS
Twitter     : https://twitter.com/FoxchainLabs
Github      : https://github.com/FoxChainLabs

*/

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IMasterFox.sol";

/// @title Admin MasterFox proxy contract used to add features to MasterFox admin functions
/// @dev This contract does NOT handle changing the dev address of the MasterFox because that can only be done
///  by the dev address itself
/// @author DeFiFoFum (Foxtastic)
/// @notice Admin functions are separated into onlyOwner and onlyFarmAdmin to separate concerns
contract MasterFoxAdmin is Ownable {
    using SafeMath for uint256;

    struct FixedPercentFarmInfo {
        uint256 pid;
        uint256 allocationPercent;
        bool isActive;
    }

    /// @notice Farm admin can manage master fox farms and fixed percent farms
    address public farmAdmin;
    /// @notice MasterFox Address
    IMasterFox public immutable masterFox;
    /// @notice Address which is eligible to accept ownership of the MasterFox. Set by the current owner.
    address public pendingMasterFoxOwner = address(0);
    /// @notice Array of MasterFox pids that are active fixed percent farms
    uint256[] public fixedPercentFarmPids;
    /// @notice mapping of MasterFox pids to FixedPercentFarmInfo
    mapping(uint256 => FixedPercentFarmInfo) public getFixedPercentFarmFromPid;
    /// @notice The percentages are divided by 10000
    uint256 public constant PERCENTAGE_PRECISION = 1e4;
    /// @notice Percentage of base pool allocation managed by MasterFox internally
    /// @dev The BASE_PERCENTAGE needs to be considered in fixed percent farm allocation updates as it's allocation is based on a percentage
    uint256 public constant BASE_PERCENTAGE = PERCENTAGE_PRECISION / 4; // The base staking pool always gets 25%
    /// @notice Approaching max fixed farm percentage makes the fixed farm allocations go to infinity
    uint256 public constant MAX_FIXED_FARM_PERCENTAGE_BUFFER =
        PERCENTAGE_PRECISION / 10; // 10% Buffer
    /// @notice Percentage available to additional fixed percent farms
    uint256 public constant MAX_FIXED_FARM_PERCENTAGE =
        PERCENTAGE_PRECISION -
            BASE_PERCENTAGE -
            MAX_FIXED_FARM_PERCENTAGE_BUFFER;
    /// @notice Total allocation percentage for fixed percent farms
    uint256 public totalFixedPercentFarmPercentage = 0;
    /// @notice Max multiplier which is possible to be set on the MasterFox
    uint256 public constant MAX_BONUS_MULTIPLIER = 4;

    event SetPendingMasterFoxOwner(address pendingMasterFoxOwner);
    event AddFarm(IERC20 indexed lpToken, uint256 allocation);
    event SetFarm(uint256 indexed pid, uint256 allocation);
    event SyncFixedPercentFarm(uint256 indexed pid, uint256 allocation);
    event AddFixedPercentFarm(
        uint256 indexed pid,
        uint256 allocationPercentage
    );
    event SetFixedPercentFarm(
        uint256 indexed pid,
        uint256 previousAllocationPercentage,
        uint256 allocationPercentage
    );
    event TransferredFarmAdmin(
        address indexed previousFarmAdmin,
        address indexed newFarmAdmin
    );
    event SweepWithdraw(
        address indexed to,
        IERC20 indexed token,
        uint256 amount
    );

    constructor(IMasterFox _masterFox, address _farmAdmin) public {
        masterFox = _masterFox;
        farmAdmin = _farmAdmin;
    }

    modifier onlyFarmAdmin() {
        require(msg.sender == farmAdmin, "must be called by farm admin");
        _;
    }

    /** External Functions  */

    /// @notice Set an address as the pending admin of the MasterFox. The address must accept afterward to take ownership.
    /// @param _pendingMasterFoxOwner Address to set as the pending owner of the MasterFox.
    function setPendingMasterFoxOwner(
        address _pendingMasterFoxOwner
    ) external onlyOwner {
        pendingMasterFoxOwner = _pendingMasterFoxOwner;
        emit SetPendingMasterFoxOwner(pendingMasterFoxOwner);
    }

    /// @notice The pendingMasterFoxOwner takes ownership through this call
    /// @dev Transferring MasterFox ownership away from this contract renders this contract useless.
    function acceptMasterFoxOwnership() external {
        require(msg.sender == pendingMasterFoxOwner, "not pending owner");
        masterFox.transferOwnership(pendingMasterFoxOwner);
        pendingMasterFoxOwner = address(0);
    }

    /// @notice Update the rewardPerBlock multiplier on the MasterFox contract
    /// @param _newMultiplier Multiplier to change to
    function updateMasterFoxMultiplier(
        uint256 _newMultiplier
    ) external onlyOwner {
        require(
            _newMultiplier <= MAX_BONUS_MULTIPLIER,
            "multiplier greater than max"
        );
        masterFox.updateMultiplier(_newMultiplier);
    }

    /// @notice Helper function to update MasterFox pools in batches
    /// @dev The MasterFox massUpdatePools function uses a for loop which in the future
    ///  could reach the block gas limit making it incallable.
    /// @param pids Array of MasterFox pids to update
    function batchUpdateMasterFoxPools(uint256[] memory pids) external {
        for (uint256 pidIndex = 0; pidIndex < pids.length; pidIndex++) {
            masterFox.updatePool(pids[pidIndex]);
        }
    }

    /// @notice Obtain detailed allocation information regarding a MasterFox pool
    /// @param pid MasterFox pid to pull detailed information from
    /// @return lpToken Address of the stake token for this pool
    /// @return poolAllocationPoint Allocation points for this pool
    /// @return totalAllocationPoints Total allocation points across all pools
    /// @return poolAllocationPercentMantissa Percentage of pool allocation points to total multiplied by 1e18
    /// @return poolFoxlayerPerBlock Amount of FOXLAYER given to the pool per block
    /// @return poolFoxlayerPerDay Amount of FOXLAYER given to the pool per day
    /// @return poolFoxlayerPerMonth Amount of FOXLAYER given to the pool per month
    function getDetailedPoolInfo(
        uint pid
    )
        external
        view
        returns (
            address lpToken,
            uint256 poolAllocationPoint,
            uint256 totalAllocationPoints,
            uint256 poolAllocationPercentMantissa,
            uint256 poolFoxlayerPerBlock,
            uint256 poolFoxlayerPerDay,
            uint256 poolFoxlayerPerMonth
        )
    {
        uint256 foxlayerPerBlock = masterFox.cakePerBlock() *
            masterFox.BONUS_MULTIPLIER();
        (lpToken, poolAllocationPoint, , ) = masterFox.getPoolInfo(pid);
        totalAllocationPoints = masterFox.totalAllocPoint();
        poolAllocationPercentMantissa = (poolAllocationPoint.mul(1e18)).div(
            totalAllocationPoints
        );
        poolFoxlayerPerBlock = (
            foxlayerPerBlock.mul(poolAllocationPercentMantissa)
        ).div(1e18);
        // Assumes a 3 second blocktime
        poolFoxlayerPerDay = poolFoxlayerPerBlock * 1200 * 24;
        poolFoxlayerPerMonth = poolFoxlayerPerDay * 30;
    }

    /// @notice An external function to sweep accidental ERC20 transfers to this contract.
    ///   Tokens are sent to owner
    /// @param _tokens Array of ERC20 addresses to sweep
    /// @param _to Address to send tokens to
    function sweepTokens(
        IERC20[] memory _tokens,
        address _to
    ) external onlyOwner {
        for (uint256 index = 0; index < _tokens.length; index++) {
            IERC20 token = _tokens[index];
            uint256 balance = token.balanceOf(address(this));
            token.transfer(_to, balance);
            emit SweepWithdraw(_to, token, balance);
        }
    }

    /// @notice Transfer the farmAdmin to a new address
    /// @param _newFarmAdmin Address of new farmAdmin
    function transferFarmAdminOwnership(
        address _newFarmAdmin
    ) external onlyFarmAdmin {
        require(
            _newFarmAdmin != address(0),
            "cannot transfer farm admin to address(0)"
        );
        address previousFarmAdmin = farmAdmin;
        farmAdmin = _newFarmAdmin;
        emit TransferredFarmAdmin(previousFarmAdmin, farmAdmin);
    }

    /// @notice Update pool allocations based on fixed percentage farm percentages
    function syncFixedPercentFarms() external onlyFarmAdmin {
        require(getNumberOfFixedPercentFarms() > 0, "no fixed farms added");
        _syncFixedPercentFarms();
    }

    /// @notice Add a batch of farms to the MasterFox contract
    /// @dev syncs fixed percentage farms after update
    /// @param _allocPoints Array of allocation points to set each address
    /// @param _withMassPoolUpdate Mass update pools before update
    /// @param _syncFixedPercentageFarms Sync fixed percentage farm allocations
    function addMasterFoxFarms(
        uint256[] memory _allocPoints,
        IERC20[] memory _lpTokens,
        bool _withMassPoolUpdate,
        bool _syncFixedPercentageFarms
    ) external onlyFarmAdmin {
        require(
            _allocPoints.length == _lpTokens.length,
            "array length mismatch"
        );

        if (_withMassPoolUpdate) {
            masterFox.massUpdatePools();
        }

        for (uint256 index = 0; index < _allocPoints.length; index++) {
            masterFox.add(
                _allocPoints[index],
                address(_lpTokens[index]),
                false
            );
            emit AddFarm(_lpTokens[index], _allocPoints[index]);
        }

        if (_syncFixedPercentageFarms) {
            _syncFixedPercentFarms();
        }
    }

    /// @notice Add a batch of farms to the MasterFox contract
    /// @dev syncs fixed percentage farms after update
    /// @param _pids Array of MasterFox pool ids to update
    /// @param _allocPoints Array of allocation points to set each pid
    /// @param _withMassPoolUpdate Mass update pools before update
    /// @param _syncFixedPercentageFarms Sync fixed percentage farm allocations
    function setMasterFoxFarms(
        uint256[] memory _pids,
        uint256[] memory _allocPoints,
        bool _withMassPoolUpdate,
        bool _syncFixedPercentageFarms
    ) external onlyFarmAdmin {
        require(_pids.length == _allocPoints.length, "array length mismatch");

        if (_withMassPoolUpdate) {
            masterFox.massUpdatePools();
        }

        uint256 pidIndexes = masterFox.poolLength();
        for (uint256 index = 0; index < _pids.length; index++) {
            require(
                _pids[index] < pidIndexes,
                "pid is out of bounds of MasterFox"
            );
            // Set all pids with no update
            masterFox.set(_pids[index], _allocPoints[index], false);
            emit SetFarm(_pids[index], _allocPoints[index]);
        }

        if (_syncFixedPercentageFarms) {
            _syncFixedPercentFarms();
        }
    }

    /// @notice Add a new fixed percentage farm allocation
    /// @dev Must be a new MasterFox pid and below the max fixed percentage
    /// @param _pid MasterFox pid to create a fixed percentage farm for
    /// @param _allocPercentage Percentage based in PERCENTAGE_PRECISION
    /// @param _withMassPoolUpdate Mass update pools before update
    /// @param _syncFixedPercentageFarms Sync fixed percentage farm allocations
    function addFixedPercentFarmAllocation(
        uint256 _pid,
        uint256 _allocPercentage,
        bool _withMassPoolUpdate,
        bool _syncFixedPercentageFarms
    ) external onlyFarmAdmin {
        require(
            _pid < masterFox.poolLength(),
            "pid is out of bounds of MasterFox"
        );
        require(_pid != 0, "cannot add reserved MasterFox pid 0");
        require(
            !getFixedPercentFarmFromPid[_pid].isActive,
            "fixed percent farm already added"
        );
        uint256 newTotalFixedPercentage = totalFixedPercentFarmPercentage.add(
            _allocPercentage
        );
        require(
            newTotalFixedPercentage <= MAX_FIXED_FARM_PERCENTAGE,
            "allocation out of bounds"
        );

        totalFixedPercentFarmPercentage = newTotalFixedPercentage;
        getFixedPercentFarmFromPid[_pid] = FixedPercentFarmInfo(
            _pid,
            _allocPercentage,
            true
        );
        fixedPercentFarmPids.push(_pid);
        emit AddFixedPercentFarm(_pid, _allocPercentage);

        if (_withMassPoolUpdate) {
            masterFox.massUpdatePools();
        }

        if (_syncFixedPercentageFarms) {
            _syncFixedPercentFarms();
        }
    }

    /// @notice Update/disable a new fixed percentage farm allocation
    /// @dev If the farm allocation is 0, then the fixed farm will be disabled, but the allocation will be unchanged.
    /// @param _pid MasterFox pid linked to fixed percentage farm to update
    /// @param _allocPercentage Percentage based in PERCENTAGE_PRECISION
    /// @param _withMassPoolUpdate Mass update pools before update
    /// @param _syncFixedPercentageFarms Sync fixed percentage farm allocations
    function setFixedPercentFarmAllocation(
        uint256 _pid,
        uint256 _allocPercentage,
        bool _withMassPoolUpdate,
        bool _syncFixedPercentageFarms
    ) external onlyFarmAdmin {
        FixedPercentFarmInfo
            storage fixedPercentFarm = getFixedPercentFarmFromPid[_pid];
        require(fixedPercentFarm.isActive, "not a valid farm pid");
        uint256 newTotalFixedPercentFarmPercentage = _allocPercentage
            .add(totalFixedPercentFarmPercentage)
            .sub(fixedPercentFarm.allocationPercent);
        require(
            newTotalFixedPercentFarmPercentage <= MAX_FIXED_FARM_PERCENTAGE,
            "new allocation out of bounds"
        );

        totalFixedPercentFarmPercentage = newTotalFixedPercentFarmPercentage;
        uint256 previousAllocation = fixedPercentFarm.allocationPercent;
        fixedPercentFarm.allocationPercent = _allocPercentage;

        if (_allocPercentage == 0) {
            // Disable fixed percentage farm and MasterFox allocation
            fixedPercentFarm.isActive = false;
            // Remove fixed percent farm from pid array
            for (
                uint256 index = 0;
                index < fixedPercentFarmPids.length;
                index++
            ) {
                if (fixedPercentFarmPids[index] == _pid) {
                    _removeFromArray(index, fixedPercentFarmPids);
                    break;
                }
            }
            // NOTE: The MasterFox pool allocation is left unchanged to not disable a fixed farm
            //  in case the creation was an accident.
        }
        emit SetFixedPercentFarm(_pid, previousAllocation, _allocPercentage);

        if (_withMassPoolUpdate) {
            masterFox.massUpdatePools();
        }

        if (_syncFixedPercentageFarms) {
            _syncFixedPercentFarms();
        }
    }

    /** Public Functions  */

    /// @notice Get the number of registered fixed percentage farms
    /// @return Number of active fixed percentage farms
    function getNumberOfFixedPercentFarms() public view returns (uint256) {
        return fixedPercentFarmPids.length;
    }

    /// @notice Get the total percentage allocated to fixed percentage farms on the MasterFox
    /// @dev Adds the total percent allocated to fixed percentage farms with the percentage allocated to the FOXLAYER pool.
    ///  The MasterFox manages the FOXLAYER pool internally and we need to account for this when syncing fixed percentage farms.
    /// @return Total percentage based in PERCENTAGE_PRECISION
    function getTotalAllocationPercent() public view returns (uint256) {
        return totalFixedPercentFarmPercentage + BASE_PERCENTAGE;
    }

    /** Internal Functions  */

    /// @notice Run through fixed percentage farm allocations and set MasterFox allocations to match the percentage.
    /// @dev The MasterFox contract manages the FOXLAYER pool percentage on its own which is accounted for in the calculations below.
    function _syncFixedPercentFarms() internal {
        uint256 numberOfFixedPercentFarms = getNumberOfFixedPercentFarms();
        if (numberOfFixedPercentFarms == 0) {
            return;
        }
        uint256 masterFoxTotalAllocation = masterFox.totalAllocPoint();
        (, uint256 poolAllocation, , ) = masterFox.getPoolInfo(0);
        uint256 currentTotalFixedPercentFarmAllocation = 0;
        // Define local vars that are used multiple times
        uint256 totalAllocationPercent = getTotalAllocationPercent();
        // Calculate the total allocation points of the fixed percent farms
        for (uint256 index = 0; index < numberOfFixedPercentFarms; index++) {
            (, uint256 fixedPercentFarmAllocation, , ) = masterFox.getPoolInfo(
                fixedPercentFarmPids[index]
            );
            currentTotalFixedPercentFarmAllocation = currentTotalFixedPercentFarmAllocation
                .add(fixedPercentFarmAllocation);
        }
        // Calculate alloted allocations
        uint256 nonPercentageBasedAllocation = masterFoxTotalAllocation
            .sub(poolAllocation)
            .sub(currentTotalFixedPercentFarmAllocation);
        uint256 percentageIncrease = (PERCENTAGE_PRECISION *
            PERCENTAGE_PRECISION) /
            (PERCENTAGE_PRECISION.sub(totalAllocationPercent));
        uint256 finalAllocation = nonPercentageBasedAllocation
            .mul(percentageIncrease)
            .div(PERCENTAGE_PRECISION);
        uint256 allotedFixedPercentFarmAllocation = finalAllocation.sub(
            nonPercentageBasedAllocation
        );
        // Update fixed percentage farm allocations
        for (uint256 index = 0; index < numberOfFixedPercentFarms; index++) {
            FixedPercentFarmInfo
                memory fixedPercentFarm = getFixedPercentFarmFromPid[
                    fixedPercentFarmPids[index]
                ];
            uint256 newFixedPercentFarmAllocation = allotedFixedPercentFarmAllocation
                    .mul(fixedPercentFarm.allocationPercent)
                    .div(totalAllocationPercent);
            masterFox.set(
                fixedPercentFarm.pid,
                newFixedPercentFarmAllocation,
                false
            );
            emit SyncFixedPercentFarm(
                fixedPercentFarm.pid,
                newFixedPercentFarmAllocation
            );
        }
    }

    /// @notice Remove an index from an array by copying the last element to the index and then removing the last element.
    function _removeFromArray(uint index, uint256[] storage array) internal {
        require(index < array.length, "Incorrect index");
        array[index] = array[array.length - 1];
        array.pop();
    }
}