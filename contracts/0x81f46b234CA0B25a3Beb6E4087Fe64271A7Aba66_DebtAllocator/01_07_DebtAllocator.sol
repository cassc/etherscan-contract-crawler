//SPDX-License-Identifier: UNLICENSED

import "@openzeppelin/access/Ownable.sol";
import "@openzeppelin/token/ERC20/IERC20.sol";
import "@openzeppelin/token/ERC20/utils/SafeERC20.sol";

pragma solidity >=0.7.0 <0.9.0;

interface ICairoVerifier {
    function isValid(bytes32) external view returns (bool);
}

interface IStreamer {
    function token() external view returns (IERC20);

    function streamToStart(bytes32) external view returns (uint256);

    function withdraw(address from, address to, uint216 amountPerSec) external;

    function getStreamId(
        address from,
        address to,
        uint216 amountPerSec
    ) external view returns (bytes32);
}

contract DebtAllocator is Ownable {
    using SafeERC20 for IERC20;

    uint256 PRECISION = 10 ** 18;

    ICairoVerifier public cairoVerifier = ICairoVerifier(address(0));
    bytes32 public cairoProgramHash = 0x0;

    struct PackedStrategies {
        address[] addresses;
        uint256[] callLen;
        address[] contracts;
        bytes[] checkdata;
        uint256[] offset;
        uint256[] calculationsLen;
        uint256[] calculations;
        uint256[] conditionsLen;
        uint256[] conditions;
    }

    struct StrategyParam {
        uint256 callLen;
        address[] contracts;
        bytes[] checkdata;
        uint256[] offset;
        uint256 calculationsLen;
        uint256[] calculations;
        uint256 conditionsLen;
        uint256[] conditions;
    }

    uint256[] public targetAllocation;

    // Everyone is free to propose a new solution, the address is stored so the user can get rewarded
    address public proposer;
    uint256 public lastUpdate;
    uint256 public strategiesHash;
    uint256 public inputHash;
    mapping(uint256 => uint256) public snapshotTimestamp;

    uint256 public staleSnapshotPeriod = 24 * 3600;

    // Rewards config
    address public rewardsPayer;
    address public rewardsStreamer;
    uint216 public rewardsPerSec;

    // 100% APY = 10^27, minimum increased = 10^23 = 0,01%
    uint256 public minimumApyIncreaseForNewSolution = 100000000000000000000000;

    constructor(address _cairoVerifier, bytes32 _cairoProgramHash) payable {
        updateCairoVerifier(_cairoVerifier);
        updateCairoProgramHash(_cairoProgramHash);
    }

    event StrategyAdded(
        address[] Strategies,
        uint256[] StrategiesCallLen,
        address[] Contracts,
        bytes4[] Checkdata,
        uint256[] Offset,
        uint256[] CalculationsLen,
        uint256[] Calculations,
        uint256[] ConditionsLen,
        uint256[] Conditions
    );
    event StrategyUpdated(
        address[] Strategies,
        uint256[] StrategiesCallLen,
        address[] Contracts,
        bytes4[] Checkdata,
        uint256[] Offset,
        uint256[] CalculationsLen,
        uint256[] Calculations,
        uint256[] ConditionsLen,
        uint256[] Conditions
    );
    event StrategyRemoved(
        address[] Strategies,
        uint256[] StrategiesCallLen,
        address[] Contracts,
        bytes4[] Checkdata,
        uint256[] Offset,
        uint256[] CalculationsLen,
        uint256[] Calculations,
        uint256[] ConditionsLen,
        uint256[] Conditions
    );

    event NewSnapshot(
        uint256[] dataStrategies,
        uint256[] calculation,
        uint256[] condition,
        uint256[] targetAllocations
    );
    event NewSolution(
        uint256 newApy,
        uint256[] newTargetAllocation,
        address proposer,
        uint256 timestamp
    );

    event NewCairoProgramHash(bytes32 newCairoProgramHash);
    event NewCairoVerifier(address newCairoVerifier);
    event NewStalePeriod(uint256 newStalePeriod);
    event NewStaleSnapshotPeriod(uint256 newStaleSnapshotPeriod);
    event targetAllocationForced(uint256[] newTargetAllocation);

    function updateRewardsConfig(
        address _rewardsPayer,
        address _rewardsStreamer,
        uint216 _rewardsPerSec
    ) external onlyOwner {
        bytes32 streamId = IStreamer(_rewardsStreamer).getStreamId(
            _rewardsPayer,
            address(this),
            _rewardsPerSec
        );
        require(
            IStreamer(_rewardsStreamer).streamToStart(streamId) > 0,
            "STREAM"
        );
        rewardsPayer = _rewardsPayer;
        rewardsStreamer = _rewardsStreamer;
        rewardsPerSec = _rewardsPerSec;
    }

    function updateCairoProgramHash(
        bytes32 _cairoProgramHash
    ) public onlyOwner {
        cairoProgramHash = _cairoProgramHash;
        emit NewCairoProgramHash(_cairoProgramHash);
    }

    function updateCairoVerifier(address _cairoVerifier) public onlyOwner {
        cairoVerifier = ICairoVerifier(_cairoVerifier);
        emit NewCairoVerifier(_cairoVerifier);
    }

    function updateStaleSnapshotPeriod(
        uint256 _staleSnapshotPeriod
    ) external onlyOwner {
        staleSnapshotPeriod = _staleSnapshotPeriod;
        emit NewStaleSnapshotPeriod(_staleSnapshotPeriod);
    }

    function forceTargetAllocation(
        uint256[] calldata _newTargetAllocation
    ) public onlyOwner {
        require(strategiesHash != 0, "NO_STRATEGIES");
        require(
            _newTargetAllocation.length == targetAllocation.length,
            "LENGTH"
        );
        for (uint256 j; j < _newTargetAllocation.length; j++) {
            targetAllocation[j] = _newTargetAllocation[j];
        }
        emit targetAllocationForced(_newTargetAllocation);
    }

    function saveSnapshot(
        PackedStrategies calldata _packedStrategies
    ) external {
        // Checks at least one strategy is registered
        require(strategiesHash != 0, "NO_STRATEGIES");

        bytes4[] memory checkdata = castCheckdataToBytes4(
            _packedStrategies.checkdata
        );

        // Checks strategies data is valid
        checkStrategyHash(_packedStrategies, checkdata);

        uint256[] memory dataStrategies = getStrategiesData(
            _packedStrategies.contracts,
            _packedStrategies.checkdata,
            _packedStrategies.offset
        );

        inputHash = uint256(
            keccak256(
                abi.encodePacked(
                    dataStrategies,
                    _packedStrategies.calculations,
                    _packedStrategies.conditions
                )
            )
        );

        snapshotTimestamp[inputHash] = block.timestamp;
        // TODO: do we need current debt in each strategy? (to be able to take into account withdrawals)
        emit NewSnapshot(
            dataStrategies,
            _packedStrategies.calculations,
            _packedStrategies.conditions,
            targetAllocation
        );
    }

    function verifySolution(
        uint256[] calldata programOutput
    ) external returns (bytes32) {
        // NOTE: Check current snapshot not stale
        uint256 _inputHash = inputHash;
        uint256 _snapshotTimestamp = snapshotTimestamp[_inputHash];

        require(
            _snapshotTimestamp + staleSnapshotPeriod > block.timestamp,
            "STALE_SNAPSHOT"
        );

        // NOTE: We get the data from parsing the program output
        (
            uint256 inputHash_,
            uint256[] memory currentTargetAllocation,
            uint256[] memory newTargetAllocation,
            uint256 currentSolution,
            uint256 newSolution
        ) = parseProgramOutput(programOutput);

        // check inputs
        require(inputHash_ == _inputHash, "HASH");

        // check target allocation len
        require(
            targetAllocation.length == currentTargetAllocation.length &&
                targetAllocation.length == newTargetAllocation.length,
            "TARGET_ALLOCATION_LENGTH"
        );

        // check if the new solution better than previous one
        require(
            newSolution - minimumApyIncreaseForNewSolution >= currentSolution,
            "TOO_BAD"
        );

        // Check with cairoVerifier
        bytes32 outputHash = keccak256(abi.encodePacked(programOutput));
        bytes32 fact = keccak256(
            abi.encodePacked(cairoProgramHash, outputHash)
        );

        require(cairoVerifier.isValid(fact), "MISSING_PROOF");

        targetAllocation = newTargetAllocation;
        lastUpdate = block.timestamp;

        sendRewardsToCurrentProposer();
        proposer = msg.sender;

        emit NewSolution(
            newSolution,
            newTargetAllocation,
            msg.sender,
            block.timestamp
        );
        return (fact);
    }

    // =============== REWARDS =================
    function sendRewardsToCurrentProposer() internal {
        IStreamer _rewardsStreamer = IStreamer(rewardsStreamer);
        if (address(_rewardsStreamer) == address(0)) {
            return;
        }
        bytes32 streamId = _rewardsStreamer.getStreamId(
            rewardsPayer,
            address(this),
            rewardsPerSec
        );
        if (_rewardsStreamer.streamToStart(streamId) == 0) {
            // stream does not exist
            return;
        }
        IERC20 _rewardsToken = IERC20(_rewardsStreamer.token());
        // NOTE: if the stream does not have enough to pay full amount, it will pay less than expected
        // WARNING: if this happens and the proposer is changed, the old proposer will lose the rewards
        // TODO: create a way to ensure previous proposer gets the rewards even when payers balance is not enough (by saving how much he's owed)
        _rewardsStreamer.withdraw(rewardsPayer, address(this), rewardsPerSec);
        uint256 rewardsBalance = _rewardsToken.balanceOf(address(this));
        _rewardsToken.safeTransfer(proposer, rewardsBalance);
    }

    function claimRewards() external {
        require(msg.sender == proposer, "NOT_ALLOWED");
        sendRewardsToCurrentProposer();
    }

    // ============== STRATEGY MANAGEMENT ================
    function addStrategy(
        PackedStrategies calldata _packedStrategies,
        address _newStrategy,
        StrategyParam calldata _newStrategyParam
    ) external onlyOwner {
        // Checks previous strategies data valid
        bytes4[] memory checkdata = castCheckdataToBytes4(
            _packedStrategies.checkdata
        );

        if (strategiesHash != 0) {
            checkStrategyHash(_packedStrategies, checkdata);
        } else {
            require(_packedStrategies.addresses.length == 0, "FIRST_DATA");
        }

        for (uint256 i = 0; i < _packedStrategies.addresses.length; i++) {
            if (_packedStrategies.addresses[i] == _newStrategy) {
                revert("STRATEGY_EXISTS");
            }
        }

        // Checks call data valid
        checkValidityOfData(_newStrategyParam);

        // Build new arrays for the Strategy Hash and the Event
        address[] memory strategies = new address[](
            _packedStrategies.addresses.length + 1
        );
        for (uint256 i = 0; i < _packedStrategies.addresses.length; i++) {
            strategies[i] = _packedStrategies.addresses[i];
        }
        strategies[_packedStrategies.addresses.length] = _newStrategy;

        uint256[] memory strategiesCallLen = appendUint256ToArray(
            _packedStrategies.callLen,
            _newStrategyParam.callLen
        );

        address[] memory contracts = new address[](
            _packedStrategies.contracts.length + _newStrategyParam.callLen
        );
        for (uint256 i = 0; i < _packedStrategies.contracts.length; i++) {
            contracts[i] = _packedStrategies.contracts[i];
        }
        for (uint256 i = 0; i < _newStrategyParam.callLen; i++) {
            contracts[
                i + _packedStrategies.contracts.length
            ] = _newStrategyParam.contracts[i];
        }

        checkdata = new bytes4[](
            _packedStrategies.checkdata.length + _newStrategyParam.callLen
        );
        for (uint256 i = 0; i < _packedStrategies.checkdata.length; i++) {
            checkdata[i] = bytes4(_packedStrategies.checkdata[i]);
        }

        for (uint256 i = 0; i < _newStrategyParam.callLen; i++) {
            checkdata[i + _packedStrategies.checkdata.length] = bytes4(
                _newStrategyParam.checkdata[i]
            );
        }

        uint256[] memory offset = concatenateUint256ArrayToUint256Array(
            _packedStrategies.offset,
            _newStrategyParam.offset
        );

        uint256[] memory calculationsLen = appendUint256ToArray(
            _packedStrategies.calculationsLen,
            _newStrategyParam.calculationsLen
        );

        uint256[] memory calculations = concatenateUint256ArrayToUint256Array(
            _packedStrategies.calculations,
            _newStrategyParam.calculations
        );

        uint256[] memory conditionsLen = appendUint256ToArray(
            _packedStrategies.conditionsLen,
            _newStrategyParam.conditionsLen
        );

        uint256[] memory conditions = concatenateUint256ArrayToUint256Array(
            _packedStrategies.conditions,
            _newStrategyParam.conditions
        );

        strategiesHash = uint256(
            keccak256(
                abi.encodePacked(
                    strategies,
                    strategiesCallLen,
                    contracts,
                    checkdata,
                    offset,
                    calculationsLen,
                    calculations,
                    conditionsLen,
                    conditions
                )
            )
        );

        // New strategy allocation always set to 0, people can then send new solution
        targetAllocation.push(0);

        emit StrategyAdded(
            strategies,
            strategiesCallLen,
            contracts,
            checkdata,
            offset,
            calculationsLen,
            calculations,
            conditionsLen,
            conditions
        );
    }

    // TODO: use utils functions
    function updateStrategy(
        PackedStrategies memory _packedStrategies,
        uint256 indexStrategyToUpdate,
        StrategyParam memory _newStrategyParam
    ) external onlyOwner {
        // Checks at least one strategy is registered
        require(strategiesHash != 0, "NO_STRATEGIES");

        // Checks strategies data is valid
        bytes4[] memory checkdata = castCheckdataToBytes4(
            _packedStrategies.checkdata
        );

        checkStrategyHash(_packedStrategies, checkdata);

        // Checks index in range
        require(
            indexStrategyToUpdate < _packedStrategies.addresses.length,
            "INDEX_OUT_OF_RANGE"
        );

        // Checks call data valid
        checkValidityOfData(_newStrategyParam);

        // Build new arrays for the Strategy Hash and the Event
        uint256[] memory strategiesCallLen = new uint256[](
            _packedStrategies.callLen.length
        );
        uint256[] memory calculationsLen = new uint256[](
            _packedStrategies.calculationsLen.length
        );
        uint256[] memory conditionsLen = new uint256[](
            _packedStrategies.conditionsLen.length
        );
        address[] memory contracts = new address[](
            _packedStrategies.contracts.length -
                _packedStrategies.callLen[indexStrategyToUpdate] +
                _newStrategyParam.callLen
        );
        checkdata = new bytes4[](
            _packedStrategies.checkdata.length -
                _packedStrategies.callLen[indexStrategyToUpdate] +
                _newStrategyParam.callLen
        );
        uint256[] memory offset = new uint256[](
            _packedStrategies.offset.length -
                _packedStrategies.callLen[indexStrategyToUpdate] +
                _newStrategyParam.callLen
        );
        uint256[] memory calculations = new uint256[](
            _packedStrategies.calculations.length -
                _packedStrategies.calculationsLen[indexStrategyToUpdate] +
                _newStrategyParam.calculationsLen
        );
        uint256[] memory conditions = new uint256[](
            _packedStrategies.conditions.length -
                _packedStrategies.conditionsLen[indexStrategyToUpdate] +
                _newStrategyParam.conditionsLen
        );
        uint256 offsetCalldata = indexStrategyToUpdate;
        if (indexStrategyToUpdate == _packedStrategies.addresses.length - 1) {
            for (uint256 i = 0; i < offsetCalldata; i++) {
                strategiesCallLen[i] = _packedStrategies.callLen[i];
            }
            strategiesCallLen[offsetCalldata] = _newStrategyParam.callLen;
            for (uint256 i = 0; i < offsetCalldata; i++) {
                calculationsLen[i] = _packedStrategies.calculationsLen[i];
            }
            calculationsLen[offsetCalldata] = _newStrategyParam.calculationsLen;
            for (uint256 i = 0; i < offsetCalldata; i++) {
                conditionsLen[i] = _packedStrategies.conditionsLen[i];
            }
            conditionsLen[offsetCalldata] = _newStrategyParam.conditionsLen;

            offsetCalldata = 0;
            for (uint256 i = 0; i < indexStrategyToUpdate; i++) {
                offsetCalldata += _packedStrategies.callLen[i];
            }
            for (uint256 i = 0; i < offsetCalldata; i++) {
                contracts[i] = _packedStrategies.contracts[i];
            }
            for (uint256 i = 0; i < _newStrategyParam.callLen; i++) {
                contracts[i + offsetCalldata] = _newStrategyParam.contracts[i];
            }
            for (uint256 i = 0; i < offsetCalldata; i++) {
                checkdata[i] = bytes4(_packedStrategies.checkdata[i]);
            }
            for (uint256 i = 0; i < _newStrategyParam.callLen; i++) {
                checkdata[i + offsetCalldata] = bytes4(
                    _newStrategyParam.checkdata[i]
                );
            }
            for (uint256 i = 0; i < offsetCalldata; i++) {
                offset[i] = _packedStrategies.offset[i];
            }
            for (uint256 i = 0; i < _newStrategyParam.callLen; i++) {
                offset[i + offsetCalldata] = _newStrategyParam.offset[i];
            }

            offsetCalldata = 0;
            for (uint256 i = 0; i < indexStrategyToUpdate; i++) {
                offsetCalldata += _packedStrategies.calculationsLen[i];
            }
            for (uint256 i = 0; i < offsetCalldata; i++) {
                calculations[i] = _packedStrategies.calculations[i];
            }
            for (uint256 i = 0; i < _newStrategyParam.calculationsLen; i++) {
                calculations[i + offsetCalldata] = _newStrategyParam
                    .calculations[i];
            }

            offsetCalldata = 0;
            for (uint256 i = 0; i < indexStrategyToUpdate; i++) {
                offsetCalldata += _packedStrategies.conditionsLen[i];
            }
            for (uint256 i = 0; i < offsetCalldata; i++) {
                conditions[i] = _packedStrategies.conditions[i];
            }
            for (uint256 i = 0; i < _newStrategyParam.conditionsLen; i++) {
                conditions[i + offsetCalldata] = _newStrategyParam.conditions[
                    i
                ];
            }
        } else {
            for (uint256 i = 0; i < offsetCalldata; i++) {
                strategiesCallLen[i] = _packedStrategies.callLen[i];
            }
            strategiesCallLen[offsetCalldata] = _newStrategyParam.callLen;
            for (
                uint256 i = offsetCalldata + 1;
                i < _packedStrategies.callLen.length;
                i++
            ) {
                strategiesCallLen[i] = _packedStrategies.callLen[i];
            }
            for (uint256 i = 0; i < offsetCalldata; i++) {
                calculationsLen[i] = _packedStrategies.calculationsLen[i];
            }
            calculationsLen[offsetCalldata] = _newStrategyParam.calculationsLen;
            for (
                uint256 i = offsetCalldata + 1;
                i < _packedStrategies.calculationsLen.length;
                i++
            ) {
                calculationsLen[i] = _packedStrategies.calculationsLen[i];
            }
            for (uint256 i = 0; i < offsetCalldata; i++) {
                conditionsLen[i] = _packedStrategies.conditionsLen[i];
            }
            conditionsLen[offsetCalldata] = _newStrategyParam.conditionsLen;
            for (
                uint256 i = offsetCalldata + 1;
                i < _packedStrategies.conditionsLen.length;
                i++
            ) {
                conditionsLen[i] = _packedStrategies.conditionsLen[i];
            }

            uint256 totalCallLen = 0;
            offsetCalldata = 0;
            for (uint256 i = 0; i < _packedStrategies.addresses.length; i++) {
                if (i == indexStrategyToUpdate) {
                    offsetCalldata = totalCallLen;
                }
                totalCallLen += _packedStrategies.callLen[i];
            }
            uint256 offsetCalldataAfter = offsetCalldata +
                _packedStrategies.callLen[indexStrategyToUpdate];
            for (uint256 i = 0; i < offsetCalldata; i++) {
                contracts[i] = _packedStrategies.contracts[i];
            }
            for (uint256 i = 0; i < _newStrategyParam.callLen; i++) {
                contracts[i + offsetCalldata] = _newStrategyParam.contracts[i];
            }
            for (uint256 i = 0; i < totalCallLen - offsetCalldataAfter; i++) {
                contracts[
                    i + offsetCalldata + _newStrategyParam.callLen
                ] = _packedStrategies.contracts[offsetCalldataAfter + i];
            }
            for (uint256 i = 0; i < offsetCalldata; i++) {
                checkdata[i] = bytes4(_packedStrategies.checkdata[i]);
            }
            for (uint256 i = 0; i < _newStrategyParam.callLen; i++) {
                checkdata[i + offsetCalldata] = bytes4(
                    _newStrategyParam.checkdata[i]
                );
            }
            for (uint256 i = 0; i < totalCallLen - offsetCalldataAfter; i++) {
                checkdata[
                    i + offsetCalldata + _newStrategyParam.callLen
                ] = bytes4(
                    _packedStrategies.checkdata[offsetCalldataAfter + i]
                );
            }
            for (uint256 i = 0; i < offsetCalldata; i++) {
                offset[i] = _packedStrategies.offset[i];
            }
            for (uint256 i = 0; i < _newStrategyParam.callLen; i++) {
                offset[i + offsetCalldata] = _newStrategyParam.offset[i];
            }
            for (uint256 i = 0; i < totalCallLen - offsetCalldataAfter; i++) {
                offset[
                    i + offsetCalldata + _newStrategyParam.callLen
                ] = _packedStrategies.offset[offsetCalldataAfter + i];
            }

            totalCallLen = 0;
            offsetCalldata = 0;
            for (uint256 i = 0; i < _packedStrategies.addresses.length; i++) {
                if (i == indexStrategyToUpdate) {
                    offsetCalldata = totalCallLen;
                }
                totalCallLen += _packedStrategies.calculationsLen[i];
            }
            offsetCalldataAfter =
                offsetCalldata +
                _packedStrategies.calculationsLen[indexStrategyToUpdate];
            for (uint256 i = 0; i < offsetCalldata; i++) {
                calculations[i] = _packedStrategies.calculations[i];
            }
            for (uint256 i = 0; i < _newStrategyParam.calculationsLen; i++) {
                calculations[i + offsetCalldata] = _newStrategyParam
                    .calculations[i];
            }
            for (uint256 i = 0; i < totalCallLen - offsetCalldataAfter; i++) {
                calculations[
                    i + offsetCalldata + _newStrategyParam.calculationsLen
                ] = _packedStrategies.calculations[offsetCalldataAfter + i];
            }

            totalCallLen = 0;
            offsetCalldata = 0;
            for (uint256 i = 0; i < _packedStrategies.addresses.length; i++) {
                if (i == indexStrategyToUpdate) {
                    offsetCalldata = totalCallLen;
                }
                totalCallLen += _packedStrategies.conditionsLen[i];
            }
            offsetCalldataAfter =
                offsetCalldata +
                _packedStrategies.conditionsLen[indexStrategyToUpdate];
            for (uint256 i = 0; i < offsetCalldata; i++) {
                conditions[i] = _packedStrategies.conditions[i];
            }
            for (uint256 i = 0; i < _newStrategyParam.conditionsLen; i++) {
                conditions[i + offsetCalldata] = _newStrategyParam.conditions[
                    i
                ];
            }
            for (uint256 i = 0; i < totalCallLen - offsetCalldataAfter; i++) {
                conditions[
                    i + offsetCalldata + _newStrategyParam.conditionsLen
                ] = _packedStrategies.conditions[offsetCalldataAfter + i];
            }
        }

        strategiesHash = uint256(
            keccak256(
                abi.encodePacked(
                    _packedStrategies.addresses,
                    strategiesCallLen,
                    contracts,
                    checkdata,
                    offset,
                    calculationsLen,
                    calculations,
                    conditionsLen,
                    conditions
                )
            )
        );

        emit StrategyUpdated(
            _packedStrategies.addresses,
            strategiesCallLen,
            contracts,
            checkdata,
            offset,
            calculationsLen,
            calculations,
            conditionsLen,
            conditions
        );
    }

    function removeStrategy(
        PackedStrategies memory _packedStrategies,
        uint256 indexStrategyToRemove
    ) external onlyOwner {
        // Checks at least one strategy is registered
        require(strategiesHash != 0, "NO_STRATEGIES");

        bytes4[] memory checkdata = castCheckdataToBytes4(
            _packedStrategies.checkdata
        );

        // Checks strategies data is valid
        checkStrategyHash(_packedStrategies, checkdata);

        // Checks index in range
        require(indexStrategyToRemove < _packedStrategies.addresses.length);

        // Build new arrays for the Strategy Hash and the Event
        uint256[] memory strategiesCallLen = new uint256[](
            _packedStrategies.callLen.length - 1
        );
        uint256[] memory calculationsLen = new uint256[](
            _packedStrategies.calculationsLen.length - 1
        );
        uint256[] memory conditionsLen = new uint256[](
            _packedStrategies.conditionsLen.length - 1
        );
        address[] memory contracts = new address[](
            _packedStrategies.contracts.length -
                _packedStrategies.callLen[indexStrategyToRemove]
        );
        checkdata = new bytes4[](
            _packedStrategies.checkdata.length -
                _packedStrategies.callLen[indexStrategyToRemove]
        );
        uint256[] memory offset = new uint256[](
            _packedStrategies.offset.length -
                _packedStrategies.callLen[indexStrategyToRemove]
        );
        uint256[] memory calculations = new uint256[](
            _packedStrategies.calculations.length -
                _packedStrategies.calculationsLen[indexStrategyToRemove]
        );
        uint256[] memory conditions = new uint256[](
            _packedStrategies.conditions.length -
                _packedStrategies.conditionsLen[indexStrategyToRemove]
        );
        uint256 offsetCalldata = indexStrategyToRemove;
        for (uint256 i = 0; i < offsetCalldata; i++) {
            strategiesCallLen[i] = _packedStrategies.callLen[i];
        }
        for (
            uint256 i = 0;
            i < _packedStrategies.addresses.length - (offsetCalldata + 1);
            i++
        ) {
            strategiesCallLen[offsetCalldata + i] = _packedStrategies.callLen[
                offsetCalldata + 1 + i
            ];
        }
        for (uint256 i = 0; i < offsetCalldata; i++) {
            calculationsLen[i] = _packedStrategies.calculationsLen[i];
        }
        for (
            uint256 i = 0;
            i < _packedStrategies.addresses.length - (offsetCalldata + 1);
            i++
        ) {
            calculationsLen[offsetCalldata + i] = _packedStrategies
                .calculationsLen[offsetCalldata + 1 + i];
        }
        for (uint256 i = 0; i < offsetCalldata; i++) {
            conditionsLen[i] = _packedStrategies.conditionsLen[i];
        }
        for (
            uint256 i = 0;
            i < _packedStrategies.addresses.length - (offsetCalldata + 1);
            i++
        ) {
            conditionsLen[offsetCalldata + i] = _packedStrategies.conditionsLen[
                offsetCalldata + 1 + i
            ];
        }

        uint256 totalCallLen = 0;
        offsetCalldata = 0;
        for (uint256 i = 0; i < _packedStrategies.addresses.length; i++) {
            if (i == indexStrategyToRemove) {
                offsetCalldata = totalCallLen;
            }
            totalCallLen += _packedStrategies.callLen[i];
        }

        for (uint256 i = 0; i < offsetCalldata; i++) {
            contracts[i] = _packedStrategies.contracts[i];
        }
        for (
            uint256 i = 0;
            i <
            totalCallLen -
                (offsetCalldata +
                    _packedStrategies.callLen[indexStrategyToRemove]);
            i++
        ) {
            contracts[i + offsetCalldata] = _packedStrategies.contracts[
                offsetCalldata +
                    _packedStrategies.callLen[indexStrategyToRemove] +
                    i
            ];
        }
        for (uint256 i = 0; i < offsetCalldata; i++) {
            checkdata[i] = bytes4(_packedStrategies.checkdata[i]);
        }
        for (
            uint256 i = 0;
            i <
            totalCallLen -
                (offsetCalldata +
                    _packedStrategies.callLen[indexStrategyToRemove]);
            i++
        ) {
            checkdata[i + offsetCalldata] = bytes4(
                _packedStrategies.checkdata[
                    offsetCalldata +
                        _packedStrategies.callLen[indexStrategyToRemove] +
                        i
                ]
            );
        }
        for (uint256 i = 0; i < offsetCalldata; i++) {
            offset[i] = _packedStrategies.offset[i];
        }
        for (
            uint256 i = 0;
            i <
            totalCallLen -
                (offsetCalldata +
                    _packedStrategies.callLen[indexStrategyToRemove]);
            i++
        ) {
            offset[i + offsetCalldata] = _packedStrategies.offset[
                offsetCalldata +
                    _packedStrategies.callLen[indexStrategyToRemove] +
                    i
            ];
        }

        totalCallLen = 0;
        offsetCalldata = 0;
        for (uint256 i = 0; i < _packedStrategies.addresses.length; i++) {
            if (i == indexStrategyToRemove) {
                offsetCalldata = totalCallLen;
            }
            totalCallLen += _packedStrategies.calculationsLen[i];
        }
        for (uint256 i = 0; i < offsetCalldata; i++) {
            calculations[i] = _packedStrategies.calculations[i];
        }
        for (
            uint256 i = 0;
            i <
            totalCallLen -
                (offsetCalldata +
                    _packedStrategies.calculationsLen[indexStrategyToRemove]);
            i++
        ) {
            calculations[i + offsetCalldata] = _packedStrategies.calculations[
                offsetCalldata +
                    _packedStrategies.calculationsLen[indexStrategyToRemove] +
                    i
            ];
        }
        totalCallLen = 0;
        offsetCalldata = 0;
        for (uint256 i = 0; i < _packedStrategies.addresses.length; i++) {
            if (i == indexStrategyToRemove) {
                offsetCalldata = totalCallLen;
            }
            totalCallLen += _packedStrategies.conditionsLen[i];
        }
        for (uint256 i = 0; i < offsetCalldata; i++) {
            conditions[i] = _packedStrategies.conditions[i];
        }
        for (
            uint256 i = 0;
            i <
            totalCallLen -
                (offsetCalldata +
                    _packedStrategies.conditionsLen[indexStrategyToRemove]);
            i++
        ) {
            conditions[i + offsetCalldata] = _packedStrategies.conditions[
                offsetCalldata +
                    _packedStrategies.conditionsLen[indexStrategyToRemove] +
                    i
            ];
        }

        strategiesHash = uint256(
            keccak256(
                abi.encodePacked(
                    _packedStrategies.addresses,
                    strategiesCallLen,
                    contracts,
                    checkdata,
                    offset,
                    calculationsLen,
                    calculations,
                    conditionsLen,
                    conditions
                )
            )
        );
        emit StrategyRemoved(
            _packedStrategies.addresses,
            strategiesCallLen,
            contracts,
            checkdata,
            offset,
            calculationsLen,
            calculations,
            conditionsLen,
            conditions
        );
    }

    //Can't set only view, .call potentially modify state (should not arrive)
    function getStrategiesData(
        address[] calldata contracts,
        bytes[] calldata checkdata,
        uint256[] calldata offset
    ) public returns (uint256[] memory dataStrategies) {
        uint256[] memory dataStrategies_ = new uint256[](contracts.length);
        for (uint256 j; j < contracts.length; j++) {
            (, bytes memory data) = contracts[j].call(checkdata[j]);
            dataStrategies_[j] = uint256(bytesToBytes32(data, offset[j]));
        }
        return (dataStrategies_);
    }

    //     function updateTargetAllocation(address[] memory strategies) internal {
    //         uint256[] memory realAllocations = new uint256[](strategies.length);
    //         uint256 cumulativeAmountRealAllocations = 0;
    //         uint256 cumulativeAmountTargetAllocations = 0;
    //         for (uint256 j; j < strategies.length; j++) {
    //             realAllocations[j] = IStrategy(strategies[j]).totalAssets();
    //             cumulativeAmountRealAllocations += realAllocations[j];
    //             cumulativeAmountTargetAllocations += targetAllocation[j];
    //         }
    //
    //         if (cumulativeAmountTargetAllocations == 0) {
    //             targetAllocation = realAllocations;
    //         } else {
    //             if (
    //                 cumulativeAmountTargetAllocations <=
    //                 cumulativeAmountRealAllocations
    //             ) {
    //                 uint256 diff = cumulativeAmountRealAllocations -
    //                     cumulativeAmountTargetAllocations;
    //                 // We need to add this amount respecting the different strategies allocation ratio
    //                 for (uint256 i = 0; i < strategies.length; i++) {
    //                     uint256 strategyAllocationRatio = (PRECISION *
    //                         targetAllocation[i]) /
    //                         cumulativeAmountTargetAllocations;
    //                     targetAllocation[i] +=
    //                         (strategyAllocationRatio * diff) /
    //                         PRECISION;
    //                 }
    //             } else {
    //                 uint256 diff = cumulativeAmountTargetAllocations -
    //                     cumulativeAmountRealAllocations;
    //                 // We need to substract this amount respecting the different strategies allocation ratio
    //                 for (uint256 i = 0; i < strategies.length; i++) {
    //                     uint256 strategyAllocationRatio = (PRECISION *
    //                         targetAllocation[i]) /
    //                         cumulativeAmountTargetAllocations;
    //                     targetAllocation[i] -=
    //                         (strategyAllocationRatio * diff) /
    //                         PRECISION;
    //                 }
    //             }
    //         }
    //     }
    //
    // UTILS
    function checkStrategyHash(
        PackedStrategies memory _packedStrategies,
        bytes4[] memory checkdata
    ) internal view {
        require(
            strategiesHash ==
                uint256(
                    keccak256(
                        abi.encodePacked(
                            _packedStrategies.addresses,
                            _packedStrategies.callLen,
                            _packedStrategies.contracts,
                            checkdata,
                            _packedStrategies.offset,
                            _packedStrategies.calculationsLen,
                            _packedStrategies.calculations,
                            _packedStrategies.conditionsLen,
                            _packedStrategies.conditions
                        )
                    )
                ),
            "DATA"
        );
    }

    function parseProgramOutput(
        uint256[] calldata programOutput
    )
        public
        pure
        returns (
            uint256 _inputHash,
            uint256[] memory _currentTargetAllocation,
            uint256[] memory _newTargetAllocation,
            uint256 _currentSolution,
            uint256 _newSolution
        )
    {
        _inputHash = programOutput[0] << 128;
        _inputHash += programOutput[1];

        _currentTargetAllocation = new uint256[](programOutput[2]);

        _newTargetAllocation = new uint256[](programOutput[2]);

        for (uint256 i = 0; i < programOutput[2]; i++) {
            // NOTE: skip the 2 first value + array len
            _currentTargetAllocation[i] = programOutput[i + 3];
            _newTargetAllocation[i] = programOutput[i + 4 + programOutput[2]];
        }
        return (
            _inputHash,
            _currentTargetAllocation,
            _newTargetAllocation,
            programOutput[programOutput.length - 2],
            programOutput[programOutput.length - 1]
        );
    }

    function bytesToBytes32(
        bytes memory b,
        uint offset
    ) private pure returns (bytes32 result) {
        offset += 32;
        assembly {
            result := mload(add(b, offset))
        }
    }

    function castCheckdataToBytes4(
        bytes[] memory oldCheckdata
    ) internal view returns (bytes4[] memory checkdata) {
        checkdata = new bytes4[](oldCheckdata.length);
        for (uint256 i = 0; i < oldCheckdata.length; i++) {
            checkdata[i] = bytes4(oldCheckdata[i]);
        }
    }

    function checkValidityOfData(
        StrategyParam memory _newStrategyParam
    ) internal {
        // check lengths
        require(
            _newStrategyParam.callLen == _newStrategyParam.contracts.length &&
                _newStrategyParam.callLen ==
                _newStrategyParam.checkdata.length &&
                _newStrategyParam.callLen == _newStrategyParam.offset.length &&
                _newStrategyParam.calculationsLen ==
                _newStrategyParam.calculations.length &&
                _newStrategyParam.conditionsLen ==
                _newStrategyParam.conditions.length,
            "ARRAY_LEN"
        );

        // check success of calls
        for (uint256 i = 0; i < _newStrategyParam.callLen; i++) {
            (bool success, ) = _newStrategyParam.contracts[i].call(
                _newStrategyParam.checkdata[i]
            );
            require(success == true, "CALLDATA");
            // Should we check for offset?
        }
    }

    function appendUint256ToArray(
        uint256[] memory array,
        uint256 newItem
    ) internal pure returns (uint256[] memory newArray) {
        newArray = new uint256[](array.length + 1);
        for (uint256 i = 0; i < array.length; i++) {
            newArray[i] = array[i];
        }
        newArray[array.length] = newItem;
    }

    function concatenateUint256ArrayToUint256Array(
        uint256[] memory arrayA,
        uint256[] memory arrayB
    ) internal pure returns (uint256[] memory newArray) {
        newArray = new uint256[](arrayA.length + arrayB.length);
        for (uint256 i = 0; i < arrayA.length; i++) {
            newArray[i] = arrayA[i];
        }
        uint256 lenA = arrayA.length;
        for (uint256 i = 0; i < arrayB.length; i++) {
            newArray[i + lenA] = arrayB[i];
        }
    }
}