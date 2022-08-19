// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;
pragma abicoder v2;

interface IRiverBox {
    struct Hierarchy {
        uint16 parentLocationId;
        uint16[] childLocationIds;
    }

    struct Product {
        uint16 locationId;
        uint16 fusionCount; // number of times used to fuse item
        uint32 signature; // properties
        uint256[] parts; // a list token ids which are used to fuse this item
    }

    /* ================ EVENTS ================ */
    /**
     * @dev Emitted when box price is changed.
     * @param from old price
     * @param to new price
     */
    event BoxPriceChanged(uint256 indexed from, uint256 indexed to);

    event BoxAwarded(address indexed payer, uint256 indexed tokenId, uint256 eventTime);

    event FusedItemAwarded(address indexed payer, uint256 indexed tokenId, uint256 eventTime);

    /* ================ UTIL FUNCTIONS ================ */

    /* ================ VIEWS ================ */
    function tokenHierarchy(uint256 locationId) external view returns (Hierarchy memory);

    function tokenDetail(uint256 tokenId) external view returns (Product memory);

    function verifyFusion(uint256[] memory tokenIds) external view returns (bool);

    function tokenURI(uint256 tokenId) external view returns (string memory);

    function implementationVersion() external view returns (string memory);

    /* ================ TRANSACTIONS ================ */
    function buy(uint256 quality, address referrer) external payable;

    function fuse(uint256[] memory tokenIds) external;

    /* ================ ADMIN ACTIONS ================ */
    function setBaseURI(string memory newBaseURI) external;

    function setFuseLock(bool lock) external;

    function setHierarchy(
        uint16[] memory locationIds,
        uint16[] memory parentTokenIds,
        uint16[][] memory listChildTokenIds
    ) external;

    function pause() external;

    function unPause() external;

    function setBoxPrice(uint256 newPrice) external;

    function setRandomGenerator(address newAddress) external;

    function setTokenURI(uint256 tokenId, string memory _tokenURI) external;

    function setShare(
        address _funderAddress,
        address _devAddress,
        address _marketAddress,
        uint8 _devShare,
        uint8 _marketShare
    ) external;

    function withdraw(uint256 amount) external;

    function claim(uint256 amount) external;

    function batchAirDrop(address[] memory receivers, uint256[] memory qualitys) external;
}