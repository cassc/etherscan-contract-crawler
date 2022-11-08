// SPDX-License-Identifier: MIT

pragma solidity 0.8.12;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "erc721a/contracts/ERC721AUUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";

/** ERROR CODES
    E01 - MINT TO AT LEAST ONE ADDRESS
    E02 - MINT WOULD EXCEED SUPPLY LIMIT
    E03 - WITHDRAW FAILED
    E04 - UNAUTHORIZED
 */

/// @title SNIF
/// @author @KfishNFT
/// @notice Sneaky's Internet Friends Collection
/** @dev Any function which updates state will require a signature from an address with the correct role
    This is an upgradeable contract using UUPSUpgradeable (IERC1822Proxiable / ERC1967Proxy) from OpenZeppelin */
contract SNIF is Initializable, AccessControlUpgradeable, ERC721AUUPSUpgradeable {
    using StringsUpgradeable for uint256;
    /// @notice Role assigned to an address that can perform upgrades to the contract
    /// @dev role can be granted by the DEFAULT_ADMIN_ROLE
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
    /// @notice Role assigned to addresses that can perform managemenet actions
    /// @dev role can be granted by the DEFAULT_ADMIN_ROLE
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
    /// @notice Role assigned to addresses that can mint
    /// @dev role can be granted by the DEFAULT_ADMIN_ROLE
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    /// @notice base URI used to retrieve metadata
    /// @dev tokenURI will use .json at the end for each token starting from 1 and ending at 2000
    string public baseURI;
    /// @notice unrevealed URIs where element 0 is blue and element 1 is red
    string[] public unrevealedURIs;
    /// @notice setting an owner in order to comply with ownable interfaces
    /// @dev this variable was only added for compatibility with contracts that request an owner
    address public owner;

    /// @notice Initializer function which replaces constructor for upgradeable contracts
    /// @dev This should be called at deploy time
    /// @param unrevealedURIs_ unrevealed URIs where element 0 is blue and element 1 is red
    function initialize(string[] memory unrevealedURIs_) public initializer {
        __ERC721A_init("SNIF", "SNIF");
        __AccessControl_init();
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        unrevealedURIs = unrevealedURIs_;
        owner = msg.sender;
    }

    /*
        Functions that require authorized roles
    */
    /// @notice Batch mint function to be called by an address with Minter Role
    /// @param addresses_ array of addresses to mint to
    function mint(address[] calldata addresses_) external onlyRole(MINTER_ROLE) {
        require(addresses_.length > 0, "E01");
        require((_totalMinted() + (addresses_.length * 2)) <= 2000, "E02");
        for (uint256 i = 0; i < addresses_.length; i++) {
            _safeMint(addresses_[i], 2);
        }
    }

    /// @notice Mint function to be called by an address with Minter Role
    /// @param to_ receiving address
    function mintAllowList(address to_) external onlyRole(MINTER_ROLE) {
        require((_totalMinted() + 2) <= 2000, "E02");
        _safeMint(to_, 2);
    }

    /// @notice Used to set the baseURI for metadata
    /// @dev the baseURI should end in '/'
    /// @param baseURI_ the base URI
    function setBaseURI(string memory baseURI_) external managed {
        baseURI = baseURI_;
    }

    /// @notice Used to set the unrevealed URI for even tokens
    /// @param unrevealedURIs_ array where element 0 corresponds to blue URI and 1 to red URI
    function setUnrevealedURIs(string[] memory unrevealedURIs_) external managed {
        unrevealedURIs = unrevealedURIs_;
    }

    /// @notice Used to set a new owner value
    /// @dev This is not the same as Ownable and was only added for compatibility
    /// @param newOwner_ the new owner
    function transferOwnership(address newOwner_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        owner = newOwner_;
    }

    /// @notice Withdraw function in case anyone sends ETH to contract by mistake
    function withdraw() external payable onlyRole(DEFAULT_ADMIN_ROLE) {
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(success, "E03");
    }

    /*
        ERC721A Overrides
    */
    /// @notice Override of ERC721A start token ID
    /// @return the initial tokenId
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    /// @notice Override of ERC721A tokenURI(uint256)
    /// @dev returns baseURI + tokenId.json if baseURI is present, if not, return blue or red unrevealed URI
    /// @param tokenId the tokenId without offsets
    /// @return the tokenURI with metadata
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
        if (bytes(baseURI).length > 0) {
            return string(abi.encodePacked(abi.encodePacked(baseURI, tokenId.toString()), ".json"));
        } else {
            if (tokenId % 2 == 0) {
                return bytes(unrevealedURIs[0]).length != 0 ? unrevealedURIs[0] : "";
            } else {
                return bytes(unrevealedURIs[1]).length != 0 ? unrevealedURIs[1] : "";
            }
        }
    }

    /// @notice Override of ERC721A and AccessControlUpgradeable supportsInterface function
    /// @param interfaceId the interfaceId
    /// @return bool if interfaceId is supported or not
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControlUpgradeable, ERC721AUUPSUpgradeable)
        returns (bool)
    {
        return
            interfaceId == type(IERC721Upgradeable).interfaceId ||
            interfaceId == type(IERC721MetadataUpgradeable).interfaceId ||
            interfaceId == type(AccessControlUpgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /// @notice UUPS Upgradeable authorization function
    /// @dev only the UPGRADER_ROLE can upgrade the contract
    /// @param newImplementation the address of the new implementation
    // solhint-disable-next-line no-empty-blocks
    function _authorizeUpgrade(address newImplementation) internal override onlyRole(UPGRADER_ROLE) {}

    /*
        Modifiers
    */
    /// @notice Modifier that ensures the function is being called by an address that is either a manager or a default admin
    modifier managed() {
        require(hasRole(MANAGER_ROLE, msg.sender) || hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "E04");
        _;
    }
}