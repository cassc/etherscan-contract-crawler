// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/interfaces/IERC2981.sol";

interface INFT is IERC2981 {
    function awardToken(address _user, uint32 _tokenID) external;

    function totalAmountOfEdition() external view returns (uint32);

    function timeStart() external view returns (uint32);

    function timeEnd() external view returns (uint32);

    function nftId() external view returns (uint32);

    function init(
        address _accessManangerAddress,
        bytes memory _staticData,
        bytes memory _dynamicData
    ) external;
}