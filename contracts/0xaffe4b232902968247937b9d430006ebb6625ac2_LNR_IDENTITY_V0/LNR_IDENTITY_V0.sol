/**
 *Submitted for verification at Etherscan.io on 2022-10-14
*/

// File: @openzeppelin/contracts/utils/Context.sol


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: contracts/LNR_IDENTITY_V0.sol


// By Derp Herpenstein (https://www.derpnation.xyz, https://www.avime.com)

pragma solidity ^0.8.0;


interface ILNR {
   function owner(bytes32 _name) external view returns(address);
   function addr(bytes32 _name) external view returns (address);
}

interface IWLNR {
  function ownerOf(uint256) view external returns (address);
  function nameToId(bytes32) view external returns (uint256);
}

interface IERC721 {
  function ownerOf(uint256) view external returns (address);
}

contract LNR_IDENTITY_V0 is Ownable{
    event Post(bytes32 indexed poster, bytes32 indexed replyTo, string message, bytes32 indexed indexedTag, bytes32[] tags);
    event SetIdentity(bytes32 indexed name, bytes32[] keys, string[] values, bool indexed store);

    // identity is a virtually infinitely large datastore that as user can shove anything they want into
    struct Identity {
      bool initialized;
      mapping(bytes32 => string) keyValue;
    }

    address public wlnrAddress = address(0);//0x2Cc8342d7c8BFf5A213eb2cdE39DE9a59b3461A7
    address public lnrAddress = address(0); //0x5564886ca2C518d1964E5FCea4f423b41Db9F561
    mapping(bytes32 => Identity) public userIdentities; // maps a LNR domain name to an identity

    constructor() payable Ownable(){
    }

    function deposit() public payable {
    }

    function updateLNRAddress(address _addr) public onlyOwner {
      require(lnrAddress == address(0), 'Can only be changed once');
      lnrAddress = _addr;
    }

    function updateWLNRAddress(address _addr) public onlyOwner {
      require(wlnrAddress == address(0), 'Can only be changed once');
      wlnrAddress = _addr;
    }

    // checks to see if the owner of the nft is either the owner of the LNR or the delegated address of the LNR
    // returns true if the caller owns or has been delegated the LNR, returns false otherwise
    function verifyAddressOwnsName(bytes32 _name, address _addr) public view returns (bool){
      if((ILNR(lnrAddress).addr(_name) == _addr) || (ILNR(lnrAddress).owner(_name) == _addr) ||
          (IWLNR(wlnrAddress).nameToId(_name) != 0 && IWLNR(wlnrAddress).ownerOf(IWLNR(wlnrAddress).nameToId(_name)) == _addr) )
        return true;
      else
        return false;
    }

    // checks to see if the owner of the nft is either the owner of the LNR or the delegated address of the LNR
    function verifyNameOwnsNFT(bytes32 _name, uint256 _tokenId, address _nftAddress) public view returns (bool){
      if(IERC721(_nftAddress).ownerOf(_tokenId) == ILNR(lnrAddress).owner(_name) || ( IERC721(_nftAddress).ownerOf(_tokenId) == ILNR(lnrAddress).addr(_name) ))
        return true;
      else
        return false;
    }

    //gets identity keyValue pairs requested that have been stored on chain
    function getIdentity(bytes32 _name, bytes32[] calldata _key) public view returns (string[] memory){
      string[] memory values = new string[](_key.length);
      uint i = 0;
      for(i=0; i<_key.length; i++){
        values[i] = userIdentities[_name].keyValue[_key[i]];
      }
      return values;
    }

    function verifyIsDomainOwner(bytes32 _name) public view { // make sure that the msg.sender is the address set by the owner, the owner, or the owner of the wrapped token
        require(  (ILNR(lnrAddress).addr(_name) == msg.sender) || (ILNR(lnrAddress).owner(_name) == msg.sender) ||
                  (IWLNR(wlnrAddress).ownerOf(IWLNR(wlnrAddress).nameToId(_name)) == msg.sender ) , "Not yours");
    }

    // ensures only the correct person can update the identity, does not verify all the data entered is valid
    // front end must still do due diligence to ensure the users pfps and other assets are theirs.
    // if the data isnt stored on chain it will need to be accessed via events
    function setIdentity(bytes32 _name, bytes32[] calldata _key, string[] calldata _value, bool _store) public {
      require(_key.length == _value.length, "not same length");
      verifyIsDomainOwner(_name); // reverts if the caller has no claim
      if(_store){
        if(!userIdentities[_name].initialized)
          userIdentities[_name].initialized = true;
        uint i = 0;
        for(i=0; i<_key.length; i++){
          userIdentities[_name].keyValue[_key[i]] = _value[i];
        }
      }
      emit SetIdentity(_name, _key, _value, _store);
    }

    function post(bytes32 _name, bytes32 _replyTo, string calldata _message, bytes32 _indexedTag, bytes32[] calldata _tags) public {
      verifyIsDomainOwner(_name);
      emit Post(_name, _replyTo, _message, _indexedTag, _tags);
    }

}