// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "./lib/ERC721EnumerableOpensea.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./lib/IWCNFTErrorCodes.sol";
import "./lib/WCNFTToken.sol";

contract CraftNouveau is
    ReentrancyGuard,
    WCNFTToken,
    IWCNFTErrorCodes,
    ERC721EnumerableOpensea
{
    uint256 public transferIdLimit;

    string public provenance;
    string private _baseURIextended;

    /// cannot transfer token if token id is less than the transfer id limit
    error TransferNotAllowed(uint256 tokenId);

    constructor() ERC721("Craft Nouveau: Navette Redemption Passes", "CRAFT") WCNFTToken() {}

    /**
     * @dev disallow transfer if token id is less than the limit
     * @param tokenId the token id to transfer
     */
    modifier transferAllowed(uint256 tokenId) {
        if (tokenId < transferIdLimit) revert TransferNotAllowed(tokenId);
        _;
    }

    /***************************************************************************
     * Tokens
     */

    /**
     * @dev sets the base uri for {_baseURI}
     * @param baseURI_ the base uri
     */
    function setBaseURI(string memory baseURI_)
        external
        onlyRole(SUPPORT_ROLE)
    {
        _baseURIextended = baseURI_;
    }

    /**
     * @dev See {ERC721-_baseURI}.
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }

    /**
     * @dev sets the provenance hash
     * @param provenance_ the provenance hash
     */
    function setProvenance(string memory provenance_)
        external
        onlyRole(SUPPORT_ROLE)
    {
        provenance = provenance_;
    }

    /***************************************************************************
     * Override
     */

    /**
     * @dev See {IERC165-supportsInterface}.
     * @param interfaceId the interface id
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721Enumerable, WCNFTToken)
        returns (bool)
    {
        return
            ERC721Enumerable.supportsInterface(interfaceId) ||
            WCNFTToken.supportsInterface(interfaceId);
    }

    /**
     * @dev See {ERC721Enumerable-_beforeTokenTransfer}.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override transferAllowed(tokenId) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    /***************************************************************************
     * Admin
     */

    /**
     * @dev sets the id limit for transferring tokens
     * @param limit the token id
     */
    function setTransferIdLimit(uint256 limit) external onlyRole(SUPPORT_ROLE) {
        transferIdLimit = limit;
    }

    /**
     * @dev send tokens to a batch of addresses.
     * @param addresses array of addresses to send tokens to.
     */
    function sendTokens(address[] calldata addresses)
        external
        onlyRole(SUPPORT_ROLE)
    {
        uint256 ts = totalSupply();

        for (uint256 index; index < addresses.length; index++) {
            address to = addresses[index];

            _safeMint(to, ts + index);
        }
    }
}