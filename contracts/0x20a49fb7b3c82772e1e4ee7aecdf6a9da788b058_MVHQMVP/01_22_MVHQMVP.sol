// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721RoyaltyUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

/// @title MVHQMVP
/// @author Kfish n Chips
/// @notice Metaverse HQ MVP
/// @dev This is an upgradeable contract using UUPSUpgradeable (IERC1822Proxiable / ERC1967Proxy) from OpenZeppelin
contract MVHQMVP is
    Initializable,
    UUPSUpgradeable,
    AccessControlUpgradeable,
    ERC721RoyaltyUpgradeable
{
    using CountersUpgradeable for CountersUpgradeable.Counter;

    /// @notice Role assigned to addresses that can perform minted actions
    /// @dev Role can be granted by the DEFAULT_ADMIN_ROLE
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    /// @notice Role assigned to an address that can perform upgrades to the contract
    /// @dev Role can be granted by the DEFAULT_ADMIN_ROLE
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
    /// @notice Base URI used to retrieve metadata
    string public baseURI;
    /// @notice Setting an owner in order to comply with ownable interfaces
    /// @dev This variable was only added for compatibility with contracts that request an owner
    address public owner;
    /// @notice Counter used to keep track of tokenIds
    CountersUpgradeable.Counter private counter;
    /// @notice Contract URI with metadata
    string private _contractURI;

    /// @notice Emitted when ownership transferred.
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /// @notice Initializer function which replaces constructor for upgradeable contracts
    /// @dev This should be called at deploy time
    function initialize() external initializer {
        __UUPSUpgradeable_init();
        __AccessControl_init();
        __ERC721_init("MVHQMVP", "MVHQMVP");
        __ERC721Royalty_init();
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        _grantRole(UPGRADER_ROLE, msg.sender);
        _contractURI =  "ipfs://QmZ6UhUQiFQ4SUbWcvhR5i3eXraPGHBpcHDVezsi36fsW2";
        baseURI = "ipfs://QmZBMPmyML4n6AxtSH3pLudajxt6v2FEyeT6X8Raqz9jsP/";
        _setDefaultRoyalty(0x9b318F4Ce0672a3f1Ac661D9739A947F38b863a0, 0);
        owner = msg.sender;
    }

    /// @notice Transfers ownership of the contract to a new account (`newOwner`)
    /// @dev Can only be called by an address with DEFAULT_ADMIN_ROLE
    /// @param newOwner_ New Owner of the contract
    /// Emits a {OwnershipTransferred} event
    function transferOwnership(address newOwner_)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(
            newOwner_ != address(0),
            "MVHQMVP: owner cannot be zero address"
        );
        address previousOwner = owner;
        owner = newOwner_;

        emit OwnershipTransferred(previousOwner, owner);
    }

    /// @notice Used to set the baseURI for metadata
    /// @dev Only callable by an address with DEFAULT_ADMIN_ROLE
    /// @param baseURI_ The base URI
    function setBaseURI(string memory baseURI_)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(bytes(baseURI_).length > 0, "MVHQMVP: invalid URI");
        baseURI = baseURI_;
    }

    /// @notice Used to set the contractURI
    /// @dev Only callable by an address with DEFAULT_ADMIN_ROLE
    /// @param newContractURI_ The base URI
    function setContractURI(string memory newContractURI_)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(bytes(newContractURI_).length > 0, "MVHQMVP: invalid URI");
        _contractURI = newContractURI_;
    }

    /// @notice Set the default royalties using the ERC2981 NFT Royalty Standard
    /// @dev Callable only by an address with DEFAULT_ADMIN_ROLE
    /// The fee numerator considers a 10000 denominator
    /// meaning that 10% royalties would require a feeNumerator of 1000
    /// @param receiver_ Address that will receive royalty payments
    /// @param feeNumerator_ The number used to calculate the royalty percentage
    function setDefaultRoyalties(address receiver_, uint96 feeNumerator_)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _setDefaultRoyalty(receiver_, feeNumerator_);
    }

    /// @notice Mints multiple tokens to `recipients_`.
    /// @dev Only callable by address with MINTER_ROLE
    /// @param recipients_ Array of addresses that will receive tokens
    function mintBatch(address[] calldata recipients_)
        external
        onlyRole(MINTER_ROLE)
    {
        for (uint256 i = 0; i < recipients_.length; i++) {
            counter.increment();
            _mint(recipients_[i], counter.current());
        }
    }

    /// @notice Mints a token to a `recipient_`.
    /// @dev Only callable by an address with MINTER_ROLE
    /// @param recipient_ The token recipient
    function mintTo(address recipient_) external onlyRole(MINTER_ROLE) {
        counter.increment();
        _mint(recipient_, counter.current());
    }

    /// @notice Burn an existing token
    /// @dev Only callable by an address with DEFAULT_ADMIN_ROLE
    /// @param tokenId_ The tokenId
    function burn(uint256 tokenId_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _burn(tokenId_);
    }

    /// @notice ContractURI containing metadata for marketplaces
    /// @return The _contractURI
    function contractURI() external view returns (string memory) {
        return _contractURI;
    }

    /// @notice Override of supportsInterface function
    /// @param interfaceId the interfaceId
    /// @return bool if interfaceId is supported or not
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(
            ERC721RoyaltyUpgradeable,
            AccessControlUpgradeable
        )
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /// @notice Override of ERC721 tokenURI(uint256)
    /// @dev returns baseURI + tokenId
    /// @param tokenId_ the tokenId
    /// @return The tokenURI containing metadata
    function tokenURI(uint256 tokenId_)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId_), "MVHQMVP: token does not exist");
        return
            string(
                abi.encodePacked(baseURI, StringsUpgradeable.toString(tokenId_))
            );
    }

    /// @notice Hook executed before transferring a token
    /// @param from address that holds the tokenId
    /// @param to address that will receive the tokenId
    /// @param tokenId tokenId that will be transferred
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    )
        internal
        virtual
        override(ERC721Upgradeable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    /// @notice Burns `tokenId_`.
    /// @dev Burns `tokenId_`.
    /// @param tokenId_ To be burned
    function _burn(uint256 tokenId_)
        internal
        virtual
        override(ERC721RoyaltyUpgradeable)
    {
        super._burn(tokenId_);
    }

    /// @notice UUPS Upgradeable authorization function
    /// @dev Callable only an address with UPGRADER_ROLE
    /// @param newImplementation_ Address of the new implementation
    function _authorizeUpgrade(address newImplementation_)
        internal
        virtual
        override
        onlyRole(UPGRADER_ROLE)
    {}
}