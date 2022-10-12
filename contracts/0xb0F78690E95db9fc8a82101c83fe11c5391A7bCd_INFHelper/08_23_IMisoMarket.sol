pragma solidity >= 0.6.12;

interface IMisoMarket {

    function init(bytes calldata data) external payable;
    function initMarket( bytes calldata data ) external;
    function marketTemplate() external view returns (uint256);
    function commitTokensFrom(
        address _from,
        uint256 _amount,
        bool readAndAgreedToMarketParticipationAgreement
    ) 
        external;
    function paymentCurrency() external view returns(address);
    function withdrawTokens() external;
    function finalize() external;
}