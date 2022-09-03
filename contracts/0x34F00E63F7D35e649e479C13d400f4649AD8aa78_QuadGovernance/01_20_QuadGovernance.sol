//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

import "./interfaces/IQuadPassport.sol";
import "./interfaces/IQuadGovernance.sol";
import "./storage/QuadGovernanceStore.sol";

/// @title Governance Contract for Quadrata Passport
/// @author Fabrice Cheng, Theodore Clapp
/// @notice All admin functions to govern the QuadPassport contract
contract QuadGovernance is IQuadGovernance, AccessControlUpgradeable, UUPSUpgradeable, QuadGovernanceStore {

    // used to prevent logic contract self destruct take over
    constructor() initializer {}

    /// @dev Initializer (constructor)
    function initialize() public initializer {
        __AccessControl_init_unchained();

        // Set Roles
        _setRoleAdmin(PAUSER_ROLE, GOVERNANCE_ROLE);
        _setRoleAdmin(ISSUER_ROLE, GOVERNANCE_ROLE);
        _setRoleAdmin(READER_ROLE, GOVERNANCE_ROLE);
        _setupRole(GOVERNANCE_ROLE, _msgSender());
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    /// @dev Set QuadPassport treasury wallet to withdraw the protocol fees
    /// @notice Restricted behind a TimelockController
    /// @param _newTreasury address of the treasury
    function setTreasury(address _newTreasury) external override {
        require(hasRole(GOVERNANCE_ROLE, _msgSender()), "INVALID_ADMIN");
        require(_newTreasury != _treasury, "TREASURY_ADDRESS_ALREADY_SET");
        require(_newTreasury != address(0), "TREASURY_ADDRESS_ZERO");
        address oldTreasury = _treasury;
        _treasury = _newTreasury;
        emit TreasuryUpdated(oldTreasury, _newTreasury);
    }

    /// @dev Set QuadPassport contract address
    /// @notice Restricted behind a TimelockController
    /// @param _passportAddr address of the QuadPassport contract
    function setPassportContractAddress(address _passportAddr)  external override {
        require(hasRole(GOVERNANCE_ROLE, _msgSender()), "INVALID_ADMIN");
        require(_passportAddr != address(0), "PASSPORT_ADDRESS_ZERO");
        require(address(_passport) != _passportAddr, "PASSPORT_ADDRESS_ALREADY_SET");
        address _oldPassport = address(_passport);
        _passport = IQuadPassport(_passportAddr);

        emit PassportAddressUpdated(_oldPassport, address(_passport));
    }

    /// @dev Set the pending QuadGovernance address in the QuadPassport contract
    /// @notice Restricted behind a TimelockController
    /// @param _newGovernance address of the QuadGovernance contract
    function updateGovernanceInPassport(address _newGovernance)  external override {
        require(hasRole(GOVERNANCE_ROLE, _msgSender()), "INVALID_ADMIN");
        require(_newGovernance != address(0), "GOVERNANCE_ADDRESS_ZERO");
        require(address(_passport) != address(0), "PASSPORT_NOT_SET");

        _passport.setGovernance(_newGovernance);
    }

    /// @dev Confirms the pending QuadGovernance address in the QuadPassport contract
    function acceptGovernanceInPassport() external {
        require(hasRole(GOVERNANCE_ROLE, _msgSender()), "INVALID_ADMIN");
        _passport.acceptGovernance();
    }

    /// @dev Set the eligibility status for a tokenId passport
    /// @notice Restricted behind a TimelockController
    /// @param _tokenId tokenId of the passport
    /// @param _eligibleStatus eligiblity boolean for the tokenId
    /// @param _uri URI of the IPFS link
    function setEligibleTokenId(uint256 _tokenId, bool _eligibleStatus, string memory _uri) external override {
        require(hasRole(GOVERNANCE_ROLE, _msgSender()), "INVALID_ADMIN");

        if(_tokenId > _maxEligibleTokenId){
            require(_maxEligibleTokenId + 1 == _tokenId, "INCREMENT_TOKENID_BY_1");
            _maxEligibleTokenId = _tokenId;
        }
        _eligibleTokenId[_tokenId] = _eligibleStatus;
        _passport.setTokenURI(_tokenId, _uri);

        emit EligibleTokenUpdated(_tokenId, _eligibleStatus);
    }

    /// @dev Set the eligibility status for an attribute type
    /// @notice Restricted behind a TimelockController
    /// @param _attribute keccak256 of the attribute name (ex: keccak256("COUNTRY"))
    /// @param _eligibleStatus eligiblity boolean for the attribute
    function setEligibleAttribute(bytes32 _attribute, bool _eligibleStatus) override external {
        require(hasRole(GOVERNANCE_ROLE, _msgSender()), "INVALID_ADMIN");
        require(_eligibleAttributes[_attribute] != _eligibleStatus, "ATTRIBUTE_ELIGIBILITY_SET");

        _eligibleAttributes[_attribute] = _eligibleStatus;
        if (_eligibleStatus) {
            _eligibleAttributesArray.push(_attribute);
        } else {
            for (uint256 i = 0; i < _eligibleAttributesArray.length; i++) {
                if (_eligibleAttributesArray[i] == _attribute) {
                    _eligibleAttributesArray[i] = _eligibleAttributesArray[_eligibleAttributesArray.length - 1];
                    _eligibleAttributesArray.pop();
                    break;
                }
            }
        }
        emit EligibleAttributeUpdated(_attribute, _eligibleStatus);
    }


    /// @dev Set the eligibility status for an attribute type grouped by DID (Applicable to AML only for now)
    /// @notice Restricted behind a TimelockController
    /// @param _attribute keccak256 of the attribute name (ex: keccak256("AML"))
    /// @param _eligibleStatus eligiblity boolean for the attribute
    function setEligibleAttributeByDID(bytes32 _attribute, bool _eligibleStatus) override external {
        require(hasRole(GOVERNANCE_ROLE, _msgSender()), "INVALID_ADMIN");
        require(_eligibleAttributesByDID[_attribute] != _eligibleStatus, "ATTRIBUTE_ELIGIBILITY_SET");

        _eligibleAttributesByDID[_attribute] = _eligibleStatus;
        emit EligibleAttributeByDIDUpdated(_attribute, _eligibleStatus);
    }

    /// @dev Set the price for querying a single attribute after owning a passport
    /// @notice Restricted behind a TimelockController
    /// @param _attribute keccak256 of the attribute name (ex: keccak256("COUNTRY"))
    /// @param _price price (Native Token Eth/Matic/etc...)
    function setAttributePriceFixed(bytes32 _attribute, uint256 _price) override external {
        require(hasRole(GOVERNANCE_ROLE, _msgSender()), "INVALID_ADMIN");
        require(_pricePerAttributeFixed[_attribute] != _price, "ATTRIBUTE_PRICE_ALREADY_SET");
        uint256 oldPrice = _pricePerAttributeFixed[_attribute];
        _pricePerAttributeFixed[_attribute] = _price;

        emit AttributePriceUpdatedFixed(_attribute, oldPrice, _price);
    }

    /// @dev Set the business attribute price for querying a single attribute after owning a passport
    /// @notice Restricted behind a TimelockController
    /// @param _attribute keccak256 of the attribute name (ex: keccak256("COUNTRY"))
    /// @param _price price (Native Token Eth/Matic/etc...)
    function setBusinessAttributePriceFixed(bytes32 _attribute, uint256 _price) override external {
        require(hasRole(GOVERNANCE_ROLE, _msgSender()), "INVALID_ADMIN");
        require(_pricePerBusinessAttributeFixed[_attribute] != _price, "KYB_ATTRIBUTE_PRICE_ALREADY_SET");
        uint256 oldPrice = _pricePerBusinessAttributeFixed[_attribute];
        _pricePerBusinessAttributeFixed[_attribute] = _price;

        emit BusinessAttributePriceUpdatedFixed(_attribute, oldPrice, _price);
    }

    /// @dev Set the revenue split percentage between Issuers and Quadrata Protocol
    /// @notice Restricted behind a TimelockController
    /// @param _split percentage split (`50` equals 50%)
    function setRevSplitIssuer(uint256 _split) override external {
        require(hasRole(GOVERNANCE_ROLE, _msgSender()), "INVALID_ADMIN");
        require(_revSplitIssuer != _split, "REV_SPLIT_ALREADY_SET");
        require(_split <= 100, "SPLIT_TOO_HIGH");

        uint256 oldSplit = _revSplitIssuer;
        _revSplitIssuer = _split;

        emit RevenueSplitIssuerUpdated(oldSplit, _split);
    }

    /// @dev Add a new issuer or update treasury
    /// @notice Restricted behind a TimelockController
    /// @param _issuer address generating the signature authorizing minting/setting attributes
    /// @param _treasury address of the issuer treasury to withdraw the fees
    function addIssuer(address _issuer, address _treasury) override external {
        require(hasRole(GOVERNANCE_ROLE, _msgSender()), "INVALID_ADMIN");
        require(_treasury != address(0), "TREASURY_ISSUER_ADDRESS_ZERO");
        require(_issuer != address(0), "ISSUER_ADDRESS_ZERO");

        _issuerTreasury[_issuer] = _treasury;

        bool issuerExist = false;

        for (uint256 i = 0; i < _issuers.length; i++) {
            if (_issuers[i] == _issuer) {
                issuerExist = true;
                break;
            }
        }

        if (!issuerExist) {
            grantRole(ISSUER_ROLE, _issuer);
            _issuers.push(_issuer);
            _issuerStatus[_issuer] = true;
        }

        emit IssuerAdded(_issuer, _treasury);
    }

    /// @dev Delete issuer
    /// @notice Restricted behind a TimelockController
    /// @param _issuer address to remove
    function deleteIssuer(address _issuer) override external {
        require(hasRole(GOVERNANCE_ROLE, _msgSender()), "INVALID_ADMIN");
        require(_issuer != address(0), "ISSUER_ADDRESS_ZERO");

        for (uint256 i = 0; i < _issuers.length; i++) {
            if (_issuers[i] == _issuer) {
                _issuers[i] = _issuers[_issuers.length-1];

                _issuers.pop();
                _issuerStatus[_issuer] = false;

                revokeRole(ISSUER_ROLE, _issuer);

                emit IssuerDeleted(_issuer);
                return;
            }
        }
    }

    /// @dev Sets the status for specified issuer
    /// @notice Restricted behind a TimelockController
    /// @param _issuer address to change status
    /// @param _status new status for issuer
    function setIssuerStatus(address _issuer, bool _status) external {
        require(hasRole(GOVERNANCE_ROLE, _msgSender()), "INVALID_ADMIN");
        require(_issuer != address(0), "ISSUER_ADDRESS_ZERO");

        _issuerStatus[_issuer] = _status;

        if(_status) {
            grantRole(ISSUER_ROLE, _issuer);
        } else {
            revokeRole(ISSUER_ROLE, _issuer);
        }
        emit IssuerStatusChanged(_issuer, _status);
    }

    /// @dev Set which attributes an issuer can attest to
    /// @notice Restricted behind a TimelockController
    /// @param _issuer address to change status
    /// @param _attribute attribute to authorize (ex: keccak256("AML"))
    /// @param _permission bool for authorizing an issuer to attest
    function setIssuerAttributePermission(address _issuer, bytes32 _attribute, bool _permission) external {
        require(hasRole(GOVERNANCE_ROLE, _msgSender()), "INVALID_ADMIN");
        require(_issuer != address(0), "ISSUER_ADDRESS_ZERO");
        require(hasRole(ISSUER_ROLE, _issuer), "INVALID_ISSUER");
        require(eligibleAttributes(_attribute) || eligibleAttributesByDID(_attribute), "ATTRIBUTE_NOT_ELIGIBLE");

        _issuerAttributePermission[keccak256(abi.encode(_issuer, _attribute))] = _permission;

        emit IssuerAttributePermission(_issuer, _attribute, _permission);
    }

    function _authorizeUpgrade(address) override internal view {
        require(hasRole(GOVERNANCE_ROLE, _msgSender()), "INVALID_ADMIN");
    }

    /// @dev Get the address of protocol treasury
    /// @return treasury address
    function treasury() override public view returns(address) {
        return _treasury;
    }

    /// @dev Get the address of passport
    /// @return passport address
    function passport() public view returns(IQuadPassport) {
        return _passport;
    }

    /// @dev Get the attribute eligibility
    /// @param _attribute Attribute Type
    /// @return attribute eligibility
    function eligibleAttributes(bytes32 _attribute) override public view returns(bool) {
        return _eligibleAttributes[_attribute];
    }

    /// @dev Get the attribute eligibility by DID
    /// @param _attribute Attribute Type
    /// @return attribute eligibility
    function eligibleAttributesByDID(bytes32 _attribute) override public view returns(bool) {
        return _eligibleAttributesByDID[_attribute];
    }

    /// @dev Get a maintained attribute from eligibility
    /// @param _attribute Attribute Type
    /// @return eligible attribute element
    function eligibleAttributesArray(uint256 _attribute) override public view returns(bytes32) {
        return _eligibleAttributesArray[_attribute];
    }

    /// @dev Get number of eligible attributes currently supported
    /// @return length of eligible attributes
    function getEligibleAttributesLength() override external view returns(uint256) {
        return _eligibleAttributesArray.length;
    }

    /// @dev Get list of eligible tokenIds currently supported
    /// @return length of eligible attributes
    function getMaxEligibleTokenId() override external view returns(uint256) {
        return _maxEligibleTokenId;
    }

    /// @dev Get active tokenId
    /// @param _tokenId TokenId
    /// @return tokenId eligibility
    function eligibleTokenId(uint256 _tokenId) override public view returns(bool) {
        return _eligibleTokenId[_tokenId];
    }

    /// @dev Get query price for an attribute in eth
    /// @param _attribute Attribute Type
    /// @return attribute price for using getter in eth
    function pricePerAttributeFixed(bytes32 _attribute) override public view returns(uint256) {
        return _pricePerAttributeFixed[_attribute];
    }

    /// @dev Get query price for an attribute given a business is asking (in eth)
    /// @param _attribute Attribute Type
    /// @return attribute price for using getter given a business is asking (in eth)
    function pricePerBusinessAttributeFixed(bytes32 _attribute) override public view returns(uint256) {
        return _pricePerBusinessAttributeFixed[_attribute];
    }

    /// @dev Get the length of _issuers array
    /// @return total number of _issuers
    function getIssuersLength() override public view returns (uint256) {
        return _issuers.length;
    }

    /// @dev Get the _issuers array
    /// @return list of issuers
    function getIssuers() override public view returns (address[] memory) {
        return _issuers;
    }

    /// @dev Get the status of an issuer
    /// @param _issuer address of issuer
    /// @return issuer status
    function getIssuerStatus(address _issuer) override public view returns(bool) {
        return _issuerStatus[_issuer];
    }

    /// @dev Get the authorization status for an issuer to attest to a specific attribute
    /// @param _issuer address of issuer
    /// @param _attribute attribute type
    /// @return authorization status
    function getIssuerAttributePermission(address _issuer, bytes32 _attribute) override public view returns(bool) {
        return _issuerAttributePermission[keccak256(abi.encode(_issuer, _attribute))];
    }

    /// @dev Get the revenue split between protocol and _issuers
    /// @return ratio of revenue distribution
    function revSplitIssuer() override public view returns(uint256) {
        return _revSplitIssuer;
    }

    /// @dev Get an issuer at a certain index
    /// @param _index Array index
    /// @return issuer element
    function issuers(uint256 _index) override public view returns(address) {
        return _issuers[_index];
    }

    /// @dev Get an issuer's treasury
    /// @param _issuer address of the issuer
    /// @return issuer treasury
    function issuersTreasury(address _issuer) override public view returns (address) {
        return _issuerTreasury[_issuer];
    }
}