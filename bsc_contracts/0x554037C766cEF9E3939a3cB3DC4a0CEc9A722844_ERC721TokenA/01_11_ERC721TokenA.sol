//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract ERC721TokenA is ERC721, Ownable {
    uint256 public totalSupply = 0;
    string public baseURI = "";

    mapping(address => bool) public _addressMintable;

    constructor() ERC721("APF SUPER RACE", "APFSR") {
        totalSupply = 0;
        _addressMintable[msg.sender] = true;
    }

    function setBaseURI(string calldata _baseURI) public onlyOwner {
        baseURI = _baseURI;
    }

    function setAddressMintable(address _address, bool _mintable)
        public
        onlyOwner
    {
        _addressMintable[_address] = _mintable;
    }

    function mintInc(address _to) public {
        require(_addressMintable[msg.sender], "Address is not mintable");
        require(_to != address(0), "Address is not valid");

        _safeMint(_to, totalSupply + 1);
        totalSupply++;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        _requireMinted(tokenId);

        return
            bytes(baseURI).length > 0
                ? string(
                    abi.encodePacked(
                        baseURI,
                        Strings.toString(tokenId),
                        ".json"
                    )
                )
                : "";
    }
}