// SPDX-License-Identifier: MIT

pragma solidity 0.8.12;

import "../../lib/enumerable/ERC721.sol";

import "../../opensea/ContextMixin.sol";
import "../../opensea/NativeMetaTransaction.sol";

import "@openzeppelin/contracts/access/Ownable.sol";


contract MetroMayor is ERC721, Ownable {

    uint256 constant internal MAX_MAYORS = 1000;

    string public baseTokenURI = "https://s3.us-east-2.amazonaws.com/data.metroverse.com/metadata/mayor/";

    address proxyRegistryAddress;

    constructor() ERC721("Metroverse Mayor", "METROMAYOR") {
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        baseTokenURI = baseURI;
    }

    function setProxyRegistryAddress(address _proxyRegistryAddress) public onlyOwner {
        proxyRegistryAddress = _proxyRegistryAddress;
    }

    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function mintNFT(address[] calldata to, uint256[] calldata itemId, uint256 amount) public onlyOwner {
        for(uint256 i=0; i < amount; i++) {
          _mint(to[i], itemId[i]);
        }
    }

    function isApprovedForAll(address owner, address operator)
        public
        view
        override
        returns (bool)
    {
        // whitelist OpenSea proxy contract for easy trading.
        if (proxyRegistryAddress != address(0x0)) {
          ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
          if (address(proxyRegistry.proxies(owner)) == operator) {
              return true;
          }
        }

        return super.isApprovedForAll(owner, operator);
    }

    function totalSupply()
        public
        view
        virtual
        returns (uint256 supply)
    {
      return MAX_MAYORS;
    }
}