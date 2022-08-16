// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../common/Upgradeable.sol";

contract NFTExchange is Upgradeable {
    event PaymentTokenEvent(address indexed _tokenAddress, string _currencyId);
    event ServiceFeeEvent(
        address indexed _tokenAddress,
        string _currencyId,
        uint256 _feeRate
    );

    modifier onlyAdmins() {
        require(adminList[msg.sender], "Need admin role");
        _;
    }

    modifier onlyAdminsAndSubAdmins(uint8 _role) {
        require(
            adminList[msg.sender] || subAdminList[msg.sender][_role],
            "Only admins or sub-admin with this role"
        );
        _;
    }

    function isAdmin(address _address) public view returns (bool) {
        return adminList[_address];
    }

    function isSubAdmin(address _address, uint8 _role)
        public
        view
        returns (bool)
    {
        return subAdminList[_address][_role] || adminList[_address];
    }

    function setOfferHandler(address newOfferHandler) public onlyAdmins {
        offerHandler = newOfferHandler;
    }

    function setSignatureUtils(address newSignatureUtils) public onlyAdmins {
        signatureUtils = newSignatureUtils;
    }

    function setBuyHandler(address newBuyHandler) public onlyAdmins {
        buyHandler = newBuyHandler;
    }

    function setRecipient(address newRecipient) public onlyAdmins {
        recipient = newRecipient;
    }

    function setFeatureHandler(address newFeatureHandler) public onlyAdmins {
        featureHandler = newFeatureHandler;
    }

    function setSellHandler(address newSellHandler) public onlyAdmins {
        sellHandler = newSellHandler;
    }

    function setCancelHandler(address newCancelHandler) public onlyAdmins {
        cancelHandler = newCancelHandler;
    }

    function setTrustedForwarder(address newForwarder) public onlyAdmins {
        trustedForwarder = newForwarder;
    }

    function setFeeUtils(address newFeeUtils) public onlyAdmins {
        feeUtils = newFeeUtils;
    }

    function setBoxUtils(address newBoxUtils) public onlyAdmins {
        boxUtils = newBoxUtils;
    }

    function setMetaHandler(address newMetaHandler) public onlyAdmins {
        metaHandler = newMetaHandler;
    }

    function setAdminList(address _address, bool value) public {
        adminList[_address] = value;
    }

    function setSubAdminList(
        address _address,
        uint8 _role,
        bool value
    ) public onlyAdmins {
        subAdminList[_address][_role] = value;
    }

    function setSigner(address _address, bool _value) external onlyAdmins {
        signers[_address] = _value;
    }

    function setTokenFee(
        string memory _currencyId,
        address _tokenAddress,
        uint256 _feeRate
    ) public onlyAdminsAndSubAdmins(2) {
        tokensFee[_tokenAddress] = _feeRate;
        emit ServiceFeeEvent(_tokenAddress, _currencyId, _feeRate);
    }

    function addAcceptedToken(string memory _currencyId, address _tokenAddress)
        public
        onlyAdminsAndSubAdmins(1)
    {
        acceptedTokens[_tokenAddress] = true;
        emit PaymentTokenEvent(_tokenAddress, _currencyId);
    }

    function removeAcceptedToken(address _tokenAddress)
        public
        onlyAdminsAndSubAdmins(1)
    {
        acceptedTokens[_tokenAddress] = false;
    }

    function setAirdropHandler(address newAirdropHandler) public onlyAdmins {
        airdropHandler = newAirdropHandler;
    }

    function getNonce(bytes32 handler, address account)
        public
        view
        returns (uint256)
    {
        return _nonces[handler][account];
    }
}