// ====== FOR ALL CRYPTO BUILDERS ======
// 
// コントラクトを読んでくれてありがとうございます！！
// こちらのコントラクトは twitter.com/chillx2land による習作です！
// 会社(newn.co)の方でもガチでNFTの事業やりそうなので自分のNFTを発行することをテーマにコード書いてみました。
// (習作がきっかけですが運営はもちろんガチでやります。)
// 市況についていろんなことを言う人がいますが、It’s best to pay no mind to “Mr. Market”.
// 信じた技術で手を動かしてプロダクトで世の中に価値を提供することに僕は集中します。
// 思想に共感する人はぜひWeb3勉強会(twitter.com/_42Crypto)にDMをください。
// WAGMI!!
// 
// =========== THANK YOU !! ===========

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "hardhat/console.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Mint is ERC721URIStorage, Ownable {

  using Counters for Counters.Counter;
  Counters.Counter private _tokenIds;

  constructor() ERC721 ("Chill's NFT Genesis", "CHLL"){}

  function mint() public payable callerIsUser{

    uint256 newItemId = _tokenIds.current();
    require(_tokenIds.current() <= 5, "reached max supply");
    _safeMint(msg.sender, newItemId);
    refundIfOver(0.05 ether);

    console.log(newItemId);

    if (newItemId == 1){
      _setTokenURI(newItemId, "ipfs://QmexVcFyjZNzvTmY597xfHP22bHUNH86GfX8QHJJAXh75J/Gradient.json");
    } else if (newItemId == 2){
      _setTokenURI(newItemId, "ipfs://QmexVcFyjZNzvTmY597xfHP22bHUNH86GfX8QHJJAXh75J/Marble.json");
    } else if (newItemId == 3){
      _setTokenURI(newItemId, "ipfs://QmexVcFyjZNzvTmY597xfHP22bHUNH86GfX8QHJJAXh75J/Stone.json");
    } else if (newItemId == 4){
      _setTokenURI(newItemId, "ipfs://QmexVcFyjZNzvTmY597xfHP22bHUNH86GfX8QHJJAXh75J/Tile.json");
    } else {
      _setTokenURI(newItemId, "ipfs://QmexVcFyjZNzvTmY597xfHP22bHUNH86GfX8QHJJAXh75J/Wave.json");
    }
    
    console.log("An NFT w/ ID %s has been minted to %s", newItemId, msg.sender);

    _tokenIds.increment();
  }

  modifier callerIsUser() {
    require(tx.origin == msg.sender, "The caller is another contract");
    _;
  }

  function refundIfOver(uint256 price) private {
    require(msg.value >= price, "Need to send more ETH.");
    if (msg.value > price) {
      payable(msg.sender).transfer(msg.value - price);
    }
  }

  function remain() public view returns (uint256) {
    unchecked {
      return 5 - _tokenIds.current();
    }
  }
}