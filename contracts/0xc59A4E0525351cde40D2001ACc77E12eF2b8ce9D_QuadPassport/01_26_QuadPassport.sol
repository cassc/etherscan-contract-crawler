//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import "@openzeppelin/contracts-upgradeable/access/IAccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

import "./interfaces/IQuadPassport.sol";
import "./interfaces/IQuadGovernance.sol";
import "./storage/QuadPassportStore.sol";
import "./storage/QuadPassportStoreV2.sol";
import "./QuadSoulbound.sol";

/// @title Quadrata Web3 Identity Passport
/// @author Fabrice Cheng, Theodore Clapp
/// @notice This represents a Quadrata NFT Passport
contract QuadPassport is IQuadPassport, UUPSUpgradeable, PausableUpgradeable, QuadSoulbound, QuadPassportStoreV2 {

    // used to prevent logic contract self destruct take over
    constructor() initializer {}

    /// @dev initializer (constructor)
    /// @param _governanceContract address of the IQuadGovernance contract
    function initialize(
        address _governanceContract
    ) public initializer {
        require(_governanceContract != address(0), "GOVERNANCE_ADDRESS_ZERO");
        governance = IQuadGovernance(_governanceContract);
        name = "Quadrata Passport";
        symbol = "QP";
    }

    /// @notice Set attributes for a Quadrata Passport (Only Individuals)
    /// @dev Only when authorized by an eligible issuer
    /// @param _config Input paramters required to authorize attributes to be set
    /// @param _sigIssuer ECDSA signature computed by an eligible issuer to authorize the mint
    /// @param _sigAccount ECDSA signature computed by an eligible EOA to prove ownership
    function setAttributes(
        AttributeSetterConfig memory _config,
        bytes calldata _sigIssuer,
        bytes calldata _sigAccount
    ) external payable override whenNotPaused {
        require(msg.value == _config.fee,  "INVALID_SET_ATTRIBUTE_FEE");

        bytes32 signedMsg = ECDSAUpgradeable.toEthSignedMessageHash("Welcome to Quadrata! By signing, you agree to the Terms of Service.");
        address account = ECDSAUpgradeable.recover(signedMsg, _sigAccount);
        address issuer = _setAttributesVerify(account, _config, _sigIssuer);

        _setAttributesInternal(account, _config, issuer);
    }

    /// @notice Set attributes from multiple issuers for a Quadrata Passport (Only Individuals)
    /// @dev Only when authorized by an eligible issuer
    /// @param _configs List of input paramters required to authorize attributes to be set
    /// @param _sigIssuers List of ECDSA signature computed by an eligible issuer to authorize the mint
    /// @param _sigAccounts List of ECDSA signature computed by an eligible EOA to prove ownership
    function setAttributesBulk(
        AttributeSetterConfig[] memory _configs,
        bytes[] calldata _sigIssuers,
        bytes[] calldata _sigAccounts
    ) external payable override whenNotPaused {
        require(_configs.length == _sigIssuers.length, "INVALID_BULK_ATTRIBUTES_LENGTH");
        require(_configs.length == _sigAccounts.length, "INVALID_BULK_ATTRIBUTES_LENGTH");

        bytes32 signedMsg = ECDSAUpgradeable.toEthSignedMessageHash("Welcome to Quadrata! By signing, you agree to the Terms of Service.");
        uint256 totalFee;

        for(uint256 i = 0; i < _configs.length; i++){
            address account = ECDSAUpgradeable.recover(signedMsg, _sigAccounts[i]);
            address issuer = _setAttributesVerify(account, _configs[i], _sigIssuers[i]);
            totalFee += _configs[i].fee;
            _setAttributesInternal(account, _configs[i], issuer);
        }
        require(msg.value == totalFee,  "INVALID_SET_ATTRIBUTE_BULK_FEE");

    }

    /// @notice Set attributes for a Quadrata Passport (only by Issuers)
    /// @param _account Address of the Quadrata Passport holder
    /// @param _config Input paramters required to set attributes
    /// @param _sigIssuer ECDSA signature computed by an eligible issuer to authorize the action
    function setAttributesIssuer(
        address _account,
        AttributeSetterConfig memory _config,
        bytes calldata _sigIssuer
    ) external payable override whenNotPaused {
        require(_account != address(0), "ACCOUNT_CANNOT_BE_ZERO");
        require(msg.value == _config.fee,  "INVALID_SET_ATTRIBUTE_FEE");

        address issuer = _setAttributesVerify(_account, _config, _sigIssuer);

        _setAttributesInternal(_account, _config, issuer);
    }

    /// @notice Internal function for `setAttributes` and `setAttributesIssuer`
    /// @param _account Address of the Quadrata Passport holder
    /// @param _config Input paramters required to set attributes
    /// @param _issuer Extracted address of ECDSA signature computed by an eligible issuer to authorize the action
    function _setAttributesInternal(
        address _account,
        AttributeSetterConfig memory _config,
        address _issuer
    ) internal {
        // Handle DID
        if(_config.did != bytes32(0)){
            require(governance.getIssuerAttributePermission(_issuer, ATTRIBUTE_DID), "ISSUER_ATTR_PERMISSION_INVALID");
            _validateDid(_account, _config.did);
            _writeAttrToStorage(
                _computeAttrKey(_account, ATTRIBUTE_DID, _config.did, _issuer),
                _config.did,
                _config.verifiedAt);
        }

        for (uint256 i = 0; i < _config.attrTypes.length; i++) {
            require(governance.getIssuerAttributePermission(_issuer, _config.attrTypes[i]), "ISSUER_ATTR_PERMISSION_INVALID");
            require(_config.attrTypes[i] != ATTRIBUTE_DID, "ISSUER_UPDATED_DID");

            _writeAttrToStorage(
                _computeAttrKey(_account, _config.attrTypes[i], _config.did, _issuer),
                _config.attrValues[i],
                _config.verifiedAt);
        }

        if (_config.tokenId != 0 && balanceOf(_account, _config.tokenId) == 0) {
            _mint(_account, _config.tokenId, 1);
        }
        emit SetAttributeReceipt(_account, _issuer, _config.fee);
    }

    /// @notice Internal function that validates supplied DID on updates do not change
    /// @param _account address of entity being attested to
    /// @param _did new DID value
    function _validateDid(address _account, bytes32 _did) internal view {
        // check if DID is already set from issuers
        address[] memory issuers = governance.getIssuers();
        for(uint256 i = 0; i < issuers.length; i++) {
            address issuer = issuers[i];
            bytes32 attrKey = keccak256(abi.encode(_account, ATTRIBUTE_DID, issuer));
            bytes32 possibleDid = _attributesv2[attrKey].value;
            if(possibleDid != bytes32(0)) {
                require(possibleDid == _did, "INVALID_DID");
            }

        }
    }

    /// @notice Internal function that writes the attribute value and issuer position to storage
    /// @param _attrKey attribute key (i.e. keccak256(address, keccak256("AML")))
    /// @param _attrValue attribute value
    /// @param _verifiedAt timestamp of when attribute was verified at
    function _writeAttrToStorage(
        bytes32 _attrKey,
        bytes32 _attrValue,
        uint256 _verifiedAt
    ) internal {
        Attribute memory attr = Attribute({
            value:  _attrValue,
            epoch: _verifiedAt,
            issuer: address(0)
        });

        _attributesv2[_attrKey] = attr;
    }


    /// @notice Internal helper to check setAttributes process
    /// @param _account Address of the Quadrata Passport holder
    /// @param _config Input paramters required to set attributes
    /// @param _sigIssuer ECDSA signature computed by an eligible issuer to authorize the action
    /// @return address of the issuer
    function _setAttributesVerify(
        address _account,
        AttributeSetterConfig memory _config,
        bytes calldata _sigIssuer
    ) internal view returns(address) {
        require(_config.tokenId == 0 || governance.eligibleTokenId(_config.tokenId), "PASSPORT_TOKENID_INVALID");
        require(_config.verifiedAt != 0, "VERIFIED_AT_CANNOT_BE_ZERO");
        require(_config.issuedAt != 0, "ISSUED_AT_CANNOT_BE_ZERO");
        require(_config.issuedAt <= block.timestamp, "INVALID_ISSUED_AT");

        require(_config.verifiedAt <= block.timestamp, "INVALID_VERIFIED_AT");
        require(block.timestamp <= _config.issuedAt + 6 hours, "EXPIRED_ISSUED_AT");
        require(_config.attrValues.length == _config.attrTypes.length, "MISMATCH_LENGTH");

        // Verify signature
        bytes32 extractionHash = keccak256(
            abi.encode(
                _account,
                _config.attrKeys,
                _config.attrValues,
                _config.did,
                _config.verifiedAt,
                _config.issuedAt,
                _config.fee,
                block.chainid,
                address(this)
            )
        );
        bytes32 signedMsg = ECDSAUpgradeable.toEthSignedMessageHash(extractionHash);
        address issuer = ECDSAUpgradeable.recover(signedMsg, _sigIssuer);

        require(IAccessControlUpgradeable(address(governance)).hasRole(ISSUER_ROLE, issuer), "INVALID_ISSUER");

        return issuer;
    }

    /// @notice Compute the attrKey for the mapping `_attributesv2`
    /// @param _account address of the wallet owner
    /// @param _attribute attribute type (ex: keccak256("COUNTRY"))
    /// @param _did DID of the passport (optional - could be pass as bytes32(0))
    /// @param _issuer address of the issuer
    function _computeAttrKey(address _account, bytes32 _attribute, bytes32 _did, address _issuer) internal view returns(bytes32) {
        if (governance.eligibleAttributes(_attribute)) {
            return keccak256(abi.encode(_account, _attribute, _issuer));
        }
        if (governance.eligibleAttributesByDID(_attribute)){
            if (_did == bytes32(0)) {
                Attribute memory did = attribute(_account, ATTRIBUTE_DID);
                if (did.value != bytes32(0)) {
                    _did = did.value;
                }
            }
            require(_did != bytes32(0), "MISSING_DID");
            return keccak256(abi.encode(_did, _attribute, _issuer));
        }

        revert("ATTRIBUTE_NOT_ELIGIBLE");
    }

    /// @notice Burn your Quadrata passport and preserve did level attributes
    /// @dev Only owner of the passport
    function burnPassports() external override whenNotPaused {
        address account = _msgSender();
        address[] memory issuers = governance.getAllIssuers();
        for (uint256 i = 0; i < governance.getEligibleAttributesLength(); i++) {
            for(uint256 j = 0; j < issuers.length; j++) {
                bytes32 attributeType = governance.eligibleAttributesArray(i);
                address issuer = issuers[j];
                bytes32 attrKey = attributeKey(account, attributeType, issuer);
                delete _attributesv2[attrKey];
            }
        }
        _burnPassports(account);
    }

    /// @notice Issuer can burn an account's Quadrata passport when requested
    /// @dev Only issuer role
    /// @param _account address of the wallet to burn
    function burnPassportsIssuer(
        address _account
    ) external override whenNotPaused {
        require(IAccessControlUpgradeable(address(governance)).hasRole(ISSUER_ROLE, _msgSender()), "INVALID_ISSUER");
        address issuer = _msgSender();
        address[] memory allIssuers = governance.getAllIssuers();
        bool isEmpty = true;

        // surface pass only delete attributes from issuer
        for (uint256 i = 0; i < governance.getEligibleAttributesLength(); i++) {
            bytes32 attributeType = governance.eligibleAttributesArray(i);
            bytes32 attrKey = attributeKey(_account, attributeType, issuer);
            delete _attributesv2[attrKey];
            // second depth checks if account still has attributes from other issuers
            for(uint256 j = 0; isEmpty && j < allIssuers.length; j++) {
                address otherIssuer = allIssuers[j];
                if (otherIssuer != issuer) {
                    attrKey = attributeKey(_account, attributeType, otherIssuer);
                    if (_attributesv2[attrKey].value != bytes32(0)) {
                        isEmpty = false;
                    }
                }
            }
        }

        if (isEmpty){
            _burnPassports(_account);
        }
        emit BurnPassportsIssuer(issuer, _account);
    }

    /// @dev Loop through all eligible token ids and burn passports if they exist
    /// @param _account address of user
    function _burnPassports(address _account) internal {
        for (uint256 currTokenId = 1; currTokenId <= governance.getMaxEligibleTokenId(); currTokenId++){
            uint256 number = balanceOf(_account, currTokenId);
            if (number > 0){
                _burn(_account, currTokenId, number);
            }
        }
    }

   /// @dev Allow an authorized readers to get all attribute information about a passport holder
    /// @param _account address of user
    /// @param _attribute attribute to get respective value from
    /// @return value of attribute from issuer
    function attributes(
        address _account,
        bytes32 _attribute
    ) public view override returns (Attribute[] memory) {
        require(msg.sender == address(reader) || IAccessControlUpgradeable(address(governance)).hasRole(READER_ROLE, _msgSender()), "INVALID_READER");
        bool groupByDID = governance.eligibleAttributesByDID(_attribute);
        address[] memory issuers = governance.getIssuers();
        Attribute memory did;
        if (groupByDID)
            did = attribute(_account, ATTRIBUTE_DID);
        uint256 counter = 0;
        bytes32 attrKey;
        for (uint256 i = 0; i < issuers.length; i++) {
            if (groupByDID)
                attrKey = keccak256(abi.encode(did.value, _attribute, issuers[i]));
            else
                attrKey = keccak256(abi.encode(_account, _attribute, issuers[i]));
            Attribute memory attr = _attributesv2[attrKey];
            if (attr.epoch != uint256(0)) {
                counter += 1;
            }
        }

        Attribute[] memory attrs = new Attribute[](counter);
        if (counter > 0) {
            uint256 j;
            for (uint256 i = 0; i < issuers.length; i++) {
                if (groupByDID)
                    attrKey = keccak256(abi.encode(did.value, _attribute, issuers[i]));
                else
                    attrKey = keccak256(abi.encode(_account, _attribute, issuers[i]));
                Attribute memory attr = _attributesv2[attrKey];
                attr.issuer = issuers[i];
                if (attr.epoch != uint256(0)) {
                    attrs[j] = attr;
                    j += 1;
                }
            }
        }

        return attrs;
    }


    /// @dev Allow an authorized readers to get one attribute information about a passport holder
    /// @param _account address of user
    /// @param _attribute attribute to get respective value from
    /// @return value of attribute from issuer
    function attribute(
        address _account,
        bytes32 _attribute
    ) public view override returns (Attribute memory) {
        require(msg.sender == address(reader) || IAccessControlUpgradeable(address(governance)).hasRole(READER_ROLE, _msgSender()), "INVALID_READER");
        address[] memory issuers = governance.getIssuers();
        for (uint256 i = 0; i < issuers.length; i++) {
            bytes32 attrKey = attributeKey(_account, _attribute, issuers[i]);
            Attribute memory attr = _attributesv2[attrKey];
            if (attr.epoch != uint256(0)) {
                attr.issuer = issuers[i];
                return attr;
            }
        }
        return Attribute({value: bytes32(0), epoch: uint256(0), issuer: address(0)});
    }


    /// @dev Allow an a user to generate a key for an attribute
    /// @param _account address of user
    /// @param _attribute attribute to get respective value from
    /// @param _issuer address of issuer
    /// @return key for attribute
    function attributeKey(
        address _account,
        bytes32 _attribute,
        address _issuer
    ) public view override returns (bytes32) {
        bytes32 did = governance.eligibleAttributesByDID(_attribute) ? _attributesv2[keccak256(abi.encode(_account, ATTRIBUTE_DID, _issuer))].value : bytes32(0);
        return did != bytes32(0) ? keccak256(abi.encode(did, _attribute, _issuer)) : keccak256(abi.encode(_account, _attribute, _issuer));
    }

    /// @dev Admin function to set the new pending Governance address
    /// @notice Restricted behind a TimelockController
    /// @param _governanceContract contract address of IQuadGovernance
    function setGovernance(address _governanceContract) external override {
        require(_msgSender() == address(governance), "ONLY_GOVERNANCE_CONTRACT");
        require(_governanceContract != address(0), "GOVERNANCE_ADDRESS_ZERO");

        pendingGovernance = _governanceContract;
        emit SetPendingGovernance(pendingGovernance);
    }

    /// @dev Gets the count of attestations for the given attribute(s)
    /// @param _account address of user
    /// @param _attribute attribute to get the counts from
    /// @return count of attestations for the given attribute(s)
    function _attributeLength(
        address _account,
        bytes32[] memory _attribute
    ) internal view returns (uint256) {
        uint256 attributeLength;
        for(uint256 i = 0; i < _attribute.length; i++) {
            for(uint256 j = 0; j < governance.getIssuersLength(); j++) {
                bytes32 attKey = attributeKey(_account, _attribute[i], governance.getIssuers()[j]);
                IQuadPassportStore.Attribute memory attribute = _attributesv2[attKey];
                if (attribute.epoch != uint256(0)) {
                    attributeLength += 1;
                }
            }
        }
        return attributeLength;
    }

    /// @dev Allow users to grab all the metadata for a given attribute(s)
    /// @param _account address of user
    /// @param _attributes attributes to get respective non-value data from
    /// @return attributeNames list of attribute names encoded as keccack256("AML") for example
    /// @return issuers list of issuers for the attribute[i]
    /// @return issuedAts list of epochs for the attribute[i]
    function attributeMetadata(
        address _account,
        bytes32[] memory _attributes
    ) public view override returns (bytes32[] memory attributeNames, address[] memory issuers, uint256[] memory issuedAts) {

        uint256 attributeLength = _attributeLength(_account, _attributes);

        // allocate arrays and set length
        attributeNames = new bytes32[](attributeLength);
        issuers = new address[](attributeLength);
        issuedAts = new uint256[](attributeLength);
        uint256 attributeIndex;

        // second pass fill arrays
        for(uint256 i = 0; i < _attributes.length; i++) {
            for(uint256 j = 0; j < governance.getIssuersLength(); j++) {
                bytes32 attKey = attributeKey(_account, _attributes[i], governance.getIssuers()[j]);
                IQuadPassportStore.Attribute memory attribute = _attributesv2[attKey];
                if (attribute.epoch != 0) {
                    attributeNames[attributeIndex] = _attributes[i];
                    issuers[attributeIndex] = governance.getIssuers()[j];
                    issuedAts[attributeIndex] = attribute.epoch;
                    attributeIndex++;
                }
            }
        }
    }

    /// @dev Allow users to grab all existences for a given attribute(s)
    /// @param _account address of user
    /// @param _attributes attributes to get respective bool data from
    /// @return existences list of bools for the attribute[i]
    function attributesExist(
        address _account,
        bytes32[] memory _attributes
    ) public view override returns(bool[] memory existences) {

        // allocate array and set length
        existences = new bool[](_attributes.length);

        for(uint256 i = 0; i < _attributes.length; i++) {
            for(uint256 j = 0; j < governance.getIssuersLength(); j++) {
                bytes32 attKey = attributeKey(_account, _attributes[i], governance.getIssuers()[j]);
                // set existence to true if attribute exists
                if (_attributesv2[attKey].epoch != 0) {
                    existences[i] = true;
                    break;
                }
            }
        }
    }


    /// @dev Withdraw to an issuer's treasury
    /// @notice Restricted behind a TimelockController
    /// @param _to address an issuer's treasury
    /// @param _amount amount to withdraw
    function withdraw(address payable _to, uint256 _amount) external override whenNotPaused {
        require(
            IAccessControlUpgradeable(address(governance)).hasRole(GOVERNANCE_ROLE, _msgSender()),
            "INVALID_ADMIN"
        );
        bool isValid = false;
        address issuer;

        address[] memory issuers = governance.getIssuers();
        for (uint256 i = 0; i < issuers.length; i++) {
            if (_to == governance.issuersTreasury(issuers[i])) {
                isValid = true;
                issuer = issuers[i];
                break;
            }
        }

        require(_to != address(0), "WITHDRAW_ADDRESS_ZERO");
        require(isValid, "WITHDRAWAL_ADDRESS_INVALID");
        require(_amount <= address(this).balance, "INSUFFICIENT_BALANCE");
        (bool sent,) = _to.call{value: _amount}("");
        require(sent, "FAILED_TO_TRANSFER_NATIVE_ETH");

        emit WithdrawEvent(issuer, _to, _amount);
    }

    /// @dev Admin function to accept and set the governance contract address
    /// @notice Restricted behind a TimelockController
    function acceptGovernance() external override {
        require(_msgSender() == pendingGovernance, "ONLY_PENDING_GOVERNANCE_CONTRACT");

        address oldGov = address(governance);
        governance = IQuadGovernance(pendingGovernance);
        pendingGovernance = address(0);

        emit GovernanceUpdated(oldGov, address(governance));
    }

    /// @dev Admin function to set Metadata URI to associate with a tokenId
    /// @param _tokenId Token Id
    /// @param _uri URI pointing to IPFS
    function setTokenURI(uint256 _tokenId, string memory _uri) external override {
        require(_msgSender() == address(governance), "ONLY_GOVERNANCE_CONTRACT");
        _setURI(_uri, _tokenId);
    }

    /// @dev Admin function to pause critical operations (emergency)
    function pause() external {
        require(
            IAccessControlUpgradeable(address(governance)).hasRole(PAUSER_ROLE, _msgSender()),
            "INVALID_PAUSER"
        );
        _pause();
    }

    /// @dev Admin function to unpause critical operations (emergency)
    function unpause() external {
        require(
            IAccessControlUpgradeable(address(governance)).hasRole(PAUSER_ROLE, _msgSender()),
            "INVALID_PAUSER"
        );
        _unpause();
    }

    /// @dev Retrieve the pause status of the contract
    function passportPaused() external view override returns(bool) {
        return paused();
    }

    function _authorizeUpgrade(address) internal view override {
        require(
            IAccessControlUpgradeable(address(governance)).hasRole(GOVERNANCE_ROLE, _msgSender()),
            "INVALID_ADMIN"
        );
    }

    function setQuadReader(IQuadReader _reader) external {
        require(
            IAccessControlUpgradeable(address(governance)).hasRole(GOVERNANCE_ROLE, _msgSender()),
            "INVALID_ADMIN"
        );
        reader = _reader;
    }

    /// @dev Migrate _attributes to _attributesv2
    /// @param _accounts list of accounts to migrate
    /// @param _eligibleAttributes list of eligible attributes to migrate
    function migrateAttributes(address[] calldata _accounts, bytes32[] calldata _eligibleAttributes) external {
        // check sender has governance role
        require(
            IAccessControlUpgradeable(address(governance)).hasRole(GOVERNANCE_ROLE, _msgSender()),
            "INVALID_ADMIN"
        );

        // loop over all attributes by did/account
        for(uint256 i = 0; i < _eligibleAttributes.length; i++) {
            bytes32 eligibleAttribute = _eligibleAttributes[i];

            // loop over all accounts
            for(uint256 j = 0; j < _accounts.length; j++) {
                address account = _accounts[j];
                bytes32 attrKeyv1;

                if(governance.eligibleAttributesByDID(eligibleAttribute)) {
                    Attribute[] memory did = _attributes[keccak256(abi.encode(account, ATTRIBUTE_DID))];
                    if(did.length == 0) {
                        continue;
                    }
                    attrKeyv1 = keccak256(abi.encode(did[0].value, eligibleAttribute));
                } else {
                    attrKeyv1 = keccak256(abi.encode(account, eligibleAttribute));
                }
                Attribute[] memory attributesV1 = _attributes[attrKeyv1];

                // loop over attributes and write to _attributesv2
                for(uint256 k = 0; k < attributesV1.length; k++) {
                    Attribute memory attributeV1 = attributesV1[k];

                    // skip writing if value is default value
                    if(attributeV1.value == bytes32(0)) {
                        continue;
                    }

                    bytes32 attKey;
                    if(governance.eligibleAttributesByDID(eligibleAttribute)) {
                        Attribute[] memory did = _attributes[keccak256(abi.encode(account, ATTRIBUTE_DID))];
                        attKey = keccak256(abi.encode(did[0].value, eligibleAttribute, attributeV1.issuer));
                    } else {
                        attKey = keccak256(abi.encode(account, eligibleAttribute, attributeV1.issuer));
                    }


                    _attributesv2[attKey] = IQuadPassportStore.Attribute({
                        value: attributeV1.value,
                        epoch: attributeV1.epoch,
                        issuer: address(0)
                    });
                }
                delete _attributes[attrKeyv1];

            }
        }
    }
}