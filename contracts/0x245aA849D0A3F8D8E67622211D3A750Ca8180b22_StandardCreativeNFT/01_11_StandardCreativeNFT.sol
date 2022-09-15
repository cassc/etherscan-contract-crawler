// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title StandardCreativeNFT
/// @author Bounyavong
/// @dev StandardCreativeNFT is a simple NFT for the auction
contract StandardCreativeNFT is ERC721, Ownable {
    using Strings for uint256;

    // the last tokenId that was minted already
    uint256 public minted;
    // Base URI for each token
    string public baseURI;
    // a mapping from an address to whether or not it can mint
    mapping(address => bool) public controllers;

    constructor(
        string memory name,
        string memory symbol,
        string memory _myBaseUri
    ) ERC721(name, symbol) {
        baseURI = _myBaseUri;
    }

    /** CONTROLLER */

    /**
     * @dev mint a token
     * @param to the address of the token holder
     */
    function mint(address to) external onlyController {
        minted++;
        _safeMint(to, minted);
    }

    /** ADMIN */

    /**
     * @dev Internal function to set the base URI for all token IDs. It is
     * automatically added as a prefix to the value returned in {tokenURI},
     * or to the token ID if {tokenURI} is empty.
     * @param _myBaseUri the base URI string
     */
    function setBaseURI(string calldata _myBaseUri) external onlyOwner {
        baseURI = _myBaseUri;
    }

    /**
     * @dev enables an address to mint
     * @param _controller the address to enable
     */
    function addController(address _controller) external onlyOwner {
        controllers[_controller] = true;
    }

    /**
     * @dev disables an address from minting
     * @param _controller the address to disbale
     */
    function removeController(address _controller) external onlyOwner {
        delete controllers[_controller];
    }

    /** VIEW */

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, tokenId.toString()))
                : "";
    }

    /** MODIFIER */

    modifier onlyController() {
        require(controllers[_msgSender()] == true, "ONLY_CONTROLLER");
        _;
    }
}