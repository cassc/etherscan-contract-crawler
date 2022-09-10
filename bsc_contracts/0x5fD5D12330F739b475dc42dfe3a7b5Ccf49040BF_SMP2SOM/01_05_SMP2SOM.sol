pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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

contract SMP2SOM is Ownable{
    mapping(address => uint256) public userTime;
    mapping(address => uint256) public userCount;
    mapping(address => bool) public whitelisted;
    mapping(address => string) private _tokenURIs;
    event WhitelistAdded(address indexed user);
    event WhitelistRemoved(address indexed user);
    uint256 public withdrawLimit;
    uint256 public totalToken;
    uint256 public day = 2592000; // 30 days
    uint256 public busdFee = 1;
    uint256 public somFee = 40000;
    IERC20 public somToken;
    IERC20 public busd;
    address _somToken = 0x31c573d1A50A745b01862edAf2ae72017cea036A;
    address _busd = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;
    constructor() {
         somToken = IERC20(_somToken);
         busd = IERC20(_busd);
         withdrawLimit = 10000000000000;
    }

   /**
     * Add contract addresses to the whitelist
     */

    function addToWhitelist(address _user) public onlyOwner {
        require(!whitelisted[_user], "already whitelisted");
        whitelisted[_user] = true;
        emit WhitelistAdded(_user);
    }
    function addAddressesToWhitelist(address[] memory _userAddresses) public onlyOwner {
        for(uint256 i = 0; i < _userAddresses.length; i++){
            addToWhitelist(_userAddresses[i]);
        }
    }
    
    function checkWhitelist(address _user) public view returns(bool)  {
        return whitelisted[_user];
    }
     
    /**
     * Remove a contract addresses from the whitelist
     */

    function removeFromWhitelist(address _user) public onlyOwner {
        require(whitelisted[_user], "user not in whitelist");
        whitelisted[_user] = false;
        _tokenURIs[_user] = "";
        emit WhitelistRemoved(_user);
    }
    function batchRemoveFromWhitelist(address[] memory _userAddresses) public onlyOwner {
        for(uint256 i = 0; i < _userAddresses.length; i++){
            removeFromWhitelist(_userAddresses[i]);
        }
    }

    function Claim(uint SOM_token, address user ) public onlyOwner {
            require(userTime[user]== 0 || block.timestamp >= userTime[user] + day, "you can not withdraw before Cooldown");
            require(SOM_token<= withdrawLimit , "withdraw limit exceeded ");
            if(checkWhitelist(user)){
               if(userCount[user] + SOM_token <= somFee *10 ** ERC20(_somToken).decimals()) {
                somToken.transfer(owner(), SOM_token);
               }
               if(userCount[user] > somFee *10 ** ERC20(_somToken).decimals()){
                somToken.transfer(user, SOM_token);
               }
               if(userCount[user] <= somFee *10 ** ERC20(_somToken).decimals() && userCount[user] + SOM_token >= somFee *10 ** ERC20(_somToken).decimals()){
                uint256 feeLeft = somFee *10 ** ERC20(_somToken).decimals() - userCount[user];
                somToken.transfer(owner(), feeLeft);
                somToken.transfer(user, SOM_token - feeLeft);
               }
            }
            if(!checkWhitelist(user)){
             somToken.transfer(user, SOM_token);
            }
            busd.transferFrom(user, owner(), busdFee *10 ** ERC20(_busd).decimals());
            userTime[user] = block.timestamp;
            userCount[user] += SOM_token; 
            totalToken += SOM_token;
    }

    function WithdrawTimePeriod(uint256 _days) public onlyOwner {
        require(_days>=1 && _days<=30,"Enter the correct Withdraw Time Period");
        day = _days * 86400;
    }

    function setlimit(uint256 _withdrawLimit) public onlyOwner{
            withdrawLimit = _withdrawLimit;
    }
    
    function setBusdFee(uint256 _busdFee) public onlyOwner{
            busdFee = _busdFee;
    }    
    
    function setSomFee(uint256 _somFee) public onlyOwner{
            somFee = _somFee;
    }
}