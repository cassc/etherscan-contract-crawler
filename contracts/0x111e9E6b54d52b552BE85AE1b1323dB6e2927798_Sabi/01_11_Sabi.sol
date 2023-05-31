// contracts/Sabi.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

contract Sabi is ERC20Burnable, Ownable {

    using SafeMath for uint256;

    uint256 public MAX_WALLET_STAKED = 100; 
    uint256 public EMISSIONS_RATE = 115740700000000; 
    uint256 public CLAIM_END_TIME = 1672581600; 

    address nullAddress = 0x0000000000000000000000000000000000000000;

    address public wabiAddress;
    mapping(uint256 => uint256) internal idToRarityBoosts;

    //Mapping of wabi to timestamp
    mapping(uint256 => uint256) internal tokenIdToTimeStamp;

    //Mapping of wabi to staker
    mapping(uint256 => address) internal tokenIdToStaker;

    //Mapping of staker to wabi
    mapping(address => uint256[]) internal stakerToTokenIds;

    constructor() ERC20("Sabi", "SABI") {
        idToRarityBoosts[285] = 3; idToRarityBoosts[476] = 3; idToRarityBoosts[556] = 3; idToRarityBoosts[1480] = 3; idToRarityBoosts[1628] = 3; idToRarityBoosts[2594] = 3; idToRarityBoosts[2834] = 3; idToRarityBoosts[2961] = 3; idToRarityBoosts[3108] = 3; idToRarityBoosts[3472] = 3;
        idToRarityBoosts[4630] = 2; idToRarityBoosts[4722] = 2; idToRarityBoosts[2564] = 2; idToRarityBoosts[3474] = 2; idToRarityBoosts[2783] = 2; idToRarityBoosts[4637] = 2; idToRarityBoosts[1730] = 2; idToRarityBoosts[4066] = 2; idToRarityBoosts[218] = 2; idToRarityBoosts[4304] = 2; 
        idToRarityBoosts[1027] = 2; idToRarityBoosts[5587] = 2; idToRarityBoosts[4466] = 2; idToRarityBoosts[2492] = 2; idToRarityBoosts[866] = 2; idToRarityBoosts[842] = 2; idToRarityBoosts[1252] = 2; idToRarityBoosts[4800] = 2; idToRarityBoosts[4425] = 2; idToRarityBoosts[5638] = 2;
        idToRarityBoosts[1358] = 2; idToRarityBoosts[4353] = 2; idToRarityBoosts[4183] = 2; idToRarityBoosts[5465] = 2; idToRarityBoosts[3530] = 2; idToRarityBoosts[3761] = 2; idToRarityBoosts[4454] = 2; idToRarityBoosts[2126] = 2; idToRarityBoosts[2425] = 2; idToRarityBoosts[101] = 2; 
        idToRarityBoosts[2967] = 2; idToRarityBoosts[2736] = 2; idToRarityBoosts[2548] = 2; idToRarityBoosts[2878] = 2; idToRarityBoosts[511] = 2; idToRarityBoosts[4191] = 2; idToRarityBoosts[3001] = 2; idToRarityBoosts[4383] = 2; idToRarityBoosts[4359] = 2; idToRarityBoosts[2569] = 2;
        idToRarityBoosts[4435] = 2; idToRarityBoosts[2083] = 2; idToRarityBoosts[5428] = 2; idToRarityBoosts[1478] = 2; idToRarityBoosts[1735] = 2; idToRarityBoosts[1528] = 2; idToRarityBoosts[3357] = 2; idToRarityBoosts[2953] = 2; idToRarityBoosts[4502] = 2; idToRarityBoosts[1685] = 2; 
        idToRarityBoosts[4424] = 2; idToRarityBoosts[1251] = 2; idToRarityBoosts[2457] = 2; idToRarityBoosts[2732] = 2; idToRarityBoosts[2917] = 2; idToRarityBoosts[519] = 2; idToRarityBoosts[1434] = 2; idToRarityBoosts[3939] = 2; idToRarityBoosts[1657] = 2; idToRarityBoosts[2676] = 2;
        idToRarityBoosts[841] = 2; idToRarityBoosts[643] = 2; idToRarityBoosts[4550] = 2; idToRarityBoosts[846] = 2; idToRarityBoosts[4587] = 2; idToRarityBoosts[1831] = 2; idToRarityBoosts[4763] = 2; idToRarityBoosts[1232] = 2; idToRarityBoosts[1594] = 2; idToRarityBoosts[1070] = 2; 
        idToRarityBoosts[4497] = 2; idToRarityBoosts[2203] = 2; idToRarityBoosts[467] = 2; idToRarityBoosts[4810] = 2; idToRarityBoosts[75] = 2; idToRarityBoosts[3911] = 2; idToRarityBoosts[2391] = 2; idToRarityBoosts[2092] = 2; idToRarityBoosts[4953] = 2; 
        
    }

    function setWabiAddress(address _wabiAddress) public onlyOwner {
        wabiAddress = _wabiAddress;
        return;
    }

    function setRarityBoost(uint256 tokenId, uint256 boost) public onlyOwner {
        idToRarityBoosts[tokenId] = boost;
        return;
    }

    function getTokensStaked(address staker)
        public
        view
        returns (uint256[] memory)
    {
        return stakerToTokenIds[staker];
    }

    function remove(address staker, uint256 index) internal {
        if (index >= stakerToTokenIds[staker].length) return;

        for (uint256 i = index; i < stakerToTokenIds[staker].length - 1; i++) {
            stakerToTokenIds[staker][i] = stakerToTokenIds[staker][i + 1];
        }
        stakerToTokenIds[staker].pop();
    }

    function removeTokenIdFromStaker(address staker, uint256 tokenId) internal {
        for (uint256 i = 0; i < stakerToTokenIds[staker].length; i++) {
            if (stakerToTokenIds[staker][i] == tokenId) {
                //This is the tokenId to remove;
                remove(staker, i);
            }
        }
    }

    function stakeByIds(uint256[] memory tokenIds) public {
        require(
            stakerToTokenIds[msg.sender].length + tokenIds.length <=
                MAX_WALLET_STAKED,
            "Must have less than 100 wabi staked!"
        );

        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(
                IERC721(wabiAddress).ownerOf(tokenIds[i]) == msg.sender &&
                    tokenIdToStaker[tokenIds[i]] == nullAddress,
                "Token must be stakable by you!"
            );

            IERC721(wabiAddress).transferFrom(
                msg.sender,
                address(this),
                tokenIds[i]
            );

            stakerToTokenIds[msg.sender].push(tokenIds[i]);

            tokenIdToTimeStamp[tokenIds[i]] = block.timestamp;
            tokenIdToStaker[tokenIds[i]] = msg.sender;
        }
    }

    function unstakeAll() public {
        require(
            stakerToTokenIds[msg.sender].length > 0,
            "Must have at least one token staked!"
        );
        uint256 totalRewards = 0;

        for (uint256 i = stakerToTokenIds[msg.sender].length; i > 0; i--) {
            uint256 tokenId = stakerToTokenIds[msg.sender][i - 1];

            IERC721(wabiAddress).transferFrom(
                address(this),
                msg.sender,
                tokenId
            );

            if (idToRarityBoosts[tokenId] != 0) {
                totalRewards =
                totalRewards +
                ((block.timestamp - tokenIdToTimeStamp[tokenId]) *
                    EMISSIONS_RATE * idToRarityBoosts[tokenId]);
            } else {
                totalRewards =
                totalRewards +
                ((block.timestamp - tokenIdToTimeStamp[tokenId]) *
                    EMISSIONS_RATE);
            }

            removeTokenIdFromStaker(msg.sender, tokenId);

            tokenIdToStaker[tokenId] = nullAddress;
        }

        _mint(msg.sender, totalRewards);
    }

    function unstakeByIds(uint256[] memory tokenIds) public {
        uint256 totalRewards = 0;

        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(
                tokenIdToStaker[tokenIds[i]] == msg.sender,
                "Message Sender was not original staker!"
            );

            IERC721(wabiAddress).transferFrom(
                address(this),
                msg.sender,
                tokenIds[i]
            );

            if (idToRarityBoosts[tokenIds[i]] != 0) {
                totalRewards =
                totalRewards +
                ((block.timestamp - tokenIdToTimeStamp[tokenIds[i]]) *
                    EMISSIONS_RATE * idToRarityBoosts[tokenIds[i]]);
            } else {
                totalRewards =
                totalRewards +
                ((block.timestamp - tokenIdToTimeStamp[tokenIds[i]]) *
                    EMISSIONS_RATE);
            }

            removeTokenIdFromStaker(msg.sender, tokenIds[i]);

            tokenIdToStaker[tokenIds[i]] = nullAddress;
        }

        _mint(msg.sender, totalRewards);
    }

    function claimByTokenId(uint256 tokenId) public {
        require(
            tokenIdToStaker[tokenId] == msg.sender,
            "Token is not claimable by you!"
        );
        require(block.timestamp < CLAIM_END_TIME, "Claim period is over!");
        if (idToRarityBoosts[tokenId] != 0) {
            _mint(
                msg.sender,
                ((block.timestamp - tokenIdToTimeStamp[tokenId]) * EMISSIONS_RATE * idToRarityBoosts[tokenId]));
                    
        } else {
            _mint(
                msg.sender,
                ((block.timestamp - tokenIdToTimeStamp[tokenId]) * EMISSIONS_RATE));    
        }

        tokenIdToTimeStamp[tokenId] = block.timestamp;
    }

    function claimAll() public {
        require(block.timestamp < CLAIM_END_TIME, "Claim period is over!");
        uint256[] memory tokenIds = stakerToTokenIds[msg.sender];
        uint256 totalRewards = 0;

        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(
                tokenIdToStaker[tokenIds[i]] == msg.sender,
                "Token is not claimable by you!"
            );

            if (idToRarityBoosts[tokenIds[i]] != 0) {
                totalRewards =
                totalRewards +
                ((block.timestamp - tokenIdToTimeStamp[tokenIds[i]]) *
                    EMISSIONS_RATE * idToRarityBoosts[tokenIds[i]]);
            } else {
                totalRewards =
                totalRewards +
                ((block.timestamp - tokenIdToTimeStamp[tokenIds[i]]) *
                    EMISSIONS_RATE);
            }

            tokenIdToTimeStamp[tokenIds[i]] = block.timestamp;
        }

        _mint(msg.sender, totalRewards);
    }

    function getAllRewards(address staker) public view returns (uint256) {
        uint256[] memory tokenIds = stakerToTokenIds[staker];
        uint256 totalRewards = 0;

        for (uint256 i = 0; i < tokenIds.length; i++) {
            if (idToRarityBoosts[tokenIds[i]] != 0) {
                totalRewards =
                totalRewards +
                ((block.timestamp - tokenIdToTimeStamp[tokenIds[i]]) *
                    EMISSIONS_RATE * idToRarityBoosts[tokenIds[i]]);
            } else {
                totalRewards =
                totalRewards +
                ((block.timestamp - tokenIdToTimeStamp[tokenIds[i]]) *
                    EMISSIONS_RATE);
            }
        }

        return totalRewards;
    }

    function getRewardsByTokenId(uint256 tokenId)
        public
        view
        returns (uint256)
    {
        require(
            tokenIdToStaker[tokenId] != nullAddress,
            "Token is not staked!"
        );

        uint256 secondsStaked = block.timestamp - tokenIdToTimeStamp[tokenId];

        if (idToRarityBoosts[tokenId] != 0) {
            return secondsStaked * EMISSIONS_RATE * idToRarityBoosts[tokenId];
        }
        return secondsStaked * EMISSIONS_RATE;
    }

    function getStaker(uint256 tokenId) public view returns (address) {
        return tokenIdToStaker[tokenId];
    }

    function getRarityBoost(uint256 tokenId) public view returns (uint256) {
        return idToRarityBoosts[tokenId];
    }
}