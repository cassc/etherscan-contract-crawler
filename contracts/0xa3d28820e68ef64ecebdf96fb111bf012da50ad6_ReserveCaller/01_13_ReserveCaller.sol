// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


interface Reserve {
  function go() external;
}

contract ReserveCaller is ERC721, ERC721Enumerable, Ownable {

    event Claimed(uint indexed ID, address indexed owner);

    uint public constant MAX_SUPPLY = 100;
    uint public ID = 0;

    Reserve public r = Reserve(0x6516298e1C94769432Ef6d5F450579094e8c21fA);

    constructor() ERC721("ReserveCaller", "RC") {}

    function claim() external {
        require(ID < MAX_SUPPLY, "Max supply exceeded.");

        r.go();
        _mint(msg.sender, ID);

        emit Claimed(ID, msg.sender);

        ID += 1;
    }

    function _baseURI() internal pure override returns (string memory) {
        return "https://reserve.ethyearone.com/";
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