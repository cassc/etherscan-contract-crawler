//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./IToken.sol";
import "./ITokenPrice.sol";
import "./IAirdropTokenSale.sol";

interface IMerkleAirdrop {
    function airdropRedeemed(
        uint256 drop,
        address recipient,
        uint256 amount
    ) external;
     function initMerkleAirdrops(IAirdrop.AirdropSettings[] calldata settingsList) external;
     function airdrop(uint256 drop) external view returns (IAirdrop.AirdropSettings memory settings);
     function airdropRedeemed(uint256 drop, address recipient) external view returns (bool isRedeemed);
}

/// @notice an airdrop airdrops tokens
interface IAirdrop {

    // emitted when airdrop is redeemed


    /// @notice the settings for the token sale,
    struct AirdropSettings {
        // sell from the whitelist only
        bool whitelistOnly;

        // this whitelist id - by convention is the whitelist hash
        uint256 whitelistId;

        // the root hash of the merkle tree
        bytes32 whitelistHash;

        // quantities
        uint256 maxQuantity; // max number of tokens that can be sold
        uint256 maxQuantityPerSale; // max number of tokens that can be sold per sale
        uint256 minQuantityPerSale; // min number of tokens that can be sold per sale
        uint256 maxQuantityPerAccount; // max number of tokens that can be sold per account

        // quantity of item sold
        uint256 quantitySold;

        // start timne and end time for token sale
        uint256 startTime; // block number when the sale starts
        uint256 endTime; // block number when the sale ends

        // inital price of the token sale
        ITokenPrice.TokenPriceData initialPrice;

        // token hash
        uint256 tokenHash;

        IAirdropTokenSale.PaymentType paymentType; // the type of payment that is being used
        address tokenAddress; // the address of the payment token, if payment type is TOKEN

        // the address of the payment token, if payment type is ETH
        address payee;
    }

    // emitted when airdrop is launched
    event AirdropLaunched(uint256 indexed airdropId, AirdropSettings airdrop);

    // emitted when airdrop is redeemed
    event AirdropRedeemed(uint256 indexed airdropId, address indexed beneficiary, uint256 indexed tokenHash, bytes32[] proof, uint256 amount);

    /// @notice airdrops check to see if proof is redeemed
    /// @param drop the id of the airdrop
    /// @param recipient the merkle proof
    /// @return isRedeemed the amount of tokens redeemed
    function airdropRedeemed(uint256 drop, address recipient) external view returns (bool isRedeemed);

    /// @notice redeem tokens for airdrop
    /// @param drop the airdrop id
    /// @param leaf the index of the token in the airdrop
    /// @param recipient the beneficiary of the tokens
    /// @param amount tje amount of tokens to redeem
    /// @param merkleProof the merkle proof of the token
    function redeemAirdrop(uint256 drop, uint256 leaf, address recipient, uint256 amount, uint256 total, bytes32[] memory merkleProof) external payable;

    /// @notice Get the token sale settings
    /// @return settings the token sale settings
    function airdrop(uint256 drop) external view returns (AirdropSettings memory settings);

}