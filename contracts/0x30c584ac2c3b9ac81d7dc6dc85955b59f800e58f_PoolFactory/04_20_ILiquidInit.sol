// SPDX-License-Identifier: WISE

pragma solidity =0.8.17;

interface ILiquidInit {

    function initialise(
        // ERC20 for loans
        address _poolToken,
        // Address used for Chainlink oracle
        address _chainLinkFeedAddress,
        // Determine how quickly the interest rate changes
        uint256 _multiplicationFactor,
        // Maximal factor every NFT can be collateralised
        uint256 _maxCollateralFactor,
        // Address of the NFT contract
        address[] memory _nftAddresses,
        // Name for ERC20 representing shares of this pool
        string memory _tokenName,
        // Symbol for ERC20 representing shares of this pool
        string memory _tokenSymbol
    )
        external;
}
