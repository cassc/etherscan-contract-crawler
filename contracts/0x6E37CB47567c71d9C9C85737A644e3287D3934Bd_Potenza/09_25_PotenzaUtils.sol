// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;
import "../interfaces/IN.sol";

library PotenzaUtils {

    function getZeroOrFourteenScore(uint256 tokenId, IN n) public view returns(uint256) {
        if(n.getFirst(tokenId) == 0 || n.getFirst(tokenId) == 14 ||
        n.getSecond(tokenId) == 0 || n.getSecond(tokenId) == 14 ||
        n.getThird(tokenId) == 0 || n.getThird(tokenId) == 14 ||
        n.getFourth(tokenId) == 0 || n.getFourth(tokenId) == 14 ||
        n.getFifth(tokenId) == 0 || n.getFifth(tokenId) == 14 ||
        n.getSixth(tokenId) == 0 || n.getSixth(tokenId) == 14 ||
        n.getSeventh(tokenId) == 0 || n.getSeventh(tokenId) == 14 ||
        n.getEight(tokenId) == 0 || n.getEight(tokenId) == 14) {
            return 20;
        }
        return 0;
    }

    function getMaxSequence(uint256 tokenId,IN n) public view returns(uint256) {
        uint256 count = 1;
        uint256 highest = 1;
        uint256[8] memory  sequenceArray = [n.getFirst(tokenId),n.getSecond(tokenId),n.getThird(tokenId),n.getFourth(tokenId),n.getFifth(tokenId),n.getSixth(tokenId),n.getSeventh(tokenId),n.getEight(tokenId)];
        for(uint256 i = 1; i < sequenceArray.length;i++) {
            if(sequenceArray[i-1] == sequenceArray[i]) {
                count += 1;
                if(i == sequenceArray.length-1 && count > highest) {
                    highest = count;
                }
            } else {
                if(count > highest) {
                    highest = count;
                }
                count = 1;
            }
        }
        return highest;
    }

    function getSum(uint256 tokenId,IN n) public view returns(uint256) {
        return n.getFirst(tokenId)+
        n.getSecond(tokenId)+
        n.getThird(tokenId)+
        n.getFourth(tokenId)+
        n.getFifth(tokenId)+
        n.getSixth(tokenId)+
        n.getSeventh(tokenId)+
        n.getEight(tokenId);
    }

    function getHighestFrequency(uint256 tokenId, IN n) public view returns(uint256[3] memory) {
        uint256[15] memory set;
        set[n.getFirst(tokenId)] = set[n.getFirst(tokenId)]+1;
        set[n.getSecond(tokenId)] = set[n.getSecond(tokenId)]+1;
        set[n.getThird(tokenId)] = set[n.getThird(tokenId)]+1;
        set[n.getFourth(tokenId)] = set[n.getFourth(tokenId)]+1;
        set[n.getFifth(tokenId)] = set[n.getFifth(tokenId)]+1;
        set[n.getSixth(tokenId)] = set[n.getSixth(tokenId)]+1;
        set[n.getSeventh(tokenId)] = set[n.getSeventh(tokenId)]+1;
        set[n.getEight(tokenId)] = set[n.getEight(tokenId)]+1;
        uint256[3] memory highest;

        for(uint256 i = 1; i < set.length;i++) {
            if(set[i] > highest[0]) {
                highest[2] = highest[1];
                highest[1] = highest[0];
                highest[0] = set[i];
            } else {
                if(set[i] > highest[1]) {
                    highest[2] = highest[1];
                    highest[1] = set[i];
                } else {
                    if(set[i] > highest[2]) {
                        highest[2] = set[i];
                    }
                }
            }
        }
        return highest;
    }
}