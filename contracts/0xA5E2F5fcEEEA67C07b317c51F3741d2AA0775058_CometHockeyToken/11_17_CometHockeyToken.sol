// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "../extensions/ERC721Airdroppable.sol";

contract CometHockeyToken is ERC721Airdroppable {
    /**
     * @notice A struct defining the token receiver.
     *
     * @param to The address to receive the token.
     * @param tokenId The token ID.
     */
    struct TokenReceiver {
        address to;
        uint256 tokenId;
    }

    /// @notice The admin wallet that holds the unclaimed tokens.
    address private _administrator;

    event AdministratorUpdated(address administrator);
    event TokensRedeemed(uint256 count);

    error NewAdministratorIsZeroAddress();
    error OnlyOwnerOrAdministrator();

    modifier onlyOwnerOrAdministrator() virtual {
        if (msg.sender != owner()) {
            if (msg.sender != _administrator) {
                revert OnlyOwnerOrAdministrator();
            }
        }
        _;
    }

    /**
     * @notice CometHockeyToken constructor.
     *
     * @param name The token name.
     * @param symbol The token symbol.
     * @param maxSupply The max supply of the token.
     * @param baseTokenURI The base token URI.
     * @param contractURI The contract URI.
     * @param administrator The wallet holding the collection prior to transfer.
     * @param royalties The royalties wallet.
     */
    constructor(
        string memory name,
        string memory symbol,
        uint256 maxSupply,
        string memory baseTokenURI,
        string memory contractURI,
        address administrator,
        address royalties
    ) ERC721Airdroppable(name, symbol) {
        // Initial maxSupply
        _maxSupply = maxSupply;

        // Initial token base URI
        _baseTokenURI = baseTokenURI;

        // Initial contract URI
        _contractURI = contractURI;

        // Initial administrator
        _administrator = administrator;

        // Initial royalties wallet
        _royalties = royalties;

        // Mint the supply out to the contract
        _mintERC2309(administrator, _maxSupply);
    }

    /**
     * @notice Set the administrator.
     *
     * @param newAdministrator The address of the administrator.
     */
    function setAdministrator(address newAdministrator) external onlyOwner {
        if (newAdministrator == address(0)) {
            revert NewAdministratorIsZeroAddress();
        }

        _administrator = newAdministrator;

        emit AdministratorUpdated(newAdministrator);
    }

    /**
     * @notice Redeem a single token to an address.
     *
     * @param to The receiving wallet address.
     * @param tokenId The token ID.
     */
    function redeem(
        address to,
        uint256 tokenId
    ) external onlyOwnerOrAdministrator {
        safeTransferFrom(_administrator, to, tokenId);
    }

    /**
     * @notice Redeem an array of tokens.
     *
     * @param receivers The array of token receivers.
     */
    function bulkRedeem(
        TokenReceiver[] memory receivers
    ) external onlyOwnerOrAdministrator {
        uint256 receiversLength = receivers.length;

        for (uint256 i = 0; i < receiversLength; i++) {
            safeTransferFrom(
                _administrator,
                receivers[i].to,
                receivers[i].tokenId
            );
        }

        emit TokensRedeemed(receiversLength);
    }
}