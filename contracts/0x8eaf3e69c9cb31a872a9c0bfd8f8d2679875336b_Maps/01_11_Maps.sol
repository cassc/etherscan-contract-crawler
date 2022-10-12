// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

interface ExternalRenderer {
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

contract Maps is ERC721, IERC721Receiver, Ownable {
    using Strings for uint256;

    ERC721 public SCROLLS = ERC721(0xd629D90a6bEF2E542cAb4Aa42EE1b509a2faB7f2);
    bytes private MESSAGE = bytes("ignis ignis bring the fire, let it reveal what I desire");

    string private ipfsBase;
    ExternalRenderer private EXT_RENDERER;
    address private BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;

    error NotScrolls();
    error InvalidMessage();

    constructor() ERC721("Map of Mages", "MAPS") {}

    /* -------------------------------------------------------------------------- */
    /*                                    MINT                                    */
    /* -------------------------------------------------------------------------- */
    function onERC721Received(
        address,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external override returns (bytes4) {
        // Ensure the token is a Scroll
        if (msg.sender != address(SCROLLS)) revert NotScrolls();

        // Ensure the message is valid
        if (keccak256(data) != keccak256(MESSAGE)) revert InvalidMessage();

        // Burn the Scroll
        SCROLLS.transferFrom(address(this), BURN_ADDRESS, tokenId);

        // Mint a Map
        _mint(from, tokenId);

        return IERC721Receiver.onERC721Received.selector;
    }

    /* -------------------------------------------------------------------------- */
    /*                                  RENDERER                                  */
    /* -------------------------------------------------------------------------- */
    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        _requireMinted(tokenId);

        // If an external renderer is set, use it
        if (address(EXT_RENDERER) != address(0))
            return EXT_RENDERER.tokenURI(tokenId);
        // Otherwise, return an IPFS url
        else return string.concat(ipfsBase, tokenId.toString());
    }

    /* -------------------------------------------------------------------------- */
    /*                               ADMIN FUNCTIONS                              */
    /* -------------------------------------------------------------------------- */
    function setIpfsBase(string calldata base) external onlyOwner {
        ipfsBase = base;
    }

    function setExternalRenderer(address renderer) external onlyOwner {
        EXT_RENDERER = ExternalRenderer(renderer);
    }
}