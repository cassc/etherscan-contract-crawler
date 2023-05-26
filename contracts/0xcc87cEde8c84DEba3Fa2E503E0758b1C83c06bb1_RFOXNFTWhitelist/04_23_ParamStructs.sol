// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

library ParamStructs {
  /**
    * @dev Parameters for Standard Feature.
    *
    * @param name NFT name.
    * @param symbol NFT symbol.
    * @param baseURI NFT base uri.
    * @param saleToken Purchase medium. Zero address will be considered as native token.
    * @param price Price per token.
    * @param maxNft Max total supply of NFT.
    * @param maxTokensPerTransaction Max NFT per transaction.
    * @param saleStartTime Starting time of the presale (whitelisted address).
    * @param saleEndTime End time of the public sale.
    * @param ownership The owner of the token.
  */
  struct StandardParams {
    string name;
    string symbol;
    string baseURI;
    IERC20 saleToken;
    uint256 price;
    uint256 maxNft;
    uint256 maxTokensPerTransaction;
    uint256 saleStartTime;
    uint256 saleEndTime;
    address owner;
  }

  /**
    * @dev Parameters for Whitelist / Presale Feature.
    *
    * @param name NFT name.
    * @param symbol NFT symbol.
    * @param baseURI NFT base uri.
    * @param saleToken Purchase medium. Zero address will be considered as native token.
    * @param price Price per token.
    * @param maxNft Max total supply of NFT.
    * @param maxTokensPerTransaction Max NFT per transaction.
    * @param saleStartTime Starting time of the presale (whitelisted address).
    * @param saleEndTime End time of the public sale.
    * @param publicSaleStartTime Starting time of the public sale
    * @param maxMintedPresalePerAddress Maximum mint per whitelisted address during presale.
    * @param pricePresale Price for minting during presale.
    * @param ownership The owner of the token.
  */
  struct WhitelistParams {
    string name;
    string symbol;
    string baseURI;
    IERC20 saleToken;
    uint256 price;
    uint256 maxNft;
    uint256 maxTokensPerTransaction;
    uint256 saleStartTime;
    uint256 saleEndTime;
    uint256 publicSaleStartTime;
    uint256 maxMintedPresalePerAddress;
    uint256 pricePresale;
    address owner;
  }
}