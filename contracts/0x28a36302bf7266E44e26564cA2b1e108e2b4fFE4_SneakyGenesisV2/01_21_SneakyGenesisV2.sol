// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "erc721a/contracts/extensions/ERC721AQueryableUUPSUpgradeable.sol";
import "erc721a/contracts/extensions/ERC721ABurnableUUPSUpgradeable.sol";
import "erc721a/contracts/extensions/ERC721AGoverenedUUPSUpgradeable.sol";

/// @title SneakyGenesis
/// @author @KfishNFT
/// @notice Sneaky Genesis Pass Collection
/** @dev Any function which updates state will require a signature from an address with the correct role
    This is an upgradeable contract using UUPSUpgradeable (IERC1822Proxiable / ERC1967Proxy) from OpenZeppelin */
contract SneakyGenesisV2 is
    Initializable,
    AccessControlUpgradeable,
    ERC721AQueryableUUPSUpgradeable,
    ERC721ABurnableUUPSUpgradeable,
    ERC721AGoverenedUUPSUpgradeable
{
    /// @notice role assigned to an address that can perform upgrades to the contract
    /// @dev role can be granted by the DEFAULT_ADMIN_ROLE
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
    /// @notice role assigned to addresses that can perform managemenet actions
    /// @dev role can be granted by the DEFAULT_ADMIN_ROLE
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
    /// @notice role assigned to addresses that can mint passes
    /// @dev role can be granted by the DEFAULT_ADMIN_ROLE
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    /// @notice base URI used to retrieve metadata
    string public baseURI;
    /// @notice setting an owner in order to comply with ownable interfaces
    /// @dev this variable was only added for compatibility with contracts that request an owner
    address public owner;
    /// @notice a way to keep track of flagged passes that are untransferable
    mapping(uint256 => uint256) private flaggedPasses;
    /// @notice reverse map of flagged passes used for insertion/deletion
    mapping(uint256 => uint256) private reversedFlaggedPasses;
    /// @notice the newest flagged pass
    uint256 private flaggedPassHead;
    /// @notice a way to keep track of flagged addresses that are unable to transfer passes
    mapping(address => address) private flaggedAddresses;
    /// @notice reverse map of flagged addresses used for insertion/deletion
    mapping(address => address) private reversedFlaggedAddresses;
    /// @notice the newest flagged address
    address private flaggedAddressHead;
    /// @notice whether refunding is enabled
    bool public isRefundingGas;
    /// @notice toggle minting
    bool public mintingActive;
    /// @notice the max amount that will be refunded
    uint256 public maxRefundAmount;
    /// @notice the gas units buffer for refunds
    uint256 public refundGasBuffer;
    /// @notice keep track of flagged addresses count
    uint256 private flaggedAddressesCount;
    /// @notice keep track of flagged passes count
    uint256 private flaggedPassesCount;
    /// @notice lock transfers
    bool private transfersLocked;

    event PassFlagged(address indexed sender, uint256 tokenId);
    event PassUnflagged(address indexed sender, uint256 tokenId);
    event AddressFlagged(address indexed sender, address flaggedAddress);
    event AddressUnflagged(address indexed sender, address unflaggedAddress);
    event AdminTransfer(address indexed sender, address from, address to, uint256 tokenId);
    event PassBurned(address indexed sender, uint256 tokenId);
    event OwnershipTransferred(address indexed sender, address previousOwner, address newOwner);
    event BaseURIChanged(address indexed sender, string previousURI, string newURI);
    event Refunded(address indexed refunded, uint256 amount);
    event Received(address indexed sender, uint256 amount);
    event TransfersLockedChanged(address indexed sender, bool locked);

    /// @notice Initializer function which replaces constructor for upgradeable contracts
    /// @dev This should be called at deploy time
    function initialize() external initializer {
        __ERC721A_init("SneakyGenesis", "SneakyGenesis");
        __AccessControl_init();
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(UPGRADER_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        baseURI = "ipfs://QmQKRTWD93THhBdyGsptkfrXWxbA2NH7CnAnzP8N9syJ15";
        owner = msg.sender;
        isRefundingGas = false;
        maxRefundAmount = 0.01 ether;
        refundGasBuffer = 32196;
        mintingActive = true;
    }

    /// @notice Callable by an address with the MINTER_ROLE
    /// @dev Refunds will only happen if it is enabled
    function mintTo(address[] calldata receivers_, uint256[] calldata quantities_)
        external
        isRefunding
        onlyRole(MINTER_ROLE)
    {
        require(mintingActive, "SneakyGenesis: minting is not active");
        require(receivers_.length == quantities_.length, "SneakyGenesis: receivers length does not equal quantities");

        for (uint256 i = 0; i < receivers_.length; i++) {
            require(receivers_[i] != address(0), "SneakyGenesis: cannot mint to zero address");

            _safeMint(receivers_[i], quantities_[i]);
        }
    }

    /// @notice function required to receive eth
    receive() external payable managed {
        emit Received(msg.sender, msg.value);
    }

    /*
        View Functions
    */
    /// @notice Check whether a pass has been flagged
    /// @param tokenId_ the pass's token id
    function isPassFlagged(uint256 tokenId_) public view returns (bool) {
        return flaggedPasses[tokenId_] != 0 || flaggedPassHead == tokenId_;
    }

    /// @notice Retrieve list of flagged passes
    function getFlaggedPasses() external view returns (uint256[] memory) {
        uint256[] memory _flaggedPasses = new uint256[](flaggedPassesCount);
        uint256 currentTokenId = 0;
        for (uint256 i = 0; i < flaggedPassesCount; i++) {
            _flaggedPasses[i] = flaggedPasses[currentTokenId];
            currentTokenId = flaggedPasses[currentTokenId];
        }
        return _flaggedPasses;
    }

    /// @notice Check whether an address has been flagged
    /// @param address_ the address
    function isAddressFlagged(address address_) public view returns (bool) {
        return flaggedAddresses[address_] != address(0) || flaggedAddressHead == address_;
    }

    /// @notice Get list of flagged addresses
    function getFlaggedAddresses() external view returns (address[] memory) {
        address[] memory _flaggedAddresses = new address[](flaggedAddressesCount);
        address currentAddress = address(0);
        for (uint256 i = 0; i < flaggedAddressesCount; i++) {
            _flaggedAddresses[i] = flaggedAddresses[currentAddress];
            currentAddress = flaggedAddresses[currentAddress];
        }
        return _flaggedAddresses;
    }

    /*
        Managed Functions
    */
    /// @notice used to flag an address and remove the ability for it to transfer passes
    /// @dev callable by admin or manager
    /// @param address_ the address that will be flagged
    function flagAddress(address address_) external managed {
        require(address_ != address(0), "SneakyGenesis: cannot flag zero address");
        require(!isAddressFlagged(address_), "SneakyGenesis: address already flagged");
        flaggedAddresses[flaggedAddressHead] = address_;
        reversedFlaggedAddresses[address_] = flaggedAddressHead;
        flaggedAddressHead = address_;
        flaggedAddressesCount += 1;
        emit AddressFlagged(msg.sender, address_);
    }

    /// @notice used to remove the flag of an address and restore the ability for it to transfer passes
    /// @dev callable by admin or manager
    /// @param address_ the address that will be unflagged
    function unflagAddress(address address_) external managed {
        require(address_ != address(0), "SneakyGenesis: cannot unflag zero address");
        require(isAddressFlagged(address_), "SneakyGenesis: address not flagged");
        if (address_ == flaggedAddressHead) {
            flaggedAddressHead = reversedFlaggedAddresses[address_];
            flaggedAddresses[flaggedAddressHead] = address(0);
        } else {
            address previousAddress = reversedFlaggedAddresses[address_];
            address nextAddress = flaggedAddresses[address_];
            flaggedAddresses[previousAddress] = nextAddress;
            reversedFlaggedAddresses[nextAddress] = previousAddress;
        }
        flaggedAddressesCount -= 1;

        emit AddressUnflagged(msg.sender, address_);
    }

    /// @notice used to flag a pass and make it untransferrable
    /// @dev callable by admin or manager
    /// @param tokenId_ the pass that will be flagged
    function flagPass(uint256 tokenId_) external managed {
        // require(_exists(tokenId_), "SneakyGenesis: pass does not exist");
        require(!isPassFlagged(tokenId_), "SneakyGenesis: pass already flagged");
        flaggedPasses[flaggedPassHead] = tokenId_;
        reversedFlaggedPasses[tokenId_] = flaggedPassHead;
        flaggedPassHead = tokenId_;
        flaggedPassesCount += 1;
        emit PassFlagged(msg.sender, tokenId_);
    }

    /// @notice used to remove the flag of a pass and restore the ability for it to be transferred
    /// @dev callable by admin or manager
    /// @param tokenId_ the pass that will be unflagged
    function unflagPass(uint256 tokenId_) external managed {
        // require(_exists(tokenId_), "SneakyGenesis: pass does not exist");
        require(isPassFlagged(tokenId_), "SneakyGenesis: pass not flagged");
        if (tokenId_ == flaggedPassHead) {
            flaggedPassHead = reversedFlaggedPasses[tokenId_];
            flaggedPasses[flaggedPassHead] = 0;
        } else {
            uint256 previousPass = reversedFlaggedPasses[tokenId_];
            uint256 nextPass = flaggedPasses[tokenId_];
            flaggedPasses[previousPass] = nextPass;
            reversedFlaggedPasses[nextPass] = previousPass;
        }
        flaggedPassesCount -= 1;

        emit PassUnflagged(msg.sender, tokenId_);
    }

    /*
        Admin Functions
    */
    /// @notice admin transfer of token from one address to another and meant to be used with extreme care
    /// @dev only callable from an address with the admin role
    /// @param from_ the address that holds the tokenId
    /// @param to_ the address which will receive the tokenId
    /// @param tokenId_ the pass's tokenId
    function adminTransfer(
        address from_,
        address to_,
        uint256 tokenId_
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _adminTransferFrom(from_, to_, tokenId_);
        emit AdminTransfer(msg.sender, from_, to_, tokenId_);
    }

    /// @notice this function will burn passes minted from this address
    /// @dev it is only callable from DEFAULT_ADMIN_ROLE
    /// @param tokenId_ the pass's tokenId
    function burn(uint256 tokenId_) public override onlyRole(DEFAULT_ADMIN_ROLE) {
        _burn(tokenId_, false);
        emit PassBurned(msg.sender, tokenId_);
    }

    /// @notice Toggle minting
    function setMintingActive() external onlyRole(DEFAULT_ADMIN_ROLE) {
        mintingActive = !mintingActive;
    }

    /// @notice Used to set the baseURI for metadata
    /// @param baseURI_ the base URI
    function setBaseURI(string memory baseURI_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        string memory previousURI = baseURI;
        baseURI = baseURI_;
        emit BaseURIChanged(msg.sender, previousURI, baseURI_);
    }

    /// @notice Used to toggle refunding tx costs
    /// @param isRefundingGas_ true to refund
    function setIsRefundingGas(bool isRefundingGas_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        isRefundingGas = isRefundingGas_;
    }

    /// @notice The maximum eth to refund per transaction
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

    /// @notice Withdraw function in case anyone sends ETH to contract by mistake or refunds leftovers
    function withdraw() external payable onlyRole(DEFAULT_ADMIN_ROLE) {
        payable(owner).transfer(address(this).balance);
    }

    /// @notice Used to set a new owner value
    /// @dev This is not the same as Ownable and was only added for compatibility
    /// @param newOwner_ the new owner
    function transferOwnership(address newOwner_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(newOwner_ != address(0), "SneakyGenesis: new owner cannot be zero address");
        address previousOwner = owner;
        owner = newOwner_;
        emit OwnershipTransferred(msg.sender, previousOwner, newOwner_);
    }

    /// @notice Lock transfers
    /// @dev This will make tokens only transferrable by DEFAULT_ADMIN_ROLE
    /// @param transfersLocked_ whether to lock transfers
    function lockTransfers(bool transfersLocked_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        transfersLocked = transfersLocked_;
        emit TransfersLockedChanged(msg.sender, transfersLocked);
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
    /// @dev returns baseURI
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
        override(AccessControlUpgradeable, ERC721AUUPSUpgradeable)
        returns (bool)
    {
        return
            interfaceId == type(IERC721Upgradeable).interfaceId ||
            interfaceId == type(IERC721MetadataUpgradeable).interfaceId ||
            interfaceId == type(AccessControlUpgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /// @notice Hook to check whether a pass is transferrable
    /// @dev admins can always transfer regardless of whether passes are flagged
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
        if (hasRole(DEFAULT_ADMIN_ROLE, msg.sender) && from != address(0)) {
            super._beforeTokenTransfers(from, to, startTokenId, quantity);
        } else if (hasRole(MINTER_ROLE, msg.sender) && from == address(0)) {
            super._beforeTokenTransfers(from, to, startTokenId, quantity);
        } else {
            require(!transfersLocked, "SneakyGenesis: transfers are locked");
            require(!isAddressFlagged(from), "SneakyGenesis: pass holder address is flagged");
            require(!isAddressFlagged(to), "SneakyGenesis: pass receiver address is flagged");
            for (uint256 i = startTokenId; i < startTokenId + quantity; i++) {
                require(!isPassFlagged(i), "SneakyGenesis: pass is flagged");
            }
            super._beforeTokenTransfers(from, to, startTokenId, quantity);
        }
    }

    /// @notice UUPS Upgradeable authorization function
    /// @dev only the UPGRADER_ROLE can upgrade the contract
    /// @param newImplementation the address of the new implementation
    // solhint-disable-next-line no-empty-blocks
    function _authorizeUpgrade(address newImplementation) internal override onlyRole(UPGRADER_ROLE) {}

    /*
        Modifiers
    */
    /// @notice Used to refund a transaction gas cost
    modifier isRefunding() {
        uint256 initialGas = gasleft() + refundGasBuffer;
        _;
        if (isRefundingGas && address(this).balance >= maxRefundAmount) {
            uint256 gasCost = (initialGas - gasleft()) * tx.gasprice;
            emit Refunded(msg.sender, gasCost);

            payable(msg.sender).transfer(gasCost > maxRefundAmount ? maxRefundAmount : gasCost);
        }
    }

    /// @notice Modifier that ensures the function is being called by an address that is either a manager or a default admin
    modifier managed() {
        require(
            hasRole(MANAGER_ROLE, msg.sender) || hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "SneakyGenesis: not authorized"
        );
        _;
    }
}