// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IVoiceMaskAlpha} from "./interfaces/IVoiceMaskAlpha.sol";
import {ERC721A} from "erc721a/contracts/ERC721A.sol";
import {IERC721A} from "erc721a/contracts/IERC721A.sol";
import {ERC721AQueryable} from "erc721a/contracts/extensions/ERC721AQueryable.sol";

contract VoiceMaskAlpha is IVoiceMaskAlpha, ERC721A, ERC721AQueryable, Ownable {
    constructor() ERC721A("Voice Mask Alpha", "VMA") {}

    address public minter;
    string private baseURI;
    uint256 public auctionSupply = 160;
    uint256 public teamSupply = 40;
    uint256 public auctionCount = 0;
    uint256 public teamCount = 0;

    mapping(uint256 => uint256) public birthdayBlock; //token id, generated block
    uint256 public durationBlock = (60 * 60 * 24 * 91) / 12; // 3 months

    modifier onlyMinter() {
        require(msg.sender == minter, "Sender is not the minter");
        _;
    }

    /**
     * Mint nft for auction.
     * Only minter can mint, can mint 1 at a time
     */
    function mintAuction() external onlyMinter returns (uint256) {
        require(auctionCount < auctionSupply, "Auction supply all sold out");

        auctionCount++;
        return _mintTo(msg.sender);
    }

    /**
     * Mint nft for the team.
     * Only owner can mint, can mint 1 at a time
     */
    function mintTeam(address to, uint256 _quantity)
        external
        onlyOwner
        returns (uint256)
    {
        //mint one by one
        _quantity = 1;
        require(
            teamCount + _quantity <= teamSupply,
            "Team supply all sold out"
        );

        teamCount++;
        return _mintTo(to);
    }

    function burn(uint256 alphaId) public override {
        require(ownerOf(alphaId) == msg.sender, "Sender does not own it");
        _burn(alphaId);
        emit AlphaBurned(alphaId);
    }

    function setBaseURI(string memory uri) external onlyOwner {
        baseURI = uri;
    }

    function setMinter(address _minter) external onlyOwner {
        minter = _minter;
        emit MinterUpdated(minter);
    }

    function setAuctionSupply(uint256 _maxMint) external onlyOwner {
        auctionSupply = _maxMint;
    }

    function setTeamSupply(uint256 _maxMint) external onlyOwner {
        teamSupply = _maxMint;
    }

    function setDurationBlock(uint256 _durationBlock) external onlyOwner {
        durationBlock = _durationBlock;
    }

    function getBirthdayBlock(uint256 _index) external view returns (uint256) {
        return birthdayBlock[_index];
    }

    /**
     * Team supply tokens should be locked for durationBlock.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public payable override(ERC721A, IERC721A) {
        if (msg.sender != this.owner() && to != this.owner()) {
            require(!_checkIfLockedtoken(tokenId), "Token is locked up yet");
        }
        super.safeTransferFrom(from, to, tokenId, _data);
    }

    /**
     * Team supply tokens should be locked for durationBlock.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override(ERC721A, IERC721A) {
        if (msg.sender != this.owner() && to != this.owner()) {
            require(!_checkIfLockedtoken(tokenId), "Token is locked up yet");
        }
        super.safeTransferFrom(from, to, tokenId);
    }

    /**
     * Team supply tokens should be locked for durationBlock.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable virtual override(ERC721A, IERC721A) {
        if (msg.sender != this.owner() && to != this.owner()) {
            require(!_checkIfLockedtoken(tokenId), "Token is locked up yet");
        }
        super.transferFrom(from, to, tokenId);
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function _mintTo(address to) internal returns (uint256) {
        _mint(to, 1);

        emit AlphaCreated(_nextTokenId() - 1, to);

        //check birthday block of team supply only
        if (_nextTokenId() - 1 <= teamSupply) {
            birthdayBlock[_nextTokenId() - 1] = block.number;
        }

        return _nextTokenId() - 1;
    }

    function _checkIfLockedtoken(uint256 tokenId) internal view returns (bool) {
        //lock team supply only
        if (tokenId > teamSupply) {
            return false;
        }
        if (birthdayBlock[tokenId] + durationBlock < block.number) {
            return false;
        }
        return true;
    }
}