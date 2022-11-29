//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './TicketSet.sol';


library TicketIndex {
  using TicketSet for uint64[];

  function findWinningTickets(uint64[][90] storage ticketsByNumber, uint8[6] storage numbers)
      public view returns (uint64[][5] memory winners)
  {
    winners = [
      new uint64[](0),  // tickets matching exactly 2 numbers
      new uint64[](0),  // tickets matching exactly 3 numbers
      new uint64[](0),  // tickets matching exactly 4 numbers
      new uint64[](0),  // tickets matching exactly 5 numbers
      new uint64[](0)   // tickets matching exactly 6 numbers
    ];
    uint8[6] memory i = [0, 0, 0, 0, 0, 0];
    for (i[0] = 0; i[0] < numbers.length; i[0]++) {
      uint64[] memory tickets0 = ticketsByNumber[numbers[i[0]] - 1];
      if (tickets0.length > 0) {
        for (i[1] = i[0] + 1; i[1] < numbers.length; i[1]++) {
          uint64[] memory tickets1 = tickets0.intersect(
              ticketsByNumber[numbers[i[1]] - 1]);
          if (tickets1.length > 0) {
            tickets0 = tickets0.subtract(tickets1);
            for (i[2] = i[1] + 1; i[2] < numbers.length; i[2]++) {
              uint64[] memory tickets2 = tickets1.intersect(
                  ticketsByNumber[numbers[i[2]] - 1]);
              if (tickets2.length > 0) {
                tickets1 = tickets1.subtract(tickets2);
                for (i[3] = i[2] + 1; i[3] < numbers.length; i[3]++) {
                  uint64[] memory tickets3 = tickets2.intersect(
                      ticketsByNumber[numbers[i[3]] - 1]);
                  if (tickets3.length > 0) {
                    tickets2 = tickets2.subtract(tickets3);
                    for (i[4] = i[3] + 1; i[4] < numbers.length; i[4]++) {
                      uint64[] memory tickets4 = tickets3.intersect(
                          ticketsByNumber[numbers[i[4]] - 1]);
                      if (tickets4.length > 0) {
                        tickets3 = tickets3.subtract(tickets4);
                        for (i[5] = i[4] + 1; i[5] < numbers.length; i[5]++) {
                          uint64[] memory tickets5 = tickets4.intersect(
                              ticketsByNumber[numbers[i[5]] - 1]);
                          if (tickets5.length > 0) {
                            tickets4 = tickets4.subtract(tickets5);
                            winners[4] = winners[4].union(tickets5);
                          }
                          delete tickets5;
                        }
                        winners[3] = winners[3].union(tickets4);
                      }
                      delete tickets4;
                    }
                    winners[2] = winners[2].union(tickets3);
                  }
                  delete tickets3;
                }
                winners[1] = winners[1].union(tickets2);
              }
              delete tickets2;
            }
            winners[0] = winners[0].union(tickets1);
          }
          delete tickets1;
        }
      }
      delete tickets0;
    }
    delete i;
    for (uint j = 0; j < winners.length - 1; j++) {
      for (uint k = j + 1; k < winners.length; k++) {
        winners[j] = winners[j].subtract(winners[k]);
      }
    }
  }
}