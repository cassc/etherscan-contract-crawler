// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


interface IWineMarketPlace {

    function initialize(
        address manager_,
        address[] memory allowedCurrencies_,
        uint256 orderFeeInPromille_
    ) external;

//////////////////////////////////////// Settings

    function _editAllowedCurrency(address currency_, bool value) external;

    function _editOrderFeeInPromille(uint256 orderFeeInPromille_) external;

//////////////////////////////////////// Owner

    event CreateOrder(
        address seller,
        uint256 poolId,
        uint256 tokenId,
        address currency,
        uint256 price,
        uint256 orderId
    );
    event CancelOrder(
        uint256 orderId
    );

    event ExecuteOrder(
        address buyer,
        uint256 orderId,
        uint256 orderFee,
        uint256 storageFee
    );

    function createOrder(
        uint256 poolId,
        uint256 tokenId,
        address currency,
        uint256 price
    ) external returns (uint256 orderId);

    function cancelOrder(uint256 orderId) external;

    function executeOrder(uint256 orderId) external;

//////////////////////////////////////// Owner

    function withdrawFee(address currencyAddress, address to, uint256 amount) external;

}