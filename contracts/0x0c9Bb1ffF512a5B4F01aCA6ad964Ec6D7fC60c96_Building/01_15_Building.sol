// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./ITownHall.sol";

// @custom:security-contact [email protected]
contract Building is ERC721, ERC721Enumerable, Ownable {
    error Building__NotOwnerOrApproved();
    error Building__CallerIsNotTownHall();
    error Building__CannotChangeTownHallAddress();

    using Strings for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;
    address public townHall;

    constructor() ERC721("HUNT Building", "HUNT_BUILDING") {}

    modifier onlyTownHall() {
        if(townHall != msg.sender) revert Building__CallerIsNotTownHall();
        _;
    }

    /**
     * @dev Set TownHall address once it's deployed
     * - Once it's assigned, the address cannot be changed even by the contract owner
     */
    function setTownHall(address _townHall) external onlyOwner {
        if (townHall != address(0)) revert Building__CannotChangeTownHallAddress();

        townHall = _townHall;
    }

    /**
     * @dev Mint a new Building NFT
     *
     * Requirements:
     * - Only Town Hall contract can mint a new building NFT with the token lock-up requirement.
     */
    function safeMint(address to) external onlyTownHall returns(uint256 tokenId) {
        tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();

        _safeMint(to, tokenId);
    }

    /**
     * @dev Burns `tokenId`.
     *
     * Requirements:
     * - Only Town Hall contract can burn the building NFT to prevent users from accidentally burning thier NFTs without unlocking their HUNT tokens.
     * - The caller must own `tokenId` or be an approved operator.
     */
    function burn(uint256 tokenId, address msgSender) external onlyTownHall {
        if(!_isApprovedOrOwner(msgSender, tokenId)) revert Building__NotOwnerOrApproved();

        _burn(tokenId);
    }

    /**
     * @dev Contract-level metadata
     *  - Ref: https://docs.opensea.io/docs/contract-level-metadata
     */
    function contractURI() public pure returns (string memory) {
        return "https://api.hunt.town/token-metadata/buildings.json";
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return "https://api.hunt.town/token-metadata/buildings/";
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        return string(abi.encodePacked(_baseURI(), tokenId.toString(), ".json"));
    }

    function nextId() external view returns (uint256) {
        return _tokenIdCounter.current();
    }

    function exists(uint256 tokenId) external view returns (bool) {
        return _exists(tokenId);
    }

    // Utility wrapper function that calls TownHall's unlockTime function
    function unlockTime(uint256 tokenId) external view returns (uint256) {
        return ITownHall(townHall).unlockTime(tokenId);
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    // MARK: - Override extensions

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}