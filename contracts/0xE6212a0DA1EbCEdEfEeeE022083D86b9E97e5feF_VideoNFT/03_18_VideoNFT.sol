pragma solidity ^0.5.0;

import "./ERC721Tradable.sol";
import "openzeppelin-solidity/contracts/ownership/Ownable.sol";

/**
 * @title VideoNFT
 * An NFT to represent COS.TV video ownership
 */
contract VideoNFT is ERC721Tradable {
    constructor(address _proxyRegistryAddress)
        public
        ERC721Tradable("COS.TV Video NFT", "VIDEO", _proxyRegistryAddress)
    {}

    function baseTokenURI() public pure returns (string memory) {
        return "https://cos.tv/api/v1/nft/token/";
    }
}