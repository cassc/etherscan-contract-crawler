// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IStore {
    function setStock(uint256 newStock, uint256 model) external;
    function getStock(uint256 model) external view returns(uint256);
    function getModels() external view returns(uint256);

    function setToken(address token) external;
    function setPrice(uint256 price, uint256 model) external;
    function getModel(uint256 frameId) external view returns(uint256);
    function getPrice(uint256 model) external view returns(uint256);

    function putNewModel(uint256 price) external returns(uint256);

    function buy(address receiver, uint256 quantity, uint256 model) external;
    function buy(address receiver, uint256 price, uint256 quantity, uint256 model, address signer, uint256 check, bytes calldata signature) external;
    function getAccountCheck(address account) external view returns(uint256);

    function gift(address receiver, uint256 quantity, uint256 model) external;

    function setFeePercentage(uint256 newFeePercentage) external;

    function lendFrameWithMoney(
        uint256 frameId,
        uint256 price,
        address token,
        address receiver,
        uint64 expires,
        bool canUpdate
    ) external;
    function lendArtworkWithMoney(
        uint256 frameId,
        uint256 price,
        address _token,
        uint256 receiver,
        uint256 expires
    ) external;

    function burnAndRefund(uint256 frameId, uint256 amount) external;
    function askForRefund(uint256 frameId, uint256 value) external;
}