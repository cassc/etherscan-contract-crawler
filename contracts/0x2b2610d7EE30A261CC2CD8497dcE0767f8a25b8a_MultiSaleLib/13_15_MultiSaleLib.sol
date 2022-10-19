//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/interfaces/IERC20.sol";

import "./MerkleProof.sol";

import "../interfaces/IMultiSale.sol";
import "../interfaces/IVariablePrice.sol";

import "./VariablePriceLib.sol";

import "../utilities/InterfaceChecker.sol";


library MultiSaleLib {

    bytes32 internal constant DIAMOND_STORAGE_POSITION =
        keccak256("diamond.nextblock.bitgem.app.MultiSaleStorage.storage");

    /// @notice get the storage for the multisale
    /// @return ds the storage
    function multiSaleStorage()
        internal
        pure
        returns (MultiSaleStorage storage ds)
    {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    /// @notice get a new tokensale id
    /// @return tokenSaleId the new id
    function _createTokenSale() internal returns (uint256 tokenSaleId) {

        // set settings object
        tokenSaleId = uint256(
            keccak256(
                abi.encodePacked(multiSaleStorage().tsnonce++, address(this))
            )
        );
    }

    /// @notice validate the token purchase
    /// @param self the multisale storage
    /// @param valueAttached the value attached to the transaction
    function _validatePurchase(
        MultiSaleContract storage self, 
        VariablePriceContract storage priceContract,
        uint256 quantity, 
        uint256 valueAttached) internal view {

        MultiSaleSettings storage settings = self.settings;

        // make sure there are still tokens to purchase
        require(settings.maxQuantity == 0 || (settings.maxQuantity != 0 &&
            self.totalPurchased < settings.maxQuantity), "soldout" );

        // make sure the max qty per sale is not exceeded
        require(settings.minQuantityPerSale == 0 || (settings.minQuantityPerSale != 0 &&
            quantity >= settings.minQuantityPerSale), "qtytoolow");

        // make sure the max qty per sale is not exceeded
        require(settings.maxQuantityPerSale == 0 || (settings.maxQuantityPerSale != 0 &&
            quantity <= settings.maxQuantityPerSale), "qtytoohigh");

        // make sure token sale is started
        require(block.timestamp >= settings.startTime || settings.startTime == 0, "notstarted");

        // make sure token sale is not over
        require(block.timestamp <= settings.endTime || settings.endTime == 0,
            "saleended" );
         
        // gt thte total price 
        uint256 totalPrice = priceContract.price * quantity;
        require(totalPrice <= valueAttached, "notenoughvalue");
    }
    
    /// @notice validate the token purchase using the given proof
    /// @param self the multisale storage
    /// @param purchaseProof the proof
    function _validateProof(
        MultiSaleContract storage self,
        MultiSalePurchase memory purchase,
        MultiSaleProof memory purchaseProof
    ) internal {
        if (self.settings.whitelistOnly) {

            // check that the airdrop has not yet been redeemed by the user
            require(!_airdropRedeemed(self, purchase.receiver), "redeemed");

            // check to see if redeemed already
            uint256 _redeemedAmt = self._redeemedDataQuantities[purchase.receiver];
            uint256 _redeemedttl = self._totalDataQuantities[purchase.receiver];
            _redeemedttl = _redeemedAmt > 0 ? _redeemedttl : purchaseProof.total;

            // ensure that the user has not redeemed more than the total
            require(_redeemedAmt + purchase.quantity <= _redeemedttl, "redeemed");
            self._totalDataQuantities[purchase.receiver] = _redeemedttl;
            self._redeemedDataQuantities[purchase.receiver] += purchase.quantity; // increment amount redeemed

            // check the proof
            bool valid = MerkleProof.verify(
                bytes32 (self.settings.whitelistHash),
                bytes32 (purchaseProof.leaf), purchaseProof.merkleProof
            );

            // Check the merkle proof
            require(valid, "Merkle proof failed");
        }
    }

    /// @notice airdrops check to see if proof is redeemed
    /// @param recipient the merkle proof
    /// @return isRedeemed the amount of tokens redeemed
    function _airdropRedeemed(MultiSaleContract storage self, address recipient) internal view returns (bool isRedeemed) {

        uint256 red = self._totalDataQuantities[recipient];
        uint256 tot = self._redeemedDataQuantities[recipient]; // i
        isRedeemed = red != 0 && red == tot;
    }

    /// @notice purchase a token sale token without any proof
    /// @param self the token sale id
    /// @param purchase the token hash
    function __purchase(
        MultiSaleContract storage self,
        MultiSalePurchase memory purchase,
        VariablePriceContract memory variablePrice,
        uint256 valueAttached
    ) internal {
        // transfer the payment to the contract if erc20
        if (self.settings.paymentType == PaymentType.ERC20 &&
            self.settings.tokenAddress != address(0)) {
            uint256 purchaseAmount = purchase.quantity * variablePrice.price;
            require(purchaseAmount > 0, "invalidamount");
            _transferErc20PaymkentToContract(
                purchase.purchaser,
                self.settings.tokenAddress,
                purchaseAmount
            );
        } else {
            uint256 purchaseAmount = purchase.quantity * variablePrice.price;
            require(valueAttached >= purchaseAmount, "invalidamount");
        }
        // transfer the tokens to the receiver
        _transferPaymentToPayee(self, valueAttached);

    }    

    /// @notice purchase a token sale token without any proof
    /// @param self the token sale id
    /// @param purchase the token hash
    function _purchaseToken(
        MultiSaleContract storage self,
        VariablePriceContract storage variablePrice,
        MultiSalePurchase memory purchase,
        MultiSaleProof memory purchaseProof,
        uint256 valueAttached
    ) internal {

        // validate the purchase
        _validatePurchase(self, variablePrice, purchase.quantity, valueAttached);
        
        // validate the proof
        _validateProof(self, purchase, purchaseProof);

        // make the purchase
        __purchase(
            self, 
            purchase, 
            VariablePriceLib.variablePriceStorage().variablePrices,
            valueAttached);

    }

    /// @notice purchase a token sale token without any proof
    /// @param self the token sale id
    /// @param purchase the token hash
    function _purchaseToken(
        MultiSaleContract storage self,
        VariablePriceContract storage variablePrice,
        MultiSalePurchase memory purchase,
        uint256 valueAttached
    ) internal {

        // validate the purchase
        _validatePurchase(self, variablePrice, purchase.quantity, valueAttached);

        // make the purchase
        __purchase(self, purchase, variablePrice, valueAttached);
    }
    
    /// @notice transfer erc20 payment to the contract
    /// @param sender the sender of the payment
    /// @param paymentToken the token address
    /// @param paymentAmount the amount of payment
    function _transferErc20PaymkentToContract(
        address sender,
        address paymentToken,
        uint256 paymentAmount
    ) internal {

        // transfer payment to contract
        IERC20(paymentToken).transferFrom(sender, address(this), paymentAmount);
    }

    /// @notice transfer payment to the token sale payee
    /// @param self the token sale settings
    /// @param valueAttached the value attached to the transaction
    function _transferPaymentToPayee(MultiSaleContract storage self, uint256 valueAttached) internal {

        // transfer the payment to the payee if the payee address is set
        if (self.settings.payee != address(0)) {
            if (self.settings.paymentType == PaymentType.ERC20) {
                IERC20(self.settings.tokenAddress).transferFrom(
                    address(this),
                    self.settings.payee,
                    valueAttached
                );
            } else {
                payable(self.settings.payee).transfer(valueAttached);
            }
        }
    }

    /// @notice get the token type
    /// @param token the token id
    /// @return tokenType the token type
    function _getTokenType(address token)
        internal
        view
        returns (TokenType tokenType) {

        tokenType = InterfaceChecker.isERC20(token)
            ? TokenType.ERC20
            : InterfaceChecker.isERC721(token)
            ? TokenType.ERC721
            : TokenType.ERC1155;
    }
}