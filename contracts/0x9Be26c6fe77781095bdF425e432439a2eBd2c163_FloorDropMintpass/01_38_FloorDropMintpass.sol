// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@      @@@@@@@@@@@@   @@@@@@@@*   @@@@@@@@                   @@@                      @@@@    &@@@@@@@@@@@@    @@@@@
// @@@@@       @@@@@@@@@@@   @@@@@@@@*   @@@@@@@@    @@@@@@@@@@@@@@@@@@@@@@@@@@@    @@@@@@@@@@@@@@@    @@@@@@@@@@    @@@@@@
// @@@@@   #@    @@@@@@@@@   @@@@@@@@*   @@@@@@@@    @@@@@@@@@@@@@@@@@@@@@@@@@@@    @@@@@@@@@@@@@@@@.   @@@@@@@    @@@@@@@@
// @@@@@   #@@    @@@@@@@@   @@@@@@@@*   @@@@@@@@    @@@@@@@@@@@@@@@@@@@@@@@@@@@    @@@@@@@@@@@@@@@@@@    @@@@    @@@@@@@@@
// @@@@@   #@@@@    @@@@@@   @@@@@@@@*   @@@@@@@@                 @@@@@@@@@@@@@@    @@@@@@@@@@@@@@@@@@@@   &    @@@@@@@@@@@
// @@@@@   #@@@@@    @@@@@   @@@@@@@@*   @@@@@@@@    @@@@@@@@@@@@@@@@@@@@@@@@@@@    @@@@@@@@@@@@@@@@@@@@@     *@@@@@@@@@@@@
// @@@@@   #@@@@@@@    @@@   @@@@@@@@*   @@@@@@@@    @@@@@@@@@@@@@@@@@@@@@@@@@@@    @@@@@@@@@@@@@@@@@@@@@@    @@@@@@@@@@@@@
// @@@@@   #@@@@@@@@@   &@   @@@@@@@@*   @@@@@@@@    @@@@@@@@@@@@@@@@@@@@@@@@@@@    @@@@@@@@@@@@@@@@@@@@@@    @@@@@@@@@@@@@
// @@@@@   #@@@@@@@@@@       @@@@@@@@*   @@@@@@@@    @@@@@@@@@@@@@@@@@@@@@@@@@@@    @@@@@@@@@@@@@@@@@@@@@@    @@@@@@@@@@@@@
// @@@@@   #@@@@@@@@@@@@     @@@@@@@@*   @@@@@@@@    @@@@@@@@@@@@@@@@@@@@@@@@@@@    @@@@@@@@@@@@@@@@@@@@@@    @@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@                                                                                                                   @@
// @@@  @@@@@@@@         [email protected]@@@@@@@    @@@@@@          @@@@@       @@@@@@@@@@@@@@       @@@@@*        &@@@@@@@@@@@@       @@
// @@@  @@@@@@@@@        @@@@@@@@@    @@@@@@          @@@@@     @@@@@@@@@@@@@@@@@@     @@@@@*     /@@@@@@@@@@@@@@@@@@    @@
// @@@  @@@@@*@@@,      @@@@ @@@@@    @@@@@@          @@@@@    @@@@@          @@@@@    @@@@@*    @@@@@@,        @@@@@@   @@
// @@@  @@@@@ @@@@      @@@@ @@@@@    @@@@@@          @@@@@    @@@@@                   @@@@@*   @@@@@@           @@@@@@  @@
// @@@  @@@@@  @@@@    @@@@  @@@@@    @@@@@@          @@@@@    %@@@@@@@@@@@            @@@@@*   @@@@@                    @@
// @@@  @@@@@  @@@@    @@@@  @@@@@    @@@@@@          @@@@@       @@@@@@@@@@@@@@@@     @@@@@*  &@@@@@                    @@
// @@@  @@@@@   @@@@  @@@@   @@@@@    @@@@@@          @@@@@               @@@@@@@@@@   @@@@@*   @@@@@                    @@
// @@@  @@@@@   @@@@ ,@@@    @@@@@    @@@@@@          @@@@@   @@@@@@           @@@@@   @@@@@*   @@@@@@           @@@@@@  @@
// @@@  @@@@@    @@@@@@@@    @@@@@    @@@@@@@        @@@@@@    @@@@@#         ,@@@@@   @@@@@*    @@@@@@@        @@@@@@   @@
// @@@  @@@@@    &@@@@@@     @@@@@     /@@@@@@@@@@@@@@@@@@      @@@@@@@@@@@@@@@@@@@    @@@@@*      @@@@@@@@@@@@@@@@@     @@
// @@@  @@@@@     @@@@@@     @@@@@        @@@@@@@@@@@@@            @@@@@@@@@@@@@       @@@@@*         @@@@@@@@@@@*       @@
// @@@                                                                                                                   @@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/// @author weiz

import "./base/ERC1155Drop.sol";
import "./extension/interface/IClaimCondition.sol";

/**
 * The FloorDropMintpass contract is a drop contract that implements the ERC1155 standard. It extends the ERC1155Drop
 * contract and adds the ability to specify a different primary sale recipient for each token.
 */

contract FloorDropMintpass is ERC1155Drop {

    address public constant SHARE_RECEIVER_ADDRESS = 0xaE1F01F1E9F72D8bC7AF9E0f8F91D1566C70D494;

    mapping(address => bool) public approvedContracts;

    /*///////////////////////////////////////////////////////////////
                                Mappings
    //////////////////////////////////////////////////////////////*/

    /// @dev Mapping from tokenId => artist recipient address
    mapping(uint256 => address) public primarySaleRecipient;

    constructor(
        string memory _name,
        string memory _symbol,
        address _royaltyRecipient,
        uint128 _royaltyBps,
        address _primarySaleRecipient
    ) ERC1155Drop(_name, _symbol, _royaltyRecipient, _royaltyBps, _primarySaleRecipient) {

    }

    /// @dev Lets an account claim tokens.
    function claim(
        address _receiver,
        uint256 _tokenId,
        uint256 _quantity,
        address _currency,
        uint256 _pricePerToken,
        AllowlistProof calldata _allowlistProof,
        bytes memory _data
    ) public payable virtual override {
        require(primarySaleRecipient[_tokenId] != address(0), "Primary Sale Recipient not set");
        _beforeClaim(_tokenId, _receiver, _quantity, _currency, _pricePerToken, _allowlistProof, _data);

        ClaimCondition memory condition = claimCondition[_tokenId];
        bytes32 activeConditionId = conditionId[_tokenId];

        verifyClaim(_tokenId, _dropMsgSender(), _quantity, _currency, _pricePerToken, _allowlistProof);

        // Update contract state.
        condition.supplyClaimed += _quantity;
        supplyClaimedByWallet[activeConditionId][_dropMsgSender()] += _quantity;
        claimCondition[_tokenId] = condition;

        // If there's a price, collect price.
        address artistRecipient = primarySaleRecipient[_tokenId];
        _collectPriceOnClaim(artistRecipient, _quantity, _currency, _pricePerToken);

        // Mint the relevant NFTs to claimer.
        _transferTokensOnClaim(_receiver, _tokenId, _quantity);

        emit TokensClaimed(_dropMsgSender(), _receiver, _tokenId, _quantity);

        _afterClaim(_tokenId, _receiver, _quantity, _currency, _pricePerToken, _allowlistProof, _data);
    }

    /// @dev Collects and distributes the primary sale value of NFTs being claimed.
    function _collectPriceOnClaim(
        address _primarySaleRecipient,
        uint256 _quantityToClaim,
        address _currency,
        uint256 _pricePerToken
    ) internal virtual override {
        if (_pricePerToken == 0) {
            return;
        }

        uint256 totalPrice = _quantityToClaim * _pricePerToken;

        if (_currency == CurrencyTransferLib.NATIVE_TOKEN) {
            if (msg.value != totalPrice) {
                revert("Must send total price.");
            }
        }

        // split the price between the artist and Nifty Music
        uint256 artistPrice = (totalPrice * 80) / 100;
        uint256 nmPrice = totalPrice - artistPrice;

        CurrencyTransferLib.transferCurrency(_currency, msg.sender, _primarySaleRecipient, artistPrice);
        CurrencyTransferLib.transferCurrency(_currency, msg.sender, SHARE_RECEIVER_ADDRESS, nmPrice);
    }

    /// @dev Sets the primary sale recipient for a token.
    function setPrimarySaleRecipient(uint256 _tokenId, address _primarySaleRecipient) external onlyOwner {
        primarySaleRecipient[_tokenId] = _primarySaleRecipient;
    }

    /// @dev Sets the base URI for the batch of tokens with the given batchId.
    function setBaseURI(uint256 _tokenId, string memory _baseURI) external onlyOwner {
        (uint256 _batchId, ) = _getBatchId(_tokenId);
        _setBaseURI(_batchId, _baseURI);
    }

    /// @dev Sets a contract as approved to call the burn function.
    function setApprovedContract(address _contract, bool _approved) external onlyOwner {
        approvedContracts[_contract] = _approved;
    }

    /// @dev Burns the token with the given tokenId.
    function burn(address _from, uint256 _tokenId) external {
        require(approvedContracts[msg.sender], "Not approved contract");
        _burn(_from, _tokenId, 1);
    }
}