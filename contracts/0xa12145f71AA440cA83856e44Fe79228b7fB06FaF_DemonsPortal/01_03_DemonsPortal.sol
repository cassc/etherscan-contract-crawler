// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "@openzeppelin/contracts/access/Ownable.sol";

interface IERC721 {

    /**
 * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Burns `tokenId`. See {ERC721-_burn}.
     *
     * Requirements:
     *
     * - The caller must own `tokenId` or be an approved operator.
     */
    function burn(uint256 tokenId) external;

}

contract DemonsPortal is Ownable {
    event SendThroughPortalEvent(address from, uint demonId, uint buernedHellId, uint keyId);


    // Contracts
    IERC721 private hell;
    IERC721 private keys;

    // Hells ducks that were turned into demons
    mapping(uint256 => bool) private _demonIds;


    // Burner address
    address private _burnerAddress = 0x000000000000000000000000000000000000dEaD;

    bool private _isPortalActive = false;


    constructor(address hellAddress, address keyAddress) {
        hell = IERC721(hellAddress);
        keys = IERC721(keyAddress);
    }

    function sendThroughPortal(uint256 demonId, uint256 hellId, uint256 keyId) public {
        require(_isPortalActive, "Portal is not active.");

        require(demonId != hellId, "The tokens must be different");
        require(hell.ownerOf(demonId) == msg.sender, "You must own the requested Demon token.");
        require(hell.ownerOf(hellId) == msg.sender, "You must own the requested Hell token.");
        require(keys.ownerOf(keyId) == msg.sender, "You must own the requested Key token.");

        require(!_demonIds[demonId], "Hell duck was already transformed into a demon");

        // Burn Tokens
        hell.safeTransferFrom(msg.sender, _burnerAddress, hellId);
        keys.burn(keyId);

        // Mark the 2 Gen as used
        _demonIds[demonId] = true;

        emit SendThroughPortalEvent(msg.sender, demonId, hellId, keyId);
    }

    function flipPortalState() public onlyOwner {
        _isPortalActive = !_isPortalActive;
    }

    function setBurnerAddress(address newBurnerAddress) public onlyOwner {
        _burnerAddress = newBurnerAddress;
    }

    function burnerAddress() public view returns (address) {
        return _burnerAddress;
    }

    function isDemon(uint256 demonId) public view returns (bool) {
        return _demonIds[demonId];
    }

    function isPortalActive() public view returns (bool) {
        return _isPortalActive;
    }

    function setDemonIds(uint256[] memory demonIds) onlyOwner public {
        for(uint256 i = 0; i< demonIds.length; i++) {
            _demonIds[demonIds[i]] = true;
        }
    }

    function removeDemonIds(uint256[] memory demonIds) onlyOwner public {
        for(uint256 i = 0; i<demonIds.length; i++) {
            _demonIds[demonIds[i]] = false;
        }
    }
}