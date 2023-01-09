// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9 <0.9.0;

import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "../../../interfaces/IERC4883.sol";
import "../ERC721F.sol";

/**
 * Extension of ERC721F which contains foundation for OnChain tokenURI generation
 */
abstract contract ERC721FOnChain is IERC4883, ERC721F {
    string private description;

    constructor(
        string memory name_,
        string memory symbol_,
        string memory description_
    ) ERC721F(name_, symbol_) {
        description = description_;
    }

    /**
     * @notice Returns description of the contract
     */
    function getDescription() public view virtual returns (string memory) {
        return description;
    }

    /**
     * @notice Creates the tokenURI which contains the name, description, generated SVG image and token traits
     */
    function tokenURI(
        uint256 tokenId
    ) public view override returns (string memory) {
        require(_exists(tokenId), "Non-Existing token");
        string memory svgData = renderTokenById(tokenId);
        string memory traits = getTraits(tokenId);
        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "',
                        name(),
                        " #",
                        Strings.toString(tokenId),
                        '", "description": "',
                        getDescription(),
                        '", "image": "data:image/svg+xml;base64,',
                        Base64.encode(bytes(svgData)),
                        bytes(traits).length == 0 ? '"' : '", "attributes": ',
                        traits,
                        "}"
                    )
                )
            )
        );
        return string(abi.encodePacked("data:application/json;base64,", json));
    }

    /**
     * @notice Generates the SVG image of the tokenId
     */
    function renderTokenById(
        uint256
    ) public view virtual returns (string memory) {}

    /**
     * @notice Returns the traits that are associated with `id`
     * @dev override and return "" to not have any traits in collection
     */
    function getTraits(uint256) public view virtual returns (string memory) {}
}