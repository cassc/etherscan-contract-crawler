// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.12;

interface IHYFI_Referrals {
    function DEFAULT_ADMIN_ROLE() external view returns (bytes32);

    function REFERRAL_SETTER() external view returns (bytes32);

    function addMultipleToReferralList(
        uint256 referralDiscount,
        uint256[] memory referralCode
    ) external;

    function addToReferralCodeList(uint256 referralCode) external;

    function addToReferralList(uint256 referralDiscount, uint256 referralCode)
        external;

    function getAllUsedReferralCodeList()
        external
        view
        returns (uint256[] memory);

    function getAmountBoughtWithReferral(uint256 referralCode)
        external
        view
        returns (uint256);

    function getReferralDiscountAmount(uint256 referralCode)
        external
        view
        returns (uint256 discountAmount);

    function getReferralDiscountAmountByRange(uint256 referralCode)
        external
        view
        returns (uint256);

    function getReferralInfo(uint256 amount)
        external
        view
        returns (string[] memory);

    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    function grantRole(bytes32 role, address account) external;

    function hasRole(bytes32 role, address account)
        external
        view
        returns (bool);

    function initialize() external;

    function removeFromReferralList(uint256 referralCode) external;

    function removeReferralInfoLayer(uint256 referralDiscount) external;

    function renounceRole(bytes32 role, address account) external;

    function revokeRole(bytes32 role, address account) external;

    function updateAmountBoughtWithReferral(
        uint256 referralCode,
        uint256 amount
    ) external;

    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}