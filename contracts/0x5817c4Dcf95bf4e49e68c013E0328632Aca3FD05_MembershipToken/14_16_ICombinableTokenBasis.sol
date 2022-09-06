// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./ICombinationToken.sol";
import "./IBasis.sol";

interface ICombinableTokenBasis is IBasis {
    function soldOut() external view returns (bool);

    function child() external view returns (ICombinationToken);

    function setChildAddress(address _child) external;

    function setTransferProhibitedForCombined(bool _prohibited) external;

    function setTransferProhibited(bool _prohibited) external;
}