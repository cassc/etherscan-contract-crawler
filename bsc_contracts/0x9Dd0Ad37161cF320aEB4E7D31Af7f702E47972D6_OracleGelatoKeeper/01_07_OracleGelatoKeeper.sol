// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/IDexUsdOracle.sol";
import "../libs/UniswapV2OracleLibrary.sol";

contract OracleGelatoKeeper is Ownable {
    address public dexUSDOracle;

    constructor() {}

    function setOracle(address _oracle) external onlyOwner {
        require(_oracle != address(0), "Zero address");
        dexUSDOracle = _oracle;
    }

    function checker() external view returns (bool canExec, bytes memory execData) {
        address pair = IDexUsdOracle(dexUSDOracle).pair();
        uint32 blockTimestampLast1Period = IDexUsdOracle(dexUSDOracle).blockTimestampLast1Period();
        (, , uint32 blockTimestamp) = UniswapV2OracleLibrary.currentCumulativePrices(pair);
        uint32 timeElapsed1Period = blockTimestamp - blockTimestampLast1Period;

        uint256 period = IDexUsdOracle(dexUSDOracle).period();
        if (timeElapsed1Period >= period) {
            canExec = true;
        }
    }

    function performUpkeep() external {
        IDexUsdOracle(dexUSDOracle).update();
    }
}