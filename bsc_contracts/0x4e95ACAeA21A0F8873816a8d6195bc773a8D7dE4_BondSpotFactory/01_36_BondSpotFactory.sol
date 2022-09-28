// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "../libraries/types/SpotFactoryStorage.sol";
import "../libraries/helper/Errors.sol";
import "../../interfaces/ISpotFactory.sol";
import "../PairManagerBond.sol";

contract BondSpotFactory is
    ISpotFactory,
    SpotFactoryStorage,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable,
    OwnableUpgradeable
{

    modifier onlyAllowedAddress() {
        require(allowedAddress[msg.sender], "!Allowed");
        _;
    }
    function initialize(address _spotHouse) external initializer {
        __ReentrancyGuard_init();
        __Ownable_init();
        __Pausable_init();
        spotHouse = _spotHouse;
    }

    function createBondPairManager(
        address _quoteAsset,
        address _baseAsset,
        uint256 _basisPoint,
        uint256 _BASE_BASIC_POINT,
        uint128 _maxFindingWordsIndex,
        uint128 _initialPip,
        uint64 _expireTime
    ) external nonReentrant onlyAllowedAddress{
        require(
            _quoteAsset != address(0) && _baseAsset != address(0),
            Errors.VL_EMPTY_ADDRESS
        );
        require(_quoteAsset != _baseAsset, Errors.VL_MUST_IDENTICAL_ADDRESSES);
        require(
            pathPairManagers[_baseAsset][_quoteAsset] == address(0),
            Errors.VL_SPOT_MANGER_EXITS
        );

        address _pairManager;

        PairManagerBond pairManager = new PairManagerBond(
            _quoteAsset,
            _baseAsset,
            spotHouse,
            _basisPoint,
            _BASE_BASIC_POINT,
            _maxFindingWordsIndex,
            _initialPip,
            _expireTime,
            msg.sender,
            address(0x00)
        );

        _pairManager = address(pairManager);

        // save
        pathPairManagers[_baseAsset][_quoteAsset] = _pairManager;

        allPairManager[_pairManager] = Pair({
            BaseAsset: _baseAsset,
            QuoteAsset: _quoteAsset
        });

        emit PairManagerCreated(_pairManager);
    }

    function getPairManager(address quoteAsset, address baseAsset)
        external
        view
        override
        returns (address spotManager)
    {
        return pathPairManagers[baseAsset][quoteAsset];
    }

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

    function addPairManagerManual(
        address _pairManager,
        address _baseAsset,
        address _quoteAsset
    ) external onlyAllowedAddress {
        require(
            _quoteAsset != address(0) && _baseAsset != address(0),
            Errors.VL_EMPTY_ADDRESS
        );
        require(_quoteAsset != _baseAsset, Errors.VL_MUST_IDENTICAL_ADDRESSES);
        require(
            pathPairManagers[_baseAsset][_quoteAsset] == address(0),
            Errors.VL_SPOT_MANGER_EXITS
        );

        // save
        pathPairManagers[_baseAsset][_quoteAsset] = _pairManager;

        allPairManager[_pairManager] = Pair({
        BaseAsset: _baseAsset,
        QuoteAsset: _quoteAsset
        });

        emit PairManagerCreated(_pairManager);
    }

    function getQuoteAndBase(address pairManager)
        external
        view
        override
        returns (Pair memory)
    {
        return allPairManager[pairManager];
    }

    function isPairManagerExist(address pairManager)
        external
        view
        override
        returns (bool)
    {
        // Just 1 in 2 address need require != address 0x000
        // Because when we added pair, already require both of them difference address 0x00
        return allPairManager[pairManager].BaseAsset != address(0);
    }

    //------------------------------------------------------------------------------------------------------------------
    // ONLY OWNER FUNCTIONS
    //------------------------------------------------------------------------------------------------------------------

    function setSpotHouse(address newSpotHouse) external nonReentrant onlyOwner {
        spotHouse = newSpotHouse;
    }


    // IMPORTANT
    // This function only for dev. MUST remove when launch production
    function delPairManager(address pairManager) external nonReentrant onlyOwner {
        Pair storage pair = allPairManager[pairManager];
        pathPairManagers[address(pair.BaseAsset)][
            address(pair.QuoteAsset)
        ] = address(0);

        allPairManager[pairManager] = Pair({
            BaseAsset: address(0),
            QuoteAsset: address(0)
        });
    }

    function addAllowedAddress(address _address, bool isAllowed) external onlyOwner {
        allowedAddress[_address] = isAllowed;
    }
}