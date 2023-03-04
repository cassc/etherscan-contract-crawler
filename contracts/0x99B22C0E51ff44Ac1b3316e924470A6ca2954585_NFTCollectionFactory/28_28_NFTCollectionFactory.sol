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

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/utils/Context.sol";

import "./mixins/shared/Gap10000.sol";
import "./mixins/shared/RouterContext.sol";

import "./mixins/nftCollectionFactory/NFTCollectionFactoryACL.sol";
import "./mixins/nftCollectionFactory/NFTCollectionFactorySharedTemplates.sol";
import "./mixins/nftCollectionFactory/NFTCollectionFactoryTemplateInitializer.sol";
import "./mixins/nftCollectionFactory/NFTCollectionFactoryTypes.sol";
import "./mixins/nftCollectionFactory/NFTCollectionFactoryV1Gap.sol";
import "./mixins/nftCollectionFactory/templates/NFTCollectionFactoryNFTCollections.sol";
import "./mixins/nftCollectionFactory/templates/NFTCollectionFactoryNFTDropCollections.sol";
import "./mixins/nftCollectionFactory/templates/NFTCollectionFactoryNFTTimedEditionCollections.sol";

/**
 * @title A factory to create NFT collections.
 * @notice Call this factory to create NFT collections.
 * @dev This creates and initializes an ERC-1167 minimal proxy pointing to an NFT collection contract implementation.
 * @author batu-inal & HardlyDifficult & reggieag
 */
contract NFTCollectionFactory is
  Context,
  RouterContext,
  Initializable,
  NFTCollectionFactoryV1Gap,
  Gap10000,
  NFTCollectionFactoryACL,
  NFTCollectionFactoryTypes,
  NFTCollectionFactoryTemplateInitializer,
  NFTCollectionFactorySharedTemplates,
  NFTCollectionFactoryNFTCollections,
  NFTCollectionFactoryNFTDropCollections,
  NFTCollectionFactoryNFTTimedEditionCollections
{
  /**
   * @notice Defines requirements for the collection factory at deployment time.
   * @param _rolesManager The address of the contract defining roles for collections to use.
   * @param router The trusted router contract address.
   * @dev
   */
  constructor(address _rolesManager, address router) NFTCollectionFactoryACL(_rolesManager) RouterContext(router) {
    // Prevent the template from being initialized.
    _disableInitializers();
  }

  /**
   * @inheritdoc RouterContext
   */
  function _msgSender() internal view override(Context, RouterContext) returns (address sender) {
    sender = super._msgSender();
  }
}