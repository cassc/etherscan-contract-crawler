// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {ERC721A} from "lib/ERC721A/contracts/ERC721A.sol";
import {IERC721A} from "lib/ERC721A/contracts/IERC721A.sol";
import {IMetadataRenderer} from "./interfaces/IMetadataRenderer.sol";
import {OwnableSkeleton} from "./utils/OwnableSkeleton.sol";

/**
                               __                                    __  .__     
  ________  _  __ ____   _____/  |_  _____ _____    ____       _____/  |_|  |__  
 /  ___/\ \/ \/ // __ \_/ __ \   __\/     \\__  \  /    \    _/ __ \   __\  |  \ 
 \___ \  \     /\  ___/\  ___/|  | |  Y Y  \/ __ \|   |  \   \  ___/|  | |   Y  \
/____  >  \/\_/  \___  >\___  >__| |__|_|  (____  /___|  / /\ \___  >__| |___|  /
     \/              \/     \/           \/     \/     \/  \/     \/          \/ 
 */
contract KasbeelSoulbound is ERC721A, OwnableSkeleton {
    /// @notice Soulbound
    error Kasbeel_Soulbound();

    /// @notice Only Owner
    error Kasbeel_OnlyOwner();

    /// @dev Metadata renderer (uint160)
    IMetadataRenderer public metadataRenderer;

    /// @notice Event emitted when metadata renderer is updated.
    /// @param sender address of the updater
    /// @param renderer new metadata renderer address
    event UpdatedMetadataRenderer(address sender, IMetadataRenderer renderer);

    constructor(
        string memory _contractName,
        string memory _contractSymbol,
        address _airdropRecipient,
        address _initialOwner,
        IMetadataRenderer _metadataRenderer,
        string memory _tokenURI
    ) ERC721A(_contractName, _contractSymbol) {
        // Set ownership to original sender of contract call
        _setOwner(_initialOwner);
        // Initialize Metadata Renderer
        metadataRenderer = IMetadataRenderer(_metadataRenderer);
        bytes memory metadataInitializer = abi.encode(
            abi.encodePacked(_tokenURI, "?"),
            _tokenURI
        );
        metadataRenderer.initializeWithData(metadataInitializer);
        // Mint soulbound token
        _mint({to: _airdropRecipient, quantity: 1});
    }

    /////////////////////////////////////////////////
    /// ADMIN
    /////////////////////////////////////////////////

    /// @dev Set new owner for royalties / opensea
    /// @param newOwner new owner to set
    function setOwner(address newOwner) public onlyOwner {
        _setOwner(newOwner);
    }

    /// @notice Set a new metadata renderer
    /// @param newRenderer new renderer address to use
    /// @param setupRenderer data to setup new renderer with
    function setMetadataRenderer(
        IMetadataRenderer newRenderer,
        bytes memory setupRenderer
    ) external onlyOwner {
        metadataRenderer = newRenderer;

        if (setupRenderer.length > 0) {
            newRenderer.initializeWithData(setupRenderer);
        }

        emit UpdatedMetadataRenderer({
            sender: msg.sender,
            renderer: newRenderer
        });
    }

    /////////////////////////////////////////////////
    /// UTILITY FUNCTIONS
    /////////////////////////////////////////////////

    /// @dev Block transfers for Soulbound.
    function _beforeTokenTransfers(
        address from,
        address,
        uint256,
        uint256
    ) internal view override {
        if (from != address(0)) {
            revert Kasbeel_Soulbound();
        }
    }

    /////////////////////////////////////////////////
    /// MODIFIERS
    /////////////////////////////////////////////////

    /// @notice Only allow for users with admin access
    modifier onlyOwner() {
        if (owner() != msg.sender) {
            revert Kasbeel_OnlyOwner();
        }

        _;
    }

    /////////////////////////////////////////////////
    /// OVERRIDES
    /////////////////////////////////////////////////

    /// @notice Start token ID for minting (1-100 vs 0-99)
    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    /// @notice Token URI Getter, proxies to metadataRenderer
    /// @param tokenId id of token to get URI for
    /// @return Token URI
    function tokenURI(
        uint256 tokenId
    ) public view override returns (string memory) {
        if (!_exists(tokenId)) {
            revert IERC721A.URIQueryForNonexistentToken();
        }

        return metadataRenderer.tokenURI(tokenId);
    }
}