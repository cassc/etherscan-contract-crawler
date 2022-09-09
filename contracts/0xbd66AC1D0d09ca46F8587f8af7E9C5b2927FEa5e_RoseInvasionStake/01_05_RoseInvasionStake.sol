// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;


import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

contract RoseInvasionStake is ReentrancyGuard, IERC721Receiver {

    event Staking(address indexed account, uint256 tokenId, uint256 startTime, uint256 stakingDays);
    event Unstaking(address indexed account, uint256 tokenId);

    mapping(uint256 => StakingInfo) public allStakingInfos;

    IERC721 public immutable roseInvasionNFT;

    mapping(address => uint256) public balances; // users staking token balance
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;
    mapping(uint256 => uint256) private _ownedTokensIndex;

    struct StakingInfo {
        address owner;
        uint256 tokenId;
        uint256 startTime;
        uint256 stakingDays;
    }
    struct StakingDayTable {
        uint256 stakingDays;
    }

    StakingDayTable[] stakingDayTable;

    constructor (address roseInvasionNFT_) {
        roseInvasionNFT = IERC721(roseInvasionNFT_);
        stakingDayTable.push(StakingDayTable({stakingDays: 30}));
        stakingDayTable.push(StakingDayTable({stakingDays: 45}));
        stakingDayTable.push(StakingDayTable({stakingDays: 60}));
    }

    function batchStaking(uint256[] memory tokenIds, uint256[] memory stakingDays) external nonReentrant {
        require(tokenIds.length == stakingDays.length);
        for (uint i = 0; i < tokenIds.length; i++) {
            staking(tokenIds[i], stakingDays[i]);
        }
    }

    function batchUnstaking(uint256[] memory tokenIds) external nonReentrant {
        for (uint i = 0; i < tokenIds.length; i++) {
            unstaking(tokenIds[i]);
        }
    }

    function staking(uint256 tokenId, uint256 stakingDay) internal  {
        require(checkStakingDay(stakingDay), "invalid days");
        StakingInfo memory info = allStakingInfos[tokenId];
        require(info.startTime == 0, "already staked");
        require(roseInvasionNFT.ownerOf(tokenId) == msg.sender, "only owner");
        _staking(msg.sender, tokenId, stakingDay);
    }

    function unstaking(uint256 tokenId) internal  {
        StakingInfo memory info = allStakingInfos[tokenId];
        require(info.owner == msg.sender, "only owner");
        require(info.startTime + info.stakingDays * 1 days < block.timestamp, "not time");
        require(roseInvasionNFT.ownerOf(tokenId) == address(this), "already unstaked");
        _unstaking(msg.sender, tokenId);
    }

    function _staking(address account, uint256 tokenId, uint256 stakingDays) internal {
        roseInvasionNFT.safeTransferFrom(account, address(this), tokenId);
        StakingInfo storage info = allStakingInfos[tokenId];
        info.owner = account;
        info.tokenId = tokenId;
        info.stakingDays = stakingDays;
        info.startTime = block.timestamp;
        _addTokenToOwner(account, tokenId);
        emit Staking(account, tokenId, block.timestamp, stakingDays);
    }

    function _unstaking(address account, uint256 tokenId) internal {
        roseInvasionNFT.safeTransferFrom(address(this), account, tokenId);
        _removeTokenFromOwner(account, tokenId);
        emit Unstaking(account, tokenId);
    }

    function checkStakingDay(uint256 stakingDays) public view returns(bool) {
        StakingDayTable[] memory _stakingDayTable = stakingDayTable;
        for(uint i; i < _stakingDayTable.length; i++) {
            if (stakingDays == _stakingDayTable[i].stakingDays) {
                return true;
            }
        }
        return false;
    }

    function tokensOfOwner(address account, uint _from, uint _to) public view returns(StakingInfo[] memory) {
        require(_to < balances[account], "Wrong max array value");
        require((_to - _from) <= balances[account], "Wrong array range");
        StakingInfo[] memory tokens = new StakingInfo[](_to - _from + 1);
        uint index = 0;
        for (uint i = _from; i <= _to; i++) {
            uint id = _ownedTokens[account][i];
            tokens[index] = allStakingInfos[id];
            index++;
        }
        return (tokens);
    }

    function _removeTokenFromOwner(address from, uint256 tokenId) private {
        uint256 lastTokenIndex = balances[from] - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId;
            _ownedTokensIndex[lastTokenId] = tokenIndex;
        }
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
        balances[from]--;
    }

    function _addTokenToOwner(address to, uint256 tokenId) private {
        uint256 length = balances[to];
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
        balances[to]++;
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }
}