// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9 <0.9.0;

import "./Sale.sol";
import "./SalesRecord.sol";

interface IERC721MultiSale {
    function getCurrentSale()
        external
        returns (
            uint8,
            SaleType,
            uint256,
            uint256
        );
    
    function getBuyCount() external view returns(uint256);

    function setCurrentSale(Sale calldata sale) external;

    function setWithdrawAddress(address payable value) external;

    function setMaxSupply(uint256 value) external;

    function pause() external;
    
    function unpause() external;
}