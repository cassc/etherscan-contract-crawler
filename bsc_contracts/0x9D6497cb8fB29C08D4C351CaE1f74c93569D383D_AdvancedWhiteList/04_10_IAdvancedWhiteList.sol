// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

//import "IERC721Enumerable.sol";
import "LibEnvelopTypes.sol";

interface IAdvancedWhiteList  {


    event WhiteListItemChanged(
        address indexed asset,
        bool enabledForFee,
        bool enabledForCollateral,
        bool enabledRemoveFromCollateral,
        address transferFeeModel
    );
    event BlackListItemChanged(
        address indexed asset,
        bool isBlackListed
    );
    function getWLItem(address _asset) external view returns (ETypes.WhiteListItem memory);
    function getWLItemCount() external view returns (uint256);
    function getBLItem(address _asset) external view returns (bool);
    function getBLItemCount() external view returns (uint256);
    function enabledForCollateral(address _asset) external view returns (bool);
    function enabledForFee(address _asset) external view returns (bool);
    function enabledRemoveFromCollateral(address _asset) external view returns (bool);
    function rulesEnabled(address _asset, bytes2 _rules) external view returns (bool);
    function validateRules(address _asset, bytes2 _rules) external view returns (bytes2);
}