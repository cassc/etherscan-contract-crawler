// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Upgradeable} from "../common/Upgradeable.sol";
import "../interfaces/IProxy.sol";

contract Implementation is Upgradeable {



    // == SETTER == //

    /**
     * @dev Set the collection721's address
     * @param _collection721 the address of collection721
     */
    function setCollection721(address _collection721)
        public
        notCurrentAddress(collection721, _collection721)
        notZeroAddress(_collection721)
        onlySuperAdmin
    {
        collection721 = _collection721;
    }

    /**
     * @dev Set the collection1155's address
     * @param _collection1155 the address of collection1155
     */
    function setCollection1155(address _collection1155)
        public
        notCurrentAddress(collection1155, _collection1155)
        notZeroAddress(_collection1155)
        onlySuperAdmin
    {
        collection1155 = _collection1155;
    }

    /**
     * @dev Set the mint handler's address
     * @param _mintHandler the address of mint handler
     */
    function setMintHandler(address _mintHandler)
        public
        notCurrentAddress(mintHandler, _mintHandler)
        notZeroAddress(_mintHandler)
        onlySuperAdmin
    {
        mintHandler = _mintHandler;
    }

    /**
     * @dev Set the admin mint handler's address
     * @param _adminMintHandler the address of admin mint handler
     */
    function setAdminMintHandler(address _adminMintHandler)
        public
        notCurrentAddress(adminMintHandler, _adminMintHandler)
        notZeroAddress(_adminMintHandler)
        onlySuperAdmin
    {
        adminMintHandler = _adminMintHandler;
    }

    /**
     * @dev Set the buy handler's address
     * @param _buyHandler the address of mint handler
     */
    function setBuyHandler(address _buyHandler)
        public
        notCurrentAddress(buyHandler, _buyHandler)
        notZeroAddress(_buyHandler)
        onlySuperAdmin
    {
        buyHandler = _buyHandler;
    }

    /**
     * @dev Set the cancel handler's address
     * @param _cancelHandler the address of mint handler
     */
    function setCancelHandler(address _cancelHandler)
        public
        notCurrentAddress(cancelHandler, _cancelHandler)
        notZeroAddress(_cancelHandler)
        onlySuperAdmin
    {
        cancelHandler = _cancelHandler;
    }

        /**
     * @dev Set the rent handler's address
     * @param _rentHandler the address of mint handler
     */
    function setRentHandler(address _rentHandler)
        public
        notCurrentAddress(rentHandler, _rentHandler)
        notZeroAddress(_rentHandler)
        onlySuperAdmin
    {
        rentHandler = _rentHandler;
    }

    /**
     * @dev Set the admin fee
     * @param _adminFee the address of mint handler
     */
    function setAdminFee(uint256 _adminFee)
        public
        onlySuperAdmin
    {
        require(_adminFee != adminFee, "Implementation: Can not set the same service fee");
        require(_adminFee <= 50000, "Implementation: service must not be greater than 50%");
        adminFee = _adminFee;
        emit SetAdminFeeEvent(_adminFee);
    }

    

    /**
     * @dev Set the rentFeeRecipient address
     * @param _rentFeeRecipient address
     */
    function setRentFeeRecipient(address _rentFeeRecipient)
        public
        notCurrentAddress(rentFeeRecipient, _rentFeeRecipient)
        notZeroAddress(_rentFeeRecipient)
        onlySuperAdmin
    {
        rentFeeRecipient = _rentFeeRecipient;
    }


    function setSaleAdmin(address _account) public notZeroAddress(_account) onlySuperAdmin notUsers(_account) {
        require(!isUser[_account] && !creatorAdmins[_account], "Implementation: Account was not set as sale admin");
        if(saleAdminList[_account] && !blackList[_account]) {
            revert("Implementation: Account was already set as sale admin");
        }
        saleAdminList[_account] = true;
        blackList[_account] = false;
        emit SetSaleAdminEvent(_account, true);
    }
    
    function revokeSaleAdmin(address _account) public notZeroAddress(_account) onlySuperAdmin {
        require(!blackList[_account] && saleAdminList[_account], "Implementation: Account was not set as sale admin");
        blackList[_account] = true;
        emit SetSaleAdminEvent(_account, false);
    }
    
    function setSaleAdmins(address[] memory _account) public onlySuperAdmin {
        bool[] memory values = new bool[](_account.length);
        
        for(uint256 i = 0; i < _account.length; i++ ){
            if(_account[i] != address(0) && !isUser[_account[i]] && !creatorAdmins[_account[i]]) {
                if(saleAdminList[_account[i]] && !blackList[_account[i]]) {
                    continue;
                }
                saleAdminList[_account[i]] = true;
                blackList[_account[i]] = false;
                values[i] = true;
            }
        }

        emit SetSaleAdminsEvent(_account, values);
    }
    
    function revokeSaleAdmins(address[] memory _account) public onlySuperAdmin {
        bool[] memory values = new bool[](_account.length);
        
        for(uint256 i = 0; i < _account.length; i++ ){
            if(saleAdminList[_account[i]] && !blackList[_account[i]]) {
                blackList[_account[i]] = true;
                values[i] = false;
            }
        }

        emit SetSaleAdminsEvent(_account, values);
    }
    
    function setCreatorAdmin(address _account) public notZeroAddress(_account) onlySuperAdmin notUsers(_account) {
        require(!isUser[_account] && !saleAdminList[_account], "Implementation: Account was not set as creator admin");
        if(creatorAdmins[_account] && !blackList[_account]) {
            revert("Implementation: Account was already set as creator admin");
        }
        creatorAdmins[_account] = true;
        blackList[_account] = false;
        emit SetCreatorAdminEvent(_account, true);
    }
    
    function revokeCreatorAdmin(address _account) public notZeroAddress(_account) onlySuperAdmin {
        require(!blackList[_account] && creatorAdmins[_account], "Implementation: Account was not set as creator admin");
        blackList[_account] = true;
        emit SetCreatorAdminEvent(_account, false);
    }
    
    function setCreatorAdmins(address[] memory _account) public onlySuperAdmin {
        bool[] memory values = new bool[](_account.length);
        
        for(uint256 i = 0; i < _account.length; i++ ){
            if(_account[i] != address(0) 
            && !isUser[_account[i]] && !saleAdminList[_account[i]] 
            ) {
                if(creatorAdmins[_account[i]] && !blackList[_account[i]]) {
                    continue;
                }
                creatorAdmins[_account[i]] = true;
                blackList[_account[i]] = false;
                values[i] = true;
            }
        }

        emit SetCreatorAdminsEvent(_account, values);
    }
    
    function revokeCreatorAdmins(address[] memory _account) public onlySuperAdmin {
        bool[] memory values = new bool[](_account.length);
        
        for(uint256 i = 0; i < _account.length; i++ ){
            if(creatorAdmins[_account[i]] && !blackList[_account[i]]) {
                blackList[_account[i]] = true;
                values[i] = false;
            }
        }

        emit SetCreatorAdminsEvent(_account, values);
    }

    /**
     * @dev Add or remove an account from the blacklist
     * @param _account the wallet address
     * @param _value true/false
     */
    function setBlackList(address _account, bool _value) public onlyOwner {
        blackList[_account] = _value;
    }

    /**
     * @dev Add or remove an account from the signer list
     * @param _account the wallet address
     */
    function setSigner(address _account)
        public
        notCurrentAddress(signer, _account)
        notZeroAddress(_account)
        onlySuperAdmin
    {
        signer = _account;
        emit SetSignerEvent(_account);
    }
    
    /**
     * @dev Add or remove an account from the signer list
     * @param _account the wallet address
     */
    function setRecipient(address _account)
        public
        notCurrentAddress(recipient, _account)
        notZeroAddress(_account)
        onlySuperAdmin
    {
        recipient = _account;
    }

    /**
     * @dev Add an account as super admin
     * @param _addr the wallet address
     */
    function setSuperAdmin(address _addr) public 
        notCurrentAddress(superAdmin, _addr)
        notZeroAddress(_addr)
        notUsers(_addr)
        onlyOwner
    {
        require(!blackList[_addr], "Implementation: Account was revoked");
        superAdmin = _addr;
        emit SetSuperAdminEvent(_addr);
    }




    // == GETTER == //
    /**
     * @dev Return an account is admin or not
     */
    function isSaleAdmin(address _account) public view returns (bool) {
        return saleAdminList[_account] || _account == owner();
    }
    
    function isCreatorAdmin(address _account) public view returns (bool) {
        return creatorAdmins[_account] || _account == owner();
    }

    /**
     * @dev Return an account is blacklisted or not
     */
    function isBlacklisted(address _account) public view returns (bool) {
        return blackList[_account];
    }

    /**
     * @dev Return an account is signer or not
     */
    function isSigner(address _account) public view returns (bool) {
        return signer == _account;
    }

    function isAdmin(address _account) public view returns (bool role) {
        if(_account == owner()) {
            role = true;
        } else if (saleAdminList[_account] && !blackList[_account]) {
            role = true;
        } else if (creatorAdmins[_account] && !blackList[_account]) {
            role = true;
        } else if (_account == superAdmin) {
            role = true;
        } else {
            role = false;
        }

    }

    /**
     * @dev Set the buy handler's address
     * @param _stakingHandler the address of mint handler
     */
    function setStakingHandler(address _stakingHandler)
        public
        notCurrentAddress(stakingHandler, _stakingHandler)
        notZeroAddress(_stakingHandler)
        onlySuperAdmin
    {
        stakingHandler = _stakingHandler;
    }
}