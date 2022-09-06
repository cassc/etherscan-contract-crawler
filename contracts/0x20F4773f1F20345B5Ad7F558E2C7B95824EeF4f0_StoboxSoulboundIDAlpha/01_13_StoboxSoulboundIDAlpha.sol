// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "ERC1155Supply.sol";
import "AccessControl.sol";
import "Strings.sol";

contract StoboxSoulboundIDAlpha is ERC1155Supply, AccessControl {       
    using Strings for uint256;

    string public name = "Stobox Soulbound ID Alpha";        
    uint256 private STOBOX_SOULB_ID_ALPHA = 10000;
    uint16 private MAX_MINT = 1000;
    uint256 private currentCounter = 0;    

    struct SoulbMeta {
        address soulbOwner;
        bool KYC;
        uint256 uintSoulbID;
        string soulbID;
        string country;
        string preferences;
    }

    mapping (uint256 => SoulbMeta) uintSoulbIdToMetadata;

    /**
    * @param _link String with the link for URI for all tokens. Has to be HTTP or IPFS URL.    
    */
    constructor(string memory _link) ERC1155(_link) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);          
        createSoulbound(msg.sender, false, "UA", "");       
    }

    modifier onlySuperAdmin() {
        require(isSuperAdmin(msg.sender), "Avaliable only for Super Admin");
        _;
    }

    /**
     * @notice Add the SuperAdmin role for the address. Allowed only for SuperAdmin.
     * @param _address Address for assigning the super admin role.
     */
    function addSuperAdmin(address _address) external onlySuperAdmin {
        grantRole(DEFAULT_ADMIN_ROLE, _address);
    }

    /**
     * @notice Renouncement of SuperAdmin role by msg.sender. Allowed only for SuperAdmin.
     */
    function renounceSuperAdmin() external onlySuperAdmin {
        renounceRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /**
     * @notice Checks if the address is assigned the SuperAdmin role.
     * @param _address Address for checking.
     */
    function isSuperAdmin(address _address) public view returns (bool) {
        return hasRole(DEFAULT_ADMIN_ROLE, _address);
    }

    /**
     * @notice Set new URI for all tokens. Allowed only for SuperAdmin.
     *         (Exactly this link reads OpenSea to get metadata).
     * @param _newuri New string with the link for URI. Has to be HTTP or IPFS URL.
     */
    function setURI(string memory _newuri) public onlySuperAdmin {
        _setURI(_newuri);
    }

    /**
     * @notice Creation of the Soulb NTT. Mints token to address of the receiver and fill in metadata.
     *         Allowed only for SuperAdmin.
     * @param _to Address of receiver of Soulb NTT.
     * @param _hasKYC True - receiver passed KYC, false - didn't pass KYC .
     * @param _country Literal code of the country of reciever (specified list exists).
     * @param _preferences The link to the json-file of this Soulb NTT.
     */
    function createSoulbound(
        address _to, 
        bool _hasKYC, 
        string memory _country, 
        string memory _preferences) public onlySuperAdmin returns (SoulbMeta memory) {            
            mint(_to, STOBOX_SOULB_ID_ALPHA, 1, "");

            string memory prefix = "AA-";
            string memory ID = (STOBOX_SOULB_ID_ALPHA + currentCounter).toString();            
            string memory currentSoulbID = string.concat(prefix, ID);
            SoulbMeta memory soulbMeta = 
                SoulbMeta(
                    _to, 
                    _hasKYC, 
                    currentCounter, 
                    currentSoulbID, 
                    _country, 
                    _preferences);
            uintSoulbIdToMetadata[currentCounter] = soulbMeta;
            currentCounter++;
            return soulbMeta;
    }

    /**
     * @notice Returns the tuple with all data of structure SoulbMeta for the proper token
     * @param _uintSoulbId uintSoulbID of token you want to get metadata
     */
    function getSoulbMetadata(uint256 _uintSoulbId) public view returns (SoulbMeta memory) {
        return uintSoulbIdToMetadata[_uintSoulbId];
    }

    /**
     * @notice Changes the prefereces (link to the file) for proper token
     * @param _uintSoulbId uintSoulbID of token you want to change metadata
     * @param _newPreferences Link to the file you want to set for proper token
     */
    function setSoulbPreferences(uint256 _uintSoulbId, string memory _newPreferences) public onlySuperAdmin {
        require(_uintSoulbId < currentCounter, "Token with such uintSoulbId doesn't exist!");
        uintSoulbIdToMetadata[_uintSoulbId].preferences = _newPreferences;
    }

    /**
     * @notice Changes the value of flag - if user passed KYC - for proper token
     * @param _uintSoulbId uintSoulbID of token you want to change metadata
     * @param _hasKYC boolean value you want to set for proper token (true - KYC passed, false - didn't pass)
     */
    function setSoulbKYC(uint256 _uintSoulbId, bool _hasKYC) public onlySuperAdmin {
        require(_uintSoulbId < currentCounter, "Token with such uintSoulbId doesn't exist!");
        uintSoulbIdToMetadata[_uintSoulbId].KYC = _hasKYC;
    }
    
    /**
     * @notice Mint new NTT_token to the address. Allowed only for SuperAdmin.
     * Max value of emission = MAX_MINT tokens. If this value exceed, function will revert.
     * @param _account Account to which NTT_token minted.
     * @param _id ID of minted NTT_token.
     * @param _amount Amount of NTT_tokens to mint.
     * @param _data Data which new NTT_token contains.
     */
    function mint(address _account, uint256 _id, uint256 _amount, bytes memory _data)
        internal {
            require(totalSupply(STOBOX_SOULB_ID_ALPHA) < MAX_MINT, 
            "'Stobox Soulbound ID Alpha' emission has reached its maximum value!");
            _mint(_account, _id, _amount, _data);
    }   

    /**
     * @notice Burn NTT_token from the address. Allowed only for SuperAdmin.
     * @param _account Account from which NTT_token burnt.     
     * @param _amount Amount of NTT_tokens to burn.    
     */
    function burn(
        address _account,        
        uint256 _amount
    ) external onlySuperAdmin {        
        _burn(_account, STOBOX_SOULB_ID_ALPHA, _amount);
    } 

    // The following functions are overrides required by Solidity.

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC1155, AccessControl)
        returns (bool)
    {
        if (interfaceId == 0xd9b67a26 || interfaceId == 0x01ffc9a7) {
            return true;
        }
            return super.supportsInterface(interfaceId);
    }    
}