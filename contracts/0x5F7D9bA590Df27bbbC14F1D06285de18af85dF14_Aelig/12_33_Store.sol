// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../interfaces/IStore.sol";
import "./FrameOwnership.sol";
import "./Lendable.sol";
import "./Roles.sol";
import "../interfaces/IERC20.sol";

contract Store is
    IStore,
    Lendable,
    Roles
{
    mapping(uint256=>uint256) internal modelToStock;
    uint256 internal models;

    address public token;
    mapping(uint256=>uint256) internal modelToPrice;

    mapping(uint256=>uint256) internal idToModel;

    mapping(address=>uint256) internal accountToCheck;

    uint256 public feePercentage = 500;

    mapping(uint256=>uint256) internal idToRefund;

    constructor(address _token, uint256 rentPercentage) {
        models = 0;
        require(_token.code.length > 0, errors.INVALID_ADDRESS);
        token = _token;
        feePercentage = rentPercentage;
    }

    modifier isValidModel(uint256 model) {
        require(model < models, errors.NOT_VALID_MODEL);
        _;
    }

    modifier isInStock(uint256 model, uint256 quantity) {
        require(modelToStock[model] >= quantity, errors.NOT_IN_STOCK);
        _;
    }

    modifier isCheckValid(address account, uint256 check) {
        require(check > accountToCheck[account], errors.CHECK_NOT_VALID);
        _;
    }

    modifier canBeRefund(uint256 frameId, uint256 amount) {
        require(idToRefund[frameId] > 0 && idToRefund[frameId] == amount, errors.NOT_AUTHORIZED);
        _;
    }

    function setStock(
        uint256 newStock,
        uint256 model
    )
        external
        override
        isAdmin(msg.sender)
    {
        _setStock(newStock, model);
    }

    function getStock(
        uint256 model
    )
        external
        override
        view
        isValidModel(model)
        returns(uint256)
    {
        return modelToStock[model];
    }

    function getModels(

    )
        external
        view
        override
        returns(uint256)
    {
        return models;
    }

    function _setStock(
        uint256 newStock,
        uint256 model
    )
        internal
        isValidModel(model)
    {
        modelToStock[model] = newStock;
        if (model > models) {
            models = model;
        }
    }

    function setToken(
        address _token
    )
        external
        override
        isAdmin(msg.sender)
    {
        require(_token.code.length > 0, errors.INVALID_ADDRESS);
        token = _token;
    }

    function setPrice(
        uint256 price,
        uint256 model
    )
        override
        external
        isAdmin(msg.sender)
    {
        _setPrice(price, model);
    }

    function _setPrice(
        uint256 price,
        uint256 model
    )
        private
        isValidModel(model)
    {
        modelToPrice[model] = price;
    }

    function getModel(
        uint256 frameId
    )
        external
        view
        override
        validNFToken(frameId)
        returns(uint256)
    {
        return idToModel[frameId];
    }

    function getPrice(
        uint256 model
    )
        external
        view
        override
        isValidModel(model)
        returns(uint256)
    {
        return modelToPrice[model];
    }

    function putNewModel(
        uint256 price
    )
        external
        override
        isAdmin(msg.sender)
        returns(uint256)
    {
        modelToPrice[models] = price;
        models++;
        return models - 1;
    }

    function buy(
        address receiver,
        uint256 quantity,
        uint256 model
    )
        external
        override
    {
        _payAndMint(receiver, modelToPrice[model] * quantity, quantity, model);
    }

    function buy(
        address receiver,
        uint256 price,
        uint256 quantity,
        uint256 model,
        address signer,
        uint256 check,
        bytes calldata signature
    )
        external
        override
        isCheckValid(msg.sender, check)
        isAdmin(signer)
    {
        require(_isSignatureAuthentic(msg.sender, price, model, quantity, signer, signature), errors.INVALID_SIGNATURE);
        _payAndMint(receiver, price, quantity, model);
        accountToCheck[msg.sender]++;
    }

    function _isSignatureAuthentic(
        address account,
        uint256 price,
        uint256 model,
        uint256 quantity,
        address signer,
        bytes calldata signature
    )
        private
        view
        returns(bool)
    {
        bytes32 ethSignedMessageHash = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", _getMessageHash(account, price, model, quantity, this.getAccountCheck(account)))
        );
        (bytes32 r, bytes32 s, uint8 v) = _splitSignature(signature);
        address detectedSigner = ecrecover(ethSignedMessageHash, v, r, s);
        return detectedSigner == signer;
    }

    function _payAndMint(
        address receiver,
        uint256 price,
        uint256 quantity,
        uint256 model
    )
        private
        isValidModel(model)
        notNullAddress(receiver)
        isInStock(model, quantity)
    {
        IERC20(token).transferFrom(msg.sender, address(this), price);
        _mintBatch(receiver, model, quantity);
    }

    function _mintBatch(
        address receiver,
        uint256 model,
        uint256 quantity
    )
        private
    {
        for (uint256 i = 0; i < quantity; i++) {
            idToModel[mintedFrames()] = model;
            _mint(receiver, mintedFrames());
        }
        modelToStock[model] -= quantity;
    }

    function _getMessageHash(
        address account,
        uint256 price,
        uint256 model,
        uint256 quantity,
        uint256 check
    )
        private
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(account, price, model, quantity, check));
    }

    function _splitSignature(
        bytes memory sig
    )
        private
        pure
        returns (bytes32 r, bytes32 s, uint8 v)
    {
        require(sig.length == 65, errors.INVALID_SIGNATURE);

        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
    }

     function getAccountCheck(
        address account
    )
        external
        view
        override
        notNullAddress(account)
        returns(uint256)
    {
        return accountToCheck[account] + 1;
    }

    function gift(
        address receiver,
        uint256 quantity,
        uint256 model
    )
        external
        isAdmin(msg.sender)
        notNullAddress(receiver)
        isInStock(model, quantity)
    {
        _mintBatch(receiver, model, quantity);
    }

    function setFeePercentage(
        uint256 newFeePercentage
    )
        external
        isAdmin(msg.sender)
    {
        feePercentage = newFeePercentage;
    }

    function lendFrameWithMoney(
        uint256 frameId,
        uint256 price,
        address _token,
        address receiver,
        uint64 expires,
        bool canUpdate
    )
        external
        override
        validNFToken(frameId)
    {
        _payWithFee(_token, price, receiver);
        _rent(frameId, receiver, expires, canUpdate);
    }
    function lendArtworkWithMoney(
        uint256 frameId,
        uint256 price,
        address _token,
        uint256 receiver,
        uint256 expires
    )
        external
        override
    {
        _payWithFee(_token, price, msg.sender);
        _lendArtwork(frameId, receiver, expires);
    }

    function _payWithFee(
        address _token,
        uint256 price,
        address receiver
    )
        private
    {
        uint256 feeToPay = price / 10000 * feePercentage;
        IERC20(_token).transferFrom(receiver, address(this), price);
        IERC20(_token).transfer(msg.sender, price - feeToPay);
    }

    function _rent(
        uint256 tokenId,
        address user,
        uint64 expires,
        bool canUpdate
    )
        private
    {
        if (canUpdate) {
            _setUserWithUploads(tokenId, user, expires);
        } else {
            _setUser(tokenId, user, expires);
        }
    }

    function burnAndRefund(
        uint256 frameId,
        uint256 amount
    )
        external
        override
        isAdmin(msg.sender)
        canBeRefund(frameId, amount)
    {
        IERC20(token).transfer(_ownerOf(frameId), idToRefund[frameId]);
        _burn(frameId);
    }

    function askForRefund(
        uint256 frameId,
        uint256 value
    )
        external
        override
        canTransfer(frameId)
    {
        idToRefund[frameId] = value;
    }
}