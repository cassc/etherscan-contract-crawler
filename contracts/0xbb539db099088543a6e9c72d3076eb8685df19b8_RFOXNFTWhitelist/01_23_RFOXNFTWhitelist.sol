// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./lib/RFOXNFTPresale.sol";
import "./structs/ParamStructs.sol";

contract RFOXNFTWhitelist is RFOXNFTPresale {

    /**
     * @dev Initialization of the RFOX NFT with presale / whitelist mechanism.
     * Can only be called by the factory.
     *
     * Features:
     * Public sale.
     * Presale / whitelisted address.
     * No Bot Prevention.
     *
     * @param params Struct for whitelist parameters.
     */
    function initialize(ParamStructs.WhitelistParams calldata params) external {
        require(msg.sender == address(factory), "Forbidden");
        require(
            params.publicSaleStartTime >= params.saleStartTime,
            "Invalid public sale time"
        );

        publicSaleStartTime = params.publicSaleStartTime;
        isWhitelistActivated = true;
        maxMintedPresalePerAddress = params.maxMintedPresalePerAddress;
        TOKEN_PRICE_PRESALE = params.pricePresale;

        initializeBase(
            params.name,
            params.symbol,
            params.baseURI,
            params.saleToken,
            params.price,
            params.maxNft,
            params.maxTokensPerTransaction,
            params.saleStartTime,
            params.saleEndTime,
            params.owner
        );
    }
}