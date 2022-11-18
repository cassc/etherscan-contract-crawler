//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract ERC721TokenB is ERC721, Ownable {
    uint256 public totalSupply = 0;
    string public baseURI = "";
    uint256 public numHoldMax = 1000;
    mapping(address => bool) public _holdUnlimited;
    mapping(address => bool) public _addressMintable;

    constructor() ERC721("APF SUPERIOR SUPER RACE", "APFSSR") {
        totalSupply = 0;
        _addressMintable[msg.sender] = true;
        _holdUnlimited[address(0x0)] = true;

        setAddressMintable(msg.sender, true);
    }

    function setBaseURI(string calldata _baseURI) public onlyOwner {
        baseURI = _baseURI;
    }

    function setNumHoldMax(uint256 _numHoldMax) public onlyOwner {
        numHoldMax = _numHoldMax;
    }

    function setAddressMintable(address _address, bool _mintable)
        public
        onlyOwner
    {
        _addressMintable[_address] = _mintable;
    }

    function mintId(address _to, uint256 tokenId) public returns (uint256) {
        require(_addressMintable[msg.sender], "Address is not mintable");
        require(_to != address(0), "Address is not valid");
        require(balanceOf(_to) < numHoldMax, "Maximum");

        _safeMint(_to, tokenId);
        totalSupply++;

        return tokenId;
    }

    function burnId(uint256 tokenId) public {
        require(_addressMintable[msg.sender], "Address is not mintable");
        _burn(tokenId);
        totalSupply--;
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

    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override {
        if (!_holdUnlimited[to]) {
            require(balanceOf(to) < numHoldMax, "Maximum");
        }
        return super._transfer(from, to, tokenId);
    }
}