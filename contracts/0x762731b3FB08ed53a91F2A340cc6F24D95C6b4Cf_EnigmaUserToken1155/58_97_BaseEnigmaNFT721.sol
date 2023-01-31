// SPDX-License-Identifier:UNLICENSED
pragma solidity ^0.7.6;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/proxy/IBeacon.sol";
import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";

import "../interfaces/ITransferGatekeeper.sol";
import "../interfaces/IRoyaltyAwareNFT.sol";

/// @title BaseEnigmaNFT721
///
/// @dev This contract is a ERC721 burnable and upgradable based in openZeppelin v3.4.0.
///         Be careful when upgrade, you must respect the same storage.

abstract contract BaseEnigmaNFT721 is IRoyaltyAwareNFT, ERC721BurnableUpgradeable, OwnableUpgradeable {
    using SafeMathUpgradeable for uint256;

    /* Storage */
    //mapping for token royaltyFee
    mapping(uint256 => uint256) private _royaltyFee;

    //mapping for token creator
    mapping(uint256 => address) private _creator;

    //token id counter, increase by 1 for each new mint
    uint256 public tokenCounter;

    // Transfer Gatekeeper with logic to allow token transfers
    IBeacon public transferGatekeeperBeacon;

    //mapping for token rights holder, the ones that will receive royalties
    mapping(uint256 => address) private _rightsHolders;

    bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;

    /* events */
    event URI(string value, uint256 indexed id);
    event TokenBaseURI(string value);

    /* functions */

    /**
     * @notice Initialize NFT721 contract.
     *
     * @param name_ the token name
     * @param symbol_ the token symbol
     * @param tokenURIPrefix_ the toke base uri
     */
    function initialize(
        string memory name_,
        string memory symbol_,
        string memory tokenURIPrefix_
    ) external initializer {
        __ERC721_init(name_, symbol_);
        __ERC721Burnable_init();
        __Ownable_init();

        tokenCounter = 1;
        _setBaseURI(tokenURIPrefix_);
        _registerInterface(_INTERFACE_ID_ERC2981);
    }

    /// oz-upgrades-unsafe-allow constructor
    // solhint-disable-next-line
    constructor() initializer {}

    /// @notice Called with the sale price to determine how much royalty
    //          is owed and to whom.
    /// @param _tokenId - the NFT asset queried for royalty information
    /// @param _salePrice - the sale price of the NFT asset specified by _tokenId
    /// @return receiver - address of who should be sent the royalty payment
    /// @return royaltyAmount - the royalty payment amount for _salePrice
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
        external
        view
        virtual
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        return (rightsHolder(_tokenId), _salePrice.mul(_royaltyFee[_tokenId]).div(1000));
    }

    /**
     * @notice Get the creator of given tokenID.
     * @param tokenId ID of the Token.
     * @return creator of given ID.
     */
    function getCreator(uint256 tokenId) public view virtual override returns (address) {
        return _creator[tokenId];
    }

    /**
     * @notice Get the rights holder (the one to receive royalties) of given tokenID.
     * @param tokenId ID of the Token.
     * @return creator of given ID.
     */
    function rightsHolder(uint256 tokenId) public view virtual override returns (address) {
        address rightsHolder_ = _rightsHolders[tokenId];
        return rightsHolder_ == address(0x0) ? getCreator(tokenId) : rightsHolder_;
    }

    /**
     * @notice Updates the rights holder for a specific tokenId
     * @param tokenId ID of the Token.
     * @param newRightsHolder new rights holderof given ID.
     * @dev Rights holder should only be set by the token creator
     */
    function setRightsHolder(uint256 tokenId, address newRightsHolder) external override {
        require(msg.sender == this.getCreator(tokenId), "Only creator");
        _rightsHolders[tokenId] = newRightsHolder;
    }

    /**
     * @notice Internal function to set the base URI for all token IDs. It is
     * automatically added as a prefix to the value returned in {tokenURI},
     * or to the token ID if {tokenURI} is empty.
     * @param baseURI_ the new base uri
     */
    function _setBaseURI(string memory baseURI_) internal virtual override {
        super._setBaseURI(baseURI_);
        emit TokenBaseURI(baseURI_);
    }

    /**
     * @notice Internal function to set the token URI for a given token.
     * Reverts if the token ID does not exist.
     * @param tokenId uint256 ID of the token to set its URI
     * @param _tokenURI string URI to assign
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual override {
        super._setTokenURI(tokenId, _tokenURI);
        emit URI(_tokenURI, tokenId);
    }

    /**
     * @notice call safe mint function and set token creator and royalty fee
     */
    function _safeMint(
        address to_,
        uint256 tokenId_,
        uint256 fee_,
        address rightsHolder_
    ) internal virtual {
        _creator[tokenId_] = msg.sender;
        _royaltyFee[tokenId_] = fee_;
        _rightsHolders[tokenId_] = rightsHolder_;
        super._safeMint(to_, tokenId_, "");
    }

    /**
     * @notice call transfer fucntion after check transferGatekeeper allowance
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        bytes memory allData = abi.encode("721", tokenId);

        ITransferGatekeeper transferGatekeeper = ITransferGatekeeper(transferGatekeeperBeacon.implementation());
        require(transferGatekeeper.canTransfer(from, to, _msgSender(), allData), "Transfer not approved");
        super._transfer(from, to, tokenId);
    }

    /**
     * @notice external function to set the base URI for all token IDs
     * @param baseURI_ the new base uri
     */
    function setBaseURI(string memory baseURI_) external onlyOwner {
        _setBaseURI(baseURI_);
    }

    /**
     * @notice Set a transferGatekeeperBeacon that points to the gatekeeper implementation
     * @param transferGatekeeperBeacon_ The IBeacon instance
     */
    function setTransferGatekeeperBeacon(IBeacon transferGatekeeperBeacon_) external onlyOwner {
        transferGatekeeperBeacon = transferGatekeeperBeacon_;
    }

    /**
     * @notice Allows to batchUpdate the royalty fees for several tokens
     * @dev This function doesn't perform any checks to make it cheaper, be careful when invoking it
     * @param tokenIds Tokens to update royalty from
     * @param newRoyaltyFees New royalty fees. They must match with the tokenIds
     */
    function batchUpdateRoyaltyFees(uint256[] calldata tokenIds, uint256[] calldata newRoyaltyFees) external onlyOwner {
        uint256 length = tokenIds.length;

        for (uint256 index; index < length; ) {
            _royaltyFee[tokenIds[index]] = newRoyaltyFees[index];
            ++index;
        }
    }

    /**
     * @notice Kind of like an initializer for the upgrade where we support ERC2981
     * @dev This is left unprotected as it is idempotent and it has no parameters
     */
    function declareERC2981Interface() external override {
        _registerInterface(_INTERFACE_ID_ERC2981);
    }

    uint256[50] private __gap;
}