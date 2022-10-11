// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.15;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "../interfaces/IUsdcOracle.sol";

contract UsdcOracle is IUsdcOracle, AccessControl {
    /* ==========  Constants  ========== */

    bytes32 public constant ORACLE_ADMIN = keccak256(abi.encode("ORACLE_ADMIN"));
    
    IUsdcOracle public immutable preferredOracle;
    address public immutable USDC;
    
    /* ==========  Storage  ========== */
    IUsdcOracle[] public fallbackOracles;
    uint256 public staleOraclePeriod = 2 days;
    mapping(address => bool) public paused;

    /* ==========  Constructor  ========== */

    constructor(address _preferredOracle, address _usdc) {
        require(_preferredOracle!= address(0), "ERR_PREFERRED_ORACLE_INIT");
        require(_usdc!= address(0), "ERR_USDC_INIT");
        preferredOracle = IUsdcOracle(_preferredOracle);        
        USDC = _usdc;
        _setupRole(ORACLE_ADMIN, msg.sender);
    }

    /* ==========  External Functions  ========== */
    
    function tokenUsdcValue(address _token, uint256 _amount)
        external
        view
        override
        returns (uint256 usdcValue, uint256 oldestObservation)
    {
        if (_token == USDC) {
            return (_amount, block.timestamp);
        }
        uint256 value;
        uint256 observationTimestamp;
        if (!paused[address(preferredOracle)]) {
            try preferredOracle.tokenUsdcValue(_token, _amount)
            returns (uint256 oracleValue, uint256 oracleTimestamp) {
                 value = oracleValue;
                 observationTimestamp = oracleTimestamp;
            } catch {
                value = 0;
                observationTimestamp = 0;
            }
            if (observationTimestamp + staleOraclePeriod > block.timestamp) {
               return (value, observationTimestamp);
            }
        }
        usdcValue = 0;
        uint256 observation = 0;
        for (uint8 i = 0; i < fallbackOracles.length; i++) {
            if (paused[address(address(fallbackOracles[i]))]) continue;
            try fallbackOracles[i].tokenUsdcValue(_token, _amount)
            returns (uint256 oracleValue, uint256 oracleTimestamp) {
                 value = oracleValue;
                 observationTimestamp = oracleTimestamp;
            } catch {
                value = 0;
                observationTimestamp = 0;
            }
            if (observationTimestamp + staleOraclePeriod > block.timestamp && value > usdcValue) {
                usdcValue = value;
                observation = observationTimestamp;
            }            
        }
        require(observation + staleOraclePeriod > block.timestamp, "ERR_STALE_ORACLE");
        return (usdcValue, observation);
    }

    function getPrice(address _base, address _quote) public view override 
      returns (uint256 price, uint256 oldestObservation) {
        if (_base == _quote) {
            uint8 decimals = IERC20Metadata(_base).decimals();
            uint256 amount = 10 ** decimals;
            return (amount, block.timestamp);
        }
        uint256 value;
        uint256 observationTimestamp;
        if (!paused[address(preferredOracle)]) {
            try preferredOracle.getPrice(_base, _quote)
            returns (uint256 oracleValue, uint256 oracleTimestamp) {
                 value = oracleValue;
                 observationTimestamp = oracleTimestamp;
            } catch {
                value = 0;
                observationTimestamp = 0;
            }
            if (observationTimestamp + staleOraclePeriod > block.timestamp) {
               return (value, observationTimestamp);
            }
        }
        price = 0;
        uint256 observation = 0;
        for (uint8 i = 0; i < fallbackOracles.length; i++) {
            if (paused[address(address(fallbackOracles[i]))]) continue;
            try fallbackOracles[i].getPrice(_base, _quote)
            returns (uint256 oracleValue, uint256 oracleTimestamp) {
                 value = oracleValue;
                 observationTimestamp = oracleTimestamp;
            } catch {
                value = 0;
                observationTimestamp = 0;
            }
            if (observationTimestamp + staleOraclePeriod > block.timestamp && value > price) {
                price = value;
                observation = observationTimestamp;
            }            
        }
        require(observation + staleOraclePeriod > block.timestamp, "ERR_STALE_ORACLE");
        return (price, observation);
    }

    function canUpdateTokenPrices() external pure override returns (bool) {
        return true;
    }

    function updateTokenPrices(address[] memory tokens) external returns (bool[] memory updates) {
        updates = new bool[](tokens.length);
        for (uint8 i = 0; i < fallbackOracles.length; i++) {
            if (fallbackOracles[i].canUpdateTokenPrices()) {
               updates = fallbackOracles[i].updateTokenPrices(tokens);
            }
        }
    }

    /* ===========   Admin functions ========= */
    function setFallbackOracles(address[] memory _fallbackOracles) external onlyRole(ORACLE_ADMIN) {
        fallbackOracles = new IUsdcOracle[](_fallbackOracles.length);
        for (uint8 i = 0; i<_fallbackOracles.length; i++) {
            fallbackOracles[i] = IUsdcOracle(_fallbackOracles[i]);
        }
    }

    function setStaleOraclePeriod(uint256 newStaleOraclePeriod) external onlyRole(ORACLE_ADMIN) {
        staleOraclePeriod = newStaleOraclePeriod;
    }
    
    function setPaused(address oracle, bool pausedState) external onlyRole(ORACLE_ADMIN) {
        require(oracle != address(0), "ERR_ZERO_ADDRESS");
        paused[oracle] = pausedState;
    }
    
}