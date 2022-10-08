// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


interface HelloEthereum {
  function go() external;
}

contract HelloEthereumSouvenier is ERC721, ERC721Enumerable, Ownable {

    event Claimed(uint indexed ID, address indexed owner);

    uint public constant MAX_SUPPLY = 1000;
    uint public ID = 0;

    HelloEthereum public he = HelloEthereum(0xa3483b08C8A0F33eB07afF3A66fbcaf5C9018CDC);

    constructor() ERC721("HelloEthereumSouvenier", "HES") {}

    function claim() external {
        require(ID < MAX_SUPPLY, "Max supply exceeded.");

        he.go();
        _mint(msg.sender, ID);

        emit Claimed(ID, msg.sender);

        ID += 1;
    }

    function _baseURI() internal pure override returns (string memory) {
        return "https://hello.ethyearone.com/";
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}