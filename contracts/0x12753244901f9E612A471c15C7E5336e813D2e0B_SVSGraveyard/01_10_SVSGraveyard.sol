// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/*
     ▄█▀▀▀█▄█   ▀████▀   ▀███▀    ▄█▀▀▀█▄█
    ▄██    ▀█     ▀██    ▄▄█     ▄██    ▀█
    ▀███▄          ██▄  ▄██      ▀███▄    
     ▀█████▄       ██▄  ▄█        ▀█████▄
    ▄     ▀██       ▀████▀       ▄     ▀██
    ██     ██        ▄██▄        ██     ██
    █▀█████▀          ██         █▀█████▀ 
    
    $BLOOD Token / 2021 / SVS Graveyard
*/

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

contract SVSGraveyard is ERC20Burnable, Ownable {
    uint256 public constant MAX_WALLET_BURIED = 30;
    uint256 public constant SVS_EMISSIONS_RATE = 34722222222222; // 3 per day
    uint256 public constant SBS_EMISSIONS_RATE = 11574074074074; // 1 per day
    address public constant SVS_ADDRESS = 0x219B8aB790dECC32444a6600971c7C3718252539;
    address public constant SBS_ADDRESS = 0xeE0BA89699A3dd0f08CB516C069D81a762f65E56;
    bool public stakingLive = false;

    mapping(uint256 => uint256) internal SVSTokenIdTimeStaked;
    mapping(uint256 => address) internal SVSTokenIdToBurier;
    mapping(address => uint256[]) internal burierToSVSTokenIds;
    
    mapping(uint256 => uint256) internal SBSTokenIdTimeStaked;
    mapping(uint256 => address) internal SBSTokenIdToBurier;
    mapping(address => uint256[]) internal burierToSBSTokenIds;
    
    IERC721Enumerable private constant _svsIERC721Enumerable = IERC721Enumerable(SVS_ADDRESS);
    IERC721Enumerable private constant _sbsIERC721Enumerable = IERC721Enumerable(SBS_ADDRESS);

    constructor() ERC20("Blood", "BLOOD") {
    }

    modifier stakingEnabled {
        require(stakingLive, "STAKING_NOT_LIVE");
        _;
    }

    function getVampsBuried(address burier) public view returns (uint256[] memory) {
        return burierToSVSTokenIds[burier];
    }
    
    function getBatsBuried(address burier) public view returns (uint256[] memory) {
        return burierToSBSTokenIds[burier];
    }
    
    function getBuriedCount(address burier) public view returns (uint256) {
        return burierToSVSTokenIds[burier].length + burierToSBSTokenIds[burier].length;
    }

    function removeTokenIdFromArray(uint256[] storage array, uint256 tokenId) internal {
        uint256 length = array.length;
        for (uint256 i = 0; i < length; i++) {
            if (array[i] == tokenId) {
                length--;
                if (i < length) {
                    array[i] = array[length];
                }
                array.pop();
                break;
            }
        }
    }

    function buryVampsByIds(uint256[] memory tokenIds) public stakingEnabled {
        require(getBuriedCount(msg.sender) + tokenIds.length <= MAX_WALLET_BURIED, "MAX_TOKENS_BURRIED_PER_WALLET");

        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 id = tokenIds[i];
            require(_svsIERC721Enumerable.ownerOf(id) == msg.sender && SVSTokenIdToBurier[id] == address(0), "TOKEN_IS_NOT_YOURS");
            _svsIERC721Enumerable.transferFrom(msg.sender, address(this), id);

            burierToSVSTokenIds[msg.sender].push(id);
            SVSTokenIdTimeStaked[id] = block.timestamp;
            SVSTokenIdToBurier[id] = msg.sender;
        }
    }

    function buryBatsByIds(uint256[] memory tokenIds) public stakingEnabled {
        require(getBuriedCount(msg.sender) + tokenIds.length <= MAX_WALLET_BURIED, "MAX_TOKENS_BURIED_PER_WALLET");

        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 id = tokenIds[i];
            require(_sbsIERC721Enumerable.ownerOf(id) == msg.sender && SBSTokenIdToBurier[id] == address(0), "TOKEN_IS_NOT_YOURS");
            _sbsIERC721Enumerable.transferFrom(msg.sender, address(this), id);

            burierToSBSTokenIds[msg.sender].push(id);
            SBSTokenIdTimeStaked[id] = block.timestamp;
            SBSTokenIdToBurier[id] = msg.sender;
        }
    }

    function unstakeAll() public {
        require(getBuriedCount(msg.sender) > 0, "MUST_ATLEAST_BE_BURIED_ONCE");
        uint256 totalRewards = 0;

        for (uint256 i = burierToSVSTokenIds[msg.sender].length; i > 0; i--) {
            uint256 tokenId = burierToSVSTokenIds[msg.sender][i - 1];

            _svsIERC721Enumerable.transferFrom(address(this), msg.sender, tokenId);
            totalRewards += ((block.timestamp - SVSTokenIdTimeStaked[tokenId]) * SVS_EMISSIONS_RATE);
            burierToSVSTokenIds[msg.sender].pop();
            SVSTokenIdToBurier[tokenId] = address(0);
        }
        
        for (uint256 i = burierToSBSTokenIds[msg.sender].length; i > 0; i--) {
            uint256 tokenId = burierToSBSTokenIds[msg.sender][i - 1];

            _sbsIERC721Enumerable.transferFrom(address(this), msg.sender, tokenId);
            totalRewards += ((block.timestamp - SBSTokenIdTimeStaked[tokenId]) * SBS_EMISSIONS_RATE);
            burierToSBSTokenIds[msg.sender].pop();
            SBSTokenIdToBurier[tokenId] = address(0);
        }

        _mint(msg.sender, totalRewards);
    }

    function unstakeVampsByIds(uint256[] memory tokenIds) public {
        uint256 totalRewards = 0;

        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 id = tokenIds[i];
            require(SVSTokenIdToBurier[id] == msg.sender, "NOT_ORIGINAL_BURIER");

            _svsIERC721Enumerable.transferFrom(address(this), msg.sender, id);
            totalRewards += ((block.timestamp - SVSTokenIdTimeStaked[id]) * SVS_EMISSIONS_RATE);

            removeTokenIdFromArray(burierToSVSTokenIds[msg.sender], id);
            SVSTokenIdToBurier[id] = address(0);
        }

        _mint(msg.sender, totalRewards);
    }
    
    function unstakeBatsByIds(uint256[] memory tokenIds) public {
        uint256 totalRewards = 0;

        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 id = tokenIds[i];
            require(SBSTokenIdToBurier[id] == msg.sender, "NOT_ORIGINAL_BURIER");

            _sbsIERC721Enumerable.transferFrom(address(this), msg.sender, id);
            totalRewards += ((block.timestamp - SBSTokenIdTimeStaked[id]) * SBS_EMISSIONS_RATE);

            removeTokenIdFromArray(burierToSBSTokenIds[msg.sender], id);
            SBSTokenIdToBurier[id] = address(0);
        }

        _mint(msg.sender, totalRewards);
    }

    function claimByVampTokenId(uint256 tokenId) public {
        require(SVSTokenIdToBurier[tokenId] == msg.sender, "NOT_BURIED_BY_YOU");
        _mint(msg.sender, ((block.timestamp - SVSTokenIdTimeStaked[tokenId]) * SVS_EMISSIONS_RATE));
        SVSTokenIdTimeStaked[tokenId] = block.timestamp;
    }
    
    function claimByBatTokenId(uint256 tokenId) public {
        require(SBSTokenIdToBurier[tokenId] == msg.sender, "NOT_BURIED_BY_YOU");
        _mint(msg.sender, ((block.timestamp - SBSTokenIdTimeStaked[tokenId]) * SBS_EMISSIONS_RATE));
        SBSTokenIdTimeStaked[tokenId] = block.timestamp;
    }

    function claimAll() public {
        uint256 totalRewards = 0;

        uint256[] memory vampTokenIds = burierToSVSTokenIds[msg.sender];
        for (uint256 i = 0; i < vampTokenIds.length; i++) {
            uint256 id = vampTokenIds[i];
            require(SVSTokenIdToBurier[id] == msg.sender, "NOT_BURIED_BY_YOU");
            totalRewards += ((block.timestamp - SVSTokenIdTimeStaked[id]) * SVS_EMISSIONS_RATE);
            SVSTokenIdTimeStaked[id] = block.timestamp;
        }
        
        uint256[] memory batTokenIds = burierToSBSTokenIds[msg.sender];
        for (uint256 i = 0; i < batTokenIds.length; i++) {
            uint256 id = batTokenIds[i];
            require(SBSTokenIdToBurier[id] == msg.sender, "NOT_BURIED_BY_YOU");
            totalRewards += ((block.timestamp - SBSTokenIdTimeStaked[id]) * SBS_EMISSIONS_RATE);
            SBSTokenIdTimeStaked[id] = block.timestamp;
        }

        _mint(msg.sender, totalRewards);
    }

    function getAllRewards(address burier) public view returns (uint256) {
        uint256 totalRewards = 0;

        uint256[] memory vampTokenIds = burierToSVSTokenIds[burier];
        for (uint256 i = 0; i < vampTokenIds.length; i++) {
            totalRewards += ((block.timestamp - SVSTokenIdTimeStaked[vampTokenIds[i]]) * SVS_EMISSIONS_RATE);
        }
        
        uint256[] memory batTokenIds = burierToSBSTokenIds[burier];
        for (uint256 i = 0; i < batTokenIds.length; i++) {
            totalRewards += ((block.timestamp - SBSTokenIdTimeStaked[batTokenIds[i]]) * SBS_EMISSIONS_RATE);
        }

        return totalRewards;
    }

    function getRewardsByVampTokenId(uint256 tokenId) public view returns (uint256) {
        require(SVSTokenIdToBurier[tokenId] != address(0), "TOKEN_NOT_BURIED");

        uint256 secondsStaked = block.timestamp - SVSTokenIdTimeStaked[tokenId];
        return secondsStaked * SVS_EMISSIONS_RATE;
    }
    
    function getRewardsByBatTokenId(uint256 tokenId) public view returns (uint256) {
        require(SBSTokenIdToBurier[tokenId] != address(0), "TOKEN_NOT_BURIED");

        uint256 secondsStaked = block.timestamp - SBSTokenIdTimeStaked[tokenId];
        return secondsStaked * SBS_EMISSIONS_RATE;
    }

    function getVampBurier(uint256 tokenId) public view returns (address) {
        return SVSTokenIdToBurier[tokenId];
    }
    
    function getBatBurier(uint256 tokenId) public view returns (address) {
        return SBSTokenIdToBurier[tokenId];
    }

    function toggle() external onlyOwner {
        stakingLive = !stakingLive;
    }
}