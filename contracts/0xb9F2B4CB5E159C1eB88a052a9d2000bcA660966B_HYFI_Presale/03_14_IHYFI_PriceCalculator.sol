// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.12;

interface IHYFI_PriceCalculator {
    struct TokenData {
        address tokenAddress;
        uint256 totalAmountBought;
        uint256 decimals;
    }

    function CALCULATOR_SETTER() external view returns (bytes32);

    function DEFAULT_ADMIN_ROLE() external view returns (bytes32);

    function HYFI_SETTER_ROLE() external view returns (bytes32);

    function HYFIexchangeRate() external view returns (uint256);

    function currencyPaymentCalculator(
        uint256 unitAmount,
        uint256 discount,
        uint256 referralCode
    ) external view returns (uint256 paymentAmount);

    function discountAmountCalculator(uint256 discount, uint256 value)
        external
        pure
        returns (uint256 discountAmount);

    function discountPercentageCalculator(uint256 unitAmount, address buyer)
        external
        view
        returns (uint256 discountPrecentage);

    function distrPercWithHYFI() external view returns (uint256);

    function getLatestETHPrice() external view returns (int256);

    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    function getTokenData(string memory token)
        external
        view
        returns (TokenData memory);

    function grantRole(bytes32 role, address account) external;

    function hasRole(bytes32 role, address account)
        external
        view
        returns (bool);

    function initialize(
        address _whitelistCotractAddress,
        address _referralsContractAddress,
        address USDTtokenAddress,
        address USDCtokenAddress,
        address HYFItokenAddress,
        uint256 _unitPrice,
        uint256 _HYFIexchangeRate
    ) external;

    function mixedTokenPaymentCalculator(
        string memory token,
        uint256 unitAmount,
        uint256 discount,
        uint256 referralCode
    )
        external
        view
        returns (uint256 stableCoinPaymentAmount, uint256 HYFIPaymentAmount);

    function renounceRole(bytes32 role, address account) external;

    function revokeRole(bytes32 role, address account) external;

    function setAmountBoughtWithReferral(string memory token, uint256 amount)
        external;

    function setHYFIexchangeRate(uint256 newExchangeRate) external;

    function setNewReferralsImplementation(address newReferrals) external;

    function setNewWhitelistImplementation(address newWhitelist) external;

    function setUnitPrice(uint256 newPrice) external;

    function simpleTokenPaymentCalculator(
        string memory token,
        uint256 unitAmount,
        uint256 discount,
        uint256 referralCode
    ) external view returns (uint256 paymentAmount);

    function supportsInterface(bytes4 interfaceId) external view returns (bool);

    function unitPrice() external view returns (uint256);
}