// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

import "./Ownable.sol";
import "./Context.sol";
import "./ERC20.sol";
import "./SafeMath.sol";
import "./ERC677.sol";
import "./ERC677Receiver.sol";


/**
 * @title CpxToken
 * @dev Very simple ERC20 Token example, where all tokens are pre-assigned to the creator.
 * Note they can later distribute these tokens as they wish using `transfer` and other
 * `ERC20` functions.
 */
contract CpxToken is Context, Ownable, ERC677 {
    
    using SafeMath for uint256;
    /* Nonces of transfers performed */
    mapping(bytes32 => bool) public transactionHashes;
    
    
    // ------------------------ EVENTS ------------------------ //
    event TransferPreSigned(address indexed from, address indexed to, address indexed delegate, uint256 amount, uint256 fee);
    event ApprovalPreSigned(address indexed from, address indexed to, address indexed delegate, uint256 amount, uint256 fee);
    
    event ValueReceived(address sender, uint256 amount);
    
    
    
    constructor () public ERC20("CenterPrime", "CPX") {
        _mint(_msgSender(), 1000000000  * (10 ** uint256(decimals())));
    }
    

	// --------------------------------------- ERC 865 -------------------------------------------
    
     /**
     * @notice Submit a presigned transfer
     * @param _to address The address which you want to transfer to.
     * @param _value uint256 The amount of tokens to be transferred.
     * @param _fee uint256 The amount of tokens paid to msg.sender, by the owner.
     * @param _nonce uint256 Presigned transaction number.
     */
    function transferPreSigned(
        address _from,
        address _to,
        uint256 _value,
        uint256 _fee,
        uint256 _nonce,
        uint8 v, 
        bytes32 r, 
        bytes32 s
    )
        public
        onlyOwner
        returns (bool)
    {
        require(_to != address(0), 'Invalid _to address');
        bytes32 hashedTx = keccak256(abi.encodePacked('transferPreSigned', address(this), _to, _value, _fee, _nonce));
        require(transactionHashes[hashedTx] == false, 'transaction hash is already used');
        address from = ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hashedTx)),v,r,s);
        require(from == _from, 'Invalid _from address');

        _balances[from] = _balances[from].sub(_value).sub(_fee);
        _balances[_to] = _balances[_to].add(_value);
        _balances[msg.sender] = _balances[msg.sender].add(_fee);
        transactionHashes[hashedTx] = true;
        emit Transfer(from, _to, _value);
        emit Transfer(from, msg.sender, _fee);
        emit TransferPreSigned(from, _to, msg.sender, _value, _fee);
        return true;
    }
    
    
    /**
     * @notice Submit a presigned approval
     * @param _spender address The address which will spend the funds.
     * @param _value uint256 The amount of tokens to allow.
     * @param _fee uint256 The amount of tokens paid to msg.sender, by the owner.
     * @param _nonce uint256 Presigned transaction number.
     */
    function approvePreSigned(
        address _spender,
        uint256 _value,
        uint256 _fee,
        uint256 _nonce,
        uint8 v, 
        bytes32 r, 
        bytes32 s
    )
        public
        onlyOwner
        returns (bool)
    {
        require(_spender != address(0));
        bytes32 hashedTx = keccak256(abi.encodePacked('approvePreSigned', address(this), _spender, _value, _fee, _nonce));
        require(transactionHashes[hashedTx] == false, 'transaction hash is already used');
        address from = ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hashedTx)),v,r,s);
        require(from != address(0), 'Invalid _from address');
        
        _allowances[from][_spender] = _value;
        _balances[from] = _balances[from].sub(_fee);
        _balances[msg.sender] = _balances[msg.sender].add(_fee);
        transactionHashes[hashedTx] = true;
        emit Approval(from, _spender, _value);
        emit Transfer(from, msg.sender, _fee);
        emit ApprovalPreSigned(from, _spender, msg.sender, _value, _fee);
        return true;
    }
    
     /**
     * @notice Increase the amount of tokens that an owner allowed to a spender.
     * @param _spender address The address which will spend the funds.
     * @param _addedValue uint256 The amount of tokens to increase the allowance by.
     * @param _fee uint256 The amount of tokens paid to msg.sender, by the owner.
     * @param _nonce uint256 Presigned transaction number.
     */
    function increaseApprovalPreSigned(
        address _spender,
        uint256 _addedValue,
        uint256 _fee,
        uint256 _nonce,
        uint8 v, 
        bytes32 r, 
        bytes32 s
    )
        public
        onlyOwner
        returns (bool)
    {
        require(_spender != address(0));
        bytes32 hashedTx = keccak256(abi.encodePacked('increaseApprovalPreSigned', address(this), _spender, _addedValue, _fee, _nonce));
        require(transactionHashes[hashedTx] == false, 'transaction hash is already used');
        address from = ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hashedTx)),v,r,s);
        require(from != address(0), 'Invalid _from address');
        
        _allowances[from][_spender] = _allowances[from][_spender].add(_addedValue);
        _balances[from] = _balances[from].sub(_fee);
        _balances[msg.sender] = _balances[msg.sender].add(_fee);
        transactionHashes[hashedTx] = true;
        emit Approval(from, _spender, _allowances[from][_spender]);
        emit Transfer(from, msg.sender, _fee);
        emit ApprovalPreSigned(from, _spender, msg.sender, _allowances[from][_spender], _fee);
        return true;
    }
    
     /**
     * @notice Decrease the amount of tokens that an owner allowed to a spender.
     * @param _spender address The address which will spend the funds.
     * @param _subtractedValue uint256 The amount of tokens to decrease the allowance by.
     * @param _fee uint256 The amount of tokens paid to msg.sender, by the owner.
     * @param _nonce uint256 Presigned transaction number.
     */
    function decreaseApprovalPreSigned(
        address _spender,
        uint256 _subtractedValue,
        uint256 _fee,
        uint256 _nonce,
        uint8 v, 
        bytes32 r, 
        bytes32 s
    )
        public
        onlyOwner
        returns (bool)
    {
        require(_spender != address(0));
        bytes32 hashedTx = keccak256(abi.encodePacked('decreaseApprovalPreSigned', address(this), _spender, _subtractedValue, _fee, _nonce));
        require(transactionHashes[hashedTx] == false, 'transaction hash is already used');
        address from = ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hashedTx)),v,r,s);
        require(from != address(0), 'Invalid _from address');
        
        if (_subtractedValue > _allowances[from][_spender]) {
            _allowances[from][_spender] = 0;
        } else {
            _allowances[from][_spender] = _allowances[from][_spender].sub(_subtractedValue);
        }
        _balances[from] = _balances[from].sub(_fee);
        _balances[msg.sender] = _balances[msg.sender].add(_fee);
        transactionHashes[hashedTx] = true;
        emit Approval(from, _spender, _subtractedValue);
        emit Transfer(from, msg.sender, _fee);
        emit ApprovalPreSigned(from, _spender, msg.sender, _allowances[from][_spender], _fee);
        return true;
    }
    
    
     /**
     * @notice Transfer tokens from one address to another
     * @param _from address The address which you want to send tokens from.
     * @param _to address The address which you want to transfer to.
     * @param _value uint256 The amount of tokens to be transferred.
     * @param _fee uint256 The amount of tokens paid to msg.sender, by the spender.
     * @param _nonce uint256 Presigned transaction number.
     */
    function transferFromPreSigned(
        address _from,
        address _to,
        uint256 _value,
        uint256 _fee,
        uint256 _nonce,
        uint8 v, 
        bytes32 r, 
        bytes32 s
    )
        public
        onlyOwner
        returns (bool)
    {
        require(_to != address(0));
        bytes32 hashedTx = keccak256(abi.encodePacked('transferFromPreSigned', address(this), _from, _to, _value, _fee, _nonce));
        require(transactionHashes[hashedTx] == false, 'transaction hash is already used');
        address spender = ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hashedTx)),v,r,s);
        require(spender != address(0), 'Invalid _from address');
        
        _balances[_from] = _balances[_from].sub(_value);
        _balances[_to] = _balances[_to].add(_value);
        _allowances[_from][spender] = _allowances[_from][spender].sub(_value);
        _balances[spender] = _balances[spender].sub(_fee);
        _balances[msg.sender] = _balances[msg.sender].add(_fee);
        
        transactionHashes[hashedTx] = true;
        emit Transfer(_from, _to, _value);
        emit Transfer(spender, msg.sender, _fee);
        return true;
    }
   
   
   // --------------------------------------- ERC 667 -------------------------------------------

      /**
      * @dev transfer token to a contract address with additional data if the recipient is a contact.
      * @param _to The address to transfer to.
      * @param _value The amount to be transferred.
      * @param _data The extra data to be passed to the receiving contract.
      */
      function transferAndCall(address _to, uint _value, bytes memory _data)
        override
        public
        returns (bool success)
      {
        super.transfer(_to, _value);
        emit Transfer(msg.sender, _to, _value, _data);
        if (isContract(_to)) {
          contractFallback(_to, _value, _data);
        }
        return true;
      }


      // PRIVATE
      function contractFallback(address _to, uint _value, bytes memory _data) private
      {
        ERC677Receiver receiver = ERC677Receiver(_to);
        receiver.onTokenTransfer(msg.sender, _value, _data);
      }
    
      function isContract(address _addr) private returns (bool hasCode)
      {
        uint length;
        assembly { length := extcodesize(_addr) }
        return length > 0;
      }
      
      /**
      * accept ether
      */
    fallback() external payable {
            emit ValueReceived(msg.sender, msg.value);
    }

    
}