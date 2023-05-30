// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./SBCC.sol";
import "./SBMP.sol";
import "./SK.sol";
import "./SOUL.sol";

contract MansionGame is Ownable, IERC721Receiver {

    SBCC private immutable sbcc;
    SBMP private immutable sbmp;
    SK private immutable sk;
    SOUL private immutable soul;
    
    struct SpookyStake {
        address owner;
        uint80 blockStakedTimestamp;
        uint16 mansionId;
    }

    struct MansionStake {
        address owner;
        uint256 owedAtTimeOfStake;
        uint80 blockStakedTimestamp;
    }

    struct Mansion {
        uint256 payoutPerDay;
        uint256 riskFactor; 
    }

    uint16[13000] rarity;


    mapping(uint256 => MansionStake) public mansionBoyStaked; 
    mapping(uint256 => SpookyStake) public spookyBoyStaked; 
    mapping(uint256 => Mansion) public mansions;
    mapping(address => uint256[]) public spookyOwnerIds;
    mapping(address => uint256[]) public mansionOwnerIds;

    uint256 public totalSpookyStaked = 0;
    uint256 public totalMansionStaked = 0;
    uint256 public owedPerMansionBoy = 0;


    constructor(address _soul) { 
        sbcc = SBCC(0xfd1076d80FfF9dC702ae9fDfEa0073467B9B3fb7);
        sbmp = SBMP(0xDa4128A4Fc209dF510E9e4483acd059D84620419);
        sk = SK(0x39AeFB036DabF9d29D33f357Dcc3dcE06dC2b899);
        soul = SOUL(_soul); 

        uint256 MAX_INT = 2**256 - 1;

        addMansion(1, 1, MAX_INT/5); // Bronze
        addMansion(69, 3, MAX_INT/5*2); // Silver
        addMansion(420, 5, MAX_INT/5*3); // Gold
        addMansion(1000, 15, 0); // Platinum
    }

    function addRarity(uint16[] calldata _values, uint16 _startingIndex) external onlyOwner {
        for( uint16 i = 0; i < _values.length; ++i ){
            rarity[_startingIndex+i] = _values[i];
        }
    }

    function getRarity(uint16 _id) external view returns(uint16){
        return rarity[_id];
    }

    function addMansion(uint256 _id, uint256 _payoutPerDay, uint256 _riskFactor) public onlyOwner {
        mansions[_id] = Mansion({
            riskFactor: _riskFactor, 
            payoutPerDay: _payoutPerDay * 1 ether
        });
    }

    function stakeSpookyBoy(uint16[] calldata _tokenIds, uint16 _mansionId) external {
        require(mansions[_mansionId].payoutPerDay != 0);
        if(_mansionId == 1000){
            require(_tokenIds.length > 5, "To stake in platinum mansion you must add atleast 6 at a time.");
        }
        for (uint i = 0; i < _tokenIds.length; i++) {
            require(sbcc.ownerOf(_tokenIds[i]) == _msgSender(), "You cannot stake this! Nice try.");
            sbcc.transferFrom(_msgSender(), address(this), _tokenIds[i]);

            spookyBoyStaked[_tokenIds[i]] = SpookyStake({
                owner: _msgSender(),
                blockStakedTimestamp: uint80(block.timestamp),
                mansionId: _mansionId
            });
            spookyOwnerIds[_msgSender()].push(_tokenIds[i]);

            totalSpookyStaked += 1;
        }
    }

    function unstakeSpookyBoy(bool unstake) external returns(uint256){
        uint256 owedToYou = 0;
        uint256 stolen = 0;

        for (uint i = 0; i < spookyOwnerIds[_msgSender()].length; i++) {
            uint256 tokenId = spookyOwnerIds[_msgSender()][i];
            SpookyStake memory stake = spookyBoyStaked[tokenId];
            require(stake.owner == _msgSender(), "You don't own this. Nice try.");
            uint256 earnedBySpooky = (block.timestamp - stake.blockStakedTimestamp) * mansions[stake.mansionId].payoutPerDay / 1 days;

            // Platinum Mansion
            if(stake.mansionId == 1000){
                owedToYou += earnedBySpooky;
            }
            // Font Door
            else if(sk.balanceOf(stake.owner, stake.mansionId) > 0){
                owedToYou += earnedBySpooky; 
            }
            // Back Door
            else{
                // Stolen!
                if(_random(tokenId) <= mansions[stake.mansionId].riskFactor){
                    stolen += earnedBySpooky;
                }
                // Got out safely
                else{
                    owedToYou += earnedBySpooky * ((rarity[tokenId] / 13000) + 1);
                }
            }

            if(unstake){
                sbcc.safeTransferFrom(address(this), stake.owner, tokenId, "");
                delete spookyBoyStaked[tokenId];
                totalSpookyStaked -= 1;
            }else{
                spookyBoyStaked[tokenId] = SpookyStake({
                    owner: _msgSender(),
                    blockStakedTimestamp: uint80(block.timestamp),
                    mansionId: stake.mansionId
                });
            }

        }
        if(unstake){
            delete spookyOwnerIds[_msgSender()];
        }
        
        if(owedToYou != 0){
            soul.mint(_msgSender(), owedToYou);
        }

        if(stolen != 0 && totalMansionStaked != 0){
            owedPerMansionBoy += stolen / totalMansionStaked;
        }

        return owedToYou + stolen; // amount you will get if nothing is stolen
    }

    function stakeMansionBoy(uint16[] calldata _tokenIds) external {
        for (uint i = 0; i < _tokenIds.length; i++) {
            require(sbmp.ownerOf(_tokenIds[i]) == _msgSender(), "You cannot stake this! Nice try.");
            sbmp.transferFrom(_msgSender(), address(this), _tokenIds[i]);

            mansionBoyStaked[_tokenIds[i]] = MansionStake({
                owner: _msgSender(),
                owedAtTimeOfStake: owedPerMansionBoy,
                blockStakedTimestamp: uint80(block.timestamp)
            });
            mansionOwnerIds[_msgSender()].push(_tokenIds[i]);

            totalMansionStaked += 1;
        }
    }

    function unstakeMansionBoy(bool unstake) external returns(uint256){
        uint256 owedToYou = 0;
        for (uint i = 0; i < mansionOwnerIds[_msgSender()].length; i++) {
            uint256 tokenId = mansionOwnerIds[_msgSender()][i];
            MansionStake memory stake = mansionBoyStaked[tokenId];
            require(stake.owner == _msgSender(), "You don't own this. Nice try.");
            
            owedToYou += owedPerMansionBoy - stake.owedAtTimeOfStake;

            if(unstake){
                sbmp.safeTransferFrom(address(this), stake.owner, tokenId, "");
                delete mansionBoyStaked[tokenId];
                totalMansionStaked -= 1;
            }else{
                mansionBoyStaked[tokenId] = MansionStake({
                    owner: _msgSender(),
                    owedAtTimeOfStake: owedPerMansionBoy,
                    blockStakedTimestamp: uint80(block.timestamp)
                });
            }
        }
        if(unstake){
            delete mansionOwnerIds[_msgSender()];
        }
        soul.mint(_msgSender(), owedToYou);

        return owedToYou;
    }
    

    function _random(uint256 seed) internal view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(
            tx.origin,
            blockhash(block.number - 1),
            block.difficulty,
            block.timestamp,
            seed
        )));
    }

    
    function onERC721Received(
        address,
        address from,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
      require(from == address(0x0), "Cannot send tokens to Barn directly");
      return IERC721Receiver.onERC721Received.selector;
    }

}