// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./CommunityStorage.sol";

//import "hardhat/console.sol";

contract CommunityView is CommunityStorage {
    using PackedSet for PackedSet.Set;
    using StringUtils for *;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;    

    ///////////////////////////////////////////////////////////
    /// external section
    ///////////////////////////////////////////////////////////
    /**
    * @notice getting balance of owner address
    * @param account user's address
    * @custom:shortd part of ERC721
    */
    function balanceOf(
        address account
    ) 
        external 
        view 
        override
        returns (uint256 balance) 
    {
        
        for (uint8 i = 1; i < rolesCount; i++) {
            if (_isTargetInRole(account, i)) {
                balance += 1;
            }
        }
    }

    /**
    * @notice getting owner of tokenId
    * @param tokenId tokenId
    * @custom:shortd part of ERC721
    */
    function ownerOf(
        uint256 tokenId
    ) 
        external 
        view 
        override
        returns (address owner) 
    {
        uint8 roleId = uint8(tokenId >> 160);
        address w = address(uint160(tokenId - (roleId << 160)));
        
        owner = (_isTargetInRole(w, roleId)) ? w : address(0);

    }
    
     /**
    * @notice getting tokenURI(part of ERC721)
    * @custom:shortd getting tokenURI
    * @param tokenId token ID
    * @return tokenuri
    */
    function tokenURI(
        uint256 tokenId
    ) 
        external 
        view 
        override 
        returns (string memory)
    {
        //_rolesByIndex[_roles[role.stringToBytes32()]].roleURI = roleURI;
        uint8 roleId = uint8(tokenId >> 160);
        address w = address(uint160(tokenId - (roleId << 160)));

        bytes memory bytesExtraURI = bytes(_rolesByIndex[roleId].extraURI[w]);

        if (bytesExtraURI.length != 0) {
            return _rolesByIndex[roleId].extraURI[w];
        } else {
            return _rolesByIndex[roleId].roleURI;
        }
        
    }
    
    

    ///////////////////////////////////////////////////////////
    /// public  section
    ///////////////////////////////////////////////////////////
    /**
     * @dev since user will be in several roles then addresses in output can be duplicated.
     * @notice Returns all addresses accross all roles
     * @custom:shortd all addresses accross all roles
     * @return array of array addresses 
     */
    function getAddresses() public view returns(address[][] memory) {
        address[][] memory l;

        l = new address[][](rolesCount-1);
            
        uint256 tmplen;
        for (uint8 j = 0; j < rolesCount-1; j++) {
            tmplen = _rolesByIndex[j].members.length();
            l[j] = new address[](tmplen);
            for (uint256 i = 0; i < tmplen; i++) {
                l[j][i] = address(_rolesByIndex[j].members.at(i));
            }
        }
        return l;
    }

    /**
     * @dev since user will be in several roles then addresses in output can be duplicated.
     * @notice Returns all addresses belong to Role
     * @custom:shortd all addresses belong to Role
     * @param roleIndexes array of role indexes
     * @return array of array addresses
     */
    function getAddresses(uint8[] memory roleIndexes) public view returns(address[][] memory) {
        address[][] memory l;

        l = new address[][](roleIndexes.length);
        if (roleIndexes.length != 0) {
            
            uint256 tmplen;
            for (uint256 j = 0; j < roleIndexes.length; j++) {
                tmplen = _rolesByIndex[roleIndexes[j]].members.length();
                l[j] = new address[](tmplen);
                for (uint256 i = 0; i < tmplen; i++) {
                    l[j][i] = address(_rolesByIndex[roleIndexes[j]].members.at(i));
                }
            }
        }
        return l;
    }

    function getAddressesByRole(
        uint8 roleIndex, 
        uint256 offset, 
        uint256 limit
    ) 
        public 
        view
        returns(address[][] memory)
    {
        address[][] memory l;

        l = new address[][](1);
        uint256 j = 0;
        uint256 tmplen = _rolesByIndex[roleIndex].members.length();

        uint256 count = 
            offset > tmplen ? 
            0 : 
            (
                limit > (tmplen - offset) ? 
                (tmplen - offset) : 
                limit
            ) ;

        l[j] = new address[](count);
        uint256 k = 0;
        for (uint256 i = offset; i < offset + count; i++) {
            l[j][k] = address(_rolesByIndex[roleIndex].members.at(i));
            k++;
        }
        
        return l;



        /*
        if (page == 0 || count == 0) {
            revert IncorrectInputParameters();
        }

        uint256 len = specialPurchasesList.length();
        uint256 ifrom = page*count-count;

        if (
            len == 0 || 
            ifrom >= len
        ) {
            ret = new address[](0);
        } else {

            count = ifrom+count > len ? len-ifrom : count ;
            ret = new address[](count);

            for (uint256 i = ifrom; i<ifrom+count; i++) {
                ret[i-ifrom] = specialPurchasesList.at(i);
                
            }
        }
        */
    }
    
    /**
     * @dev can be duplicate items in output. see https://github.com/Intercoin/CommunityContract/issues/4#issuecomment-1049797389
     * @notice Returns all roles which member belong to
     * @custom:shortd account's roles
     * @param accounts account's addresses
     * @return array of array of roles, with index of output array corresponding to index of input account
     */
    function getRoles(address[] memory accounts) public view returns(uint8[][] memory) {
        uint8[][] memory l;

        l = new uint8[][](accounts.length);
        if (accounts.length != 0) {
        
            uint256 tmplen;
            for (uint256 j = 0; j < accounts.length; j++) {
                tmplen = _rolesByAddress[accounts[j]].length();
                l[j] = new uint8[](tmplen);
                for (uint256 i = 0; i < tmplen; i++) {
                    l[j][i] = _rolesByAddress[accounts[j]].get(i);

                }
            }
        }
        return l;
    }
    
    /**
     * @dev whether an account has a role
     * @notice returns boolean
     * @custom:shortd whether account has a role
     * @param account address
     * @param role uint8
     * @return boolean
     */
    function hasRole(address account, uint8 role) public view returns(bool) {
        uint256 l = _rolesByAddress[account].length();
        for (uint256 i = 0; i < l; i++) {
            if (_rolesByAddress[account].get(i) == role) {
                return true;
            }
        }
        return false;
    }

    /**
     * @dev can be duplicate items in output. see https://github.com/Intercoin/CommunityContract/issues/4#issuecomment-1049797389
     * @notice if call without params then returns all existing roles 
     * @custom:shortd all roles
     * @return array of roles 
     */
    function getRoles(
    ) 
        public 
        view
        returns(uint8[] memory, string[] memory, string[] memory)
    {
        uint8[] memory indexes = new uint8[](rolesCount-1);
        string[] memory names = new string[](rolesCount-1);
        string[] memory roleURIs = new string[](rolesCount-1);
        // rolesCount start from 1
        for (uint8 i = 1; i < rolesCount; i++) {
            indexes[i-1] = i-1;
            names[i-1] = _rolesByIndex[i].name.bytes32ToString();
            roleURIs[i-1] = _rolesByIndex[i].roleURI;
        }
        return (indexes, names, roleURIs);
    }
    
    /**
     * @notice count of accounts for that role
     * @custom:shortd count of accounts for role
     * @param roleIndex role index
     * @return count of accounts for that role
     */
    function addressesCount(
        uint8 roleIndex
    )
        public
        view
        returns(uint256)
    {
        return _rolesByIndex[roleIndex].members.length();
    }
        
    /**
     * @notice if call without params then returns count of all users which have at least one role
     * @custom:shortd all accounts count
     * @return count of accounts
     */
    function addressesCount(
    )
        public
        view
        returns(uint256)
    {
        return addressesCounter;
    }
    
    /**
     * @notice viewing invite by admin signature
     * @custom:shortd viewing invite by admin signature
     * @param sSig signature of admin whom generate invite and signed it
     * @return structure inviteSignature
     */
    function inviteView(
        bytes memory sSig
    ) 
        public 
        view
        returns(inviteSignature memory)
    {
        return inviteSignatures[sSig];
    }
   
}