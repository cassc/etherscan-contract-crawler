// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

interface IApeStaking {
    
    struct SingleNft {
        uint32 tokenId;
        uint224 amount;
    }

    struct PairNft {
        uint128 mainTokenId;
        uint128 bakcTokenId;
    }

    struct PairNftDepositWithAmount {
        uint32 mainTokenId;
        uint32 bakcTokenId;
        uint184 amount;
    }

    struct PairNftWithdrawWithAmount {
        uint32 mainTokenId;
        uint32 bakcTokenId;
        uint184 amount;
        bool isUncommit;
    }

    function nftPosition(uint256 _poolId, uint256 _nftId) external view returns (uint256, int256);
    function bakcToMain(uint256 _nftId, uint256 _poolId) external view returns (uint248, bool);
    function mainToBakc(uint256 _poolId, uint256 _nftId) external view returns (uint248, bool);

    function depositBAYC(SingleNft[] calldata _nfts) external;
    function depositMAYC(SingleNft[] calldata _nfts) external;
    function depositBAKC(PairNftDepositWithAmount[] calldata _baycPairs, PairNftDepositWithAmount[] calldata _maycPairs) external;
    function withdrawBAYC(SingleNft[] calldata _nfts, address _recipient) external;
    function withdrawMAYC(SingleNft[] calldata _nfts, address _recipient) external;
    function withdrawBAKC(PairNftWithdrawWithAmount[] calldata _baycPairs, PairNftWithdrawWithAmount[] calldata _maycPairs) external;
    function claimBAYC(uint256[] calldata _nfts, address _recipient) external;
    function claimMAYC(uint256[] calldata _nfts, address _recipient) external;
    function claimBAKC(PairNft[] calldata _baycPairs, PairNft[] calldata _maycPairs, address _recipient) external;
}