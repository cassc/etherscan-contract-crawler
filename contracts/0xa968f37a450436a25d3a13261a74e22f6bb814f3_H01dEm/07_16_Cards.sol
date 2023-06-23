// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;
library Cards {
    function getTrait(uint8[10] memory hand) internal pure returns (string memory) {
        for(uint8 i = 0; i < 10; i+=2) { // implement custom sorting
            for(uint8 j = i+2; j < 10; j+=2) {
                if(hand[i] > hand[j]) {
                    uint8 temp = hand[i];
                    uint8 tempSuit = hand[i+1];
                    hand[i] = hand[j];
                    hand[j] = temp;
                    hand[i+1] = hand[j+1];
                    hand[j+1] = tempSuit;
                }
            }
        }

        uint8 card1 = hand[0];
        uint8 card2 = hand[2];
        uint8 card3 = hand[4];
        uint8 card4 = hand[6];
        uint8 card5 = hand[8];

        uint8 suit1 = hand[1];
        uint8 suit2 = hand[3];
        uint8 suit3 = hand[5];
        uint8 suit4 = hand[7];
        uint8 suit5 = hand[9];

        if ((card1 == card2 && card2 == card3 && card3 == card4) ||
            (card2 == card3 && card3 == card4 && card4 == card5)) {
          return 'Four of a Kind';
        }
        else if (card1 == card2 && card2 == card3) {
          if (card4 == card5) {
            return 'Full House';
          }
          return 'Three of a Kind';
        }
        else if (card3 == card4 && card4 == card5) {
          if (card1 == card2) {
            return 'Full House';
          }
          return 'Three of a Kind';
        }
        else if (card2 == card3 && card3 == card4) {
          return 'Three of a Kind';
        }
        else if ((card1 == card2 && card3 == card4) ||
                 (card1 == card2 && card4 == card5) ||
                 (card2 == card3 && card4 == card5)) {
          return 'Two Pair';
        }
        else if ((card1 == card2) ||
            (card2 == card3) ||
            (card3 == card4) ||
            (card4 == card5)) {
          return 'One Pair';
        }
        else if (card2+1 == card3 && card3+1 == card4 && card4+1 == card5 && card5 == 12 && card1 == 0 &&
                 suit1 == suit2 && suit2 == suit3 && suit3 == suit4 && suit4 == suit5) {
          return 'Royal Flush';
        }
        else if (card1+1 == card2 && card2+1 == card3 && card3+1 == card4 && card4+1 == card5 &&
                 suit1 == suit2 && suit2 == suit3 && suit3 == suit4 && suit4 == suit5) {
          return 'Straight Flush';
        }
        else if ((card1+1 == card2 && card2+1 == card3 && card3+1 == card4 && card4+1 == card5) ||
                 (card2+1 == card3 && card3+1 == card4 && card4+1 == card5 && card5 == 12 && card1 == 0)) {
          return 'Straight';
        }
        else if (suit1 == suit2 && suit2 == suit3 && suit3 == suit4 && suit4 == suit5) {
          return 'Flush';
        }
        return 'High Card';
    }
}