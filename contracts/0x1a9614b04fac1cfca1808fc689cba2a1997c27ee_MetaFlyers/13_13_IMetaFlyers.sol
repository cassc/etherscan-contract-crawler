// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;


interface IMetaFlyers {

    // store lock meta data
    struct Locked {
        uint64 tokenId;
        uint64 lockTimestamp;
        uint128 claimedAmount;
    }
    
    function totalMinted() external returns (uint16);
    function totalLocked() external returns (uint16);
    function getLock(uint256 tokenId) external view returns (Locked memory);
    function isLocked(uint256 tokenId) external view returns(bool);
    
    function mint(address recipient, uint16 qty) external; // onlyAdmin
    function burn(uint256 tokenId) external; // onlyAdmin
    function lock( uint256 tokenId, address user) external; // onlyAdmin
    function unlock(uint256 tokenId, address user) external; // onlyAdmin
    function refreshLock(uint256 tokenId, uint256 amount) external; // onlyAdmin
    
}