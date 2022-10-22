pragma solidity 0.8.9;
pragma experimental ABIEncoderV2;

interface IDPPController {
    function init(
        address admin,
        address dppAddress,
        address dppAdminAddress,
        address weth
    ) external;

    function _BASE_TOKEN_() external view returns (address base);

    function _QUOTE_TOKEN_() external view returns (address quote);

    function recommendBaseAndQuote(uint256 shareAmount_)
        external
        view
        returns (uint256 baseAmount, uint256 quoteAmount);
}