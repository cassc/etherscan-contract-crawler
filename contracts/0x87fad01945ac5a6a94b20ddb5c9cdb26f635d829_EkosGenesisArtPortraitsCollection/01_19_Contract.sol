// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./lib/IWCNFTErrorCodes.sol";
import "./lib/WCNFTToken.sol";
import "./lib/ERC721AOpensea.sol";

contract EkosGenesisArtPortraitsCollection is
    ReentrancyGuard,
    WCNFTToken,
    IWCNFTErrorCodes,
    ERC721AOpensea
{
    struct ReceiverData {
        address to; // address to send tokens to
        uint32 numberOfTokens; // number of tokens to send
    }

    uint256 public constant MAX_SUPPLY = 100;
    string public provenance;
    string private _baseURIextended;
    address payable public immutable shareholderAddress;

    constructor(address payable shareholderAddress_)
        ERC721A("EkosGenesisArtPortraitsCollection", "EGP")
        WCNFTToken()
    {
        if (shareholderAddress_ == address(0)) revert ZeroAddressProvided();

        // set immutable variables
        shareholderAddress = shareholderAddress_;
    }

    /**
     * @dev checks to see if amount of tokens to be minted would exceed the
     *   maximum supply allowed
     * @param numberOfTokens the number of tokens to be minted
     */
    modifier supplyAvailable(uint256 numberOfTokens) {
        if (_totalMinted() + numberOfTokens > MAX_SUPPLY)
            revert ExceedsMaximumSupply();
        _;
    }

    /**
     * @dev handles all minting.
     * @param to address to mint tokens to.
     * @param numberOfTokens number of tokens to mint.
     */
    function _internalMint(address to, uint256 numberOfTokens)
        internal
        supplyAvailable(numberOfTokens)
    {
        _safeMint(to, numberOfTokens);
    }

    /**
     * @dev handles multiple send tokens
     * @param receiver address to send tokens.
     */
    function _sendTokens(ReceiverData calldata receiver) internal {
        address to = receiver.to;
        uint32 numberOfTokens = receiver.numberOfTokens;
        _internalMint(to, numberOfTokens);
    }

    /**
     * @notice send tokens to an address.
     * @param receiver address to send tokens.
     */
    function sendTokens(ReceiverData calldata receiver)
        external
        onlyOwner
        nonReentrant
    {
        _sendTokens(receiver);
    }

    /**
     * @notice send tokens to a batch of addresses.
     * @param receivers array of addresses to send tokens.
     */
    function sendTokensBatch(ReceiverData[] calldata receivers)
        external
        onlyOwner
        nonReentrant
    {
        uint256 receiversLength = receivers.length;
        for (uint256 i; i < receiversLength; i++) {
            _sendTokens(receivers[i]);
        }
    }

    /***************************************************************************
     * Tokens
     */

    /**
     * @dev sets the base uri for {_baseURI}
     * @param baseURI_ the base uri
     */
    function setBaseURI(string calldata baseURI_)
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
    function setProvenance(string calldata provenance_)
        external
        onlyRole(SUPPORT_ROLE)
    {
        provenance = provenance_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     * @param interfaceId the interface id
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721AOpensea, WCNFTToken)
        returns (bool)
    {
        return
            ERC721AOpensea.supportsInterface(interfaceId) ||
            WCNFTToken.supportsInterface(interfaceId);
    }

    /***************************************************************************
     * Withdraw
     */

    /**
     * @dev withdraws ether from the contract to the shareholder address
     */
    function withdraw() external onlyOwner nonReentrant {
        (bool success, ) = shareholderAddress.call{
            value: address(this).balance
        }("");
        if (!success) revert WithdrawFailed();
    }
}