// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import { UUPS } from "./lib/proxy/UUPS.sol";
import { Ownable } from "./lib/utils/Ownable.sol";
import { ERC1967Proxy } from "./lib/proxy/ERC1967Proxy.sol";
import { ICuratorFactory } from "./interfaces/ICuratorFactory.sol";
import { ICurator } from "./interfaces/ICurator.sol";
import { Curator } from "./Curator.sol";

/**
 * @notice Storage contracts
 */
abstract contract CuratorFactoryStorageV1 {
    address public defaultMetadataRenderer;

    mapping(address => mapping(address => bool)) internal isUpgrade;

    uint256[50] __gap;
}

/**
 * @notice Base contract for curation functioanlity. Inherits ERC721 standard from CuratorSkeletonNFT.sol
 *      (curation information minted as non-transferable "listingRecords" to curators to allow for easy integration with NFT indexers)
 * @dev For curation contracts: assumes 1. linear mint order
 * @author [email protected]
 *
 */
contract CuratorFactory is ICuratorFactory, UUPS, Ownable, CuratorFactoryStorageV1 {
    address public immutable curatorImpl;
    bytes32 public immutable curatorHash;

    constructor(address _curatorImpl) payable initializer {
        curatorImpl = _curatorImpl;
        curatorHash = keccak256(abi.encodePacked(type(ERC1967Proxy).creationCode, abi.encode(_curatorImpl, "")));
    }

    function setDefaultMetadataRenderer(address _renderer) external {
        defaultMetadataRenderer = _renderer;

        emit HasNewMetadataRenderer(_renderer);
    }

    function initialize(address _owner, address _defaultMetadataRenderer) external initializer {
        __Ownable_init(_owner);
        defaultMetadataRenderer = _defaultMetadataRenderer;
    }

    function deploy(
        address curationManager,
        string memory name,
        string memory symbol,
        address tokenPass,
        bool initialPause,
        uint256 curationLimit,
        address renderer,
        bytes memory rendererInitializer,
        ICurator.Listing[] memory listings
    ) external returns (address curator) {
        if (renderer == address(0)) {
            renderer = defaultMetadataRenderer;
        }

        curator = address(
            new ERC1967Proxy(
                curatorImpl,
                abi.encodeWithSelector(
                    ICurator.initialize.selector,
                    curationManager,
                    name,
                    symbol,
                    tokenPass,
                    initialPause,
                    curationLimit,
                    renderer,
                    rendererInitializer,
                    listings
                )
            )
        );

        emit CuratorDeployed(curator, curationManager, msg.sender);
    }

    function isValidUpgrade(address _baseImpl, address _newImpl) external view returns (bool) {
        return isUpgrade[_baseImpl][_newImpl];
    }

    function addValidUpgradePath(address _baseImpl, address _newImpl) external onlyOwner {
        isUpgrade[_baseImpl][_newImpl] = true;
        emit RegisteredUpgradePath(_baseImpl, _newImpl);
    }

    function _authorizeUpgrade(address _newImpl) internal override onlyOwner {}
}