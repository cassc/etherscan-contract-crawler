// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// Inheritance
import "../utils/proxy/solidity-0.8.0/ProxyOwned.sol";

// Internal references
import "./Position.sol";
import "./PositionalMarket.sol";
import "./PositionalMarketFactory.sol";
import "../interfaces/IPriceFeed.sol";
import "../interfaces/IPositionalMarket.sol";
import "@openzeppelin/contracts-4.4.1/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-4.4.1/proxy/Clones.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract PositionalMarketFactory is Initializable, ProxyOwned {
    /* ========== STATE VARIABLES ========== */
    address public positionalMarketManager;

    address public positionalMarketMastercopy;
    address public positionMastercopy;

    address public limitOrderProvider;
    address public thalesAMM;

    struct PositionCreationMarketParameters {
        address creator;
        IERC20 _sUSD;
        IPriceFeed _priceFeed;
        bytes32 oracleKey;
        uint strikePrice;
        uint[2] times; // [maturity, expiry]
        uint initialMint;
    }

    function initialize(address _owner) external initializer {
        setOwner(_owner);
    }

    /// @notice createMarket create market function
    /// @param _parameters PositionCreationMarketParameters needed for market creation
    /// @return PositionalMarket created market
    function createMarket(PositionCreationMarketParameters calldata _parameters) external returns (PositionalMarket) {
        require(positionalMarketManager == msg.sender, "Only permitted by the manager.");

        PositionalMarket pom = PositionalMarket(Clones.clone(positionalMarketMastercopy));
        Position up = Position(Clones.clone(positionMastercopy));
        Position down = Position(Clones.clone(positionMastercopy));
        pom.initialize(
            PositionalMarket.PositionalMarketParameters(
                positionalMarketManager,
                _parameters._sUSD,
                _parameters._priceFeed,
                _parameters.creator,
                _parameters.oracleKey,
                _parameters.strikePrice,
                _parameters.times,
                _parameters.initialMint,
                address(up),
                address(down),
                thalesAMM
            )
        );
        emit MarketCreated(
            address(pom),
            _parameters.oracleKey,
            _parameters.strikePrice,
            _parameters.times[0],
            _parameters.times[1],
            _parameters.initialMint
        );
        return pom;
    }

    /// @notice setPositionalMarketManager sets positionalMarketManager value
    /// @param _positionalMarketManager address of the PositionalMarketManager contract
    function setPositionalMarketManager(address _positionalMarketManager) external onlyOwner {
        positionalMarketManager = _positionalMarketManager;
        emit PositionalMarketManagerChanged(_positionalMarketManager);
    }

    /// @notice setPositionalMarketMastercopy sets positionalMarketMastercopy value
    /// @param _positionalMarketMastercopy address of the PositionalMarketMastercopy contract
    function setPositionalMarketMastercopy(address _positionalMarketMastercopy) external onlyOwner {
        positionalMarketMastercopy = _positionalMarketMastercopy;
        emit PositionalMarketMastercopyChanged(_positionalMarketMastercopy);
    }

    /// @notice setPositionMastercopy sets positionMastercopy value
    /// @param _positionMastercopy address of the PositionMastercopy contract
    function setPositionMastercopy(address _positionMastercopy) external onlyOwner {
        positionMastercopy = _positionMastercopy;
        emit PositionMastercopyChanged(_positionMastercopy);
    }

    /// @notice setThalesAMM sets thalesAMM value
    /// @param _thalesAMM address of ThalesAMM contract
    function setThalesAMM(address _thalesAMM) external onlyOwner {
        thalesAMM = _thalesAMM;
        emit SetThalesAMM(_thalesAMM);
    }

    event PositionalMarketManagerChanged(address _positionalMarketManager);
    event PositionalMarketMastercopyChanged(address _positionalMarketMastercopy);
    event PositionMastercopyChanged(address _positionMastercopy);
    event SetThalesAMM(address _thalesAMM);
    event MarketCreated(
        address market,
        bytes32 indexed oracleKey,
        uint strikePrice,
        uint maturityDate,
        uint expiryDate,
        uint initialMint
    );
}