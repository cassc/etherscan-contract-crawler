// SPDX-License-Identifier: UNLICENSED

/**
 * ███╗   ███╗ ██████╗  ██████╗ ███╗   ██╗    ██╗      █████╗ ██████╗ ███████╗
 * ████╗ ████║██╔═══██╗██╔═══██╗████╗  ██║    ██║     ██╔══██╗██╔══██╗██╔════╝
 * ██╔████╔██║██║   ██║██║   ██║██╔██╗ ██║    ██║     ███████║██████╔╝███████╗
 * ██║╚██╔╝██║██║   ██║██║   ██║██║╚██╗██║    ██║     ██╔══██║██╔══██╗╚════██║
 * ██║ ╚═╝ ██║╚██████╔╝╚██████╔╝██║ ╚████║    ███████╗██║  ██║██████╔╝███████║
 * ╚═╝     ╚═╝ ╚═════╝  ╚═════╝ ╚═╝  ╚═══╝    ╚══════╝╚═╝  ╚═╝╚═════╝ ╚══════╝
 */

pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MoonLabsStakingCards is ERC721Enumerable, Ownable {
    using Strings for uint;

    constructor(
        string memory name,
        string memory symbol,
        string memory _baseTokenURI
    ) ERC721(name, symbol) {
        baseTokenURI = _baseTokenURI;
    }

    /*|| === STATE VARIABLES === ||*/
    string public BASE_EXTENSION = ".json";
    uint public constant MAX_SUPPLY = 500;
    string public baseTokenURI;

    /*|| === EXTERNAL FUNCTIONS === ||*/

    /**
     * @notice Return all token ids of desired address
     * @param _owner address indexed
     */
    function getTokenIds(address _owner) external view returns (uint[] memory) {
        /// Count owned Token
        uint ownerTokenCount = balanceOf(_owner);
        uint[] memory tokenIds = new uint[](ownerTokenCount);
        /// Get ids of owned Token
        for (uint i = 0; i < ownerTokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokenIds;
    }

    /**
     * @param _to address to mint nfts to. Only owner function.
     * @param amount number of nfts to min
     */
    function ownerMint(address _to, uint amount) external onlyOwner {
        uint supply = totalSupply();
        require(supply + amount <= MAX_SUPPLY, "Max supply reached");
        for (uint i = 1; i <= amount; i++) {
            _safeMint(_to, supply + i);
        }
    }

    /**
     * @notice set the base token uri. Only owner function.
     * @param baseURI new uri address
     */
    function setBaseURI(string memory baseURI) external onlyOwner {
        baseTokenURI = baseURI;
    }

    /**
     * @notice Claim all eth in contract. Only owner function.
     */
    function claimETH() external payable onlyOwner {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success);
    }

    /*|| === PUBLIC FUNCTIONS === ||*/

    /**
     * @notice  Return compiled Token URI
     * @param _id token id to index
     */
    function tokenURI(
        uint _id
    ) public view virtual override returns (string memory) {
        require(_exists(_id), "URI query for nonexistent token");
        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        _id.toString(),
                        BASE_EXTENSION
                    )
                )
                : "";
    }

    /*|| === INTERNAL FUNCTIONS === ||*/

    /**
     * @notice  URI Handling
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }
}