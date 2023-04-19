// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IERC721EnumerableUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/IERC721EnumerableUpgradeable.sol";
import {ClonesUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/ClonesUpgradeable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {OwnableUpgradeable} from "./ownable/OwnableUpgradeable.sol";
import {IVRFNFTRandomDrawFactory} from "./interfaces/IVRFNFTRandomDrawFactory.sol";
import {IVRFNFTRandomDraw} from "./interfaces/IVRFNFTRandomDraw.sol";
import {Version} from "./utils/Version.sol";

/// @notice VRFNFTRandom Draw with NFT Tickets Factory Implementation
/// @author iainnash
contract VRFNFTRandomDrawFactory is
    IVRFNFTRandomDrawFactory,
    OwnableUpgradeable,
    UUPSUpgradeable,
    Version(2)
{
    /// @notice Implementation to clone of the raffle code
    address public immutable implementation;

    mapping(address => uint256) public numberContractsByAddress;

    /// @notice Constructor to set the implementation
    constructor(address _implementation) initializer {
        if (_implementation == address(0)) {
            revert IMPL_ZERO_ADDRESS_NOT_ALLOWED();
        }
        implementation = _implementation;
    }

    function initialize(address _initialOwner) external initializer {
        __Ownable_init(_initialOwner);
        __UUPSUpgradeable_init();
        emit SetupFactory();
    }

    function _keyForAdminAndId(address admin, uint256 id)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(abi.encode(admin, id));
    }

    function getDrawingAddressById(address admin, uint256 id)
        public
        view
        returns (address)
    {
        return
            ClonesUpgradeable.predictDeterministicAddress(
                implementation,
                _keyForAdminAndId(admin, id),
                address(this)
            );
    }

    function getNextDrawingAddress(address admin) external view returns (address) {
        return getDrawingAddressById(admin, numberContractsByAddress[admin]);
    }

    /// @notice Function to make a new drawing
    /// @param settings settings for the new drawing
    function makeNewDraw(IVRFNFTRandomDraw.Settings memory settings)
        external
        returns (address newDrawing, uint256 requestId)
    {
        address admin = msg.sender;

        // TODO
        // Validate token range exists and ownership here?
        // ownerOf(startTokenId) && ownerOf(endTokenId) != 0

        // Clone the contract
        newDrawing = ClonesUpgradeable.cloneDeterministic(
            implementation,
            _keyForAdminAndId(admin, numberContractsByAddress[admin]++)
        );

        // Escrow NFT
        IERC721EnumerableUpgradeable(settings.token).transferFrom(
            msg.sender,
            address(newDrawing),
            settings.tokenId
        );

        // Setup the new drawing
        requestId = IVRFNFTRandomDraw(newDrawing).initialize(admin, settings);

        // Emit event for indexing
        emit SetupNewDrawing(admin, newDrawing);
    }

    /// @notice Allows only the owner to upgrade the contract
    /// @param newImplementation proposed new upgrade implementation
    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyOwner
    {}
}