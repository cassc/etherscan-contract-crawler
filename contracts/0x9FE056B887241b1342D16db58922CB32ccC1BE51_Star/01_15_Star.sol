// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

////////////////////////////////////////////////////////////////////////////////////////
//                                                                                    //
//  ████████████████████████████████████████████████████████████████████████████████  //
//  ████████████████████████████████████████████████████████████████████████████████  //
//  ████████████████████████████████████████████████████████████████████████████████  //
//  ████████████████████████████████████████████████████████████████████████████████  //
//  ████████████████████████████████████████████████████████████████████████████████  //
//  ████████████████████████████████████████████████████████████████████████████████  //
//  ████████████████████████████████████████████████████████████████████████████████  //
//  ████████████████████████████████████████████████████████████████████████████████  //
//  ██████████████▌          ╟██           ████████████████          j██████████████  //
//  ██████████████▌          ╟███           ███████████████          j██████████████  //
//  ██████████████▌          ╟███▌           ██████████████          j██████████████  //
//  ██████████████▌          ╟████▌           █████████████          j██████████████  //
//  ██████████████▌          ╟█████▌          ╙████████████          j██████████████  //
//  ██████████████▌          ╟██████▄          ╙███████████          j██████████████  //
//  ██████████████▌          ╟███████           ╙██████████          j██████████████  //
//  ██████████████▌          ╟████████           ╟█████████          j██████████████  //
//  ██████████████▌          ╟█████████           █████████          j██████████████  //
//  ██████████████▌          ╟██████████           ████████          j██████████████  //
//  ██████████████▌          ╟██████████▌           ███████          j██████████████  //
//  ██████████████▌          ╟███████████▌           ██████          j██████████████  //
//  ██████████████▌          ╟████████████▄          ╙█████        ,████████████████  //
//  ██████████████▌          ╟█████████████           ╙████      ▄██████████████████  //
//  ██████████████▌          ╟██████████████           ╙███    ▄████████████████████  //
//  ██████████████▌          ╟███████████████           ╟██ ,███████████████████████  //
//  ██████████████▌                      ,████           ███████████████████████████  //
//  ██████████████▌                    ▄██████▌           ██████████████████████████  //
//  ██████████████▌                  ▄█████████▌           █████████████████████████  //
//  ██████████████▌               ,█████████████▄           ████████████████████████  //
//  ████████████████████████████████████████████████████████████████████████████████  //
//  ████████████████████████████████████████████████████████████████████████████████  //
//  ████████████████████████████████████████████████████████████████████████████████  //
//  ████████████████████████████████████████████████████████████████████████████████  //
//  ████████████████████████████████████████████████████████████████████████████████  //
//  ████████████████████████████████████████████████████████████████████████████████  //
//  ████████████████████████████████████████████████████████████████████████████████  //
//  ████████████████████████████████████████████████████████████████████████████████  //
//                                                                                    //
////////////////////////////////////////////////////////////////////////////////////////

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "../resources/IResources.sol";
import "./IStar.sol";
import "./IStarMetadata.sol";

contract Star is ERC721, IStar, Ownable {

    // Resources contract address
    address public immutable RESOURCES_ADDRESS;

    // Contract which renders star metadata
    address private _starMetadataContract;

    // Star type to star ingredients
    mapping(uint8 => StarIngredient[]) private _starIngredients;

    // Star type for a given star token id
    mapping(uint256 => StarInfo) private _starInfo;

    // Total star supply
    uint256 public totalSupply;

    // Royalty configuration
    uint256 private _royaltyBps;
    address payable private _royaltyRecipient;
    bytes4 private constant _INTERFACE_ID_ROYALTIES_CREATORCORE = 0xbb3bafd6;
    bytes4 private constant _INTERFACE_ID_ROYALTIES_EIP2981 = 0x2a55205a;
    bytes4 private constant _INTERFACE_ID_ROYALTIES_RARIBLE = 0xb7799584;

    constructor(address resourcesAddress) ERC721("LVCIDIA// STAR", "STAR") {
        RESOURCES_ADDRESS = resourcesAddress;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, IERC165) returns (bool) {
        return
            ERC721.supportsInterface(interfaceId) ||
            interfaceId == _INTERFACE_ID_ROYALTIES_CREATORCORE ||
            interfaceId == _INTERFACE_ID_ROYALTIES_EIP2981 ||
            interfaceId == _INTERFACE_ID_ROYALTIES_RARIBLE;
    }

    /**
     * @dev See {IStar-updateStarIngredients}.
     */
    function updateStarIngredients(uint8[] calldata starTypes, StarIngredient[][] calldata starIngredients) external override onlyOwner {
        require(starTypes.length == starIngredients.length, "Invalid input");
        uint256 typesLength = starTypes.length;
        for (uint i = 0; i < typesLength;) {
            uint8 starType = starTypes[i];
            delete _starIngredients[starType];
            StarIngredient[] memory newIngredients = starIngredients[i];
            uint256 ingredientsLength = newIngredients.length;
            for (uint j = 0; j < ingredientsLength; ) {
                _starIngredients[starType].push(newIngredients[j]);
                unchecked { j++; }
            }
            unchecked { i++; }
        }
    }

    function getStarIngredients(uint8 starType) external view returns(StarIngredient[] memory) {
      return _starIngredients[starType];
    }

    /**
     * @dev See {IStar-updateStarMetadata}.
     */
    function updateStarMetadata(address starMetadata) external override onlyOwner {
        _starMetadataContract = starMetadata;
    }

    /**
     * @dev See {IStar-formStar}.
     */
    function formStar(uint8 starType) external override returns(uint256) {
        StarIngredient[] memory ingredients = _starIngredients[starType];
        uint256 length = ingredients.length;
        require(length > 0, "Invalid star type");

        uint256[] memory resourceIds = new uint256[](length);
        uint256[] memory amounts = new uint256[](length);
        for (uint i = 0; i < length;) {
            StarIngredient memory ingredient = ingredients[i];
            resourceIds[i] = ingredient.resourceId;
            amounts[i] = ingredient.amount;
            unchecked { i++; }
        }

        // Burn required resources
        IResources(RESOURCES_ADDRESS).burn(msg.sender, resourceIds, amounts);

        totalSupply++;

        // Info used by IStartMetadata contact to determine metadata
        _starInfo[totalSupply] = StarInfo(starType, uint48(block.timestamp), tx.origin);

        _mint(msg.sender, totalSupply);
        return totalSupply;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        require(_exists(_starInfo[tokenId].starType), "Query for malformed NFT");
        require(_starMetadataContract != address(0), "No metadata contract");

        return IStarMetadata(_starMetadataContract).metadata(tokenId, _starInfo[tokenId]);
    }

    /**
     * @dev Update royalties
     */
    function updateRoyalties(address payable recipient, uint256 bps) external onlyOwner {
        _royaltyRecipient = recipient;
        _royaltyBps = bps;
    }

    /**
     * ROYALTY FUNCTIONS
     */
    function getRoyalties(uint256) external view returns (address payable[] memory recipients, uint256[] memory bps) {
        if (_royaltyRecipient != address(0x0)) {
            recipients = new address payable[](1);
            recipients[0] = _royaltyRecipient;
            bps = new uint256[](1);
            bps[0] = _royaltyBps;
        }
        return (recipients, bps);
    }

    function getFeeRecipients(uint256) external view returns (address payable[] memory recipients) {
        if (_royaltyRecipient != address(0x0)) {
            recipients = new address payable[](1);
            recipients[0] = _royaltyRecipient;
        }
        return recipients;
    }

    function getFeeBps(uint256) external view returns (uint[] memory bps) {
        if (_royaltyRecipient != address(0x0)) {
            bps = new uint256[](1);
            bps[0] = _royaltyBps;
        }
        return bps;
    }

    function royaltyInfo(uint256, uint256 value) external view returns (address, uint256) {
        return (_royaltyRecipient, value*_royaltyBps/10000);
    }
}