// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import { IPools, IStash, IStashFactory } from "./Interfaces.sol";
import { IBoosterOwner } from "./BoosterOwner.sol";

interface IFeeTokenVerifier {
    function checkToken(address) external view returns (bool);
}

/**
 * @title   BoosterOwnerSecondary
 * @author  ConvexFinance -> AuraFinance
 * @notice  Immutable booster owner that requires all pools to be shutdown before shutting down the entire convex system
 * @dev     A timelock is required if forcing a shutdown if there is a bugged pool that can not be withdrawn from.
 *          Allow arbitrary calls to other contracts, but limit how calls are made to Booster.
 */
contract BoosterOwnerSecondary {
    IPools public immutable booster;
    IBoosterOwner public immutable boosterOwner;
    uint256 public immutable oldPidCheckpoint;

    address public owner;
    address public manager;
    address public pendingowner;

    bool public sealStashImplementation;

    address public feeTokenVerifier;

    event TransferOwnership(address pendingOwner);
    event AcceptedOwnership(address newOwner);
    event SealStashImplementation();
    event SetFeeTokenVerifier(address feeTokenVerifier);
    event SetManager(address manager);

    /**
     * @param _owner          Owner (e.g. CVX multisig)
     * @param _boosterOwner   BoosterOwner
     */
    constructor(
        address _owner,
        address _boosterOwner,
        address _booster
    ) public {
        owner = _owner;
        manager = _owner;
        boosterOwner = IBoosterOwner(_boosterOwner);
        booster = IPools(_booster);

        oldPidCheckpoint = IPools(_booster).poolLength() - 1;
    }

    /* ----------------------------------------------------------------
     * Modifiers
     * ------------------------------------------------------------- */

    modifier onlyOwner() {
        require(owner == msg.sender, "!owner");
        _;
    }

    modifier onlyManager() {
        require(manager == msg.sender, "!manager");
        _;
    }

    /* ----------------------------------------------------------------
     * Setters
     * ------------------------------------------------------------- */

    function setSealStashImplementation() external onlyOwner {
        sealStashImplementation = true;
        emit SealStashImplementation();
    }

    function setFeeTokenVerifier(address _feeTokenVerifier) external onlyManager {
        feeTokenVerifier = _feeTokenVerifier;
        emit SetFeeTokenVerifier(_feeTokenVerifier);
    }

    function setManager(address _manager) external onlyOwner {
        require(manager != address(0), "sealed");
        manager = _manager;
        emit SetManager(_manager);
    }

    function transferOwnership(address _owner) external onlyOwner {
        pendingowner = _owner;
        emit TransferOwnership(_owner);
    }

    function acceptOwnership() external {
        require(pendingowner == msg.sender, "!pendingowner");
        owner = pendingowner;
        pendingowner = address(0);
        emit AcceptedOwnership(owner);
    }

    /* ----------------------------------------------------------------
     * Booster Functions
     * ------------------------------------------------------------- */

    function acceptOwnershipBoosterOwner() external {
        boosterOwner.acceptOwnership();
    }

    function setArbitrator(address _arb) external onlyOwner {
        boosterOwner.setArbitrator(_arb);
    }

    function setFeeInfo(address _feeToken, address _feeDistro) external onlyOwner {
        if (feeTokenVerifier != address(0)) {
            require(IFeeTokenVerifier(feeTokenVerifier).checkToken(_feeToken), "!verified");
        }
        boosterOwner.setFeeInfo(_feeToken, _feeDistro);
    }

    function updateFeeInfo(address _feeToken, bool _active) external onlyOwner {
        boosterOwner.updateFeeInfo(_feeToken, _active);
    }

    function setFeeManager(address _feeM) external onlyOwner {
        boosterOwner.setFeeManager(_feeM);
    }

    function setVoteDelegate(address _voteDelegate) external onlyOwner {
        boosterOwner.setVoteDelegate(_voteDelegate);
    }

    function shutdownSystem() external onlyOwner {
        boosterOwner.shutdownSystem();
    }

    function queueForceShutdown() external onlyOwner {
        boosterOwner.queueForceShutdown();
    }

    function forceShutdownSystem() external onlyOwner {
        boosterOwner.forceShutdownSystem();
    }

    function setStashFactoryImplementation(
        address _v1,
        address _v2,
        address _v3
    ) external onlyOwner {
        require(!sealStashImplementation, "sealed");
        boosterOwner.setStashFactoryImplementation(_v1, _v2, _v3);
    }

    function execute(
        address _to,
        uint256 _value,
        bytes memory _data
    ) external onlyOwner returns (bool, bytes memory) {
        bytes4 sig;
        assembly {
            sig := mload(add(_data, 32))
        }

        require(
            sig != IBoosterOwner.setFactories.selector && 
                sig != IStashFactory.setImplementation.selector &&
                sig != IStash.setExtraReward.selector &&
                sig != IBoosterOwner.setFeeInfo.selector,
            "!allowed"
        );

        (bool success, bytes memory result) = boosterOwner.execute(_to, _value, _data);
        require(success, "!success");
        return (success, result);
    }

    // --- Helper functions for other systems, could also just use execute() ---

    function setRescueTokenDistribution(
        address _distributor,
        address _rewardDeposit,
        address _treasury
    ) external onlyOwner {
        boosterOwner.setRescueTokenDistribution(_distributor, _rewardDeposit, _treasury);
    }

    function setRescueTokenReward(address _token, uint256 _option) external onlyOwner {
        boosterOwner.setRescueTokenReward(_token, _option);
    }

    function setStashExtraReward(uint256 _pid, address _token) external onlyOwner {
        require(_pid > oldPidCheckpoint, "!checkpoint");
        (, , , , address stash, ) = booster.poolInfo(_pid);
        boosterOwner.setStashExtraReward(stash, _token);
    }

    function setStashRewardHook(address _stash, address _hook) external onlyOwner {
        boosterOwner.setStashRewardHook(_stash, _hook);
    }

    function setStashTokenIsValid(address stashToken, bool isValid) external onlyOwner {
        bytes memory data = abi.encodeWithSignature("setIsValid(bool)", isValid); 
        (bool success, ) = boosterOwner.execute(stashToken, 0, data);
        require(success, "!success");
    }
}