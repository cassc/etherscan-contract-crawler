// SPDX-License-Identifier: GPL-3.0-only

// ┏━━━┓━━━━━┏┓━━━━━━━━━┏━━━┓━━━━━━━━━━━━━━━━━━━━━━━
// ┃┏━┓┃━━━━┏┛┗┓━━━━━━━━┃┏━━┛━━━━━━━━━━━━━━━━━━━━━━━
// ┃┗━┛┃┏━┓━┗┓┏┛┏━━┓━━━━┃┗━━┓┏┓┏━┓━┏━━┓━┏━┓━┏━━┓┏━━┓
// ┃┏━┓┃┃┏┓┓━┃┃━┃┏┓┃━━━━┃┏━━┛┣┫┃┏┓┓┗━┓┃━┃┏┓┓┃┏━┛┃┏┓┃
// ┃┃ ┃┃┃┃┃┃━┃┗┓┃┃━┫━┏┓━┃┃━━━┃┃┃┃┃┃┃┗┛┗┓┃┃┃┃┃┗━┓┃┃━┫
// ┗┛ ┗┛┗┛┗┛━┗━┛┗━━┛━┗┛━┗┛━━━┗┛┗┛┗┛┗━━━┛┗┛┗┛┗━━┛┗━━┛
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

pragma solidity ^0.8.0;

import "./AntePool.sol";
import "./interfaces/IAnteTest.sol";
import "./interfaces/IAntePool.sol";
import "./interfaces/IAntePoolFactory.sol";
import "./interfaces/IAntePoolFactoryController.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/// @title Ante V0.6 Ante Pool Factory smart contract
/// @notice Contract that creates an AntePool wrapper for an AnteTest
contract AntePoolFactory is IAntePoolFactory, ReentrancyGuard {
    struct TestStateInfo {
        bool hasFailed;
        address verifier;
        uint256 failedBlock;
        uint256 failedTimestamp;
    }

    mapping(address => TestStateInfo) private stateByTest;

    // Stores all the pools associated with a test
    mapping(address => address[]) public poolsByTest;
    /// @inheritdoc IAntePoolFactory
    mapping(bytes32 => address) public override poolByConfig;
    /// @inheritdoc IAntePoolFactory
    address[] public override allPools;

    /// @dev The maximum number of pools allowed to be created for an Ante Test
    uint256 public constant MAX_POOLS_PER_TEST = 10;

    /// @inheritdoc IAntePoolFactory
    IAntePoolFactoryController public override controller;

    /// @param _controller The address of the Ante Factory Controller
    constructor(address _controller) {
        controller = IAntePoolFactoryController(_controller);
    }

    /// @inheritdoc IAntePoolFactory
    function createPool(
        address testAddr,
        address tokenAddr,
        uint256 payoutRatio,
        uint256 decayRate,
        uint256 authorRewardRate
    ) external override returns (address testPool) {
        // Checks that a non-zero AnteTest address is passed in and that
        // an AntePool has not already been created for that AnteTest
        require(testAddr != address(0), "ANTE: Test address is 0");
        require(!stateByTest[testAddr].hasFailed, "ANTE: Test has previously failed");
        require(controller.isTokenAllowed(tokenAddr), "ANTE: Token not allowed");
        require(poolsByTest[testAddr].length < MAX_POOLS_PER_TEST, "ANTE: Max pools per test reached");

        uint256 tokenMinimum = controller.getTokenMinimum(tokenAddr);
        bytes32 configHash = keccak256(
            abi.encodePacked(testAddr, tokenAddr, tokenMinimum, payoutRatio, decayRate, authorRewardRate)
        );
        address poolAddr = poolByConfig[configHash];
        require(poolAddr == address(0), "ANTE: Pool with the same config already exists");

        IAnteTest anteTest = IAnteTest(testAddr);

        testPool = address(new AntePool{salt: configHash}(controller.antePoolLogicAddr()));

        require(testPool != address(0), "ANTE: Pool creation failed");

        poolsByTest[testAddr].push(testPool);
        poolByConfig[configHash] = testPool;
        allPools.push(testPool);

        IAntePool(testPool).initialize(
            anteTest,
            IERC20(tokenAddr),
            tokenMinimum,
            decayRate,
            payoutRatio,
            authorRewardRate
        );

        emit AntePoolCreated(
            testAddr,
            tokenAddr,
            tokenMinimum,
            payoutRatio,
            decayRate,
            authorRewardRate,
            testPool,
            msg.sender
        );
    }

    /// @inheritdoc IAntePoolFactory
    function hasTestFailed(address testAddr) external view override returns (bool) {
        return stateByTest[testAddr].hasFailed;
    }

    /// @inheritdoc IAntePoolFactory
    function checkTestWithState(
        bytes memory _testState,
        address verifier,
        bytes32 poolConfig
    ) public override nonReentrant {
        address poolAddr = poolByConfig[poolConfig];
        require(poolAddr == msg.sender, "ANTE: Must be called by a pool");

        IAntePool pool = IAntePool(msg.sender);
        (, , uint256 claimableShares, ) = pool.getChallengerInfo(verifier);
        require(claimableShares > 0, "ANTE: Only confirmed challengers can checkTest");
        require(
            pool.getCheckTestAllowedBlock(verifier) < block.number,
            "ANTE: must wait 12 blocks after challenging to call checkTest"
        );
        IAnteTest anteTest = pool.anteTest();
        bool hasFailed = stateByTest[address(anteTest)].hasFailed;
        require(!hasFailed, "ANTE: Test already failed.");

        pool.updateVerifiedState(verifier);
        if (!_checkTestNoRevert(anteTest, _testState)) {
            _setFailureStateForTest(address(anteTest), verifier);
        }
    }

    /// @inheritdoc IAntePoolFactory
    function getPoolsByTest(address testAddr) external view override returns (address[] memory) {
        return poolsByTest[testAddr];
    }

    /// @inheritdoc IAntePoolFactory
    function getNumPoolsByTest(address testAddr) external view override returns (uint256) {
        return poolsByTest[testAddr].length;
    }

    /// @inheritdoc IAntePoolFactory
    function numPools() external view override returns (uint256) {
        return allPools.length;
    }

    /*****************************************************
     * =============== INTERNAL HELPERS ================ *
     *****************************************************/

    /// @notice Checks the connected Ante Test, also returns true if
    /// setStateAndCheckTestPasses or checkTestPasses reverts
    /// @return passes bool if the Ante Test passed
    function _checkTestNoRevert(IAnteTest anteTest, bytes memory _testState) internal returns (bool) {
        // This condition replicates the logic from AnteTest(v0.6).setStateAndCheckTestPasses
        // It is used for backward compatibility with v0.5 tests
        if (_testState.length > 0) {
            try anteTest.setStateAndCheckTestPasses(_testState) returns (bool passes) {
                return passes;
            } catch {
                return true;
            }
        }

        try anteTest.checkTestPasses() returns (bool passes) {
            return passes;
        } catch {
            return true;
        }
    }

    function _setFailureStateForTest(address testAddr, address verifier) internal {
        TestStateInfo storage testState = stateByTest[testAddr];
        testState.hasFailed = true;
        testState.failedBlock = block.number;
        testState.failedTimestamp = block.timestamp;
        testState.verifier = verifier;

        address[] memory pools = poolsByTest[testAddr];
        uint256 numPoolsByTest = pools.length;
        for (uint256 i = 0; i < numPoolsByTest; i++) {
            try IAntePool(pools[i]).updateFailureState(verifier) {} catch {
                emit PoolFailureReverted();
            }
        }
    }
}