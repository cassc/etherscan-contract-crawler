// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract DigiMonkzStaking {
    IERC721 public genesis111;
    IERC721 public genesis2;

    struct NftInfo {
        uint16 tokenId;
        uint256 stakedAt;
        uint256 lastClaimedAt;
        uint256 artifact;
    }
    mapping(uint16 => uint256) public artifactPerGen1Nft;
    mapping(uint16 => uint256) public artifactPerGen2Nft;
    mapping(address => uint256) public artifactPerStaker;
    mapping(address => NftInfo[]) public gen1InfoPerStaker;
    mapping(address => NftInfo[]) public gen2InfoPerStaker;
    mapping(address => uint16[]) public gen1StakedArray;
    mapping(address => uint16[]) public gen2StakedArray;

    // event Stake(uint256 indexed tokenId);
    // event Unstake(
    //     uint256 indexed tokenId,
    //     uint256 stakedAtTimestamp,
    //     uint256 removedFromStakeAtTimestamp
    // );

    constructor(address _gen1Addr, address _gen2Addr) {
        genesis111 = IERC721(_gen1Addr);
        genesis2 = IERC721(_gen2Addr);
    }

    function gen1IndividualStake(uint16 _tokenId) private {
        require(genesis111.ownerOf(_tokenId) == msg.sender);

        uint256 len = gen1InfoPerStaker[msg.sender].length;
        bool flag;
        for (uint256 i = 0; i < len; i++) {
            if (gen1InfoPerStaker[msg.sender][i].tokenId == _tokenId) {
                flag = true;
            }
        }
        require(flag == false);

        genesis111.transferFrom(msg.sender, address(this), _tokenId);

        uint256 artifact = artifactPerGen1Nft[_tokenId];
        NftInfo memory stakingNft = NftInfo(
            _tokenId,
            block.timestamp,
            0,
            artifact
        );
        gen1InfoPerStaker[msg.sender].push(stakingNft);
        gen1StakedArray[msg.sender].push(_tokenId);

        // emit Stake(_tokenId);
    }

    function gen1Stake(uint16[] memory _tokenIds) external returns (bool) {
        uint256 tokenLen = _tokenIds.length;
        for (uint256 i = 0; i < tokenLen; i++) {
            gen1IndividualStake(_tokenIds[i]);
        }
        return true;
    }

    function gen2IndividualStake(uint16 _tokenId) private {
        require(genesis2.ownerOf(_tokenId) == msg.sender);

        uint256 len = gen2InfoPerStaker[msg.sender].length;
        bool flag;
        for (uint256 i = 0; i < len; i++) {
            if (gen2InfoPerStaker[msg.sender][i].tokenId == _tokenId) {
                flag = true;
            }
        }
        require(flag == false);

        genesis2.transferFrom(msg.sender, address(this), _tokenId);

        uint256 artifact = artifactPerGen2Nft[_tokenId];
        NftInfo memory stakingNft = NftInfo(
            _tokenId,
            block.timestamp,
            0,
            artifact
        );
        gen2InfoPerStaker[msg.sender].push(stakingNft);
        gen2StakedArray[msg.sender].push(_tokenId);

        // emit Stake(_tokenId);
    }

    function gen2Stake(uint16[] memory _tokenIds) external returns (bool) {
        uint256 tokenLen = _tokenIds.length;
        for (uint256 i = 0; i < tokenLen; i++) {
            gen2IndividualStake(_tokenIds[i]);
        }
        return true;
    }

    function gen1IndividualUnstake(uint16 _tokenId) private {
        require(genesis111.ownerOf(_tokenId) == address(this));

        uint256 len = gen1InfoPerStaker[msg.sender].length;
        require(len != 0);

        uint256 idx = len;
        for (uint256 i = 0; i < len; i++) {
            if (gen1InfoPerStaker[msg.sender][i].tokenId == _tokenId) {
                idx = i;
            }
        }
        require(idx != len);

        genesis111.transferFrom(address(this), msg.sender, _tokenId);

        // uint256 stakedTime = gen1InfoPerStaker[msg.sender][idx].stakedAt;
        if (idx != len - 1) {
            gen1InfoPerStaker[msg.sender][idx] = gen1InfoPerStaker[msg.sender][
                len - 1
            ];
            gen1StakedArray[msg.sender][idx] = gen1StakedArray[msg.sender][
                len - 1
            ];
        }
        gen1InfoPerStaker[msg.sender].pop();
        gen1StakedArray[msg.sender].pop();

        // emit Unstake(_tokenId, stakedTime, block.timestamp);
    }

    function gen1Unstake(uint16[] memory _tokenIds) external returns (bool) {
        uint256 tokenLen = _tokenIds.length;
        for (uint256 i = 0; i < tokenLen; i++) {
            gen1IndividualUnstake(_tokenIds[i]);
        }
        return true;
    }

    function gen2IndividualUnstake(uint16 _tokenId) private {
        require(genesis2.ownerOf(_tokenId) == address(this));

        uint256 len = gen2InfoPerStaker[msg.sender].length;
        require(len != 0);

        uint256 idx = len;
        for (uint256 i = 0; i < len; i++) {
            if (gen2InfoPerStaker[msg.sender][i].tokenId == _tokenId) {
                idx = i;
            }
        }
        require(idx != len);
        genesis2.transferFrom(address(this), msg.sender, _tokenId);

        // uint256 stakedTime = gen2InfoPerStaker[msg.sender][idx].stakedAt;
        if (idx != len - 1) {
            gen2InfoPerStaker[msg.sender][idx] = gen2InfoPerStaker[msg.sender][
                len - 1
            ];
            gen2StakedArray[msg.sender][idx] = gen2StakedArray[msg.sender][
                len - 1
            ];
        }
        gen2InfoPerStaker[msg.sender].pop();
        gen2StakedArray[msg.sender].pop();

        // emit Unstake(_tokenId, stakedTime, block.timestamp);
    }

    function gen2Unstake(uint16[] memory _tokenIds) external returns (bool) {
        uint256 tokenLen = _tokenIds.length;
        for (uint256 i = 0; i < tokenLen; i++) {
            gen2IndividualUnstake(_tokenIds[i]);
        }
        return true;
    }

    function getArtifactForGen1(uint16 _tokenId) public returns (uint256) {
        require(genesis111.ownerOf(_tokenId) == address(this));

        uint256 stakedTime;
        uint256 lastClaimedTime;
        uint256 idx;
        uint256 len = gen1InfoPerStaker[msg.sender].length;
        for (uint256 i = 0; i < len; i++) {
            if (gen1InfoPerStaker[msg.sender][i].tokenId == _tokenId) {
                stakedTime = gen1InfoPerStaker[msg.sender][i].stakedAt;
                lastClaimedTime = gen1InfoPerStaker[msg.sender][i]
                    .lastClaimedAt;
                idx = i;
                break;
            }
        }
        require(stakedTime != 0);

        uint256 artifact;
        uint256 period;
        uint256 currentTime = block.timestamp;

        if (_tokenId >= 0 && _tokenId <= 10) {
            period = 12 days;
        } else if (_tokenId >= 11 && _tokenId <= 111) {
            period = 15 days;
        }

        if (lastClaimedTime >= stakedTime) {
            artifact =
                (currentTime - stakedTime) /
                period -
                (lastClaimedTime - stakedTime) /
                period;
        } else {
            artifact = (currentTime - stakedTime) / period;
        }
        require(artifact > 0);

        artifactPerGen1Nft[_tokenId] += artifact;
        gen1InfoPerStaker[msg.sender][idx].lastClaimedAt = currentTime;
        gen1InfoPerStaker[msg.sender][idx].artifact += artifact;
        artifactPerStaker[msg.sender] += artifact;

        return artifact;
    }

    function getArtifactForGen2(uint16 _tokenId) public returns (uint256) {
        require(genesis2.ownerOf(_tokenId) == address(this));

        uint256 stakedTime;
        uint256 lastClaimedTime;
        uint256 idx;
        uint256 len = gen2InfoPerStaker[msg.sender].length;
        for (uint256 i = 0; i < len; i++) {
            if (gen2InfoPerStaker[msg.sender][i].tokenId == _tokenId) {
                stakedTime = gen2InfoPerStaker[msg.sender][i].stakedAt;
                lastClaimedTime = gen2InfoPerStaker[msg.sender][i]
                    .lastClaimedAt;
                idx = i;
                break;
            }
        }
        require(stakedTime != 0);

        uint256 artifact;
        uint256 period;
        uint256 currentTime = block.timestamp;

        if (_tokenId >= 1 && _tokenId <= 11) {
            period = 20 days;
        } else {
            period = 30 days;
        }

        if (lastClaimedTime >= stakedTime) {
            artifact =
                (currentTime - stakedTime) /
                period -
                (lastClaimedTime - stakedTime) /
                period;
        } else {
            artifact = (currentTime - stakedTime) / period;
        }
        require(artifact > 0);

        artifactPerGen2Nft[_tokenId] += artifact;
        gen2InfoPerStaker[msg.sender][idx].lastClaimedAt = currentTime;
        gen2InfoPerStaker[msg.sender][idx].artifact += artifact;
        artifactPerStaker[msg.sender] += artifact;

        return artifact;
    }

    function claimRewardWithGen1(
        uint256 _numArtifact,
        uint16[] memory _idxArray
    ) external returns (bool) {
        require(artifactPerStaker[msg.sender] >= _numArtifact);

        uint256 sum;
        uint256 len = _idxArray.length;
        uint16 tokenId;
        for (uint256 i = 0; i < len; i++) {
            tokenId = gen1InfoPerStaker[msg.sender][_idxArray[i]].tokenId;
            require(genesis111.ownerOf(tokenId) == address(this));
            sum += artifactPerGen1Nft[tokenId];
            artifactPerGen1Nft[tokenId] = 0;
            gen1InfoPerStaker[msg.sender][_idxArray[i]].artifact = 0;
        }
        require(sum >= _numArtifact);

        artifactPerStaker[msg.sender] -= sum;

        return true;
    }

    function claimRewardWithGen2(
        uint256 _numArtifact,
        uint16[] memory _idxArray
    ) external returns (bool) {
        require(artifactPerStaker[msg.sender] >= _numArtifact);

        uint256 sum;
        uint256 len = _idxArray.length;
        uint16 tokenId;
        for (uint256 i = 0; i < len; i++) {
            tokenId = gen2InfoPerStaker[msg.sender][_idxArray[i]].tokenId;
            require(genesis2.ownerOf(tokenId) == address(this));
            sum += artifactPerGen2Nft[tokenId];
            artifactPerGen2Nft[tokenId] = 0;
            gen2InfoPerStaker[msg.sender][_idxArray[i]].artifact = 0;
        }
        require(sum >= _numArtifact);

        artifactPerStaker[msg.sender] -= sum;

        return true;
    }

    function getGen1StakedArray(
        address _wallet
    ) external view returns (NftInfo[] memory) {
        NftInfo[] memory nftInfo;
        nftInfo = gen1InfoPerStaker[_wallet];
        return nftInfo;
    }

    function getGen2StakedArray(
        address _wallet
    ) external view returns (NftInfo[] memory) {
        NftInfo[] memory nftInfo;
        nftInfo = gen2InfoPerStaker[_wallet];
        return nftInfo;
    }

    function getGen1StakedTokens(
        address _wallet
    ) external view returns (uint16[] memory) {
        return gen1StakedArray[_wallet];
    }

    function getGen2StakedTokens(
        address _wallet
    ) external view returns (uint16[] memory) {
        return gen2StakedArray[_wallet];
    }
}