// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/common/ERC2981Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts/utils/Multicall.sol";

import "../interfaces/IGaslessListingManager.sol";

contract ERC721BurnableV3 is
    Initializable,
    ERC721Upgradeable,
    ERC721BurnableUpgradeable,
    ERC2981Upgradeable,
    OwnableUpgradeable,
    UUPSUpgradeable,
    Multicall
{
    enum ApprovalStatus {
        Default,
        Allow,
        Deny
    }

    string private _baseTokenURI;

    IGaslessListingManager private _gaslessListingManager;

    mapping(address => mapping(address => ApprovalStatus)) private _operatorApprovalsStatus;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        string memory name_,
        string memory symbol_,
        string memory baseTokenURI_,
        address royaltyReceiver_,
        uint96 royaltyBps_,
        uint256 initialSupply_,
        address initialSupplyReceiver_,
        address gaslessListingManager_
    ) public reinitializer(3) {
        __ERC721_init(name_, symbol_);
        __ERC721Burnable_init();
        __Ownable_init();
        __UUPSUpgradeable_init();

        _gaslessListingManager = IGaslessListingManager(gaslessListingManager_);

        // Initialize the contents
        if (bytes(baseTokenURI_).length > 0) {
            _baseTokenURI = baseTokenURI_;
        }

        _setDefaultRoyalty(royaltyReceiver_, royaltyBps_);

        for (uint256 i = 0; i < initialSupply_; i++) {
            // mint the initial supply to the initial owner starting with token ID 1
            _safeMint(initialSupplyReceiver_, i + 1);
        }
    }

    /// @dev Reinitializes the contract after upgrade.
    function reinitialize(
        string memory baseTokenURI_,
        address royaltyReceiver_,
        uint96 royaltyBps_,
        address gaslessListingManager_
    ) public reinitializer(3) {
        _gaslessListingManager = IGaslessListingManager(gaslessListingManager_);

        // Initialize the contents
        if (bytes(baseTokenURI_).length > 0) {
            _baseTokenURI = baseTokenURI_;
        }

        _setDefaultRoyalty(royaltyReceiver_, royaltyBps_);
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    function contractURI() public view returns (string memory) {
        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, "collection")) : "";
    }

    function safeMint(address to_, uint256 tokenId_) external onlyOwner {
        _safeMint(to_, tokenId_);
    }

    /**
     * @dev Checks if an operator address is approved to transact the owner's tokens. Implements gasless listing by
     * automaticlly allowing approval to specified operators.
     * @param owner_ - the address of who owns a token
     * @param operator_ - the address of a user with access to transact the owner's tokens
     */
    function isApprovedForAll(address owner_, address operator_) public view virtual override returns (bool) {
        ApprovalStatus status = _operatorApprovalsStatus[owner_][operator_];

        if (status == ApprovalStatus.Default) {
            return _gaslessListingManager.isApprovedForAll(owner_, operator_);
        }

        return status == ApprovalStatus.Allow;
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Overrides GaslessListingManager's `isApprovedForAll`.
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner_,
        address operator_,
        bool approved_
    ) internal virtual override {
        require(owner_ != operator_, "ERC721: approve to caller");

        _operatorApprovalsStatus[owner_][operator_] = approved_ ? ApprovalStatus.Allow : ApprovalStatus.Deny;

        emit ApprovalForAll(owner_, operator_, approved_);
    }

    /**
     * @dev Sets the royalty info for this contract.
     * @param receiver_ - the address of who should be sent the royalty payment
     * @param royaltyBps_ - the share of the sale price owed as royalty to the receiver, expressed as BPS (1/10,000)
     */
    function setRoyaltyInfo(address receiver_, uint96 royaltyBps_) external onlyOwner {
        _setDefaultRoyalty(receiver_, royaltyBps_);
    }

    /**
     * @dev It's sufficient to restrict upgrades to the owner.
     */
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {} // solhint-disable-line no-empty-blocks

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId_)
        public
        view
        override(ERC721Upgradeable, ERC2981Upgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId_);
    }
}