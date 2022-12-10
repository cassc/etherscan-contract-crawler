//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import './ShurikenNFT.sol';
import './ShurikenStakingNFT.sol';
import './ShurikenStakedNFT.sol';
import './PassportNFT.sol';

contract CALStaker is ReentrancyGuard, Ownable {
    struct ProjectInfo {
        string projectName;
        uint256 stakingCount;
        uint256 stakingTotal;
        uint256 maxTotal;
        uint256 maxTotalPerAddress;
        uint256 minTotalPerAddress;
    }

    struct StakingInfo {
        uint256 stakingCount;
        uint256 stakingTotal;
        uint256 unstakingCount;
    }

    event Stake(address indexed from, uint256[] tokenIds, uint256 indexed projectIdIndex);
    event Restake(address indexed from, uint256[] tokenIds, uint256 indexed projectIdIndex);
    event Unstake(address indexed from, uint256[] tokenIds, uint256 indexed projectIdIndex);

    ShurikenNFT public immutable shurikenNFT;
    ShurikenStakingNFT public immutable shurikenStakingNFT;
    ShurikenStakedNFT public immutable shurikenStakedNFT;
    PassportNFT public immutable passportNFT;

    bool public stakingPaused = true;

    ProjectInfo[] public projectInfos;
    mapping(address => mapping(uint256 => StakingInfo)) public stakingInfos;

    constructor(
        ShurikenNFT _shurikenNFT,
        ShurikenStakingNFT _shurikenStakingNFT,
        ShurikenStakedNFT _shurikenStakedNFT,
        PassportNFT _passportNFT
    ) {
        shurikenNFT = _shurikenNFT;
        shurikenStakingNFT = _shurikenStakingNFT;
        shurikenStakedNFT = _shurikenStakedNFT;
        passportNFT = _passportNFT;
    }

    function stake(uint256[] calldata tokenIds, uint256 projectIdIndex) external nonReentrant {
        require(!stakingPaused, 'paused');
        require(passportNFT.balanceOf(_msgSender()) == 1, 'passport required');
        require(
            projectInfos[projectIdIndex].stakingTotal + tokenIds.length <= projectInfos[projectIdIndex].maxTotal,
            'max'
        );
        require(
            stakingInfos[_msgSender()][projectIdIndex].stakingTotal + tokenIds.length <=
                projectInfos[projectIdIndex].maxTotalPerAddress,
            'max per address'
        );
        require(
            stakingInfos[_msgSender()][projectIdIndex].stakingTotal + tokenIds.length >
                projectInfos[projectIdIndex].minTotalPerAddress,
            'min per address'
        );
        projectInfos[projectIdIndex].stakingCount += tokenIds.length;
        projectInfos[projectIdIndex].stakingTotal += tokenIds.length;
        stakingInfos[_msgSender()][projectIdIndex].stakingCount += tokenIds.length;
        stakingInfos[_msgSender()][projectIdIndex].stakingTotal += tokenIds.length;
        shurikenNFT.burnerBurn(_msgSender(), tokenIds);
        shurikenStakingNFT.minterMint(_msgSender(), tokenIds.length);
        emit Stake(_msgSender(), tokenIds, projectIdIndex);
    }

    function restake(uint256[] calldata tokenIds, uint256 projectIdIndex) external nonReentrant {
        require(!stakingPaused, 'paused');
        require(tokenIds.length <= stakingInfos[_msgSender()][projectIdIndex].unstakingCount, 'amount error');
        projectInfos[projectIdIndex].stakingCount += tokenIds.length;
        stakingInfos[_msgSender()][projectIdIndex].stakingCount += tokenIds.length;
        stakingInfos[_msgSender()][projectIdIndex].unstakingCount -= tokenIds.length;
        shurikenStakedNFT.burnerBurn(_msgSender(), tokenIds);
        shurikenStakingNFT.minterMint(_msgSender(), tokenIds.length);
        emit Restake(_msgSender(), tokenIds, projectIdIndex);
    }

    function unstake(uint256[] calldata tokenIds, uint256 projectIdIndex) external nonReentrant {
        require(!stakingPaused, 'paused');
        require(tokenIds.length <= stakingInfos[_msgSender()][projectIdIndex].stakingCount, 'amount error');
        projectInfos[projectIdIndex].stakingCount -= tokenIds.length;
        stakingInfos[_msgSender()][projectIdIndex].stakingCount -= tokenIds.length;
        stakingInfos[_msgSender()][projectIdIndex].unstakingCount += tokenIds.length;
        shurikenStakingNFT.burnerBurn(_msgSender(), tokenIds);
        shurikenStakedNFT.minterMint(_msgSender(), tokenIds.length);
        emit Unstake(_msgSender(), tokenIds, projectIdIndex);
    }

    function projectInfosLength() external view returns (uint256) {
        return projectInfos.length;
    }

    function addProjectInfo(ProjectInfo memory info) external onlyOwner {
        projectInfos.push(info);
    }

    function setProjectInfo(uint256 index, ProjectInfo memory info) external onlyOwner {
        projectInfos[index] = info;
    }

    function editProjectInfo(uint256 index, ProjectInfo memory info) external onlyOwner {
        projectInfos[index].projectName = info.projectName;
        projectInfos[index].maxTotal = info.maxTotal;
        projectInfos[index].maxTotalPerAddress = info.maxTotalPerAddress;
        projectInfos[index].minTotalPerAddress = info.minTotalPerAddress;
    }

    function setStakingPaused(bool _stakingPaused) external onlyOwner {
        stakingPaused = _stakingPaused;
    }

    function withdraw(address payable withdrawAddress) external onlyOwner {
        (bool os, ) = withdrawAddress.call{value: address(this).balance}('');
        require(os);
    }
}