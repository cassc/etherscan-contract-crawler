// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

import "../interfaces/IERC20.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

import "../AnteTest.sol";

// Ante Test that the top 5 assets do not get rugged. (lose 90% of value.)
contract AnteMultichainBridgeRugTest is AnteTest("Top 5 assets do not lose 90% value.") {
    // Externally Owned Account - https://etherscan.io/address/0x13B432914A996b0A48695dF9B2d701edA45FF264
    address public constant eoaAnyswapBSCBridgeAddr = 0x13B432914A996b0A48695dF9B2d701edA45FF264;

    // Selecting the top 4 ERC-20 Tokens + ETH on Anyway Bridge

    //TRVL - https://etherscan.io/address/0xd47bDF574B4F76210ed503e0EFe81B58Aa061F3d
    address public constant trvlAddr = 0xd47bDF574B4F76210ed503e0EFe81B58Aa061F3d;

    //Super - https://etherscan.io/address/0xe53EC727dbDEB9E2d5456c3be40cFF031AB40A55
    address public constant superAddr = 0xe53EC727dbDEB9E2d5456c3be40cFF031AB40A55;

    //mtlx - https://etherscan.io/address/0x2e1E15C44Ffe4Df6a0cb7371CD00d5028e571d14
    address public constant mtlxAddr = 0x2e1E15C44Ffe4Df6a0cb7371CD00d5028e571d14;

    //TetherUSD - https://etherscan.io/address/0xdAC17F958D2ee523a2206206994597C13D831ec7
    address public constant tetherAddr = 0xdAC17F958D2ee523a2206206994597C13D831ec7;

    IERC20 public trvlToken;
    IERC20 public superToken;
    IERC20 public mtlxToken;
    IERC20 public tetherToken;

    uint256 public immutable trvlBalanceAtDeploy;
    uint256 public immutable superBalanceAtDeploly;
    uint256 public immutable mtlxBalanceAtDeploy;
    uint256 public immutable tetherBalanceAtDeploy;
    uint256 public immutable ethBalanceAtDeploy;

    constructor() {
        protocolName = "Anyswap: BSC Bridge";
        testedContracts = [eoaAnyswapBSCBridgeAddr];

        trvlToken = IERC20(trvlAddr);
        superToken = IERC20(superAddr);
        mtlxToken = IERC20(mtlxAddr);
        tetherToken = IERC20(tetherAddr);

        trvlBalanceAtDeploy = trvlToken.balanceOf(eoaAnyswapBSCBridgeAddr);
        superBalanceAtDeploly = superToken.balanceOf(eoaAnyswapBSCBridgeAddr);
        mtlxBalanceAtDeploy = mtlxToken.balanceOf(eoaAnyswapBSCBridgeAddr);
        tetherBalanceAtDeploy = tetherToken.balanceOf(eoaAnyswapBSCBridgeAddr);
        ethBalanceAtDeploy = address(eoaAnyswapBSCBridgeAddr).balance;
    }

    function checkTestPasses() public view override returns (bool) {
        return
            trvlBalanceAtDeploy <= trvlToken.balanceOf(eoaAnyswapBSCBridgeAddr) * 10 &&
            superBalanceAtDeploly <= superToken.balanceOf(eoaAnyswapBSCBridgeAddr) * 10 &&
            mtlxBalanceAtDeploy <= mtlxToken.balanceOf(eoaAnyswapBSCBridgeAddr) * 10 &&
            tetherBalanceAtDeploy <= tetherToken.balanceOf(eoaAnyswapBSCBridgeAddr) * 10 &&
            ethBalanceAtDeploy <= address(eoaAnyswapBSCBridgeAddr).balance * 10;
    }
}