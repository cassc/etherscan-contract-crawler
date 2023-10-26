// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 *   __
 *  |  | ___\|/_     ____    ____  _\|/_
 *  |  |/ /\__  \   /    \  /    \ \__  \
 *  |    <  / __ \_|   |  \|   |  \ / __ \_
 *  |__|_ \(____  /|___|  /|___|  /(____  /
 *       \/     \/      \/      \/      \/
 *            __                    __                       __   .__
 *    _______/  |_   ____    ____  |  | __   ____  ______  _/  |_ |__|  ____    ____
 *   /  ___/\   __\ /  _ \ _/ ___\ |  |/ /  /  _ \ \____ \ \   __\|  | /  _ \  /    \
 *   \___ \  |  |  (  <_> )\  \___ |    <  (  <_> )|  |_> > |  |  |  |(  <_> )|   |  \
 *  /____  > |__|   \____/  \___  >|__|_ \  \____/ |   __/  |__|  |__| \____/ |___|  /
 *       \/                     \/      \/         |__|                            \/
 *
 *  @title KNN Stock Option (Vesting)
 *  @author KANNA Team
 *  @custom:github  https://github.com/kanna-coin
 *  @custom:site https://kannacoin.io
 *  @custom:discord https://discord.kannacoin.io
 */
interface IKannaStockOption is IERC165 {
    enum Status {
        Cliff,
        Lock,
        Vesting
    }

    function totalVested() external view returns (uint256);
    function vestingForecast(uint256 date) external view returns (uint256);
    function availableToWithdraw() external view returns (uint256);
    function status() external view returns (Status);
    function withdraw(uint256 amountToWithdraw) external;
    function finalize() external;
    function abort() external;
}