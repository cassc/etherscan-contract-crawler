pragma solidity >=0.5.16;
interface IZirconPylon {
    function initialized() external view returns (uint);
//    function anchorPoolTokenAddress() external view returns (address);
//    function floatPoolTokenAddress() external view returns (address);
//    function energyAddress() external view returns (address);
    function gammaMulDecimals() external view returns (uint);
    function isFloatReserve0() external view returns (bool);
    function virtualAnchorBalance() external view returns (uint);
    function virtualFloatBalance() external view returns (uint);
    function p2x() external view returns (uint);
    function p2y() external view returns (uint);
    function lastRootKTranslated() external view returns (uint);
    function formulaSwitch() external view returns (bool);
    function lastPrice() external view returns (uint);
    function EMABlockNumber() external view returns (bool);
    function getSyncReserves() external view returns  (uint112 _reserve0, uint112 _reserve1);
    // Called once by the factory at time of deployment
    // @_floatPoolToken -> Contains Address Of Float PT
    // @_anchorPoolToken -> Contains Address Of Anchor PT
    // @token0 -> Float token
    // @token1 -> Anchor token
    function initMigratedPylon(uint _gamma, uint _vab, bool _formulaSwitch) external;
    function initialize(address _floatPoolTokenAddress, address _anchorPoolTokenAddress, address _floatToken, address _anchorToken, address _pairAddress, address _pairFactoryAddress, address _energy, address _energyRev) external;
    // On init pylon we have to handle two cases
    // The first case is when we initialize the pair through the pylon
    // And the second one is when initialize the pylon with a pair al ready existing
    function initPylon(address _to) external returns (uint floatLiquidity, uint anchorLiquidity);
    // External Function called to mint pool Token
    // Liquidity have to be sent before
    function mintPoolTokens(address to, bool isAnchor) external returns (uint liquidity);
//    function mintAsync100(address to, bool isAnchor) external returns (uint liquidity);
    function mintAsync(address to, bool shouldMintAnchor) external returns (uint liquidity);
    // Burn Async send both tokens 50-50
    // Liquidity has to be sent before
    function burnAsync(address _to, bool _isAnchor) external returns (uint amount0, uint amount1);
    // Burn send liquidity back to user burning Pool tokens
    // The function first uses the reserves of the Pylon
    // If not enough reserves it burns The Pool Tokens of the pylon
    function burn(address _to, bool _isAnchor) external returns (uint amount);
    function changeEnergyAddress(address _energyAddress, address _energyRevAddress) external;
    function migrateLiquidity(address newPylon) external;

    }