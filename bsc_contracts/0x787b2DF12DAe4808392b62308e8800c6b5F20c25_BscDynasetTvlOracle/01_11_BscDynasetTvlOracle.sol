// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.15;

import "./interfaces/IDynasetTvlOracle.sol";
import "./interfaces/IDynaset.sol";
import "./interfaces/IUsdcOracle.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract BscDynasetTvlOracle is IDynasetTvlOracle, AccessControl {
    /* ==========  Constants  ========== */
    bytes32 public constant ORACLE_ADMIN = keccak256(abi.encode("ORACLE_ADMIN"));
    
    uint256 public constant USDC_DECIMALS = 18; // BUSD is 18 decimals
    uint256 public constant DYNASET_DECIMALS = 18;
    uint256 public constant RATIO_PRECISION = 1e18;

    /* ==========  Storage  ========== */

    IDynaset public immutable dynaset;
    address public immutable USDC; // BUSD 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56
    IUsdcOracle public immutable usdcOracle;

    /* ==========  Constructor  ========== */

    constructor(address _dynaset, address _usdc, address _usdcOracle) {
        require(_dynaset != address(0), "ERR_DYNASET_INIT");
        require(_usdc!= address(0), "ERR_USDC_INIT");
        require(_usdcOracle!= address(0), "ERR_USDCORACLE_INIT");
        dynaset = IDynaset(_dynaset);
        USDC = _usdc;
        usdcOracle = IUsdcOracle(_usdcOracle);
        _setupRole(ORACLE_ADMIN, msg.sender);
    }

    /* ==========  External Functions  ========== */
    function dynasetTvlUsdc() public view override returns (uint256 totalUSDC) {
        (address[] memory tokens, uint256[] memory amounts) = dynaset.getTokenAmounts();
        uint256 amount;
        for (uint256 i = 0; i < tokens.length; i++) {
            if (tokens[i] == USDC) {
                totalUSDC += amounts[i];
            } else {
                (amount,) = usdcOracle.tokenUsdcValue(tokens[i], amounts[i]);
                totalUSDC += amount;
            }
        }
        return totalUSDC;
    }

    function tokenUsdcValue(address _token, uint256 _amount) external view override returns (uint256 usdcValue) {
        (usdcValue,) = usdcOracle.tokenUsdcValue(_token, _amount);
    }

    // returns token USDC ratios in 18 decimals precision
    function dynasetTokenUsdcRatios() public view returns (address[] memory, uint256[] memory, uint256) {
        (address[] memory tokens, uint256[] memory amounts) = dynaset.getTokenAmounts();
        uint256 totalUSDC = 0;
        uint256[] memory amountsUSDC = new uint256[](tokens.length);
        for (uint256 i = 0; i < tokens.length; i++) {
            if (tokens[i] == USDC) {
                amountsUSDC[i] = amounts[i];
            } else {
                (amountsUSDC[i],) = usdcOracle.tokenUsdcValue(tokens[i], amounts[i]);
            }
            totalUSDC += amountsUSDC[i];
        }
        uint256[] memory ratios = new uint256[](tokens.length);
        for (uint256 i = 0; i < tokens.length; i++) {
            ratios[i] = amountsUSDC[i] * RATIO_PRECISION / totalUSDC;
        }
        return (tokens, ratios, totalUSDC);
    }

    // This method should return 18 decimals precision
    function dynasetUsdcValuePerShare() external view override returns (uint256) {
        uint256 totalSupply = dynaset.totalSupply();
        uint256 totalUsdcValue = dynasetTvlUsdc();
        uint256 netAssetValue = totalUsdcValue * (10**(DYNASET_DECIMALS + DYNASET_DECIMALS - USDC_DECIMALS)) 
                                / totalSupply;
        return netAssetValue;
    }

    /**
     * @dev Updates the prices of multiple tokens.
     *
     * @return updates Array of boolean values indicating which tokens
     * successfully updated their prices.
     */
    function updateDynasetTokenPrices() external returns (bool[] memory updates) {
        return usdcOracle.updateTokenPrices(dynaset.getCurrentTokens());
    }

}