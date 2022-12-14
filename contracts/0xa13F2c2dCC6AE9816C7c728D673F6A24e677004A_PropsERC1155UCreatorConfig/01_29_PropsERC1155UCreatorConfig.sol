// SPDX-License-Identifier: Apache 2.0
pragma solidity ^0.8.4;

//  ==========  External imports    ==========

import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/MulticallUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";

import "@thirdweb-dev/contracts/openzeppelin-presets/metatx/ERC2771ContextUpgradeable.sol";
import "@thirdweb-dev/contracts/feature/interface/IOwnable.sol";
import "@thirdweb-dev/contracts/lib/MerkleProof.sol";

//  ==========  Internal imports    ==========

import "../interfaces/IAllowlist.sol";
import "../interfaces/IConfig.sol";
import "../interfaces/IPropsContract.sol";
import "../interfaces/IPropsAccessRegistry.sol";
import "../interfaces/ISplitMain.sol";
import "../interfaces/IPropsCreatorConfig.sol";

import "hardhat/console.sol";

interface SanctionsList {
    function isSanctioned(address addr) external view returns (bool);
}

contract PropsERC1155UCreatorConfig is
    Initializable,
    IOwnable,
    IConfig,
    IPropsContract,
    ReentrancyGuardUpgradeable,
    PausableUpgradeable,
    ERC2771ContextUpgradeable,
    MulticallUpgradeable,
    AccessControlEnumerableUpgradeable
{
    using StringsUpgradeable for uint256;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.Bytes32Set;
    using ECDSAUpgradeable for bytes32;

    bytes32 private constant MODULE_TYPE = bytes32("PropsERC1155UCreatorConfig");
    uint256 private constant VERSION = 2;

    bytes32 private constant CONTRACT_ADMIN_ROLE = keccak256("CONTRACT_ADMIN_ROLE");
    bytes32 private constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 private constant PRODUCER_ROLE = keccak256("PRODUCER_ROLE");
    // @dev reserving space for 10 more roles
    bytes32[32] private __gap;

    string public baseURI_;
    uint256 public tokenIndex;
    address private _owner;
    address public splitMain;
    address public project;
    address[] private trustedForwarders;
    address public signatureVerifier;
    string public contractURI;
    address private parentContract;

    address public SANCTIONS_CONTRACT;

    mapping(uint256 => IPropsCreatorConfig.ERC1155Token) public tokens;
    mapping(string => bool) internal nonces;

    mapping(address => bool) public disallowedOperators;
    mapping(address => string) public disallowedOperatorsMessages;

    struct ownedToken{
        uint256 _tokenId;
        uint256 _quantity;
    }

    mapping(address => uint256[]) public tokenIDsOwnedByAddress;
    mapping(address => uint256[]) public tokenIDQuantityOwnedByAddress; 

    error AllowlistInactive();
    error MintQuantityInvalid();
    error MerkleProofInvalid();
    error InvalidSignature();
    error ExpiredSignature();
    error Sanctioned();

    uint256 public signatureExpiration;

    //////////////////////////////////////////////
    // Init
    /////////////////////////////////////////////

    function initialize(
        address _defaultAdmin,
        address[] memory _trustedForwarders
    ) public initializer {
        __ReentrancyGuard_init();
        __ERC2771Context_init(_trustedForwarders);
     
        _owner = _defaultAdmin;
        tokenIndex = 1;

        _setupRole(DEFAULT_ADMIN_ROLE, _defaultAdmin);
        _setRoleAdmin(CONTRACT_ADMIN_ROLE, DEFAULT_ADMIN_ROLE);
        _setRoleAdmin(PRODUCER_ROLE, CONTRACT_ADMIN_ROLE);
        _setRoleAdmin(MINTER_ROLE, PRODUCER_ROLE);

    }

    /*///////////////////////////////////////////////////////////////
                      Generic contract logic
  //////////////////////////////////////////////////////////////*/

    /// @dev Returns the type of the contract.
    function contractType() external pure returns (bytes32) {
        return MODULE_TYPE;
    }

    /// @dev Returns the version of the contract.
    function contractVersion() external pure returns (uint8) {
        return uint8(VERSION);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return hasRole(DEFAULT_ADMIN_ROLE, _owner) ? _owner : address(0);
    }

    function setParentContract(address _address)
        external
    {
        require(hasMinRole(CONTRACT_ADMIN_ROLE));
        parentContract = _address;
    }

    function setSactionsContract(address _address)
        external
    {
        require(hasMinRole(CONTRACT_ADMIN_ROLE));
        SANCTIONS_CONTRACT = _address;
    }

    function setSplitMain(address _address)
        external
    {
        require(hasMinRole(CONTRACT_ADMIN_ROLE));
        splitMain = _address;
    }

    function getSplitMain() external view returns (address) {
        return splitMain;
    }

    function setSignatureVerifier(address _address)
        external
    {
        require(hasMinRole(CONTRACT_ADMIN_ROLE));
        signatureVerifier = _address;
    }

    function getSignatureVerifier() external view returns (address) {
        return signatureVerifier;
    }

    function toggleOperatorAccess(address _operatorAddress, bool _isBlocked, string memory _message)
        external
    {
        require(hasMinRole(CONTRACT_ADMIN_ROLE));
        disallowedOperators[_operatorAddress] = _isBlocked;
        disallowedOperatorsMessages[_operatorAddress] = _message;
    }

    function getDisallowedOperatorMessage(address _operatorAddress) external view returns (string memory) {
        return disallowedOperatorsMessages[_operatorAddress];
    }

    function isOperatorBlocked(address _operatorAddress) external view returns (bool) {
        if(isSanctioned(_operatorAddress)) {
            return true;
        }
        else{
            return disallowedOperators[_operatorAddress];
        }
        
    }

   

    function isSanctioned(address _operatorAddress) public view returns (bool) {
        SanctionsList sanctionsList = SanctionsList(SANCTIONS_CONTRACT);
        bool isToSanctioned = sanctionsList.isSanctioned(_operatorAddress);
        return isToSanctioned;
    }

    function getToken(uint256 _tokenId) public view returns (IPropsCreatorConfig.ERC1155Token memory) {
        return tokens[_tokenId];
    }

    function getTokenIndex() external view returns (uint256) {
        return tokenIndex;
    }

    function setTokenIndex(uint256 _index)
        external
    {
        require(hasMinRole(CONTRACT_ADMIN_ROLE));
        tokenIndex = _index;
    }

     /// @dev Lets a contract admin set the URI for the baseURI.
    function setBaseURI(string calldata _baseURI)
        external
    {
        require(hasMinRole(CONTRACT_ADMIN_ROLE));
        baseURI_ = _baseURI;
    }

    function getBaseURI() public view returns (string memory) {
        return baseURI_;
    }

    function getTokenURI(uint256 _tokenId) public view returns (string memory) {
       return string(abi.encodePacked(baseURI_, _tokenId.toString(), ".json"));
    }

    function getTokenCheck(IPropsCreatorConfig.ERC1155Token memory _token) public view returns (string memory) {
         string memory tokenCheck = string(
                abi.encodePacked(
                    _token.uid,
                    StringsUpgradeable.toString(_token.tokenId),
                    _token.name,
                    StringsUpgradeable.toString(_token.maxSupply),
                    StringsUpgradeable.toString(_token.royaltyPercentage)
                )
            );
        return tokenCheck;
    }

    function getPrimaryCheck(IPropsCreatorConfig.Split memory _primarySplit) public view returns (string memory) {
         string memory primaryCheck = StringsUpgradeable.toString(_primarySplit.distributorFee);
         for (uint256 i; i < _primarySplit.accounts.length; i++) {
            if(isSanctioned(_primarySplit.accounts[i])) revert Sanctioned();
           primaryCheck =  string(
                abi.encodePacked(
                    primaryCheck,
                    StringsUpgradeable.toHexString(uint160(address(_primarySplit.accounts[i])), 20),
                    StringsUpgradeable.toString(_primarySplit.percentAllocations[i])
                )
            );
         }
        return primaryCheck;
    }


     function getRoyaltyCheck(IPropsCreatorConfig.Split memory _royaltySplit) public view returns (string memory) {
        string memory royaltyCheck = StringsUpgradeable.toString(_royaltySplit.distributorFee);
         for (uint256 i; i < _royaltySplit.accounts.length; i++) {
            if(isSanctioned(_royaltySplit.accounts[i])) revert Sanctioned();
            royaltyCheck =  string(
                abi.encodePacked(
                    royaltyCheck,
                    StringsUpgradeable.toHexString(uint160(address(_royaltySplit.accounts[i])), 20),
                    StringsUpgradeable.toString(_royaltySplit.percentAllocations[i])
                )
            );

         }
        return royaltyCheck;
    }

     function getCreationCheck(IPropsCreatorConfig.ERC1155Token memory _token, IPropsCreatorConfig.Split memory _primarySplit, IPropsCreatorConfig.Split memory _royaltySplit) external view returns(string memory, string memory, string memory) {
        return (getTokenCheck(_token), getPrimaryCheck(_primarySplit),getRoyaltyCheck(_royaltySplit));
    }


    function _upsertToken(IPropsCreatorConfig.ERC1155Token memory _token, IPropsCreatorConfig.Split memory _primarySplit, IPropsCreatorConfig.Split memory _royaltySplit, bool _updateSplits)
        internal
        returns (IPropsCreatorConfig.ERC1155Token memory)
    {

        if(_updateSplits){
            revertSanctionedSplitAccounts(_primarySplit.accounts);
            revertSanctionedSplitAccounts(_royaltySplit.accounts);
            address royaltySplitAddress = ISplitMain(splitMain).createSplit(_royaltySplit.accounts, _royaltySplit.percentAllocations, _royaltySplit.distributorFee, _owner);
            address primarySplitAddress = ISplitMain(splitMain).createSplit(_primarySplit.accounts, _primarySplit.percentAllocations, _primarySplit.distributorFee, _owner);
            _token.royaltyReceiver = royaltySplitAddress;
            _token.primaryReceiver = primarySplitAddress;
            IPropsCreatorConfig(parentContract).setTokenRoyalty(_token.tokenId, royaltySplitAddress, uint96(_token.royaltyPercentage));
        }
        

       if(_token.tokenId > 0 && keccak256(abi.encodePacked(tokens[_token.tokenId].name)) != keccak256("")){
            console.log("UPDATING EXISTING TOKEN");
            tokens[_token.tokenId] = _token;
        }
        else{
             console.log("UPSERTING NEW TOKEN", tokenIndex);
            _token.tokenId = tokenIndex;
            tokens[tokenIndex] = _token;
            tokenIndex++;
        }

        return _token;

    }

    function revertSanctionedSplitAccounts(address[] memory _accounts) internal view {
        for (uint256 i; i < _accounts.length; i++) {
            if(isSanctioned(_accounts[i])) revert Sanctioned();
        }
    }

    function upsertToken(IPropsCreatorConfig.ERC1155Token memory _token, IPropsCreatorConfig.Split memory _primarySplit, IPropsCreatorConfig.Split memory _royaltySplit, bool _updateSplits)
        external returns (IPropsCreatorConfig.ERC1155Token memory)
    {
        require(msg.sender == parentContract || hasMinRole(PRODUCER_ROLE), "UNAUTHORIZED");
        if(isSanctioned(_msgSender())) revert Sanctioned();
        _token = _upsertToken(_token, _primarySplit, _royaltySplit, _updateSplits);
        return _token;
    }

    function updateOwnership(address from, address to, uint256[] memory tokenIds, uint256[] memory amounts) external
    {
        require(msg.sender == parentContract, "UNAUTHORIZED");
        for (uint256 i = 0; i < tokenIds.length; i++) {
           _updateTokenOwnership(from, to, tokenIds[i], amounts[i]);
        }
        
    }

    function _updateTokenOwnership(address from, address to, uint256 tokenId, uint256 amount) internal
    {
        if (from != address(0x0)) {
            for (uint256 i = 0; i < tokenIDsOwnedByAddress[from].length; i++) {
                if (tokenIDsOwnedByAddress[from][i] == tokenId) {
                    _removeTokenOwnership(from, i, amount);
                    break;
                }
            }
        }
        _addTokenOwnership(to, tokenId, amount);
        
    }

    function _removeTokenOwnership(address from, uint256 index, uint256 amount) internal
    {
        if (tokenIDQuantityOwnedByAddress[from][index] > amount) {
            tokenIDQuantityOwnedByAddress[from][index] -= amount;
        } else {
            tokenIDQuantityOwnedByAddress[from][index] = tokenIDQuantityOwnedByAddress[from][tokenIDQuantityOwnedByAddress[from].length - 1];
            tokenIDQuantityOwnedByAddress[from].pop();

            tokenIDsOwnedByAddress[from][index] = tokenIDsOwnedByAddress[from][tokenIDsOwnedByAddress[from].length - 1];
            tokenIDsOwnedByAddress[from].pop();
        }
    }

    function _addTokenOwnership(address to, uint256 tokenId, uint256 amount) internal
    {
        for (uint256 i = 0; i < tokenIDsOwnedByAddress[to].length; i++) {
            if (tokenIDsOwnedByAddress[to][i] == tokenId) {
                tokenIDQuantityOwnedByAddress[to][i] += amount;
                return;
            }
        }

        tokenIDsOwnedByAddress[to].push(tokenId);
        tokenIDQuantityOwnedByAddress[to].push(amount);

    }

    function balanceOf(address owner) external view returns (uint256 balance){
        return tokenIDsOwnedByAddress[owner].length;
    }

    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256) { 
        return tokenIDsOwnedByAddress[owner][index];
    }
    

    function setOwner(address _newOwner) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(hasRole(DEFAULT_ADMIN_ROLE, _newOwner), "!ADMIN");
        address _prevOwner = _owner;
        _owner = _newOwner;

        emit OwnerUpdated(_prevOwner, _newOwner);
    }


    /// @dev Lets a contract admin set the address for the parent project.
    function setProject(address _project) external {
        require(hasMinRole(PRODUCER_ROLE));
        project = _project;
    }

    function setContractURI(string calldata _uri)
        external
    {
        require(hasMinRole(CONTRACT_ADMIN_ROLE));
        contractURI = _uri;
    }

     function setSignatureExpirationWindow(uint256 _lengthOfValidity)
        external
    {
        require(hasMinRole(CONTRACT_ADMIN_ROLE));
        signatureExpiration = _lengthOfValidity;
    }

    /*///////////////////////////////////////////////////////////////
                      Miscellaneous / Overrides
  //////////////////////////////////////////////////////////////*/

  function packMintString(string memory _string1, string memory _string2, string memory _string3,string memory _string4,string memory _string5) external pure returns (string memory) {
    return string(abi.encodePacked(_string1, _string2, _string3, _string4, _string5));

  }

  function revertOnAllocationCheckFailure(IPropsCreatorConfig.AllocationCheck calldata check) external view {
     if (
            block.timestamp < check.allowlist.startTime ||
            block.timestamp > check.allowlist.endTime ||
            !check.allowlist.isActive
        ) revert AllowlistInactive();
        if(check._quantity + check._minted > check.allowlist.maxMintPerWallet || check._quantity < 1) revert MintQuantityInvalid();
        if(check.allowlist.typedata != bytes32(0)){
        if (check._quantity > check._alloted || ((check._quantity + check._minted) > check._alloted)) revert MintQuantityInvalid();
        (bool validMerkleProof, ) = MerkleProof.verify(
            check._proof,
            check.allowlist.typedata,
            keccak256(abi.encodePacked(check._address, check._alloted))
        );
        if (!validMerkleProof) revert MerkleProofInvalid();
        }
  }

   function revertOnUnauthorizedSignature(IPropsCreatorConfig.SignatureRequest calldata _inputs ) external view {
   
     if(isSanctioned(_msgSender())) revert Sanctioned();
     if(_inputs.issuedOn > block.timestamp || block.timestamp - _inputs.issuedOn > signatureExpiration) revert ExpiredSignature();
     if(ECDSAUpgradeable.recover(keccak256(abi.encodePacked(_inputs.tokenCheck, _inputs.primaryCheck, _inputs.royaltyCheck, _inputs.configuration, _inputs.quantity, _inputs.price, _inputs.nonce, _inputs.issuedOn)).toEthSignedMessageHash(), _inputs.signature) !=  signatureVerifier) revert InvalidSignature();
   }

   function isUniqueArray(uint256[] calldata _array)
        public
        view
        returns (bool)
    {

        for (uint256 i = 0; i < _array.length; i++) {
            for (uint256 j = 0; j < _array.length; j++) {
                if (_array[i] == _array[j] && i != j) return false;
            }
        }
        return true;
    }

     function isValidMinter(address _operatorAddress, uint256[] calldata _array) public view returns (bool) {
        require(!isSanctioned(_operatorAddress), "S");
        require(isUniqueArray(_array), "D");
        return true;
    }

    function grantRole(bytes32 role, address account)
        public
        virtual
        override(AccessControlUpgradeable, IAccessControlUpgradeable)
    {
        require(hasMinRole(CONTRACT_ADMIN_ROLE));
        _grantRole(role, account);
       
    }

    function revokeRole(bytes32 role, address account)
        public
        virtual
        override(AccessControlUpgradeable, IAccessControlUpgradeable)
    {
        require(hasMinRole(CONTRACT_ADMIN_ROLE));
        _revokeRole(role, account);
       
    }

    function hasMinRole(bytes32 _role) public view virtual returns (bool) {
        // @dev does account have role?
        if (hasRole(_role, _msgSender())) return true;
        // @dev are we checking against default admin?
        if (_role == DEFAULT_ADMIN_ROLE) return false;
        // @dev walk up tree to check if user has role admin role
        return hasMinRole(getRoleAdmin(_role));
    }


    function _msgSender()
        internal
        view
        virtual
        override(ContextUpgradeable, ERC2771ContextUpgradeable)
        returns (address sender)
    {
        return ERC2771ContextUpgradeable._msgSender();
    }

    function _msgData()
        internal
        view
        virtual
        override(ContextUpgradeable, ERC2771ContextUpgradeable)
        returns (bytes calldata)
    {
        return ERC2771ContextUpgradeable._msgData();
    }


    uint256[49] private ___gap;
}