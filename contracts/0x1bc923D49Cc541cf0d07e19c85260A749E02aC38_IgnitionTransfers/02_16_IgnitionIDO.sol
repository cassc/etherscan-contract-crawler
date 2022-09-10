// SPDX-License-Identifier: MIT

pragma solidity 0.8.5;

import "./IgnitionPools.sol";


/**
* @title IGNITION IDO Contract
* @author Luis Sanchez / Alfredo Lopez: PAID Network 2021.4
* @dev First 2 are moon and galaxy which are the standard pools on every IDO
* @dev the other ones are any other pools that needs to be added to the IDO
*/
contract IgnitionIDO is IgnitionPools {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using LibPool for LibPool.PoolTokenModel;

    event LogFinalize(
        address indexed baseAsset,
        uint8 indexed pool,
        address indexed admin,
        address quoteAsset,
        bool autoTranfer,
        uint8 nextpool,
        uint256 transferAmount
    );

    event LogRevertFinalize(
        address indexed baseAsset,
        uint8 indexed pool,
        address indexed admin,
        address quoteAsset,
        bool autoTranfer,
        uint8 nextpool,
        uint256 transferAmount
    );

    event LogWhiteList(
        address indexed baseAsset,
        uint8 indexed pool,
        bytes32 merkleRoot
    );

    /**
    * @notice Finalized CrownSale Pool Token, and Remove the Rest Amount of Token
    * @notice Removed Token From the Pool and Finalized
    * @dev Only Owner and Project Owner of the IDO
    * @dev Error IGN20 - Pool Token Sale has already started
    * @dev Error IGN52 - Pool is not auto-transfer
    * @param _pool Id of the pool (is important to clarify this number must be order 
    * by priority for handle the Auto Transfer function)
    * @param _poolAddr _poolAddr Address of the baseAsset, and Index of the Mapping in the Smart Contract
    */
    function finalize(uint8 _pool, address _poolAddr)
    external virtual isAdmin(_poolAddr) {

        uint8 nextPoolId = _pool + 1;
        LibPool.PoolTokenModel storage _currentPool = poolTokens[_poolAddr][_pool];
        LibPool.PoolTokenModel storage _nextPool = poolTokens[_poolAddr][nextPoolId];

        if (_pool > 0) {
            uint8 prevPoolId = _pool - 1;
            LibPool.PoolTokenModel storage _prevPool = poolTokens[_poolAddr][prevPoolId];

            if (_prevPool.valid) {
                require(_prevPool.isFinalized(), "IGN61");
            }
        }

        _nextPool.poolIsValid();
        require(block.timestamp > _currentPool.getStartDate(), "IGN20");
        require(_currentPool.isAutoTransfer(), "IGN52");

        LibPool.FallBackModel storage _fallback = fallBacks[_poolAddr][_pool];

        _fallback.fbck_endDate = _currentPool.getEndDate();

        if (_fallback.fbck_endDate > block.timestamp) {
            _currentPool.setEndDate(block.timestamp, STATUS_BOOLEAN);
        }

        _fallback.fbck_finalize = _currentPool.tokenTotalAmount -
            _currentPool.soldAmount;

        _nextPool.tokenTotalAmount = _nextPool.tokenTotalAmount +
            _fallback.fbck_finalize;

        _currentPool.setFinalized();
        _currentPool.tokenTotalAmount = _currentPool.soldAmount;

        emit LogFinalize(
            _poolAddr,
            _pool,
            idoManagers[_poolAddr],
            _currentPool.quoteAsset,
            true,
            nextPoolId,
            _fallback.fbck_finalize
        );
    }

    /**
    * @notice Revert Finalized CrownSale Pool Token status
    * @dev Error IGN20 - Pool Token Sale has already started
    * @dev Error IGN52 - Pool is not auto-transfer
    * @dev Error IGN16 - Pool is not finalized
    * @param _pool Id of the pool (is important to clarify this number must be order 
    * by priority for handle the Auto Transfer function)
    * @param _poolAddr _poolAddr Address of the baseAsset, and Index of the Mapping in the Smart Contract
    */
    function revertFinalize(uint8 _pool, address _poolAddr)
    external virtual isAdmin(_poolAddr) {
        uint8 nextPoolId = _pool + 1;
        LibPool.PoolTokenModel storage _finalizedPool = poolTokens[_poolAddr][_pool];
        LibPool.PoolTokenModel storage _nextPool = poolTokens[_poolAddr][nextPoolId];
        LibPool.FallBackModel memory _fallback = fallBacks[_poolAddr][_pool];

        require(_finalizedPool.isAutoTransfer(), "IGN52");
        require(_finalizedPool.isFinalized(), "IGN16");

        _nextPool.poolIsValid();

        if (_fallback.fbck_endDate > block.timestamp) {
            _finalizedPool.setEndDate(block.timestamp, STATUS_BOOLEAN);
        }

        _nextPool.tokenTotalAmount = _nextPool.tokenTotalAmount -
            _fallback.fbck_finalize;

        _finalizedPool.tokenTotalAmount = _finalizedPool.tokenTotalAmount +
            _fallback.fbck_finalize;

        _finalizedPool.packageData = _finalizedPool.packageData & ~(uint256(1)<<233);

        emit LogRevertFinalize(
            _poolAddr,
            _pool,
            idoManagers[_poolAddr],
            _finalizedPool.quoteAsset,
            true,
            nextPoolId,
            _fallback.fbck_finalize
        );
    }

    /**
    * @notice Add Whitelist
    * @dev Only Owner
    * @dev Error IGN21 - Pool Token Crowd Sale is active or finalized
    * @dev Error IGN58 - Pools and roots array lenghts are not equal
    * @param _pools Id of the pool (is important to clarify this number must be order by priority 
    * for handle the Auto Transfer function)
    * @param _poolAddr Address of the baseAsset, and Index of the Mapping in the Smart Contract
    * @param _merkleRoots root of the merkle three
    */
    function setWhiteList(
        uint8[] calldata _pools,
        address _poolAddr,
        bytes32[] calldata _merkleRoots
    ) external virtual whenNotPaused {
        _isAdmin(_poolAddr);
        require(_pools.length == _merkleRoots.length, "IGN58");

        for (uint i = 0; i < _pools.length; i++) {
            LibPool.PoolTokenModel storage pt = poolTokens[_poolAddr][_pools[i]];
            pt.poolIsValid();
            // require(block.timestamp <= pt.getStartDate(), "IGN21");
            merkleRoots[_poolAddr][_pools[i]] = _merkleRoots[i];

            emit LogWhiteList(_poolAddr, _pools[i], _merkleRoots[i]);
        }
    }
}