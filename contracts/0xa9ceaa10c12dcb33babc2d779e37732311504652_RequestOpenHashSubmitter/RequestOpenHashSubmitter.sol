/**
 *Submitted for verification at Etherscan.io on 2019-07-26
*/

/**
 *Submitted for verification at Etherscan.io on 2019-07-16
*/

pragma solidity ^0.5.0;

/**
 * @title SafeMath
 * @dev Unsigned math operations with safety checks that revert on error
 */
library SafeMath {
    /**
    * @dev Multiplies two unsigned integers, reverts on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    /**
    * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
    * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    /**
    * @dev Adds two unsigned integers, reverts on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

    /**
    * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
    * reverts when dividing by zero.
    */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

/**
 * @title Roles
 * @dev Library for managing addresses assigned to a Role.
 */
library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

    /**
     * @dev give an account access to this role
     */
    function add(Role storage role, address account) internal {
        require(account != address(0));
        require(!has(role, account));

        role.bearer[account] = true;
    }

    /**
     * @dev remove an account's access to this role
     */
    function remove(Role storage role, address account) internal {
        require(account != address(0));
        require(has(role, account));

        role.bearer[account] = false;
    }

    /**
     * @dev check if an account has this role
     * @return bool
     */
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0));
        return role.bearer[account];
    }
}


/**
 * @title WhitelistAdminRole
 * @dev WhitelistAdmins are responsible for assigning and removing Whitelisted accounts.
 */
contract WhitelistAdminRole {
    using Roles for Roles.Role;

    event WhitelistAdminAdded(address indexed account);
    event WhitelistAdminRemoved(address indexed account);

    Roles.Role private _whitelistAdmins;

    constructor () internal {
        _addWhitelistAdmin(msg.sender);
    }

    modifier onlyWhitelistAdmin() {
        require(isWhitelistAdmin(msg.sender));
        _;
    }

    function isWhitelistAdmin(address account) public view returns (bool) {
        return _whitelistAdmins.has(account);
    }

    function addWhitelistAdmin(address account) public onlyWhitelistAdmin {
        _addWhitelistAdmin(account);
    }

    function renounceWhitelistAdmin() public {
        _removeWhitelistAdmin(msg.sender);
    }

    function _addWhitelistAdmin(address account) internal {
        _whitelistAdmins.add(account);
        emit WhitelistAdminAdded(account);
    }

    function _removeWhitelistAdmin(address account) internal {
        _whitelistAdmins.remove(account);
        emit WhitelistAdminRemoved(account);
    }
}


/**
 * @title WhitelistedRole
 * @dev Whitelisted accounts have been approved by a WhitelistAdmin to perform certain actions (e.g. participate in a
 * crowdsale). This role is special in that the only accounts that can add it are WhitelistAdmins (who can also remove
 * it), and not Whitelisteds themselves.
 */
contract WhitelistedRole is WhitelistAdminRole {
    using Roles for Roles.Role;

    event WhitelistedAdded(address indexed account);
    event WhitelistedRemoved(address indexed account);

    Roles.Role private _whitelisteds;

    modifier onlyWhitelisted() {
        require(isWhitelisted(msg.sender));
        _;
    }

    function isWhitelisted(address account) public view returns (bool) {
        return _whitelisteds.has(account);
    }

    function addWhitelisted(address account) public onlyWhitelistAdmin {
        _addWhitelisted(account);
    }

    function removeWhitelisted(address account) public onlyWhitelistAdmin {
        _removeWhitelisted(account);
    }

    function renounceWhitelisted() public {
        _removeWhitelisted(msg.sender);
    }

    function _addWhitelisted(address account) internal {
        _whitelisteds.add(account);
        emit WhitelistedAdded(account);
    }

    function _removeWhitelisted(address account) internal {
        _whitelisteds.remove(account);
        emit WhitelistedRemoved(account);
    }
}

/**
 * @title RequestHashStorage
 * @notice This contract is the entry point to retrieve all the hashes of the request network system.
  */
contract RequestHashStorage is WhitelistedRole {

  // Event to declare a new hash
  event NewHash(string hash, address hashSubmitter, bytes feesParameters);

  /**
   * @notice Declare a new hash
   * @param _hash hash to store
   * @param _feesParameters Parameters use to compute the fees. This is a bytes to stay generic, the structure is on the charge of the hashSubmitter contracts.
   */
  function declareNewHash(string calldata _hash, bytes calldata _feesParameters)
    external
    onlyWhitelisted
  {
    // Emit event for log
    emit NewHash(_hash, msg.sender, _feesParameters);
  }

  // Fallback function returns funds to the sender
  function()
    external
  {
    revert("not payable fallback");
  }
}


/**
 * @title Bytes util library.
 * @notice Collection of utility functions to manipulate bytes for Request.
 */
library Bytes {
  /**
    * @notice Extract a bytes32 from a bytes.
    * @param data bytes from where the bytes32 will be extract
    * @param offset position of the first byte of the bytes32
    * @return address
    */
  function extractBytes32(bytes memory data, uint offset)
    internal
    pure
    returns (bytes32 bs)
  {
    require(offset >= 0 && offset + 32 <= data.length, "offset value should be in the correct range");

    // solium-disable-next-line security/no-inline-assembly
    assembly {
        bs := mload(add(data, add(32, offset)))
    }
  }
}

/**
 * @title StorageFeeCollector
 *
 * @notice StorageFeeCollector is a contract managing the fees
 */
contract StorageFeeCollector is WhitelistAdminRole {
  using SafeMath for uint256;

  /**
   * Fee computation for storage are based on four parameters:
   * minimumFee (wei) fee that will be applied for any size of storage
   * rateFeesNumerator (wei) and rateFeesDenominator (byte) define the variable fee,
   * for each <rateFeesDenominator> bytes above threshold, <rateFeesNumerator> wei will be charged
   *
   * Example:
   * If the size to store is 50 bytes, the threshold is 100 bytes and the minimum fee is 300 wei,
   * then 300 will be charged
   *
   * If rateFeesNumerator is 2 and rateFeesDenominator is 1 then 2 wei will be charged for every bytes above threshold,
   * if the size to store is 150 bytes then the fee will be 300 + (150-100)*2 = 400 wei
   */
  uint256 public minimumFee;
  uint256 public rateFeesNumerator;
  uint256 public rateFeesDenominator;

  // address of the contract that will burn req token
  address payable public requestBurnerContract;

  event UpdatedFeeParameters(uint256 minimumFee, uint256 rateFeesNumerator, uint256 rateFeesDenominator);
  event UpdatedMinimumFeeThreshold(uint256 threshold);
  event UpdatedBurnerContract(address burnerAddress);

  /**
   * @param _requestBurnerContract Address of the contract where to send the ether.
   * This burner contract will have a function that can be called by anyone and will exchange ether to req via Kyber and burn the REQ
   */
  constructor(address payable _requestBurnerContract)
    public
  {
    requestBurnerContract = _requestBurnerContract;
  }

  /**
    * @notice Sets the fees rate and minimum fee.
    * @dev if the _rateFeesDenominator is 0, it will be treated as 1. (in other words, the computation of the fees will not use it)
    * @param _minimumFee minimum fixed fee
    * @param _rateFeesNumerator numerator rate
    * @param _rateFeesDenominator denominator rate
    */
  function setFeeParameters(uint256 _minimumFee, uint256 _rateFeesNumerator, uint256 _rateFeesDenominator)
    external
    onlyWhitelistAdmin
  {
    minimumFee = _minimumFee;
    rateFeesNumerator = _rateFeesNumerator;
    rateFeesDenominator = _rateFeesDenominator;
    emit UpdatedFeeParameters(minimumFee, rateFeesNumerator, rateFeesDenominator);
  }


  /**
    * @notice Set the request burner address.
    * @param _requestBurnerContract address of the contract that will burn req token (probably through Kyber)
    */
  function setRequestBurnerContract(address payable _requestBurnerContract)
    external
    onlyWhitelistAdmin
  {
    requestBurnerContract = _requestBurnerContract;
    emit UpdatedBurnerContract(requestBurnerContract);
  }

  /**
    * @notice Computes the fees.
    * @param _contentSize Size of the content of the block to be stored
    * @return the expected amount of fees in wei
    */
  function getFeesAmount(uint256 _contentSize)
    public
    view
    returns(uint256)
  {
    // Transactions fee
    uint256 computedAllFee = _contentSize.mul(rateFeesNumerator);

    if (rateFeesDenominator != 0) {
      computedAllFee = computedAllFee.div(rateFeesDenominator);
    }

    if (computedAllFee <= minimumFee) {
      return minimumFee;
    } else {
      return computedAllFee;
    }
  }

  /**
    * @notice Sends fees to the request burning address.
    * @param _amount amount to send to the burning address
    */
  function collectForREQBurning(uint256 _amount)
    internal
  {
    // .transfer throws on failure
    requestBurnerContract.transfer(_amount);
  }
}

/**
 * @title RequestOpenHashSubmitter
 * @notice Contract declares data hashes and collects the fees.
 * @notice The hash is declared to the whole request network system through the RequestHashStorage contract.
 * @notice Anyone can submit hashes.
 */
contract RequestOpenHashSubmitter is StorageFeeCollector {

  RequestHashStorage public requestHashStorage;
  
  /**
   * @param _addressRequestHashStorage contract address which manages the hashes declarations
   * @param _addressBurner Burner address
   */
  constructor(address _addressRequestHashStorage, address payable _addressBurner)
    StorageFeeCollector(_addressBurner)
    public
  {
    requestHashStorage = RequestHashStorage(_addressRequestHashStorage);
  }

  /**
   * @notice Submit a new hash to the blockchain.
   *
   * @param _hash Hash of the request to be stored
   * @param _feesParameters fees parameters used to compute the fees. Here, it is the content size in an uint256
   */
  function submitHash(string calldata _hash, bytes calldata _feesParameters)
    external
    payable
  {
    // extract the contentSize from the _feesParameters
    uint256 contentSize = uint256(Bytes.extractBytes32(_feesParameters, 0));

    // Check fees are paid
    require(getFeesAmount(contentSize) == msg.value, "msg.value does not match the fees");

    // Send fees to burner, throws on failure
    collectForREQBurning(msg.value);

    // declare the hash to the whole system through to RequestHashStorage
    requestHashStorage.declareNewHash(_hash, _feesParameters);
  }

  // Fallback function returns funds to the sender
  function()
    external
    payable
  {
    revert("not payable fallback");
  }
}