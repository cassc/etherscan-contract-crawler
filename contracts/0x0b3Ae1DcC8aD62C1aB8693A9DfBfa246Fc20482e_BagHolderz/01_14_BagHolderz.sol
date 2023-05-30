// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "erc721a/contracts/ERC721A.sol";
import "./utils/AccessLock.sol";

/// @title BagHolderz
/// @author 0xhohenheim <[email protected]>
/// @notice ERC721 NFT Contract for BagHolderz
contract BagHolderz is ERC721A, AccessLock {
    using Counters for Counters.Counter;
    using Strings for uint256;
    string public baseURI;
    bool public isRevealed;
    string public initialURI;

    event RevealUpdated(address indexed admin, string baseURI);
    event InitialURIUpdated(address indexed admin, string newURI);
    event BaseURIUpdated(address indexed admin, string newBaseURI);

    constructor(string memory _initialURI)
        ERC721A("BAGHOLDERZ", "BH")
    {
        initialURI = _initialURI;
    }

    /// @notice - Mint NFT
    /// @dev - callable only by admin
    /// @param recipient - mint to
    function mint(address recipient, uint256 quantity)
        external
        onlyAdmin
    {
        _safeMint(recipient, quantity);
    }

    /// @notice - Set initial unrevealed URI
    /// @dev - callable only by admin
    /// @param _initialURI - initial unrevealed URI
    function setInitialURI(string memory _initialURI) external onlyAdmin {
        initialURI = _initialURI;
        emit InitialURIUpdated(msg.sender, _initialURI);
    }

    /// @notice - Reveal NFTs
    /// @dev - callable only by admin
    /// @param baseURI_ - base URI to set
    /// @param _isRevealed - is the URI revealed?
    function reveal(string memory baseURI_, bool _isRevealed)
        external
        onlyAdmin
    {
        isRevealed = _isRevealed;
        emit RevealUpdated(msg.sender, baseURI_);
        setBaseURI(baseURI_);
    }

    /// @notice - Set base URI for token
    /// @dev - callable only by admin
    /// @param baseURI_ - base URI to set
    function setBaseURI(string memory baseURI_) public onlyAdmin {
        baseURI = baseURI_;
        emit BaseURIUpdated(msg.sender, baseURI_);
    }

    /// @notice - Get token URI
    /// @param tokenId - Token ID of NFT
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        if (!isRevealed) return initialURI;
        else
            return
                bytes(baseURI).length != 0
                    ? string(
                        abi.encodePacked(baseURI, tokenId.toString(), ".json")
                    )
                    : initialURI;
    }
}