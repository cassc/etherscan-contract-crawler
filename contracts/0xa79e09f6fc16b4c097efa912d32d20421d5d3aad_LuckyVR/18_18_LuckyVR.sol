// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.14;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

/// @title Lucky VR
/// @author Kfish n Chips
/// @custom:security-contact [email protected]
contract LuckyVR is
    Initializable,
    ERC1155Upgradeable,
    AccessControlUpgradeable,
    UUPSUpgradeable
{
    /// @notice Role assigned to addresses that can perform minting actions
    /// @dev Role can be granted by the DEFAULT_ADMIN_ROLE
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    /// @notice Role assigned to an address that can perform upgrades contract upgrades
    /// @dev Role can be granted by the DEFAULT_ADMIN_ROLE
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
    /// @notice POAP ID starts at 100 in order to avoid clashing commemoration token ids
    uint256 private constant STARTING_POAP_ID = 100;
    /// @notice Enable/disable tokens transfer
    bool private _tokenTransfer;
    /// @notice Setting an owner in order to comply with ownable interfaces
    /// @dev This variable was only added for compatibility with contracts that request an owner
    address public owner;
    /// @dev This variable was only added for compatibility with systems that require it
    string public name;
    /// @dev This variable was only added for compatibility with systems that require it
    string public symbol;
    /// @notice Track the current POAP
    uint256 public currentPoap;
    /// @notice Track the last ID used for POAPs to make sure they are not overwritten
    uint256 private _lastPoapId;
    /// @notice Whether poap minting is active or not
    bool public poapActive;
    /// @dev Track the last years Minted  Address -> Last Year
    mapping(address => uint256) private lastYearMinted;
    /// @notice Contract URI with metadata
    string private _contractURI;

    /// @notice Emitted when the token transfer status change.
    event ToggleTokenTransfer(address sender, bool state);

    /// @notice Emitted when ownership transferred.
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /// @notice ContractURI containing metadata for marketplaces
    /// @return The _contractURI
    function contractURI() external view returns (string memory) {
        return _contractURI;
    }

    /// @notice Initializer called instead of constructor in upgradeable contract
    /// @dev Only called once
    function initialize() external initializer {
        __ERC1155_init(
            "ipfs://QmTqqEun4KWeg8iG6VavfPHpyFuGJjGm3Wu6zfM1P2pNx1/{id}.json"
        );
        __AccessControl_init();
        __UUPSUpgradeable_init();
        _tokenTransfer = false;
        _lastPoapId = 100;
        currentPoap = _lastPoapId;
        owner = msg.sender;
        name = "LuckyVR";
        symbol = "LVR";
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        _grantRole(UPGRADER_ROLE, msg.sender);
        _contractURI = "ipfs://QmQo1nAxQFAschsKMcWi1NrSfuhnPpNZJxpa36TYA5t11t";
    }

    // @notice Transfers ownership of the contract to a new account (`newOwner`)
    /// @dev Can only be called by an address with DEFAULT_ADMIN_ROLE
    /// @param newOwner_ New Owner of the contract
    /// Emits a {OwnershipTransferred} event
    function transferOwnership(address newOwner_)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(newOwner_ != address(0), "LuckyVR: owner cannot be zero");
        address previousOwner = owner;
        owner = newOwner_;

        emit OwnershipTransferred(previousOwner, owner);
    }

    /// @notice Used to set the contractURI
    /// @dev Only callable by an address with DEFAULT_ADMIN_ROLE
    /// @param newContractURI_ The base URI
    function setContractURI(string memory newContractURI_)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(bytes(newContractURI_).length > 0, "LuckyVR: invalid URI");
        _contractURI = newContractURI_;
    }

    /// @notice Create a new POAP and set it to active_ value
    /// @dev POAP tokenIds start from 100
    /// @param active_ Status of new POAP
    function startNewPoap(bool active_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _lastPoapId += 1;
        currentPoap = _lastPoapId;
        poapActive = active_;
    }

    /// @notice Set tokenId_ as current POAP and to active status
    /// @param tokenId_ The existing POAP id
    function setCurrentPoap(uint256 tokenId_, bool active_)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(isValidPoap(tokenId_), "LuckyVR: POAP does not exist");
        currentPoap = tokenId_;
        poapActive = active_;
    }

    /// @notice Change whether POAP minting is active or not
    function togglePOAP() external onlyRole(DEFAULT_ADMIN_ROLE) {
        poapActive = !poapActive;
    }

    /// @notice Will update the base URL of token's URI
    /// @param uri_ New base URL of token's URI
    function setURI(string memory uri_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(bytes(uri_).length > 0, "LuckyVR: invalid URI");
        _setURI(uri_);
    }

    /// @notice Mint current POAP to one address
    /// @param receiver_ Address that will receive the tokens
    /// @param force_ Force mint when POAP minting is NOT active
    function mintCurrentPoap(address receiver_, bool force_)
        external
        onlyRole(MINTER_ROLE)
    {
        if (!force_) require(poapActive, "LuckyVR: POAP is not active");
        require(receiver_ != address(0), "LuckyVR: cannot mint to zero");
        require(
            balanceOf(receiver_, currentPoap) == 0,
            "LuckyVR: already has this POAP"
        );
        _mint(receiver_, currentPoap, 1, "");
    }

    /// @notice Mint a specific POAP to one address
    /// @dev Does not check whether POAP minting is active
    /// @param receiver_ Address that will receive the tokens
    /// @param tokenId_ POAP with LuckyVR
    function mintPoap(address receiver_, uint256 tokenId_)
        public
        onlyRole(MINTER_ROLE)
    {
        require(receiver_ != address(0), "LuckyVR: cannot mint to zero");
        require(
            isValidPoap(tokenId_) && balanceOf(receiver_, tokenId_) == 0,
            "LuckyVR: already has this POAP"
        );
        _mint(receiver_, tokenId_, 1, "");
    }

    /// @notice Mint current POAP to addresses
    /// @dev Does not check whether POAP minting is active
    /// @param receivers_ Addresses that will receive the tokens
    function batchMintPoap(address[] calldata receivers_)
        external
        onlyRole(MINTER_ROLE)
    {
        require(receivers_.length > 0, "LuckyVR: no receivers");
        for (uint256 i = 0; i < receivers_.length; i++) {
            mintPoap(receivers_[i], currentPoap);
        }
    }

    /// @notice Mint to one address Year and current POAP
    /// @dev Iterate through the amount of years, POAP tokenIds start from 100
    /// @param receiver_ Address that will receive the tokens
    /// @param years_ Years with LuckyVR
    function mintWithPoap(address receiver_, uint256 years_)
        external
        onlyRole(MINTER_ROLE)
    {
        mint(receiver_, years_, true);
    }

    /// @notice Mint to multiples addresses including current POAP
    /// @dev Receivers and years lengths must match
    /// @param receivers_ Array of addresses that will receive the tokens
    /// @param years_ Array of years with LuckyVR
    function mintBatchWithPoap(
        address[] calldata receivers_,
        uint256[] calldata years_
    ) external onlyRole(MINTER_ROLE) {
        mintBatch(receivers_, years_, true);
    }

    /// @notice enable/disable Token Transfer
    function toggleTokenTransfer() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _tokenTransfer = !_tokenTransfer;
        emit ToggleTokenTransfer(msg.sender, _tokenTransfer);
    }

    /// @notice Checks if POAP token id exists
    /// @dev POAP tokenIds must be between 100 and the last POAP id
    /// @param tokenId_ The POAP id to check
    function isValidPoap(uint256 tokenId_) public view returns (bool) {
        return tokenId_ >= STARTING_POAP_ID && tokenId_ <= _lastPoapId;
    }

    // The following functions are overrides required by the ERC165 standard
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC1155Upgradeable, AccessControlUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /// @notice Mint to one address
    /// @dev Iterate through the amount of years, POAP tokenIds start from 100
    /// @param receiver_ Address that will receive the tokens
    /// @param years_ Years with LuckyVR
    /// @param withPoap_ Mint with or without POAP
    function mint(
        address receiver_,
        uint256 years_,
        bool withPoap_
    ) public onlyRole(MINTER_ROLE) {
        if (withPoap_) require(poapActive, "LuckyVR: POAP is not active");
        require(
            years_ > lastYearMinted[receiver_],
            "LuckyVR: years already minted"
        );
        uint256 startingYearId = lastYearMinted[receiver_] + 1;
        uint256 tokenCount = years_ - lastYearMinted[receiver_];
        uint256[] memory tokenIds;
        uint256[] memory quantities;
        if (withPoap_ && balanceOf(receiver_, currentPoap) == 0) {
            tokenIds = new uint256[](tokenCount + 1);
            quantities = new uint256[](tokenCount + 1);
            tokenIds[tokenCount] = currentPoap;
            quantities[tokenCount] = 1;
        } else {
            tokenIds = new uint256[](tokenCount);
            quantities = new uint256[](tokenCount);
        }
        for (uint256 i = 0; i < tokenCount; i++) {
            tokenIds[i] = startingYearId + i;
            quantities[i] = 1;
        }
        lastYearMinted[receiver_] = years_;
        _mintBatch(receiver_, tokenIds, quantities, "");
    }

    /// @notice Mint to multiples addresses
    /// @dev Receivers and years lengths must match
    /// @param receivers_ Array of Address that will receive the tokens
    /// @param years_ Years with LuckyVR
    function mintBatch(
        address[] calldata receivers_,
        uint256[] calldata years_,
        bool withPoap_
    ) public onlyRole(MINTER_ROLE) {
        require(
            receivers_.length == years_.length,
            "LuckyVR: receivers and years lengths must match"
        );
        if (withPoap_) require(poapActive, "LuckyVR: POAP is not active");
        for (uint256 i = 0; i < receivers_.length; i++) {
            mint(receivers_[i], years_[i], withPoap_);
        }
    }

    function burnBatch(
        address[] calldata receivers_,
        uint256[] calldata tokenIds_,
        uint256[] calldata quantities_
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(
            receivers_.length == tokenIds_.length && receivers_.length == quantities_.length,
            "LuckyVR: receivers, tokenIds, quantities lengths must match"
        );
        for (uint256 i = 0; i < receivers_.length; i++) {
            _burn(receivers_[i], tokenIds_[i], quantities_[i]);
        }
    }

    /// @notice UUPSUpgradeable authorization
    /// @dev Implementation required by UUPSUpgradeable and restricted to UPGRADER_ROLE
    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyRole(UPGRADER_ROLE)
    {}

    /// @dev Only address with DEFAULT_ADMIN_ROLE can transfer
    ///      unless _tokenTransfer is on
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override(ERC1155Upgradeable) {
        require(
            _tokenTransfer || hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "LuckyVR: transfer not allowed"
        );
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }
}