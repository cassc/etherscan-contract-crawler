// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/interfaces/IERC721.sol";

/// @title Metasender Protocol a MULTI-TRANSFER project
/// @notice A protocol to send bulk of Transaction compatible with ERC20 and ERC721
/// @notice Using ERC-20 that is complatible with BEP-20

contract MetaSender is Ownable {

    /**************************************************************/
    /****************** PALCO MEMBERS and FEEs ********************/

    //// @notice PALCO members ( free Transactions )
    mapping(address => bool) public PALCO;

    //// @notice cost per transaction
    uint256 public txFee = 0.04 ether;

    //// @notice cost to become a PALCO Member
    uint256 public PALCOPass = 6 ether;

    /**************************************************************/
    /*************************** EVENTS ***************************/

    /// @param  newPALCOMember address of the new PALCO member
    event NewPALCOMember( address newPALCOMember );

    /// @param  addressToRemove address of a PALCO member
    event RemoveToPALCO( address addressToRemove );

    /// @param  newPALCOPass value of new transaction Fee
    event SetPALCOPass( uint256 newPALCOPass );

    /// @param  newTxFee value of new transaction Fee
    event SetTxFee( uint256 newTxFee );

    /// @param  from address of the user
    /// @param  amount transferred amount
    event LogNativeTokenBulkTransfer( address from, uint256 amount);

    /// @param  contractAddress token contract address
    /// @param  amount transferred amount
    event LogTokenBulkTransfer( address contractAddress, uint amount);

    /// @param  contractAddress token contract address
    /// @param  amount withdraw amount
    event WithDrawERC20( address contractAddress, uint256 amount );

    /// @param  owner owner address
    /// @param  amount withdrawn value
    event WithdrawTxFee( address owner, uint256 amount );

    constructor() {

        PALCO[msg.sender] = true;

    }

    /**************************************************************/
    /************************ SET AND GET *************************/

    //// @notice it returns true if a user is on the palco
    //// @param _address the address of the required user
    function isOnPALCO( address _address) public view returns (bool) {

        return PALCO[ _address ];

    }

    //// @notice it adds a new PALCO member
    //// @param _address the address of the new PALCO Member
    function addToPALCO( address _address) external payable {

        require(msg.value >= PALCOPass, "Can't add: Value must be equal or superior of current PALCO fee");

        require( !PALCO[_address] , "Can't add: The address is already a PALCO member");

        PALCO[_address] = true;

        emit NewPALCOMember( _address );

    }

    //// @notice it remove a PALCO Member only owner can access
    //// @param _address address of PALCO Member
    function removeToPALCO( address _address) onlyOwner external {

        require( PALCO[_address], "Can't Delete: User not exist");

        delete PALCO[_address];

        emit RemoveToPALCO( _address );
        
    }

    //// @notice change PALCO membership cost
    //// @param _newTxFee the new PALCO membership cost
    function setPALCOPass( uint256 _newPALCOPass ) onlyOwner external  {

        PALCOPass = _newPALCOPass;

        emit SetPALCOPass( _newPALCOPass );
        
    }

    //// @notice change the Transaction cost
    //// @param _newTxFee the new Transaction cost
    function setTxFee( uint256 _newTxFee ) onlyOwner external  {

        txFee = _newTxFee;

        emit SetTxFee( _newTxFee );

    }

    //// @notice returns total value of passed amount array
    //// @param _value a array with transfer amounts
    function getTotalValue(uint256[] memory _value) private pure returns (uint256) {

        uint256 _amount;

        for (uint256 i = 0; i < _value.length; i++) {

            _amount += _value[i];

        }

        require(_amount > 0);

        return _amount;

    }

    //// @notice returns the required transfer Bulk cost
    //// @param _value the initial value
    //// @param _requiredValue value depending of transaction fee
    function getTransactionCost( uint256 _value, uint256 _requiredValue) private view returns(uint256) {

        uint remainingValue = _value;

        if ( isOnPALCO( msg.sender )) require( remainingValue >= _requiredValue, "Invalid Value: The value is less than required");

        else {

            require( remainingValue >= _requiredValue + txFee, "Invalid Value: The value is less than required");

            remainingValue -= txFee;

        }

        return remainingValue;

    }

    /*************************************************************/
    /*************** MULTI-TRANSFER FUNCTIONS ********************/

    //// @notice BNB MULTI-TRANSFER transactions with same value
    //// @param _to array of receiver addresses
    //// @param _value amount to transfer
    function sendNativeTokenSameValue(address[] memory _to, uint256 _value) external payable{

        require(_to.length <= 255, "Invalid Arguments: Max 255 transactions by batch");

        uint256 totalValue = _to.length * _value;

        uint256 remainingValue = getTransactionCost( msg.value, totalValue );

        for (uint256 i = 0; i < _to.length; i++) {

            remainingValue -= _value;

            require(payable(_to[i]).send(_value), "Transfer failed");

        }

        if (remainingValue > 0) payable(msg.sender).transfer(remainingValue);

        emit LogNativeTokenBulkTransfer( msg.sender, totalValue );

    }

    //// @notice BNB MULTI-TRANSFER transaction with different value
    //// @param _to array of receiver addresses
    //// @param _value array of amounts to transfer
    function sendNativeTokenDifferentValue( address[] memory _to, uint256[] memory _value) external payable {

        require( _to.length == _value.length, "Invalid Arguments: Addresses and values must be equal" );

        require( _to.length <= 255, "Invalid Arguments: Max 255 transactions by batch" );

        uint256 totalValue = getTotalValue( _value );

        uint256 remainingValue = getTransactionCost( msg.value, totalValue );

        for (uint256 i = 0; i < _to.length; i++) {

            remainingValue -= _value[i];

            require( payable(_to[i]).send(_value[i]), "Transfer failed" );

        }

        if (remainingValue > 0) payable(msg.sender).transfer(remainingValue);

        emit LogNativeTokenBulkTransfer( msg.sender, totalValue);
    }

    //// @notice MULTI-TRANSFER ERC20 Tokens with different value
    //// @param _contractAddress Token contract address
    //// @param _to array of receiver addresses
    //// @param _value amount to transfer
    function sendERC20SameValue( address _contractAddress, address[] memory _to, uint256 _value) payable external{

        require( _to.length <= 255, "Invalid Arguments: Max 255 transactions by batch" );

        getTransactionCost( msg.value, 0);

        IERC20 Token = IERC20(_contractAddress);

        for(uint256 i = 0; i < _to.length; i++){

            require(Token.transferFrom(msg.sender, _to[i], _value), 'Transfer failed');

        }

        emit LogTokenBulkTransfer( _contractAddress, _to.length * _value);

    }

    //// @notice MULTI-TRANSFER ERC20 Tokens with different value
    //// @param _contractAddress Token contract address
    //// @param _to array of receiver addresses
    //// @param _value array of amounts to transfer
    function sendERC20DifferentValue( address _contractAddress, address[] memory _to, uint256[] memory _value) payable external{

        require( _to.length == _value.length, "Invalid Arguments: Addresses and values must be equal" );

        require( _to.length <= 255, "Invalid Arguments: Max 255 transactions by batch" );

        getTransactionCost( msg.value, 0);

        IERC20 Token = IERC20(_contractAddress);

        for(uint256 i = 0; i < _to.length; i++){

            require(Token.transferFrom(msg.sender, _to[i], _value[i]), 'Transfer failed');

        }

        emit LogTokenBulkTransfer( _contractAddress, getTotalValue(_value));

    }

    //// @notice MULTI-TRANSFER ERC721 Tokens with different value
    //// @param _contractAddress Token contract address
    //// @param _to array of receiver addresses
    //// @param _tokenId array of token Ids to transfer
    function sendERC721( address _contractAddress, address[] memory _to, uint256[] memory _tokenId) payable external{

        require( _to.length == _tokenId.length, "Invalid Arguments: Addresses and values must be equal" );

        require( _to.length <= 255, "Invalid Arguments: Max 255 transactions by batch" );

        getTransactionCost( msg.value, 0);

        IERC721 Token = IERC721(_contractAddress);

        for(uint256 i = 0; i < _to.length; i++){

            Token.transferFrom(msg.sender, _to[i], _tokenId[i]);
            
        }

        emit LogTokenBulkTransfer( _contractAddress, _tokenId.length );

    }

    /**************************************************************/
    /********************* WITHDRAW FUNCTIONS *********************/

    //// @notice withdraw a ERC20 tokens
    //// @param _address token contract address
    function withDrawERC20( address _address ) onlyOwner external  {

        IERC20 Token = IERC20( _address );

        uint256 balance = Token.balanceOf(address(this));

        require(balance > 0, "Can't withDraw: insufficient founds");

        Token.transfer(owner(), balance);

        emit WithDrawERC20( _address, balance );

    } 

    //// @notice withdraw Fees and memberships
    function withdrawTxFee() onlyOwner external{

        uint256 balance = address(this).balance;

        require(balance > 0, "Can't withDraw: insufficient founds");

        payable(owner()).transfer(balance);

        emit WithdrawTxFee( owner(), balance );

    }

}