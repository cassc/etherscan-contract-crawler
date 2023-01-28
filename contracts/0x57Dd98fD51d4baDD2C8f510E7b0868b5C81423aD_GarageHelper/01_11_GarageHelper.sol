// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./interfaces/IDust.sol";
import "./interfaces/ISweepersTokenV1.sol";
import "./interfaces/IGarage.sol";

contract GarageHelper is Ownable, ReentrancyGuard {

    IDust private DustInterface;
    ISweepersTokenV1 private SweepersInterface;
    IGarage private oldGarage;
    uint256 public dailyDust;
    uint80 private rewardEnd;

    mapping(uint8 => uint16) public multiplier;

     // @param minStakeTime is block timestamp in seconds
    constructor(address _dust, address _sweepers, address _oldGarage) {
        dailyDust = 10*10**18;
        DustInterface = IDust(_dust);
        SweepersInterface = ISweepersTokenV1(_sweepers);
        oldGarage = IGarage(_oldGarage);

        multiplier[0] = 15000;
        multiplier[1] = 10000;
        multiplier[2] = 10000;
        multiplier[3] = 35000;
        multiplier[4] = 20000;
        multiplier[5] = 10000;
        multiplier[6] = 10000;
        multiplier[7] = 10000;
        multiplier[8] = 10000;
        multiplier[9] = 10000;
        multiplier[10] = 10000;
        multiplier[11] = 25000;
        multiplier[12] = 10000;
        multiplier[13] = 10000;
        multiplier[14] = 20000;
        multiplier[15] = 10000;
        multiplier[16] = 20000;
        multiplier[17] = 10000;
        multiplier[21] = 15000;
        multiplier[22] = 20000;
        multiplier[23] = 20000;
        multiplier[24] = 20000;
        multiplier[25] = 20000;
    }

    event SweepersStaked(address indexed staker, uint16[] stakedIDs);
    event SweepersUnstaked(address indexed unstaker, uint16[] stakedIDs);
    event DustClaimed(address indexed claimer, uint256 amount);
    event RewardEndSet(uint80 rewardEnd, uint256 timestamp);

    function setDailyDust(uint256 _dailyDust) external onlyOwner {
        dailyDust = _dailyDust;
    }

    function setDustContract(address _dust) external onlyOwner {
        DustInterface = IDust(_dust);
    }

    function setSweepersContract(address _sweepers) external onlyOwner {
        SweepersInterface = ISweepersTokenV1(_sweepers);
    }

    function setSingleMultiplier(uint8 _index, uint16 _mult) external onlyOwner {
        multiplier[_index] = _mult;
    }

    function setRewardEnd(uint80 _endTime) external onlyOwner {
        rewardEnd = _endTime;
        emit RewardEndSet(_endTime, block.timestamp);
    }

    function getUnclaimedDust(uint16[] calldata _ids) external view returns (uint256 owed, uint256[] memory dustPerNFTList) {
        uint16 length = uint16(_ids.length);
        uint256 tokenDustValue; // amount owed for each individual token in the calldata array
        dustPerNFTList = new uint256[](length); 
        uint80 _lastClaimTimestamp; 
        uint8 _bg;
        for (uint16 i = 0; i < length; i++) {
            if(SweepersInterface.isStakedAndLocked(_ids[i])) {
                (,, _lastClaimTimestamp) = oldGarage.StakedNFTInfo(_ids[i]);
                _bg = oldGarage.NFTMultiplier(_ids[i]);

                if(rewardEnd > 0 && block.timestamp > rewardEnd) {
                    tokenDustValue = ((((rewardEnd - _lastClaimTimestamp) * dailyDust) / 86400) * multiplier[_bg]) / 10000;
                } else {
                    tokenDustValue = ((((block.timestamp - _lastClaimTimestamp) * dailyDust) / 86400) * multiplier[_bg]) / 10000;
                }
            }

            owed += tokenDustValue;

            dustPerNFTList[i] = tokenDustValue;
        }
        return (owed, dustPerNFTList);
    }

    function isNFTStaked(uint16 _id) public view returns (bool) {
        if(SweepersInterface.isStakedAndLocked(_id)) {
            return true;
        } else {
            return false;
        }
    }

    function isNFTStakedBatch(uint16[] calldata _ids) external view returns (bool[] memory isStaked) {
        uint length = _ids.length;
        isStaked = new bool[](length);
        for(uint i = 0; i < length; i++) {
            isStaked[i] = isNFTStaked(_ids[i]);
        }
    }

    function unstake(uint16[] calldata _ids) external nonReentrant {
        uint16 length = uint16(_ids.length);
        uint80 _lastClaimTimestamp; 
        uint8 _bg;
        uint256 owed;
        for (uint16 i = 0; i < length; i++) {
            require(SweepersInterface.isStakedAndLocked(_ids[i]), 
            "NFT is not staked");
            require(msg.sender == SweepersInterface.ownerOf(_ids[i]), "Not owner of Sweeper");

            (,, _lastClaimTimestamp) = oldGarage.StakedNFTInfo(_ids[i]);
            _bg = oldGarage.NFTMultiplier(_ids[i]);

            if(rewardEnd > 0 && block.timestamp > rewardEnd) {
                owed += ((((rewardEnd - _lastClaimTimestamp) * dailyDust) / 86400) * multiplier[_bg]) / 10000;
            } else {
                owed += ((((block.timestamp - _lastClaimTimestamp) * dailyDust) / 86400) * multiplier[_bg]) / 10000;
            }

            SweepersInterface.unstakeAndUnlock(_ids[i]);
        }
        DustInterface.mint(msg.sender, owed);
        emit DustClaimed(msg.sender, owed);
        emit SweepersUnstaked(msg.sender, _ids);
    }

    // function migrateGarage(uint256 start, uint256 end) external onlyOwner {
    //     uint80 _stakedTimestamp;
    //     uint80 _lastClaimTimestamp; 
    //     uint16 _staked = sweepersInGarage;
    //     for(uint i = start; i <= end;) {
    //         if(oldGarage.StakedAndLocked(uint16(i)) && StakedNFTInfo[uint16(i)].stakedTimestamp == 0) {
    //             (, _stakedTimestamp, _lastClaimTimestamp) = oldGarage.StakedNFTInfo(uint16(i));
    //             StakedNFTInfo[uint16(i)].stakedTimestamp = _stakedTimestamp;
    //             StakedNFTInfo[uint16(i)].lastClaimTimestamp = _lastClaimTimestamp;
    //             StakedNFTInfo[uint16(i)].NFTMultiplier = oldGarage.NFTMultiplier(uint16(i));
    //             _staked++;
    //             unchecked{i++;}
    //         } else {
    //             unchecked{i++;}
    //             continue;
    //         }
    //     }
    //     sweepersInGarage = _staked;
    // }
}