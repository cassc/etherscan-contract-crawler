// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./interfaces/IEscrowBuyer.sol";
import "./interfaces/ICryptopunksMarket.sol";

contract CryptopunksEscrowBuyer is
    Initializable,
    OwnableUpgradeable,
    IEscrowBuyer
{
    address public immutable EXCHANGE; //CRYPTOPUNKS_ADDRESS

    constructor(address _exchange) {
        EXCHANGE = _exchange;
    }

    function initialize() external initializer {
        __Ownable_init();
    }

    /**
     * @notice Purchase an NFT and escrow it in this contract.
     * @param parameters Seaport Protocol order parameters.
     */
    function fulfillBasicOrderWithEth(BasicOrderParameters calldata parameters)
        public
        payable
        onlyOwner
        returns (bool)
    {
        require(
            parameters.offerToken == EXCHANGE,
            "Invalid token address in offer"
        );

        uint256 punkId = parameters.offerIdentifier;

        ICryptopunksMarket(EXCHANGE).buyPunk{ value: msg.value }(punkId);

        return true;
    }


     function fulfillBasicOrderWithToken(BasicOrderParameters calldata parameters, uint256 totalPurchasePrice)
        public 
        onlyOwner
        returns (bool)
    {
        revert("Cannot purchase cryptopunks with tokens");
        return false;
    }

    /**
     * @notice Transfer the NFT from escrow to a users wallet.
     * @param tokenAddress The NFT contract address.
     * @param tokenId The NFT token ID.
     * @param tokenType The type of NFT asset
     * @param amount The amount of NFT asset quantity (1 if not 1155)
     * @param recipient The address that will receive the NFT.
     */

    function claimNFT(
        address tokenAddress,
        uint256 tokenId,
        IBNPLMarket.TokenType tokenType,
        uint256 amount,
        address recipient
    ) external onlyOwner returns (bool) {
        ICryptopunksMarket(EXCHANGE).transferPunk(recipient, tokenId);
        return true;
    }

    /**
     * @notice A read-only method to validate that an NFT is escrowed in this contract
     * @param assetContractAddress The NFT contract address.
     * @param assetTokenId The NFT token ID.
     * @param quantity The amount of NFT asset quantity (1 if not 1155).
     * @param tokenType The type of NFT asset.
     */
    function hasOwnershipOfAsset(
        address assetContractAddress,
        uint256 assetTokenId,
        uint256 quantity,
        IBNPLMarket.TokenType tokenType
    ) public view returns (bool) {
        if (
            tokenType == IBNPLMarket.TokenType.PUNK &&
            quantity == 1 &&
            assetContractAddress == EXCHANGE
        ) {
            return
                ICryptopunksMarket(EXCHANGE).punkIndexToAddress(assetTokenId) ==
                address(this);
        }

        return false;
    }
}