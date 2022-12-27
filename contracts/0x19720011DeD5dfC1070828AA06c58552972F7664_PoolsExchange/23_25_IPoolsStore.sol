// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;
pragma abicoder v2;

import "../libraries/LibPart.sol";

interface IPoolsStore {
    function singleTransfer(
        address _from,
        address _to,
        uint256 _tokenId
    ) external returns (uint256);

    function mintTo(address _to, LibPart.Part memory _royalty)
        external
        returns (uint256);

    function owner() external view returns (address);
}