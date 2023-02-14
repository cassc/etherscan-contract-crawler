pragma solidity ^0.8.4;

contract Stakable {
    error AlreadyStaked();
    error NotStaked();
    error StakingNotOpen();

    bool public canStake;

    event Stake(uint256 indexed tokenId, address indexed by, uint256 stakedAt);

    event Unstake(
        uint256 indexed tokenId,
        address indexed by,
        uint256 stakedAt,
        uint256 unstakedAt
    );

    mapping(uint256 => uint256) public tokensLastStakedAt; // tokenId => timestamp

    function stake(uint256 tokenId) public virtual {
        if (canStake != true) revert StakingNotOpen();

        if (tokensLastStakedAt[tokenId] != 0) revert AlreadyStaked();

        tokensLastStakedAt[tokenId] = block.timestamp;
        emit Stake(tokenId, msg.sender, tokensLastStakedAt[tokenId]);
    }

    function unstake(uint256 tokenId) public virtual {
        if (tokensLastStakedAt[tokenId] == 0) revert NotStaked();

        uint256 tokenLastStakedAt = tokensLastStakedAt[tokenId];

        tokensLastStakedAt[tokenId] = 0;
        emit Unstake(tokenId, msg.sender, tokenLastStakedAt, block.timestamp);
    }
}