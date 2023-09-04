// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import '@openzeppelin/contracts/interfaces/IERC721.sol';

interface IAvastarsTeleporter is IERC721 {
    enum Wave {
        PRIME,
        REPLICANT
    }

    function useTraits(uint256 _primeId, bool[12] calldata _traitFlags) external;
    function getPrimeReplicationByTokenId(uint256 _tokenId) external view returns (uint256 tokenId, bool[12] memory replicated);
    function mintReplicant(
        address _owner,
        uint256 _traits,
        uint8   _generation,
        uint8   _gender,
        uint8   _ranking
    ) external returns (uint256 tokenId, uint256 serial);

    function getAvastarWaveByTokenId(uint256 _tokenId) external view returns (Wave wave);
}