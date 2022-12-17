pragma solidity 0.8.12;

interface IVotingEscrow {
    struct Point {
        int128 bias;
        int128 slope; // # -dweight / dt
        uint256 ts;
        uint256 blk; // block
    }

    function locked__end(uint _tokenId) external view returns (uint);

    function ownerOf(uint _tokenId) external view returns (address);

    function user_point_epoch(uint tokenId) external view returns (uint);

    function user_point_history(
        uint tokenId,
        uint loc
    ) external view returns (Point memory);

    function deposit_for(uint tokenId, uint value) external;

    function token() external view returns (address);

    function supply() external view returns (uint256);
}