//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

import "./JoyrideParts.sol";
import "./JoyrideWrenches.sol";
import "./WithERC721Metadata.sol";

contract Joyrides is ERC721, Ownable, WithERC721Metadata {
    using Counters for Counters.Counter;

    address private joyridePartsAddress;
    address private wrenchesAddress;

    Counters.Counter private _tokenCount;
    mapping(uint256 => bool) private _claimedTokens;

    event CarAssembled(
        uint256 indexed tokenId, uint256 indexed baseId, uint256 indexed topId, string color
    );

    event ChangeColor(
        uint256 indexed tokenId, string color
    );

    constructor (address _joyridePartsAddress, address _wrenchesAddress, string memory baseURI_)
        ERC721("Joyrides", "RIDE")
        WithERC721Metadata(baseURI_)
    {
        joyridePartsAddress = _joyridePartsAddress;
        wrenchesAddress = _wrenchesAddress;
    }

    /// @dev Assemble a car
    /// @param baseId Token Id of a base car part
    /// @param topId Token Id of a top car part
    /// @param color The background color
    function assemble(uint256 baseId, uint256 topId, string calldata color) public {
        JoyrideParts joyrideParts = JoyrideParts(joyridePartsAddress);
        require(joyrideParts.ownerOf(baseId) == msg.sender &&
                joyrideParts.ownerOf(topId) == msg.sender, "Not the owner.");
        require(joyrideParts.isBase(baseId) && joyrideParts.isTop(topId), "Invalid car parts");
        JoyrideWrenches wrenches = JoyrideWrenches(wrenchesAddress);
        require(wrenches.balanceOf(msg.sender, wrenches.TOKEN_ID()) >= 1, "Missing a wrench");

        joyrideParts.useInAssembly(baseId);
        joyrideParts.useInAssembly(topId);
        wrenches.useInAssembly(msg.sender);

        uint256 tokenId = nextToken();

        _safeMint(msg.sender, tokenId);
        emit CarAssembled(tokenId, baseId, topId, color);
    }

    /// @dev Assemble many cars
    /// @param bases All bases token Ids to use in the assembly
    /// @param tops All tops token Ids to use in the assembly
    /// @param color The background color
    function assembleMany(uint256[] memory bases, uint256[] memory tops, string calldata color) public {
        uint256 length = bases.length;
        require(length == tops.length, "Invalid number of parts.");

        for (uint i = 0; i < length; i++) {
            assemble(bases[i], tops[i], color);
        }
    }

    /// @dev Change the color of a car
    /// @param tokenId Token Id
    /// @param color The new background color
    function changeColor(uint256 tokenId, string calldata color) public {
        require(_isApprovedOrOwner(msg.sender, tokenId), "Not the owner");

        emit ChangeColor(tokenId, color);
    }

    /// @dev Increment the token count and fetch the latest count
    function nextToken() internal virtual returns (uint256) {
        _tokenCount.increment();
        uint256 token = _tokenCount.current();
        return token;
    }

    /// @dev Get the current token count
    function totalSupply() external view returns (uint256) {
        return _tokenCount.current();
    }

    /// @dev Get the tokenURI for a specific token
    function tokenURI(uint256 tokenId)
        public view override(WithERC721Metadata, ERC721)
        returns (string memory)
    {
        return WithERC721Metadata.tokenURI(tokenId);
    }

    /// @dev Configure the baseURI for the tokenURI method
    function _baseURI()
        internal view override(WithERC721Metadata, ERC721)
        returns (string memory)
    {
        return WithERC721Metadata._baseURI();
    }
}