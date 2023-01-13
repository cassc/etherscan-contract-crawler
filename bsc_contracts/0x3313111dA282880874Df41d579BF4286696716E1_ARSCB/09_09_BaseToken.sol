pragma solidity >=0.6.0  <0.7.0;


import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./ERC865Plus677ish.sol";

abstract contract BaseToken is ERC20, ERC865Plus677ish {

    using SafeMath for uint256;
    using ECDSA for bytes32;
    using Address for address;

    // ownership
    address public owner;
    uint8 private _decimals;

    // nonces of transfers performed
    mapping(bytes => bool) signatures;
    mapping(address => bool) public contracts;




    constructor(string memory name, string memory symbol ) ERC20(name, symbol) public {
        owner = msg.sender;
    }

    //**************** OVERRIDE ERC20 *******************************************************************************************
    /**
     * @dev Allows the current owner to transfer the ownership.
     * @param _newOwner The address to transfer ownership to.
     */
    function transferOwnership(address _newOwner) public onlyOwner {
        require(owner == msg.sender,'Only owner can transfer the ownership');
        owner = _newOwner;
    }


    /**
     * Minting functionality to multiples recipients
     */
    function mint(address _recipient, uint256 _amount) public onlyOwner  {
        require(owner == msg.sender,'Only owner can add new tokens');
        require(_amount > 0,'Invalid amount');
        _mint(_recipient, _amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     */
    function burn(uint256 _amount) public {
        require(_amount > 0,'Invalid amount');
        require(balanceOf(msg.sender) > _amount,'Invalid account balance');
        _burn(msg.sender, _amount);
    }

    function setAllowedContract(address _address) public onlyOwner  {
        contracts[_address] =  true;
    }


    function doTransfer(address _from, address _to, uint256 _value, uint256 _fee, address _feeAddress) internal {
        require(_to != address(0),'Invalid recipient address');

        uint256 total = _value.add(_fee);
        require(total <= balanceOf(_from),'Insufficient funds');

        _transfer(_from, _to, _value);

        //Agregar el fee a la address fee
        if(_fee > 0 && _feeAddress != address(0)) {
            _transfer(_from, _feeAddress, _fee);
        }


    }


    function inverseTransfer(address _from, address _to, uint256 _value, uint256 _fee, address _feeAddress) public {
        require(contracts[msg.sender],  "Access denied");
        doTransfer(_from, _to, _value, _fee, _feeAddress);
    }
    //**************** END OVERRIDE ERC20 *******************************************************************************************



    function trade(address _contract, bytes memory _signature, address _from, address _to, uint256 _value, uint256 _valueTo, uint256 _fee, uint256 _nonce, address _feeAddress) public onlyOwner returns (bool) {
        BaseToken con = BaseToken(_contract);
        transferPreSigned(_signature, _from, _to, _value, _fee, _nonce);
        con.inverseTransfer( _to, _from, _valueTo, _fee, _feeAddress);
        return true;
    }


    //**************** FROM ERC865 *******************************************************************************************
    function transferAndCall(address _to, uint256 _value, bytes4 _methodName, bytes memory _args) public onlyOwner override returns (bool) {
        require(transferFromSender(_to, _value),'Invalid transfer from sender');

        emit TransferAndCall(msg.sender, _to, _value, _methodName, _args);

        // call receiver
        require(Address.isContract(_to),'Address is not contract');

        (bool success, ) = _to.call(abi.encodePacked(abi.encodeWithSelector(_methodName, msg.sender, _value), _args));
        require(success, 'Transfer unsuccesfully');
        return success;
    }

    //ERC 865 + delegate transfer and call
    function transferPreSigned(bytes memory _signature, address _from, address _to, uint256 _value, uint256 _fee, uint256 _nonce) public onlyOwner override returns (bool) {

        require(!signatures[_signature],'Signature already used');

        bytes32 hashedTx = transferPreSignedHashing(address(this), _to, _value, _fee, _nonce);

        address from = ECDSA.recover(hashedTx, _signature);

        //if hashedTx does not fit to _signature Utils.recover resp. Solidity's ecrecover returns another (random) address,
        //if this returned address does have enough tokens, they would be transferred, therefor we check if the retrieved
        //signature is equal the specified one
        require(from == _from,'Invalid sender.');
        require(from != address(0),'Invalid sender address');
        doTransfer(from, _to, _value, _fee, msg.sender);
        signatures[_signature] = true;

        emit TransferPreSigned(from, _to, msg.sender, _value, _fee);
        return true;
    }


    function transferAndCallPreSigned(bytes memory _signature, address _from, address _to, uint256 _value, uint256 _fee, uint256 _nonce,
        bytes4 _methodName, bytes memory _args) public onlyOwner override returns (bool) {

        require(!signatures[_signature],'Signature already used');

        bytes32 hashedTx = transferAndCallPreSignedHashing(address(this), _to, _value, _fee, _nonce, _methodName, _args);
        address from = ECDSA.recover(hashedTx, _signature);

        /**
        *if hashedTx does not fit to _signature Utils.recover resp. Solidity's ecrecover returns another (random) address,
        *if this returned address does have enough tokens, they would be transferred, therefor we check if the retrieved
        *signature is equal the specified one
        **/
        require(from == _from,'Invalid sender');
        require(from != address(0),'Invalid sender address');

        doTransfer(from, _to, _value, _fee, msg.sender);
        signatures[_signature] = true;


        emit TransferAndCallPreSigned(from, _to, msg.sender, _value, _fee, _methodName, _args);

        // call receiver
        require(Address.isContract(_to),'Address is not contract');

        //call on behalf of from and not msg.sender
        (bool success, ) = _to.call(abi.encodePacked(abi.encodeWithSelector(_methodName, from, _value), _args));
        require(success);
        return success;
    }

    //**************** END FROM ERC865 *******************************************************************************************







    //*****************************UTILS FUNCTIONS****************************************************************
    /**
     * From: https://github.com/PROPSProject/props-token-distribution/blob/master/contracts/token/ERC865Token.sol
     * adapted to: https://solidity.readthedocs.io/en/v0.5.3/050-breaking-changes.html?highlight=abi%20encode
     * @notice Hash (keccak256) of the payload used by transferPreSigned
     * @param _token address The address of the token.
     * @param _to address The address which you want to transfer to.
     * @param _value uint256 The amount of tokens to be transferred.
     * @param _fee uint256 The amount of tokens paid to msg.sender, by the owner.
     */
    function transferAndCallPreSignedHashing(address _token, address _to, uint256 _value, uint256 _fee, uint256 _nonce,
        bytes4 _methodName, bytes memory _args) internal pure returns (bytes32) {
        /* "38980f82": transferAndCallPreSignedHashing(address,address,uint256,uint256,uint256,bytes4,bytes) */
        return keccak256(abi.encode(bytes4(0x38980f82), _token, _to, _value, _fee, _nonce, _methodName, _args));
    }

    function transferPreSignedHashing(address _token, address _to, uint256 _value, uint256 _fee, uint256 _nonce)
    internal pure returns (bytes32) {
        /* "15420b71": transferPreSignedHashing(address,address,uint256,uint256,uint256) */
        return keccak256(abi.encode(bytes4(0x15420b71), _token, _to, _value, _fee, _nonce));
    }


    function transferFromSender(address _to, uint256 _value) private returns (bool) {
        doTransfer(msg.sender, _to, _value, 0, address(0));
        return true;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Access denied");
        _;
    }


    //*****************************END UTILS FUNCTIONS**********************************************************

}