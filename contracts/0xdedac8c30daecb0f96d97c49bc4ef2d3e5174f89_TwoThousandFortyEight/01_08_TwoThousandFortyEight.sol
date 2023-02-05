// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

contract TwoThousandFortyEight is ERC721A, Ownable {
    using Strings for uint256;
    using Strings for uint16;

    uint256 public available = 1024;

    uint16 maxPower = 1;

    // Mapping from owner address to mint status
    mapping(address => bool) public minters;

    // Mapping from token ID to power of two
    mapping(uint256 => uint16) tokenPower;

    constructor() ERC721A("2048 On-Chain", "2048") {}

    /**
     * EACH WALLET CAN MINT A MAXIMUM OF ONE 2-TILE
     * THERE ARE ONLY 1024 2-TILES
     */
    function mint() public {
        require(available > 0, "NO MORE TILES");
        require(minters[msg.sender] == false, "ALREADY MINTED");

        available--;
        minters[msg.sender] = true;

        // Mint a new tile
        tokenPower[_nextTokenId()] = 1;
        _mint(msg.sender, 1);
    }

    /**
     * EACH WALLET CAN HODL
     * A MAXIMUM OF 16 TILES
     */
    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual override(ERC721A) {
        require(to == address(0) || balanceOf(to) < 16,             "NO MORE SPACE IN WALLET");

        super._beforeTokenTransfers(from, to, startTokenId, quantity);
    }

    /**
     * BURN TWO TILES AND
     * MINT A NEW TILE
     */
    function burn(uint256 firstTokenId, uint256 secondTokenId) public {
        uint16 firstTokenPower = tokenPower[firstTokenId];
        uint16 secondTokenPower = tokenPower[secondTokenId];

        require(firstTokenPower == secondTokenPower,     "TILES DON'T HAVE THE SAME VALUE");

        // Burn the existing tiles
        _burn(firstTokenId, true);
        _burn(secondTokenId, true);

        uint16 newPower = firstTokenPower + 1;

        if (newPower > maxPower) {
            maxPower = newPower;
        }

        // Mint a new tile
        tokenPower[_nextTokenId()] = newPower;
        _mint(msg.sender, 1);
    }

    function generateTile(uint256 tokenId) public view returns (string memory) {
        uint16 power = tokenPower[tokenId];
        uint256 value = 2 ** power;

        bytes memory svg = abi.encodePacked(
            '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 56 56">',
            '<rect id="Rectangle" fill="',
            power == maxPower ? "#e2b43e" : "#18181b",
            '" x="0" y="0" width="56" height="56"></rect>',
            '<text x="50%" y="50%" dominant-baseline="middle" text-anchor="middle" font-family="ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, Courier New, monospace" font-size="16" font-weight="bold" fill="#FFFFFF">',
            value.toString(),
            '</text>',
            '</svg>'
        );

        return string(
            abi.encodePacked(
                "data:image/svg+xml;base64,", 
                Base64.encode(svg)
            )    
        );
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) _revert(URIQueryForNonexistentToken.selector);

        uint16 power = tokenPower[tokenId];
        uint256 value = 2 ** power;

        bytes memory dataURI = abi.encodePacked(
            '{',
            '"name": "2048 On-Chain #', tokenId.toString(), '",',
            '"description": "burn the tokens and get to 2048",',
            '"image": "',  generateTile(tokenId), '",',
            '"attributes": [{', 
            '"trait_type": "value",',
            '"display_type": "number",',
            '"value": ', value.toString(),
            '}]}'
        );

        return string(
            abi.encodePacked(
                "data:application/json;base64,",
                Base64.encode(dataURI)
            )
        );
    }

    /**
     * @dev For more efficient reverts.
     */
    function _revert(bytes4 errorSelector) internal pure {
        assembly {
            mstore(0x00, errorSelector)
            revert(0x00, 0x04)
        }
    }


}