/**
 * @author NiKa
 */
// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@positionex/matching-engine/contracts/interfaces/IMatchingEngineAMM.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "@positionex/matching-engine/contracts/libraries/helper/Require.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import "./interfaces/ISpotFactory.sol";
import "./libraries/types/SpotFactoryStorage.sol";
import "./libraries/helper/DexErrors.sol";

contract PositionSpotFactory is
    PausableUpgradeable,
    ReentrancyGuardUpgradeable,
    OwnableUpgradeable,
    SpotFactoryStorage
{
    /// @notice initalization the contract
    function initialize() public initializer {
        __ReentrancyGuard_init();
        __Ownable_init();
        __Pausable_init();
    }

    /// @notice create new pair
    /// @param quoteAsset the address of quote
    /// @param baseAsset the address of base
    /// @param basisPoint the number of basis point
    /// @param maxFindingWordsIndex max finding word index can find
    /// @param initialPip the start pip
    /// @param pipRange the pip range of liquidity pool
    /// @param tickSpace tick space for generate orderbook
    function createPairManager(
        address quoteAsset,
        address baseAsset,
        uint256 basisPoint,
        uint128 maxFindingWordsIndex,
        uint128 initialPip,
        uint128 pipRange,
        uint32 tickSpace
    ) external override(ISpotFactory) nonReentrant {
        address creator = msg.sender;
        Require._require(
            quoteAsset != address(0) && baseAsset != address(0),
            DexErrors.DEX_EMPTY_ADDRESS
        );
        Require._require(
            quoteAsset != baseAsset,
            DexErrors.DEX_MUST_IDENTICAL_ADDRESSES
        );
        Require._require(
            pathPairManagers[baseAsset][quoteAsset] == address(0) &&
                pathPairManagers[quoteAsset][baseAsset] == address(0),
            DexErrors.DEX_SPOT_MANGER_EXITS
        );

        Require._require(
            IERC20Metadata(quoteAsset).decimals() == 18 &&
            IERC20Metadata(baseAsset).decimals() == 18,
            DexErrors.DEX_MUST_TOKEN_DECIMALS_18
        );

        Require._require(
            basisPoint > 0 &&
                basisPoint % 2 == 0 &&
                basisPoint <= 8 &&
                maxFindingWordsIndex > 0 &&
                initialPip > 0 &&
                pipRange > 0 &&
                tickSpace > 0,
            DexErrors.DEX_INVALID_PAIR_INFO
        );

        address pair;

        bytes32 salt = keccak256(
            abi.encodePacked(creator, address(this), block.timestamp)
        );

        pair = Clones.cloneDeterministic(
            mappingVersionTemplate[latestVersion],
            salt
        );

        // save
        pathPairManagers[baseAsset][quoteAsset] = pair;

        allPairManager[pair] = Pair({
            BaseAsset: baseAsset,
            QuoteAsset: quoteAsset
        });

        ownerPairManager[pair] = creator;

        IMatchingEngineAMM(pair).initialize(
            IMatchingEngineAMM.InitParams({
                quoteAsset: IERC20(quoteAsset),
                baseAsset: IERC20(baseAsset),
                basisPoint: 10**basisPoint,
                maxFindingWordsIndex: maxFindingWordsIndex,
                initialPip: initialPip,
                pipRange: pipRange,
                tickSpace: tickSpace,
                positionLiquidity: positionLiquidity,
                spotHouse: spotHouse,
                router: positionRouter
            })
        );

        emit PairManagerInitialized(
            quoteAsset,
            baseAsset,
            10**basisPoint,
            maxFindingWordsIndex,
            initialPip,
            creator,
            pair,
            pipRange,
            tickSpace
        );
    }

    /// @notice set staking manager for pair, only owner of pair can set
    /// @param pair address of pair
    /// @param stakingManager address of staking manager
    function setStakingManagerForPair(address pair, address stakingManager)
        public
    {
        address owner = msg.sender;
        require(owner == ownerPairManager[pair], DexErrors.DEX_ONLY_OWNER);
        stakingManagerOfPair[owner][pair] = stakingManager;
        emit StakingForPairAdded(pair, stakingManager, owner);
    }

    /// @notice get staking address from pair address
    /// @param pair address of pair
    function getStakingManager(address pair) public view returns (address) {
        address ownerOfPair = ownerPairManager[pair];
        return stakingManagerOfPair[ownerOfPair][pair];
    }

    /// @notice get pair manager from quote asset and base asset
    /// @param quoteAsset address of quote
    /// @param baseAsset address of base
    /// @return spotManager the address of pair address
    function getPairManager(address quoteAsset, address baseAsset)
        external
        view
        override(ISpotFactory)
        returns (address spotManager)
    {
        return pathPairManagers[baseAsset][quoteAsset];
    }

    /// @notice get pair manager from any two address
    /// @param tokenA address of quote
    /// @param tokenB address of base
    /// @return baseToken the address of base asset
    /// @return quoteToken the address of quote asset
    /// @return pairManager the address of pair address
    function getPairManagerSupported(address tokenA, address tokenB)
        public
        view
        override
        returns (
            address baseToken,
            address quoteToken,
            address pairManager
        )
    {
        if (pathPairManagers[tokenA][tokenB] != address(0)) {
            return (tokenA, tokenB, pathPairManagers[tokenA][tokenB]);
        }
        if (pathPairManagers[tokenB][tokenA] != address(0)) {
            return (tokenB, tokenA, pathPairManagers[tokenB][tokenA]);
        }
    }

    /// @notice get quote and base address from pair manager
    /// @param pairManager address of pair address
    /// @return struct pair with base asset, quote asset and pair manager
    function getQuoteAndBase(address pairManager)
        external
        view
        override(ISpotFactory)
        returns (Pair memory)
    {
        return allPairManager[pairManager];
    }

    /// @notice check pair manager exist in posi dex
    /// @param pairManager address of pair address
    /// @return return bool type, true is exist, false is no
    function isPairManagerExist(address pairManager)
        external
        view
        override(ISpotFactory)
        returns (bool)
    {
        // Just 1 in 2 address needRequire._require != address 0x000
        // Because when we added pair, alreadyRequire._require both of them difference address 0x00
        return allPairManager[pairManager].BaseAsset != address(0);
    }

    //------------------------------------------------------------------------------------------------------------------
    // ONLY OWNER FUNCTIONS
    //------------------------------------------------------------------------------------------------------------------

    function setSpotHouse(address newSpotHouse) external onlyOwner {
        spotHouse = newSpotHouse;
    }

    function setPositionRouter(address newPositionRouter) external onlyOwner {
        positionRouter = newPositionRouter;
    }

    function setFeeShareAmm(uint32 _feeShareAmm) external onlyOwner {
        feeShareAmm = _feeShareAmm;
    }

    function setPositionLiquidity(address _positionLiquidity)
        external
        onlyOwner
    {
        Require._require(
            _positionLiquidity != address(0),
            DexErrors.DEX_EMPTY_ADDRESS
        );
        positionLiquidity = _positionLiquidity;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function addPairManagerManual(
        address _pairManager,
        address _baseAsset,
        address _quoteAsset
    ) external onlyOwner {
        Require._require(
            _quoteAsset != address(0) && _baseAsset != address(0),
            DexErrors.DEX_EMPTY_ADDRESS
        );
        Require._require(
            _quoteAsset != _baseAsset,
            DexErrors.DEX_MUST_IDENTICAL_ADDRESSES
        );
        Require._require(
            pathPairManagers[_baseAsset][_quoteAsset] == address(0),
            DexErrors.DEX_SPOT_MANGER_EXITS
        );

        // save
        pathPairManagers[_baseAsset][_quoteAsset] = _pairManager;

        allPairManager[_pairManager] = Pair({
            BaseAsset: _baseAsset,
            QuoteAsset: _quoteAsset
        });
        ownerPairManager[_pairManager] = msg.sender;
    }

    function updateTemplatePair(address templatePair) public onlyOwner {
        latestVersion++;
        mappingVersionTemplate[latestVersion] = templatePair;
    }

    // IMPORTANT
    // This function only for dev. MUST remove when launch production
    function delPairManager(address pairManager) external onlyOwner {
        Pair storage pair = allPairManager[pairManager];
        pathPairManagers[address(pair.BaseAsset)][
            address(pair.QuoteAsset)
        ] = address(0);

        allPairManager[pairManager] = Pair({
            BaseAsset: address(0),
            QuoteAsset: address(0)
        });
    }

    function addAllowedAddress(address _address, bool allow)
        external
        onlyOwner
    {
        allowedAddressAddPair[_address] = allow;
    }
}