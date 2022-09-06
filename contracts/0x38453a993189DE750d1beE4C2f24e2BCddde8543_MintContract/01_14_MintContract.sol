// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "./roleControl.sol";

contract MintContract is
ERC721,
RoleControl
{
    using Strings for uint256;

    uint256 public totalSupply;
    string baseURI;
    string baseExtension = ".json";
    uint256 public supply;
    uint256 public mintPrice = 0.06 ether;
    bool public paused = true;
    bool public isRevealed = false;


    modifier isUnpaused() {
        require(!paused, "Mint is paused");
        _;
    }

    modifier isEnoughTokensToMint(uint256 amount) {
        require(amount + supply <= totalSupply, "Not enough supply");
        _;
    }

    modifier onlyOwner(uint256 tokenId) {
        require(ownerOf(tokenId) == msg.sender, "You are not owner");
        _;
    }

    constructor(
        string memory name_,
        string memory symbol_,
        uint256 totalSupply_,
        string memory baseUri_
    ) ERC721(name_, symbol_) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        totalSupply = totalSupply_;
        baseURI = baseUri_;
    }

    function changePauseStatus() public onlyAdmin {
        paused = !paused;
    }

    function changeMintPrice(uint256 newPrice) public onlyAdmin {
        mintPrice = newPrice;
    }

    function tokenURI(uint256 tokenId)
    public
    view
    override
    returns (string memory)
    {
        require(_exists(tokenId), "Token not exists");
        return string(
            abi.encodePacked(baseURI, "/", tokenId.toString(), baseExtension)                );

    }

    function mint(uint256 amount) public payable isUnpaused isEnoughTokensToMint(amount) {
        require(msg.value >= amount * mintPrice, "Not enough ETH sent");

        for (uint256 i = 0; i < amount; i++) {
            supply++;
            _safeMint(msg.sender, supply);
        }
    }

    function burn(uint256 tokenId) public onlyOwner(tokenId) {
        _burn(tokenId);
    }

    function withdraw(uint256 amount, address payable to) public onlyAdmin {
        (bool success, ) = to.call{value: amount}("");
        require(success);
    }

    function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(ERC721, RoleControl)
    returns (bool)
    {
        return
        interfaceId == type(IAccessControl).interfaceId ||
        interfaceId == type(IERC721).interfaceId ||
        super.supportsInterface(interfaceId);
    }
}