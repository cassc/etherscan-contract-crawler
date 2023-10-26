// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract CflatsBox is ERC721 {
    using Strings for uint256;

    uint256 public constant MARKET_CAP = 1_111;
    address public immutable TEAM_WALLET;
    uint256 public mintedSupply;

    constructor(address teamWallet) 
    ERC721("Cflats-WLBox", "CNRS-WLGEN1") {
        TEAM_WALLET = teamWallet;
    }



    function baseURI() 
        public
        pure
        returns (string memory) 
    {
        return "ipfs://QmULsVQHjm94DNAWgHbybfwp9oM57WNDJrLTvzCvbm5X4Z/";
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory) 
    {
        _requireMinted(_tokenId);
        string memory baseUri = baseURI();
        return bytes(baseUri).length > 0 ? string(abi.encodePacked(baseUri, _tokenId.toString(), ".json")) : "";
    }


    function mintAll(address account, uint256 idFrom, uint256 idTo) external
    {
        uint256 toBeMinted = idTo - idFrom;
        require(mintedSupply + toBeMinted <= MARKET_CAP, "CflatsBox: cannot be minted more tokens than market cap!");

        for(uint256 i = idFrom; i < idTo;)
        {
            _mint(account, i);
            unchecked{ 
                ++i;
                ++mintedSupply;
            }
        }
    }
}