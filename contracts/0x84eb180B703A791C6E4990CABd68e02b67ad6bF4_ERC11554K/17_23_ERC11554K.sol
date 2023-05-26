// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155SupplyUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/IERC1155MetadataURIUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/common/ERC2981Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165Upgradeable.sol";
import "./interfaces/IGuardians.sol";
import "./interfaces/IERC11554K.sol";
import "./interfaces/IERC11554KController.sol";
import "./libraries/Strings.sol";
import "./libraries/GuardianTimeMath.sol";

/**
 * @dev {ERC11554K} token. 4K collections are created as 4K modified ERC1155 contracts,
 * which inherit all ERC1155 and ERC2981 functionality and extend it.
 */
contract ERC11554K is
    Initializable,
    OwnableUpgradeable,
    ERC1155SupplyUpgradeable,
    ERC2981Upgradeable
{
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using Strings for uint256;

    /// @notice Guardians contract.
    IGuardians public guardians;
    /// @notice IERC11554KController contract.
    IERC11554KController public controller;
    /// @notice 4K collection URI.
    string internal _collectionURI;
    /// @notice Collection Name. Not part of the 1155 standard but still picked up by platforms.
    string public name;
    /// @notice Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json.
    string internal _uri;
    /// @notice Collection Symbol. Not part of the 1155 standard but still picked up by platforms.
    string public symbol;
    /// @notice This collection is "verified" by 4k itself.
    bool public isVerified;
    /// @notice Maximum royalty fee is 7.5%.
    uint256 public constant MAX_ROYALTY_FEE = 750;

    /// @notice Version of the contract
    bytes32 public version;

    /**
     * @dev Only admin modifier.
     */
    modifier onlyAdmin() {
        require(controller.owner() == _msgSender(), "must be an admin");
        _;
    }

    /**
     * @notice Initialize ERC11554K contract.
     * @param guardians_ Address of the guardian contract.
     * @param controller_ Address of the controller contract.
     * @param name_ Name of the collection.
     * @param symbol_ Symbol of the collection.
     * @param version_ Version of contract
     */
    function initialize(
        IGuardians guardians_,
        IERC11554KController controller_,
        string memory name_,
        string memory symbol_,
        string memory uri_,
        string memory collectionURI_,
        bytes32 version_
    ) external virtual initializer {
        __Ownable_init();
        __ERC1155Supply_init();
        guardians = guardians_;
        controller = controller_;
        name = name_;
        symbol = symbol_;
        _uri = uri_;
        _collectionURI = collectionURI_;
        version = version_;
    }

    /**
     * @dev Mint function for controller contract.
     *
     * Requirements:
     *
     * 1) The caller must be a controller contract.
     * @param mintAddress Address to which the token(s) will be minted.
     * @param tokenId Token id of the token within the collection that will be minted.
     * @param amount Amount of token(s) that will be minted.
     */
    function controllerMint(
        address mintAddress,
        uint256 tokenId,
        uint256 amount
    ) external virtual {
        require(
            _msgSender() == address(controller),
            "Only callable by controller"
        );
        _mint(mintAddress, tokenId, amount, "0x");
    }

    /**
     * @dev Burn function for controller contract.
     *
     * Requirements:
     *
     * 1) The caller must be a controller contract.
     * @param burnAddress Address that will be burnining token(s).
     * @param tokenId Token id of the token within the collection that will be burnt.
     * @param amount Amount of token(s) that will be burnt.
     */
    function controllerBurn(
        address burnAddress,
        uint256 tokenId,
        uint256 amount
    ) external virtual {
        require(
            _msgSender() == address(controller),
            "Only callable by controller"
        );
        _burn(burnAddress, tokenId, amount);
    }

    /**
     * @notice Sets guardians contract.
     *
     * Requirements:
     *
     * 1) The caller must be a contract admin.
     * @param guardians_ New guardian contract address.
     **/
    function setGuardians(IGuardians guardians_) external virtual onlyAdmin {
        guardians = guardians_;
    }

    /**
     * @notice Sets token URI.
     *
     * Requirements:
     *
     * 1) The caller be a contract owner.
     * @param newuri New root uri for the tokens.
     **/
    function setURI(string calldata newuri) external virtual onlyAdmin {
        _uri = newuri;
    }

    /**
     * @notice Sets contract-level collection URI.
     *
     * Requirements:
     *
     * 1) The caller be a contract owner.
     * @param collectionURI_ New collection uri for the collection info.
     **/
    function setCollectionURI(
        string calldata collectionURI_
    ) external virtual onlyAdmin {
        _collectionURI = collectionURI_;
    }

    /**
     * @notice Sets the verification status of the contract.
     *
     * Requirements:
     *
     * 1) The caller be a contract owner.
     * @param _isVerified Boolean that signifies if this is a verified collection or not.
     */
    function setVerificationStatus(
        bool _isVerified
    ) external virtual onlyAdmin {
        isVerified = _isVerified;
    }

    /**
     * @notice Sets the royalty information for a specific token id, overriding the global default.
     *
     * Requirements:
     *
     * 1) tokenId must be already minted.
     * 2) Receiver cannot be the zero address.
     * 3) feeNumerator cannot be greater than the fee denominator.
     * @param tokenId The token id for which the user is setting the royalty.
     * @param receiver The address of the entity that will be getting the royalty.
     * @param feeNumerator The amount of royalty the receiver will receive. Numerator that generates percentage, over the _feeDenominator().
     */
    function setTokenRoyalty(
        uint256 tokenId,
        address receiver,
        uint96 feeNumerator
    ) external virtual {
        _setTokenRoyalty(tokenId, receiver, feeNumerator);
    }

    /**
     * @notice Sets the royalty information that all ids in this contract will default to.
     *
     * Requirements:
     *
     * 1) Receiver cannot be the zero address.
     * 2) feeNumerator cannot be greater than the fee denominator.
     * @param receiver the address of the entity that will be getting the default royalty.
     * @param feeNumerator the amount of royalty the receiver will receive. Numerator that generates percentage, over the _feeDenominator().
     */
    function setGlobalRoyalty(
        address receiver,
        uint96 feeNumerator
    ) external virtual onlyAdmin {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    /**
     * @dev Sets the version of the contract.
     * @param version_ New version of contract.
     */
    function setVersion(bytes32 version_) external virtual onlyOwner {
        version = version_;
    }

    /**
     * @notice Opensea contract-level URI standard.
     * See https://docs.opensea.io/docs/contract-level-metadata.
     * @return URI URI of the collection.
     */
    function contractURI() external view returns (string memory) {
        return _collectionURI;
    }

    /**
     * @notice uri returns the URI for item with id.
     * @param id Token id for which the requester will get the URI.
     * @return uri URI of the token.
     */
    function uri(
        uint256 id
    ) public view virtual override returns (string memory) {
        return string(abi.encodePacked(_uri, id.toPaddedHexString(), ".json"));
    }

    /**
     * @notice See {IERC165-supportsInterface}.
     * @param interfaceId interfaceId to query.
     */
    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        virtual
        override(ERC1155Upgradeable, ERC2981Upgradeable)
        returns (bool)
    {
        return
            interfaceId == type(IERC1155Upgradeable).interfaceId ||
            interfaceId == type(IERC1155MetadataURIUpgradeable).interfaceId ||
            interfaceId == type(IERC2981Upgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev Interal wrapper method for ERC2981 _setDefaultRoyalty used by setGlobalRoyalty.
     */
    function _setDefaultRoyalty(
        address receiver,
        uint96 feeNumerator
    ) internal virtual override {
        require(feeNumerator <= MAX_ROYALTY_FEE, "higher than maximum");
        super._setDefaultRoyalty(receiver, feeNumerator);
    }

    /**
     * @dev Interal wrapper method for ERC2981 _setTokenRoyalty used by setTokenRoyalty.
     */
    function _setTokenRoyalty(
        uint256 tokenId,
        address receiver,
        uint96 feeNumerator
    ) internal virtual override {
        require(
            controller.originators(address(this), tokenId) == _msgSender(),
            "Must be originator of token"
        );
        require(feeNumerator <= MAX_ROYALTY_FEE, "higher than maximum");
        super._setTokenRoyalty(tokenId, receiver, feeNumerator);
    }

    /**
     * @dev If an item's guardian class charges guardian fees, then the item should have a minimum to transfer.
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
        // Non-mint non-burn scenario aka transfers between actual addresses
        if (from != address(0) && to != address(0)) {
            for (uint256 i = 0; i < ids.length; ++i) {
                require(
                    balanceOf(from, ids[i]) -
                        guardians.inRepossession(
                            from,
                            IERC11554K(address(this)),
                            ids[i]
                        ) >=
                        amounts[i],
                    "Too many in repossession"
                );
                // No need to prevent transfers or shift guardian fees when items are in a free guardian class
                if (
                    guardians.getGuardianFeeRateByCollectionItem(
                        IERC11554K(address(this)),
                        ids[i]
                    ) > 0
                ) {
                    require(
                        guardians.guardianFeePaidUntil(
                            from,
                            address(this),
                            ids[i]
                        ) >= block.timestamp + guardians.minStorageTime(),
                        "Not enough storage time to transfer"
                    );
                    guardians.shiftGuardianFeesOnTokenMove(
                        from,
                        to,
                        ids[i],
                        amounts[i]
                    );
                }
            }
        }
    }
}