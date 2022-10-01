//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";

interface IClonableRaffleVRFReference {
  function initialize(
    address vrfProvider,
    uint256 snapshotBlock,
    address admin,
    uint256 _raffleStartTimeUnix,
    uint256 _raffleEndTimeUnix,
    bool _useSnapshotBlockAsEndTime
  ) external;
}

contract RaffleFactory is Ownable {

    event NewRaffleClone(
        uint256 indexed id,
        address indexed referenceContract,
        address indexed raffleClone,
        address vrfProvider,
        uint256 snapshotBlock,
        address admin
    );

    event SetClonableRaffleReferenceValidity(
        address indexed referenceContract,
        bool validity
    );

    event SetVRFProviderValidity(
        address indexed vrfProvider,
        bool validity
    );

    mapping(address => bool) public validClonableRaffleReferences;
    mapping(address => bool) public validVRFProviders;

    // Controlled variables
    using Counters for Counters.Counter;
    Counters.Counter private _raffleIds;

    constructor(
        address _clonableRaffle,
        address _vrfProvider
    ) {
        validClonableRaffleReferences[_clonableRaffle] = true;
        emit SetClonableRaffleReferenceValidity(_clonableRaffle, true);
        validVRFProviders[_vrfProvider] = true;
        emit SetVRFProviderValidity(_vrfProvider, true);
    }

    function newRaffle(
        address _raffleReferenceContract,
        address _vrfProvider,
        uint256 _snapshotBlock,
        address _admin,
        uint256 _raffleStartTimeUnix,
        uint256 _raffleEndTimeUnix,
        bool _useSnapshotBlockAsEndTime
    ) external onlyOwner {
        require(validClonableRaffleReferences[_raffleReferenceContract], "INVALID_RAFFLE_REFERENCE_CONTRACT");
        require(validVRFProviders[_vrfProvider], "INVALID_RAFFLE_REFERENCE_CONTRACT");
        _raffleIds.increment();
        uint256 newRaffleId = _raffleIds.current();
        // Deploy new raffle contract
        address newRaffleCloneAddress = Clones.clone(_raffleReferenceContract);
        IClonableRaffleVRFReference newRaffleClone = IClonableRaffleVRFReference(newRaffleCloneAddress);
        newRaffleClone.initialize(_vrfProvider, _snapshotBlock, _admin, _raffleStartTimeUnix, _raffleEndTimeUnix, _useSnapshotBlockAsEndTime);
        emit NewRaffleClone(newRaffleId, _raffleReferenceContract, newRaffleCloneAddress, _vrfProvider, _snapshotBlock, _admin);
    }

    function setClonableRaffleReferenceValidity(
        address _clonableRaffle,
        bool _validity
    ) external onlyOwner {
        validClonableRaffleReferences[_clonableRaffle] = _validity;
        emit SetClonableRaffleReferenceValidity(_clonableRaffle, _validity);
    }

    function setVRFProviderValidity(
        address _vrfProvider,
        bool _validity
    ) external onlyOwner {
        validVRFProviders[_vrfProvider] = _validity;
        emit SetVRFProviderValidity(_vrfProvider, _validity);
    }

}