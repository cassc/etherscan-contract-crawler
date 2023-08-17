// SPDX-License-Identifier: MIT
// @ Fair.xyz dev

pragma solidity 0.8.17;

import "IERC721xyzUpgradeable.sol";
import {IRegistry} from "IRegistry.sol";
import "PausableUpgradeable.sol";
import "OwnableUpgradeable.sol";
import "ERC721Upgradeable.sol";
import "ERC2981Upgradeable.sol";
import "UUPSUpgradeable.sol";

contract FairXYZBurn2RedeemUpgradeable is
    ERC721Upgradeable,
    PausableUpgradeable,
    OwnableUpgradeable,
    ERC2981Upgradeable,
    UUPSUpgradeable
{
    /// @dev Boolean to represent that the URIs for the collection can never be modified again
    bool public lockURI;

    /// @dev Mapping of individual token ID to URI
    mapping(uint256 => string) public newURI;

    /// @dev Base URI for collection metadata
    string internal baseURI;

    /// @dev Contract address for collars
    address public collarsContractAddress;

    /// @dev Operator filter registry
    address public registryAddress;

    /// @dev Materials Contract address
    address public materialsContract;

    /// Events
    event NewSecondaryRoyalties(address newReceiver, uint96 newValue);
    event RegistryUpdated(address indexed registryAddress);

    /// Errors
    error OperatorNotAllowed(address operator);

    /// @dev Ensures the implementation contract cannot be taken over
    constructor() {
        _disableInitializers();
    }

    /*///////////////////////////////////////////////////////////////
                            Initializer
    //////////////////////////////////////////////////////////////*/

    function initialize(
        string memory name,
        string memory symbol,
        string memory _newBaseURI,
        address _royaltiesReceiver,
        uint96 _royaltyPercentage,
        address _collarsContractAddress,
        address owner_,
        address registryAddress_
    ) public initializer {
        __ERC721_init(name, symbol);
        _transferOwnership(owner_);
        _pause();
        _setDefaultRoyalty(_royaltiesReceiver, _royaltyPercentage);
        _setRegistryAddress(registryAddress_);

        baseURI = _newBaseURI;
        collarsContractAddress = _collarsContractAddress;
    }

    /*///////////////////////////////////////////////////////////////
                            Royalties
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Override secondary royalty receiver and royalty percentage fee
     */
    function changeSecondaryRoyaltyReceiver(
        address newSecondaryRoyaltyReceiver,
        uint96 newRoyaltyValue
    ) external onlyOwner {
        _setDefaultRoyalty(newSecondaryRoyaltyReceiver, newRoyaltyValue);
        emit NewSecondaryRoyalties(
            newSecondaryRoyaltyReceiver,
            newRoyaltyValue
        );
    }

    /*///////////////////////////////////////////////////////////////
                            Token Metadata
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Returns the Base URI of the collection
     */
    function _baseURI()
        internal
        view
        override(ERC721Upgradeable)
        returns (string memory)
    {
        return baseURI;
    }

    /**
     * @dev Allows the owner to modify the base URI of the collection
     */
    function setBaseURI(string memory newBaseURI) public onlyOwner {
        require(!lockURI, "URI is locked");
        baseURI = newBaseURI;
    }

    /**
     * @dev Allows the owner to modify the URI for a specific token ID in the collection
     */
    function setTokenURI(uint256 tokenId, string memory newTokenURI)
        public
        onlyOwner
    {
        require(!lockURI, "URI is locked");
        newURI[tokenId] = newTokenURI;
    }

    /**
     * @dev View the tokenURI for a given token ID
     */
    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721Upgradeable)
        returns (string memory)
    {
        if (bytes(newURI[tokenId]).length != 0) {
            return newURI[tokenId];
        } else {
            return super.tokenURI(tokenId);
        }
    }

    /**
     * @dev Lock the base URI modification forever
     */
    function lockURIforever() external onlyOwner {
        lockURI = true;
    }

    /*///////////////////////////////////////////////////////////////
                                Pausable
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Pause minting
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @dev Unpause minting
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /*///////////////////////////////////////////////////////////////
                                Minting & burning
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Burn a collar to redeem a hound
     */

    function burn2Redeem(uint256[] memory tokenIds) public whenNotPaused {
        uint256 length = tokenIds.length;
        require(length > 0, "No token IDs specified");

        uint256 i = 0;

        do {
            require(
                msg.sender ==
                    IERC721xyzUpgradeable(collarsContractAddress).ownerOf(
                        tokenIds[i]
                    ),
                "Sender is not the owner of the collar"
            );
            IERC721xyzUpgradeable(collarsContractAddress).burn(tokenIds[i]);
            _mint(msg.sender, tokenIds[i]);

            unchecked {
                ++i;
            }
        } while (i < length);
    }

    /**
     * @dev Burn a hound for use in the Materials contract
     */

    function materialsBurn(uint256[] memory tokenIds, address burner) external {
        require(msg.sender == materialsContract, "Only the materials contract can burn Mutant Hounds");

        uint256 length = tokenIds.length;
        require(length > 0, "No token IDs specified");

        uint256 i = 0;

        do {
            require(burner == ownerOf(tokenIds[i]), "Burner is not token owner");
            _burn(tokenIds[i]);
            unchecked {
                ++i;
            }
        } while (i < length);

    }

    /**
     * @dev Burn a hound for use in the Materials contract
     */

    function setMaterialsContract(address newContractAddress) onlyOwner external {
        materialsContract = newContractAddress;
    }

    /*///////////////////////////////////////////////////////////////
                        Royalty Abidance
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Sets the registry that the contract will check against
     * @param newRegistryAddress - Registry address
     */
    function setRegistryAddress(address newRegistryAddress) external onlyOwner {
        _setRegistryAddress(newRegistryAddress);
    }

    /**
     * @dev Sets the registry that the contract will check against
     * @param newRegistryAddress - Registry address
     */
    function _setRegistryAddress(address newRegistryAddress) internal {
        registryAddress = newRegistryAddress;
        emit RegistryUpdated(newRegistryAddress);
    }

    /**
     * @notice Checks whether msg.sender is valid on the registry. Will return true if registry isn't active.
     * @param operator - Operator address
     */
    function _isValidAgainstRegistry(address operator)
        internal
        view
        returns (bool)
    {
        if (registryAddress != address(0)) {
            IRegistry registry = IRegistry(registryAddress);

            return registry.isAllowedOperator(operator);
        }

        return true;
    }

    modifier isValidOperatorApproval(address operator, bool approved) {
        if (operator != address(0)) {
            if (approved) {
                if (!_isValidAgainstRegistry(operator))
                    revert OperatorNotAllowed(operator);
            }
        }
        _;
    }

    modifier isValidOperator(address from) {
        if (from != msg.sender) {
            if (!_isValidAgainstRegistry(msg.sender))
                revert OperatorNotAllowed(from);
        }
        _;
    }

    function setApprovalForAll(address operator, bool approved)
        public
        override
        isValidOperatorApproval(operator, approved)
    {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId)
        public
        override
        isValidOperatorApproval(operator, true)
    {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override isValidOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override isValidOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public override isValidOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    /*///////////////////////////////////////////////////////////////
                            Miscellaneous
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721Upgradeable, ERC2981Upgradeable)
        returns (bool)
    {
        return
            interfaceId == type(IERC2981Upgradeable).interfaceId ||
            interfaceId == type(IERC721Upgradeable).interfaceId ||
            interfaceId == type(IERC721MetadataUpgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}
}