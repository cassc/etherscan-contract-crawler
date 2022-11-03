// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

interface IRoyaltyRegistry {
    function getRoyaltyInfo(address _token) external view returns (address _receiver, uint96 _royaltyRatePercentage);

    function setRoyaltyRateForCollection(
        address _token,
        uint96 _royaltyRate,
        address _royaltyReceiver
    ) external;

    function collectionManager() external view returns (address);

    function collectionAuthorizedSignerAddress() external view returns (address);

    function collectionOwner() external view returns (address);

    function getContractURIForToken() external view returns (string calldata);

    function getTokenPrice(uint256 _formulaType) external view returns (uint256 _price);
}