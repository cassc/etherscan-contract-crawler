/*
  ･
   *　★
      ･ ｡
        　･　ﾟ☆ ｡
  　　　 *　★ ﾟ･｡ *  ｡
          　　* ☆ ｡･ﾟ*.｡
      　　　ﾟ *.｡☆｡★　･
​
                      `                     .-:::::-.`              `-::---...```
                     `-:`               .:+ssssoooo++//:.`       .-/+shhhhhhhhhhhhhyyyssooo:
                    .--::.            .+ossso+/////++/:://-`   .////+shhhhhhhhhhhhhhhhhhhhhy
                  `-----::.         `/+////+++///+++/:--:/+/-  -////+shhhhhhhhhhhhhhhhhhhhhy
                 `------:::-`      `//-.``.-/+ooosso+:-.-/oso- -////+shhhhhhhhhhhhhhhhhhhhhy
                .--------:::-`     :+:.`  .-/osyyyyyyso++syhyo.-////+shhhhhhhhhhhhhhhhhhhhhy
              `-----------:::-.    +o+:-.-:/oyhhhhhhdhhhhhdddy:-////+shhhhhhhhhhhhhhhhhhhhhy
             .------------::::--  `oys+/::/+shhhhhhhdddddddddy/-////+shhhhhhhhhhhhhhhhhhhhhy
            .--------------:::::-` +ys+////+yhhhhhhhddddddddhy:-////+yhhhhhhhhhhhhhhhhhhhhhy
          `----------------::::::-`.ss+/:::+oyhhhhhhhhhhhhhhho`-////+shhhhhhhhhhhhhhhhhhhhhy
         .------------------:::::::.-so//::/+osyyyhhhhhhhhhys` -////+shhhhhhhhhhhhhhhhhhhhhy
       `.-------------------::/:::::..+o+////+oosssyyyyyyys+`  .////+shhhhhhhhhhhhhhhhhhhhhy
       .--------------------::/:::.`   -+o++++++oooosssss/.     `-//+shhhhhhhhhhhhhhhhhhhhyo
     .-------   ``````.......--`        `-/+ooooosso+/-`          `./++++///:::--...``hhhhyo
                                              `````
   *　
      ･ ｡
　　　　･　　ﾟ☆ ｡
  　　　 *　★ ﾟ･｡ *  ｡
          　　* ☆ ｡･ﾟ*.｡
      　　　ﾟ *.｡☆｡★　･
    *　　ﾟ｡·*･｡ ﾟ*
  　　　☆ﾟ･｡°*. ﾟ
　 ･ ﾟ*｡･ﾟ★｡
　　･ *ﾟ｡　　 *
　･ﾟ*｡★･
 ☆∴｡　*
･ ｡
*/

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.12;

import "./mixins/shared/TxDeadline.sol";

import "./mixins/nftMarketRouter/NFTMarketRouterCore.sol";
import "./mixins/nftMarketRouter/NFTMarketRouterList.sol";
import "./mixins/nftMarketRouter/NFTCreateAndListTimedEditionCollection.sol";

import "./mixins/nftMarketRouter/apis/NFTMarketRouterAPIs.sol";
import "./mixins/nftMarketRouter/apis/NFTDropMarketRouterAPIs.sol";
import "./mixins/nftMarketRouter/apis/NFTCollectionFactoryRouterAPIs.sol";

/**
 * @title A contract which offers value-added APIs and routes requests to the NFTMarket's existing API.
 * @dev Features in this contract can be created with a clear separation of concerns from the NFTMarket contract.
 * It also provides the contract size space required for targeted APIs and to experiment with new features.
 * @author batu-inal & HardlyDifficult & reggieag
 */
contract NFTMarketRouter is
  TxDeadline,
  NFTMarketRouterCore,
  NFTMarketRouterAPIs,
  NFTCollectionFactoryRouterAPIs,
  NFTDropMarketRouterAPIs,
  NFTMarketRouterList,
  NFTCreateAndListTimedEditionCollection
{
  /**
   * @notice Initialize the template's immutable variables.
   * @param _nftMarket The address of the NFTMarket contract to which requests will be routed.
   * @param _nftDropMarket The address of the NFTDropMarket contract to which requests will be routed.
   * @param _nftCollectionFactory The address of the NFTCollectionFactory contract to which requests will be routed.
   */
  constructor(
    address _nftMarket,
    address _nftDropMarket,
    address _nftCollectionFactory
  ) NFTMarketRouterCore(_nftMarket, _nftDropMarket, _nftCollectionFactory) {}
}