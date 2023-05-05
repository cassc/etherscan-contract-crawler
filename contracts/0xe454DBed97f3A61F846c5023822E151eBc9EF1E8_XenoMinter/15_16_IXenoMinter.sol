// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "./ICouponClipper.sol";

interface IXenoMinter is IERC165 {
    function mint(
        address to,
        uint256 count
    ) external payable returns (uint256[] memory);

    function couponMint(
        address to,
        uint256 count,
        Signature memory signature,
        bytes memory coupon
    ) external payable returns (uint256[] memory);

    function allowListMint(
        address to,
        uint256 count,
        Signature memory signature,
        bytes memory coupon
    ) external payable returns (uint256[] memory);

    function paperMint(address _to, uint256 _quantity) external payable;

    function checkGeneralSaleActive(uint256 quantity, uint256 value) external view returns (string memory);

    function checkAllowListSaleActive(uint256 quantity, uint256 value) external view returns (string memory);

    function withdrawEth(uint256 amount) external;

    function upgradeXenoContract(address) external;

    function addManager(address) external;

    function removeManager(address) external;

    function setWithdrawalAddress(address _newWithdrawal) external;

    function getWithdrawalAddress() external view returns (address);

    function setPhasePrices(uint64[3] calldata prices) external;

    function getPhasePrice(uint64 index) external view returns (uint64);

    function calculatePrice(uint256 count) external view returns (uint256);

    function getPresaleCount() external view returns (uint256);

    function setPresaleAvailability(uint256 amount) external;

    function setGeneralSaleActive(bool active) external;

    function setPresaleActive(bool active) external;

    function setPaperAddresses(address[] memory addresses) external;

    function setAllowListSaleActive(bool active) external;

    function generalSaleActive() external view returns (bool);

    function presaleActive() external view returns (bool);

    function allowListSaleActive() external view returns (bool);
}