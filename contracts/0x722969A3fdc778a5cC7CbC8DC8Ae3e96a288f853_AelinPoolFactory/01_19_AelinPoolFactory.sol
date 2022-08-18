// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./MinimalProxyFactory.sol";
import "./AelinPool.sol";

/**
 * @dev the factory contract allows an Aelin sponsor to permissionlessly create new pools
 */
contract AelinPoolFactory is MinimalProxyFactory {
    address public immutable AELIN_TREASURY;
    address public immutable AELIN_POOL_LOGIC;
    address public immutable AELIN_DEAL_LOGIC;
    address public immutable AELIN_ESCROW_LOGIC;

    constructor(
        address _aelinPoolLogic,
        address _aelinDealLogic,
        address _aelinTreasury,
        address _aelinEscrow
    ) {
        require(_aelinPoolLogic != address(0), "cant pass null pool address");
        require(_aelinDealLogic != address(0), "cant pass null deal address");
        require(_aelinTreasury != address(0), "cant pass null treasury address");
        require(_aelinEscrow != address(0), "cant pass null escrow address");
        AELIN_POOL_LOGIC = _aelinPoolLogic;
        AELIN_DEAL_LOGIC = _aelinDealLogic;
        AELIN_TREASURY = _aelinTreasury;
        AELIN_ESCROW_LOGIC = _aelinEscrow;
    }

    /**
     * @dev the method a sponsor calls to create a pool
     */
    function createPool(IAelinPool.PoolData calldata _poolData) external returns (address) {
        require(_poolData.purchaseToken != address(0), "cant pass null token address");
        address aelinPoolAddress = _cloneAsMinimalProxy(AELIN_POOL_LOGIC, "Could not create new deal");
        AelinPool aelinPool = AelinPool(aelinPoolAddress);
        aelinPool.initialize(_poolData, msg.sender, AELIN_DEAL_LOGIC, AELIN_TREASURY, AELIN_ESCROW_LOGIC);

        emit CreatePool(
            aelinPoolAddress,
            string(abi.encodePacked("aePool-", _poolData.name)),
            string(abi.encodePacked("aeP-", _poolData.symbol)),
            _poolData.purchaseTokenCap,
            _poolData.purchaseToken,
            _poolData.duration,
            _poolData.sponsorFee,
            msg.sender,
            _poolData.purchaseDuration,
            _poolData.allowListAddresses.length > 0
        );

        return aelinPoolAddress;
    }

    event CreatePool(
        address indexed poolAddress,
        string name,
        string symbol,
        uint256 purchaseTokenCap,
        address indexed purchaseToken,
        uint256 duration,
        uint256 sponsorFee,
        address indexed sponsor,
        uint256 purchaseDuration,
        bool hasAllowList
    );
}