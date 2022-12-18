// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IBreeding {
    struct Microphone {
        // Mic body types = [0, 1, 2, ..., 6]
        uint8 body;
        // Mic head types = [0, 1, 2, ..., 6]
        uint8 head;
        // Mic kinds = [0 (Beginner), 1 (Cover), 2 (Riser), 3 (Master)]
        uint8 kind;
        // The class of mic = [0 (Bronze), 1 (Silver), 2 (Gold), 3 (Platinum), 4 (Diamond)]
        uint8 class;
        // The timestamp from the block when this pass came into existence.
        uint256 birthTime;
        // Set to the index in the cooldown array (see below) that represents the current cooldown duration
        uint256 cooldownIndex;
        // The minimum timestamp after which this cat can engage in breeding activities again
        uint256 cooldownEndTime;
    }

    function updateManagement(address _newManagement) external;

    function updateMaxBreedTimes(uint256 _maxBreedTimes) external;

    function updateBusdFees(
        uint256 _microphoneClass,
        uint256[] calldata _rubyFees
    ) external;

    function updateRubyFees(
        uint256 _microphoneClass,
        uint256[] calldata _rubyFees
    ) external;

    function updateCooldown(uint256 _value) external;

    function updateDropRates(
        uint8 _classCol1,
        uint8 _classCol2,
        uint256[] calldata _dropRates
    ) external;

    function breed(
        uint256 _matronId,
        uint256 _sireId,
        uint256 _matronScrollId,
        uint256 _sireScrollId,
        bytes calldata _signature
    ) external;

    function getMicro(uint256 _id) external view returns (Microphone memory);

    function addMicro(
        uint8 _body,
        uint8 _head,
        uint8 _kind,
        uint8 _class
    ) external returns (uint256 _micId);
}