// SPDX-License-Identifier: UNLICENSED

pragma solidity =0.8.4;

import "./EDataTypes.sol";
pragma experimental ABIEncoderV2;

interface IEvent {
    function info(uint256 _eventId) external view returns (EDataTypes.Event memory _event);

    function createSingleEvent(
        uint256[3] memory _times,
        address _helperAddress,
        uint256[] calldata _odds,
        string memory _datas,
        address _creator,
        uint256 _pro,
        bool _affiliate,
        uint256 _hostFee
    ) external returns (uint256 _idx);
}