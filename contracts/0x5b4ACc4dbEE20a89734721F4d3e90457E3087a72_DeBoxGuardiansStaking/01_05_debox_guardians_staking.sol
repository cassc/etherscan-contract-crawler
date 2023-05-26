/**
 *Submitted for verification at Etherscan.io on 2022-09-10
*/

// SPDX-License-Identifier: MIT
// Creator: Debox Labs

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract DeBoxGuardiansStaking is Ownable {
  
    struct StakedInfo {
        address owner;
        uint48 timestamp;
    }

    bool public _isActive = false;
    mapping(address => uint256) private _stakedCnt;    // offset 1 for verifing ca
    mapping(address => mapping(uint256 => StakedInfo)) private _staking;

    constructor(address[] memory cas) {
        _isActive = true;
        for (uint256 i = 0; i < cas.length; i++) {
            address addr = cas[i];
            _stakedCnt[addr] = 1;
        }
    }

    function setState(bool state) public onlyOwner {
        _isActive = state;
    }
    function appendAllowedCA(address ca) public onlyOwner {
        if (_stakedCnt[ca] == 0) {
            _stakedCnt[ca] = 1;
        }
    }

    function getStakedCnt(address ca) public view returns (uint256) {
        // offset: 1
        return _stakedCnt[ca] - 1;
    }

    function getStakedInfo(address ca, uint256 tokenId) public view returns (address,uint48) {
        StakedInfo memory si = _staking[ca][tokenId];
        return (si.owner, si.timestamp);
    }

    function stake(address ca, uint256 tokenId) public {
        require(_isActive, "stake state is not active");
        require(_stakedCnt[ca] > 0, "invalid contract address for staking");
        address ownerAddr = IERC721(ca).ownerOf(tokenId);
        require(_msgSender() == ownerAddr, "invalid owner address for staking");
        // staking
        IERC721(ca).transferFrom(_msgSender(), address(this), tokenId);
        _staking[ca][tokenId] = StakedInfo({
            owner: _msgSender(),
            timestamp: uint48(block.timestamp)
            });
        _stakedCnt[ca]++;
    }

    function unstake(address ca, uint256 tokenId) public {
        require(_isActive, "stake state is not active");
        require(_stakedCnt[ca] > 0, "invalid token address for staking");
        require(_staking[ca][tokenId].owner == _msgSender(), "invalid owner address for staking");
        // unstaking
        IERC721(ca).transferFrom(address(this), _msgSender(), tokenId);
        delete _staking[ca][tokenId];
        _stakedCnt[ca]--;
    }
}