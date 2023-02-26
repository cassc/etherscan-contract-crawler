// SPDX-License-Identifier: NO LICENSE

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "./previous/OperatorFilter/OperatorFiltererUpgradeable.sol";
import "./previous/OperatorFilter/Constants.sol";

contract WoolfGen2 is
Initializable,
ERC721Upgradeable,
OwnableUpgradeable,
PausableUpgradeable,
OperatorFiltererUpgradeable
{
    mapping(address => bool) public controllers;

    uint256 public currentId;
    string public baseURI;

    /** INITIALIZER */

    /**
     * @notice instantiates contract
     * @param woolfRebornMaxTokenId    the id of the last token minted in WoolfReborn
     */
    function initialize(
        uint256 woolfRebornMaxTokenId
    ) external initializer {
        require(woolfRebornMaxTokenId != 0, 'Invalid woolfRebornMaxTokenId');

        __Ownable_init();
        __Pausable_init();
        __ERC721_init("Wolf Gen2", "WGEN2");

        currentId = woolfRebornMaxTokenId;
    }


    /** PUBLIC */

    /**
     * @notice mints a new ERC721
     * @dev must implement correct checks on controller contract for allowed mints
     * @param recipient address to mint the token to
     */
    function mint(address recipient) external whenNotPaused {
        require(controllers[_msgSender()], "Only controllers can mint");
        _mint(recipient, ++currentId);
    }

    /** OWNER */

    /**
     * @notice enables owner to pause / unpause minting
     * @param paused   true / false for pausing / unpausing minting
     */
    function setPaused(bool paused) external onlyOwner {
        if (paused) _pause();
        else _unpause();
    }

    /**
     * @notice enables an address to mint
     * @param controller the address to enable
     */
    function addController(address controller) external onlyOwner {
        controllers[controller] = true;
    }

    /**
     * @notice disables an address from minting
     * @param controller the address to disable
     */
    function removeController(address controller) external onlyOwner {
        controllers[controller] = false;
    }

    /**
     * @notice sets the baseURI value to be returned by _baseURI() & tokenURI() methods.
     * @param newBaseURI the new baseUri
     */
    function setBaseURI(string memory newBaseURI) external virtual onlyOwner {
        baseURI = newBaseURI;
    }

    /** INTERNAL */

    /**
     * @notice Implements the ERC721Upgradeable._baseURI empty function
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    //operator-filter-registry
    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
    public
    override
    onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function setOperatorFilterer() external onlyOwner {
        OperatorFiltererUpgradeable.__OperatorFilterer_init(CANONICAL_CORI_SUBSCRIPTION, true);
    }
}