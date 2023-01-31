// Runiverse Land Plots
// Website: https://runiverse.world
//
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

abstract contract ERC721Vestable is ERC721 {
    /// @notice master switch for vesting
    uint256 public vestingEnabled = 1;

    /// @notice the tokens from 0 to lastVestedTokenId will vest over time
    uint256 public lastVestingGlobalId = 10924;

    /// @notice the time the vesting started
    uint256 public vestingStart = 1674172801; // Jan 20th, 2023. 23:59 gmt

    /// @notice the time the vesting ends
    uint256 public vestingEnd = 1737331201; // Jan 20th, 2025. 23:59 gmt

    /// Invalid Vesting Global Id, the gived Global ID : "`gived_global_id`" must be greater than 0
    /// @param gived_global_id Global id.
    error InvalidVestingGlobalId(uint256 gived_global_id);

    /// Token Not Vested, The Vesting date is the next one `gived_global_id`
    /// @param current_time Current time on chain.
    /// @param token_vesting_time Vesting time.
    error TokenNotVested(uint256 current_time,uint256 token_vesting_time);


    /**
     * @dev See {ERC721-_beforeTokenTransfer}.
     *
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);
        uint256 globalId = getGlobalId(tokenId);
        if (
            vestingEnabled == 1 &&
            from != address(0) && // minting
            globalId <= lastVestingGlobalId &&
            block.timestamp < vestingEnd
        ) {
            uint256 vestingDuration = vestingEnd - vestingStart;

            if(block.timestamp < (vestingDuration * globalId) / lastVestingGlobalId + vestingStart){
                revert TokenNotVested({
                    current_time: block.timestamp,
                    token_vesting_time: (vestingDuration * globalId) / lastVestingGlobalId + vestingStart
                });
            }
        }
        
    }
    /**
     * @notice returns true if a tokenId has besting property.
     */
    function isVestingToken(uint256 tokenId) external view returns (bool) {
        uint256 globalId = getGlobalId(tokenId);
        return globalId <= lastVestingGlobalId;
    }
    /**
     * @notice returns the time when a tokenId will be vested.
     */
    function vestsAt(uint256 tokenId) public view returns (uint256) {
        uint256 globalId = getGlobalId(tokenId);
        uint256 vestingDuration = vestingEnd - vestingStart;
        return (vestingDuration * globalId) / lastVestingGlobalId + vestingStart;
    }

    /**
     * @notice returns true if a tokenId is already vested.
     */
    function isVested(uint256 tokenId) public view returns (bool) {
        uint256 globalId = getGlobalId(tokenId);
        if (vestingEnabled == 0) return true;
        if (globalId > lastVestingGlobalId) return true;
        if (block.timestamp > vestingEnd) return true;
        return block.timestamp >= vestsAt(tokenId);
    }

    /**
     * @notice set the vesting toggle
     */
    function _setVestingEnabled(uint256 _newVestingEnabled) internal virtual {
        vestingEnabled = _newVestingEnabled;
    }

    /**
     * @notice set the last vesting token Id
     */
    function _setLastVestingGlobalId(uint256 _newTokenId) internal virtual {
        if(_newTokenId <= 0){
            revert InvalidVestingGlobalId({
                gived_global_id: _newTokenId
            });
        }
        lastVestingGlobalId = _newTokenId;
    }

    /**
     * @notice set the new vesting start time
     */
    function _setVestingStart(uint256 _newVestingStart) internal virtual {
        require(
            _newVestingStart < vestingEnd,
            "Start must be less than end"
        );
        vestingStart = _newVestingStart;
    }

    /**
     * @notice set the new vesting start time
     */
    function _setVestingEnd(uint256 _newVestingEnd) internal virtual {
        require(
            _newVestingEnd > vestingStart,
            "End must be greater than start"
        );
        vestingEnd = _newVestingEnd;
    }

    /**
     * @notice extracts global id from token id
     */
    function getGlobalId(uint256 tokenId) public pure returns (uint256) {
        return tokenId>>40;
    }

}