// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./RFOXNFTSale.sol";
import "./base/BaseRFOXNFTPresale.sol";

contract RFOXNFTPresale is RFOXNFTSale, BaseRFOXNFTPresale
{
    /**
     * @dev Overwrite the authorizePublicSale modifier from the base RFOX NFT contract.
     * In the standard sale contract, the saleStartTime is the starting time of the public sale.
     * In the presale contract, the saleStartTime will be considered as the starting time of the presale.
     * and the publicSaleStartTime will be the starting time of the public sale.
     */
    modifier authorizePublicSale() override {
        require(
            block.timestamp >= publicSaleStartTime,
            "Sale has not been started"
        );
        _;
    }

    /**
     * @dev Each whitelisted address has quota to mint for the presale.
     * There is limit amount of token that can be minted during the presale.
     *
     * @param tokensNumber How many NFTs for buying this round
     * @param proof The bytes32 array from the offchain whitelist address.
     */
    function buyNFTsPresale(uint256 tokensNumber, bytes32[] calldata proof)
        external
        payable
        whenNotPaused
        callerIsUser
        authorizePresale(proof)
    {
        _buyNFTsPresale(tokensNumber);
    }
}