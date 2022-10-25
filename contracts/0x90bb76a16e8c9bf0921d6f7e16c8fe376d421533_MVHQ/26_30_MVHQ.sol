// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "./erc721a/contracts/extensions/ERC721AQueryableUUPSUpgradeable.sol";
import "./erc721a/contracts/extensions/ERC721ABurnableUUPSUpgradeable.sol";
import "./erc721a/contracts/extensions/ERC721AGoverenedUUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";

/// @title MVHQ
/// @author @KfishNFT
/// @notice Metaverse HQ Key Collection
/** @dev Any function which updates state will require a signature from an address with the correct role
    This is an upgradeable contract using UUPSUpgradeable (IERC1822Proxiable / ERC1967Proxy) from OpenZeppelin */
contract MVHQ is
    Initializable,
    AccessControlUpgradeable,
    ERC721AQueryableUUPSUpgradeable,
    ERC721ABurnableUUPSUpgradeable,
    ERC721AGoverenedUUPSUpgradeable,
    IERC1155Receiver
{
    using StringsUpgradeable for uint256;
    /// @notice role assigned to an address that can perform upgrades to the contract
    /// @dev role can be granted by the DEFAULT_ADMIN_ROLE
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
    /// @notice role assigned to addresses that can perform managemenet actions
    /// @dev role can be granted by the DEFAULT_ADMIN_ROLE
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
    /// @notice role assigned to addresses that can perform mint/burn operations
    /// @dev role can be granted by the DEFAULT_ADMIN_ROLE
    bytes32 public constant ORCHESTRATOR_ROLE = keccak256("ORCHESTRATOR_ROLE");
    /// @notice opensea Storefront ERC1155 contract
    ERC1155 public constant OSSF = ERC1155(0x495f947276749Ce646f68AC8c248420045cb7b5e);
    /// @notice opensea Storefront ERC1155 MVHQ Token ID
    uint256 public constant OSMVHQ_TOKENID =
        70196056058896361747704672441801371315898722973429726505227809712513925252572;
    /// @notice flag whether claiming is available or not
    bool public claimActive;
    /// @notice base URI used to retrieve metadata
    /// @dev tokenURI will use .json at the end for each token starting from 1 and ending at 2000
    string public baseURI;
    /// @notice setting an owner in order to comply with ownable interfaces
    /// @dev this variable was only added for compatibility with contracts that request an owner
    address public owner;
    /// @notice a way to keep track of flagged keys that are untransferable
    uint256[] private flaggedKeys;
    /// @notice a way to keep track of flagged addresses that are unable to transfer keys
    address[] private flaggedAddresses;
    /// @notice whale status requirement
    uint256 public whaleRequirement;
    /// @notice whether to refund gas of key claims
    bool public isRefundingGas;
    /// @notice the max amount that will be refunded in key claims
    uint256 public maxRefundAmount;
    /// @notice the gas units buffer for refunds
    uint256 public refundGasBuffer;
    /// @notice current season year start
    uint256 public season;
    /// @notice keeping track of whale tokens to avoid burning them
    mapping(uint256 => bool) private _whaleTokens;

    event KeysClaimed(address indexed sender, uint256 amount);
    event KeyFlagged(address indexed sender, uint256 tokenId);
    event KeyUnflagged(address indexed sender, uint256 tokenId);
    event AddressFlagged(address indexed sender, address flaggedAddress);
    event AddressUnflagged(address indexed sender, address unflaggedAddress);
    event AdminTransfer(address indexed sender, address from, address to, uint256 tokenId);
    event LegacyKeysTransferred(address indexed sender, address to, uint256 quantity);
    event KeyBurned(address indexed sender, uint256 tokenId);
    event OwnershipTransferred(address indexed sender, address previousOwner, address newOwner);
    event BaseURIChanged(address indexed sender, string previousURI, string newURI);
    event WhaleRequirementChanged(address indexed sender, uint256 previousQuantity, uint256 newQuantity);
    event ClaimActiveChanged(address indexed sender, bool active);
    event Refunded(address indexed refunded, uint256 amount);
    event Received(address indexed sender, uint256 amount);
    event KeysMinted(address indexed receiver, uint256[] tokenIds, bool whaleTokens);
    event KeyMinted(address indexed receiver, uint256 tokenId, bool whaleToken);

    /// @notice Initializer function which replaces constructor for upgradeable contracts
    /// @dev This should be called at deploy time
    /// @param baseURI_ the URI with the metadata
    function initialize(string memory baseURI_) public initializer {
        __ERC721A_init("MVHQ", "MVHQ");
        __AccessControl_init();
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        baseURI = baseURI_;
        whaleRequirement = 5;
        owner = msg.sender;
        isRefundingGas = true;
        maxRefundAmount = 0.01 ether;
        refundGasBuffer = 32174;
    }

    /// @notice Callable by users that have legacy MVHQ keys. Their keys will be transferred to this contract in the process
    /// @dev unfortunately Opensea does not allow burning storefront keys unless the sender has all of the supply
    function claimKeys() external isRefunding {
        require(isManagerOrAdmin(msg.sender) || claimActive, "MVHQ: claiming not active");
        require(OSSF.isApprovedForAll(msg.sender, address(this)), "MVHQ: approval required");

        uint256 claimable = OSSF.balanceOf(msg.sender, OSMVHQ_TOKENID);
        require(claimable > 0, "MVHQ: no claimable keys");

        uint256[] memory ids = new uint256[](1);
        uint256[] memory amounts = new uint256[](1);

        ids[0] = OSMVHQ_TOKENID;
        amounts[0] = claimable;

        OSSF.safeTransferFrom(msg.sender, address(this), OSMVHQ_TOKENID, claimable, bytes("0x0"));
        _safeMint(msg.sender, claimable);

        emit KeysClaimed(msg.sender, claimable);
    }

    /// @notice function required to receive eth
    receive() external payable managed {
        emit Received(msg.sender, msg.value);
    }

    /*
        View Functions
    */
    /// @notice check whether an address meets the whale requirement
    /// @param address_ the address to check
    /// @return whether the address is a whale
    function isWhale(address address_) external view returns (bool) {
        return balanceOf(address_) >= whaleRequirement;
    }

    /// @notice Check whether a key has been flagged
    /// @param tokenId_ the key's token id
    function isKeyFlagged(uint256 tokenId_) public view returns (bool) {
        for (uint256 i = 0; i < flaggedKeys.length; i++) {
            if (flaggedKeys[i] == tokenId_) return true;
        }
        return false;
    }

    /// @notice Retrieve list of flagged keys
    function getFlaggedKeys() external view returns (uint256[] memory) {
        return flaggedKeys;
    }

    /// @notice Check whether an address has been flagged
    /// @param address_ the address
    function isAddressFlagged(address address_) public view returns (bool) {
        for (uint256 i = 0; i < flaggedAddresses.length; i++) {
            if (flaggedAddresses[i] == address_) return true;
        }
        return false;
    }

    /// @notice Get list of flagged addresses
    function getFlaggedAddresses() external view returns (address[] memory) {
        return flaggedAddresses;
    }

    /// @notice Balance of legacy MVHQ Keys of an address
    /// @param address_ The address to check balance for
    function balanceOfLegacyKeys(address address_) external view returns (uint256) {
        return OSSF.balanceOf(address_, OSMVHQ_TOKENID);
    }

    /*
        Managed Functions
    */
    /// @notice used to set the whale requirement
    /// @param quantity_ the amount required
    function setWhaleRequirement(uint256 quantity_) external managed {
        uint256 previousQuantity = whaleRequirement;
        whaleRequirement = quantity_;
        emit WhaleRequirementChanged(msg.sender, previousQuantity, quantity_);
    }

    /// @notice used to flag an address and remove the ability for it to transfer keys
    /// @dev callable by admin or manager
    /// @param address_ the address that will be flagged
    function flagAddress(address address_) external managed {
        flaggedAddresses.push(address_);
        emit AddressFlagged(msg.sender, address_);
    }

    /// @notice used to remove the flag of an address and restore the ability for it to transfer keys
    /// @dev callable by admin or manager
    /// @param address_ the address that will be unflagged
    function unflagAddress(address address_) external managed {
        for (uint256 i = 0; i < flaggedAddresses.length; i++) {
            if (flaggedAddresses[i] == address_) {
                flaggedAddresses[i] = flaggedAddresses[flaggedAddresses.length - 1];
                flaggedAddresses.pop();
                break;
            }
        }
        emit AddressUnflagged(msg.sender, address_);
    }

    /// @notice used to flag a key and make it untransferrable
    /// @dev callable by admin or manager
    /// @param tokenId_ the key that will be flagged
    function flagKey(uint256 tokenId_) external managed {
        flaggedKeys.push(tokenId_);
        emit KeyFlagged(msg.sender, tokenId_);
    }

    /// @notice used to remove the flag of a key and restore the ability for it to be transferred
    /// @dev callable by admin or manager
    /// @param tokenId_ the key that will be unflagged
    function unflagKey(uint256 tokenId_) external managed {
        for (uint256 i = 0; i < flaggedKeys.length; i++) {
            if (flaggedKeys[i] == tokenId_) {
                flaggedKeys[i] = flaggedKeys[flaggedKeys.length - 1];
                flaggedKeys.pop();
                break;
            }
        }
        emit KeyUnflagged(msg.sender, tokenId_);
    }

    /*
        Admin Functions
    */
    /// @notice admin transfer of token from one address to another and meant to be used with extreme care
    /// @dev only callable from an address with the admin role
    /// @param from_ the address that holds the tokenId
    /// @param to_ the address which will receive the tokenId
    /// @param tokenId_ the key's tokenId
    function adminTransfer(
        address from_,
        address to_,
        uint256 tokenId_
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _adminTransferFrom(from_, to_, tokenId_);
        emit AdminTransfer(msg.sender, from_, to_, tokenId_);
    }

    /// @notice admin function used to transfer legacy keys to an address
    /// @dev the address can't be the burn address unless the contract holds all legacy keys
    /// @param to_ the address that will receive all the legacy keys
    function transferLegacyKeys(address to_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 balance = OSSF.balanceOf(address(this), OSMVHQ_TOKENID);
        require(balance > 0, "MVHQ: no legacy keys to transfer");
        OSSF.safeTransferFrom(address(this), to_, OSMVHQ_TOKENID, balance, bytes("0x0"));
        emit LegacyKeysTransferred(msg.sender, to_, balance);
    }

    /// @notice this function will burn keys minted from this address
    /// @dev it will not work with legacy keys
    /// @param tokenId_ the key's tokenId
    function burn(uint256 tokenId_) public override onlyRole(DEFAULT_ADMIN_ROLE) {
        _burn(tokenId_, false);
        emit KeyBurned(msg.sender, tokenId_);
    }

    /// @notice toggle the claiming functionality
    /// @param _claimActive whether it will be active or not
    function setClaimActive(bool _claimActive) external onlyRole(DEFAULT_ADMIN_ROLE) {
        claimActive = _claimActive;
        emit ClaimActiveChanged(msg.sender, _claimActive);
    }

    /// @notice Used to set the baseURI for metadata
    /// @param baseURI_ the base URI
    function setBaseURI(string memory baseURI_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        string memory previousURI = baseURI;
        baseURI = baseURI_;
        emit BaseURIChanged(msg.sender, previousURI, baseURI_);
    }

    /// @notice Used to toggle between refunding key claims
    /// @param isRefundingGas_ true to refund
    function setIsRefundingGas(bool isRefundingGas_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        isRefundingGas = isRefundingGas_;
    }

    /// @notice The maximum eth to refund per key claim transaction
    /// @param maxRefundAmount_ the new max refund amount
    function setMaxRefundAmount(uint256 maxRefundAmount_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        maxRefundAmount = maxRefundAmount_;
    }

    /// @notice The gas units buffer for refunds
    /// @dev this is to include the transfer gas itself
    /// @param refundGasBuffer_ the new max refund amount
    function setRefundGasBuffer(uint256 refundGasBuffer_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        refundGasBuffer = refundGasBuffer_;
    }

    /// @notice Set the current season
    function setSeason(uint256 newSeason) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(newSeason > 0, "MVHQ: invalid season");
        season = newSeason;
    }

    /// @notice Withdraw function in case anyone sends ETH to contract by mistake
    function withdraw() external payable onlyRole(DEFAULT_ADMIN_ROLE) {
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(success, "MVHQ: failed to withdraw");
    }

    /// @notice Used to set a new owner value
    /// @dev This is not the same as Ownable and was only added for compatibility
    /// @param newOwner_ the new owner
    function transferOwnership(address newOwner_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        address previousOwner = owner;
        owner = newOwner_;
        emit OwnershipTransferred(msg.sender, previousOwner, newOwner_);
    }

    /// @notice Used to burn a range tokens at the end of a season
    /// @dev Whale tokens and already burned tokens will be skipped
    /// @param initialTokenId_ the first token to be burned
    /// @param endTokenId_ the last token to be burned
    function burnRange(uint256 initialTokenId_, uint256 endTokenId_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(initialTokenId_ > 0 && endTokenId_ <= _totalMinted(), "MVHQ: invalid token range");
        for (uint256 i = initialTokenId_; i <= endTokenId_; i++) {
            if(!_whaleTokens[i] && _exists(i)) {
                _burn(i, false);
            }
        }
    }

    /// @notice Used to burn a batch of token ids owned by a single address
    /// @dev Whale tokens, burned tokens, and wrong ownership will revert
    /// @param tokensOwner_ the owner of the tokens
    /// @param tokenIds_ the tokens to be burned
    function burnBatch(address tokensOwner_, uint256[] calldata tokenIds_) external onlyRole(ORCHESTRATOR_ROLE) {
        for (uint256 i = 0; i < tokenIds_.length; i++) {
            require(_exists(tokenIds_[i]) && ownerOf(tokenIds_[i]) == tokensOwner_, "MVHQ: token not owned by tokensOwner");
            require(!_whaleTokens[tokenIds_[i]], "MVHQ: whale token cannot be burned");
            _burn(tokenIds_[i], false);
        }
    }

    /// @notice Batch minting to a list of receivers
    /// @dev Does not work for whales and regular keys at the same time
    /// @param receivers_ the list of addresses that will receive keys
    /// @param quantities_ the quantities each address will receive
    /// @param whaleMint_ whether the mints correspond to whale tokens or regular ones
    function mintBatch(address[] calldata receivers_, uint256[] calldata quantities_, bool whaleMint_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(receivers_.length == quantities_.length, "MVHQ: receivers and quantities length mismatch");
        for (uint256 i = 0; i < receivers_.length; i++) {
            _mintKeys(receivers_[i], quantities_[i], whaleMint_);
        }
    }

    function mint(address receiver_) external onlyRole(ORCHESTRATOR_ROLE) {
        uint256 nextTokenId = _currentIndex;
        _safeMint(receiver_, 1);
        emit KeyMinted(receiver_, nextTokenId, false);
    }

    /// @notice Batch minting to a list of receivers
    /// @dev Does not work for whales and regular keys at the same time
    /// @param receiver_ the list of addresses that will receive keys
    /// @param quantity_ the quantities each address will receive
    /// @param whaleMint_ whether the mints correspond to whale tokens or regular ones
    function _mintKeys(address receiver_, uint256 quantity_, bool whaleMint_) private {
        uint256 nextTokenId = _currentIndex;
        uint256[] memory tokenIds = new uint256[](quantity_);
        if(whaleMint_) {
            for (uint256 i = 0; i < quantity_; i++) {
                _whaleTokens[nextTokenId] = true;
                tokenIds[i] = nextTokenId++;
            }
        } else {
            for (uint256 i = 0; i < quantity_; i++) {
                tokenIds[i] = nextTokenId++;
            }
        }
        _safeMint(receiver_, quantity_);
        emit KeysMinted(receiver_, tokenIds, whaleMint_);
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
    /// @dev returns baseURI + tokenId.json
    /// @param tokenId the tokenId without offsets
    /// @return the tokenURI with metadata
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
        if (bytes(baseURI).length > 0) {
            return baseURI;
        } else {
            return "";
        }
    }

    /// @notice Override of ERC721A and AccessControlUpgradeable supportsInterface function
    /// @param interfaceId the interfaceId
    /// @return bool if interfaceId is supported or not
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControlUpgradeable, ERC721AUUPSUpgradeable, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IERC721Upgradeable).interfaceId ||
            interfaceId == type(IERC721MetadataUpgradeable).interfaceId ||
            interfaceId == type(AccessControlUpgradeable).interfaceId ||
            interfaceId == type(IERC165).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /// @notice Hook to check whether a key is transferrable
    /// @dev admins can always transfer regardless of whether keys are flagged
    /// @param from address that holds the tokenId
    /// @param to address that will receive the tokenId
    /// @param startTokenId index of first tokenId that will be transferred
    /// @param quantity amount that will be transferred
    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal override {
        if (!hasRole(DEFAULT_ADMIN_ROLE, msg.sender)) {
            require(!isAddressFlagged(from), "MVHQ: key holder address is flagged");
            require(!isAddressFlagged(to), "MVHQ: key receiver address is flagged");
            for (uint256 i = startTokenId; i < startTokenId + quantity; i++) {
                require(!isKeyFlagged(i), "MVHQ: key is flagged");
            }
        }
        super._beforeTokenTransfers(from, to, startTokenId, quantity);
    }

    /// @notice UUPS Upgradeable authorization function
    /// @dev only the UPGRADER_ROLE can upgrade the contract
    /// @param newImplementation the address of the new implementation
    // solhint-disable-next-line no-empty-blocks
    function _authorizeUpgrade(address newImplementation) internal override onlyRole(UPGRADER_ROLE) {}

    function isManagerOrAdmin(address sender_) internal view returns (bool) {
        return hasRole(MANAGER_ROLE, sender_) || hasRole(DEFAULT_ADMIN_ROLE, sender_);
    }

    /// @dev required in order to receive ERC155 tokenIds
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    /// @dev required in order to receive ERC155 tokenIds
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }

    /*
        Modifiers
    */
    /// @notice Used to refund a transaction gas cost
    modifier isRefunding() {
        uint256 initialGas = gasleft() + refundGasBuffer;
        _;
        if (isRefundingGas && address(this).balance >= maxRefundAmount) {
            uint256 gasCost = (initialGas - gasleft()) * tx.gasprice;
            payable(msg.sender).transfer(gasCost > maxRefundAmount ? maxRefundAmount : gasCost);
            emit Refunded(msg.sender, gasCost);
        }
    }

    /// @notice Modifier that ensures the function is being called by an address that is either a manager or a default admin
    modifier managed() {
        require(isManagerOrAdmin(msg.sender), "MVHQ: not authorized");
        _;
    }
}