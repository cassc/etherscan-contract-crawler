// SPDX-Licence-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

enum CollateralType {
    ERC20,
    ERC721,
    ERC1155
}

struct Collateral {
    CollateralType _collateralType;
    uint256 _amount;
    uint256 _tokenId;
    address _collateralAddress;
}

interface ICollateralEscrowV1 {
    /**
     * @notice Deposits a collateral ERC20 token into the escrow.
     * @param _collateralAddress The address of the collateral token.
     * @param _amount The amount to deposit.
     */
    function depositToken(address _collateralAddress, uint256 _amount) external;

    /**
     * @notice Deposits a collateral asset into the escrow.
     * @param _collateralType The type of collateral asset to deposit (ERC721, ERC1155).
     * @param _collateralAddress The address of the collateral token.
     * @param _amount The amount to deposit.
     */
    function depositAsset(
        CollateralType _collateralType,
        address _collateralAddress,
        uint256 _amount,
        uint256 _tokenId
    ) external payable;

    /**
     * @notice Withdraws a collateral asset from the escrow.
     * @param _collateralAddress The address of the collateral contract.
     * @param _amount The amount to withdraw.
     * @param _recipient The address to send the assets to.
     */
    function withdraw(
        address _collateralAddress,
        uint256 _amount,
        address _recipient
    ) external;

    function getBid() external view returns (uint256);

    function initialize(uint256 _bidId) external;
}