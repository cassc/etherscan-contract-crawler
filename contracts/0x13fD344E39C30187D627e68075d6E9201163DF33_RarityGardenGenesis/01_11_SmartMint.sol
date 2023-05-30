// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import "./ERC721A.sol";
 
/**
* RarityGarden - a gas-saving mint-on-receive experiment.
*
* A first-of-a-kind smart contract for cheap minting.
* No presale, anyone can mint for free (+ gas).
*
* Max. supply 10k, max. 10 mints per tx.
*
* Important Details (How to mint):
*
* With the combined forces of the mint-on-receive principle and Azuki's EIP721A proposal, 
* minting - especially batch minting - on Mainnet has never been cheaper.
*
* This collection demonstrates additional gas savings of 20-35% on top of the known EIP721A savings.
*
* Here is how it works:
*
* Instead of calling a mint function, simply send _zero_ ETH for minting 1 NFT _or_ a tiny amount between 0.000000000000000002 ETH and 0.0000000000000000015 ETH
* to the collection address, representing the desired minting amounts (=15 max. per tx).
*
* Once the tx completed, the senders will find their NFTs in their wallets.
*
* By leaving out the mint function - and with it function parameters - the minting process will save substantial amounts of gas.
*
* Additionally, this collection derives from EIP721A and provides quasi-constant minting costs.
*
* This collection is fully erc721 compliant.
*
* Once this collection is minted out, Rarity Garden will provide unique art for collectors with interesting traits, rarities and potential use-cases.
*
* If this experiment is successful, Rarity Garden will explore further on how to allow actual 1st market/presale-collections and provide further technical insight.
*
* Mint on: https://rarity.garden/
* Discord: https://discord.gg/Ur8XGaurSd
* Twitter: https://t.me/raritygarden
*/
contract RarityGardenGenesis is ERC721A
{

    using Strings for uint256;

    uint256 public _total_max = 10000;
    address public owner;
    string public _baseTokenUri;

    constructor(
        string memory name,
        string memory symbol,
        string memory baseTokenURI,
        uint256 max_batch,
        uint256 collection_size
    ) ERC721A(name, symbol, max_batch, collection_size) {

        _baseTokenUri = baseTokenURI;
        owner = _msgSender();
        _total_max = collection_size;
    }

    receive() external payable {

        uint256 amount = msg.value == 0 ? 1 : msg.value;

        require(totalSupply() + amount <= _total_max, "receive(): max. supply reached.");

        _safeMint(_msgSender(), amount, "");
    }

    function _baseURI() internal view virtual override returns (string memory) {

        return _baseTokenUri;
    }
    
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
          
        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json")) : "https://rarity.garden/media/rgg/prereveal.json";
    }
    
    function setBaseUri(string calldata baseTokenURI) public virtual {

        require(owner == _msgSender(), "setBaseUri: must be owner to set base uri.");

        _baseTokenUri = baseTokenURI;
    }
}