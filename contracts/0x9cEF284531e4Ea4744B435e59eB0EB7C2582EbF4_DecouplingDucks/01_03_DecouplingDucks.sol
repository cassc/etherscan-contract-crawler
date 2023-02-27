// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

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

}

contract DecouplingDucks is Ownable {
    event Burned(address indexed owner, address indexed nft, uint256 indexed tokenId);


    // Contracts
    IERC721 private og;
    IERC721 private hell;

    // Burner address
    address constant private _burnerAddress = 0x000000000000000000000000000000000000dEaD;

    constructor(address ogAddress, address hellAddress) {
        og = IERC721(ogAddress);
        hell = IERC721(hellAddress);
    }

    function burn(uint256 tokenId, IERC721 nft) private {
        nft.safeTransferFrom(_msgSender(), _burnerAddress, tokenId);
        emit Burned(_msgSender(), address(nft), tokenId);
    }

    function decouple(uint256[] calldata ogIds, uint256[] calldata hellIds) public {
        for(uint256 i = 0; i < ogIds.length; i++) {
            burn(ogIds[i], og);
        }

        for(uint256 i = 0; i < hellIds.length; i++) {
            burn(hellIds[i], hell);
        }
    }
}