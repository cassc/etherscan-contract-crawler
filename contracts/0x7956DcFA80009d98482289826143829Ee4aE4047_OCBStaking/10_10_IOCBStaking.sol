// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

interface IOCBStaking {

    struct Position {
        address owner;
        uint40 startTime;
    }

    struct ReadablePosition {
        uint256 tokenId;
        address owner;
        uint40 startTime;
        uint40 tokenStakingTime;
        bool isTokenStaked;
    }

    error SenderIsNotTokenOwner( uint256 tokenId );
    error TokenAlreadyStaked( uint256 tokenId );
    error TokenIsNotStaked( uint256 tokenId );
    error TokenHasToBeStaked( uint256 tokenId );

    event MetadataUpdate(uint256 tokenId); // eip-4906
    event TokenStaked( uint256 tokenId, address owner );
    event TokenUnstaked( uint256 tokenId, address owner );
    event ocbContractChanged( address newContract );

}