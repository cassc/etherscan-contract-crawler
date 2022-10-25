/**
 *Submitted for verification at BscScan.com on 2022-10-24
*/

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    function mint(address account, uint amount)external;
    function balanceOf(address receiver)external view returns(uint256);
    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

  
}



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
    //mapping(uint256 => uint256) public stopIdoValue;
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
interface IRouter {
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
}
contract BEP20PayToken is Ownable{
    address private token=0x372E5F4cb6668A2C7A655a6325a483e3a73c8bA9;
    uint256 public commID=1;//订单
    uint public commIDsa=1;
    mapping (uint=>address)public tokens;
    mapping(uint=>comm)public comms;//订单记录
    mapping(uint=>comm)public commIDs;//所有商品记录
    mapping(uint=>bool)public isOk;//商品ID唯一性
    uint public rmbToUsdt=7.2 ether;
    struct comm{
        address addr;
        uint time;
        string commid;
        uint sl;
        uint boxc; 
    }
    function buy(string memory commid,uint rmb)public {
        require(rmb >10 ether);
        uint _bsb=getPrice(rmb);
        IERC20(token).transferFrom(msg.sender,address(this),_bsb);
        comms[commID].addr=msg.sender;
        comms[commID].time=block.timestamp;
        comms[commID].sl=rmb;
        comms[commID].boxc=rmb / 1 ether;
        comms[commID].commid=commid;
        commID++;
    }
    function getPrice(uint vav)public view returns (uint){
        uint _usdt=vav*1 ether/rmbToUsdt;
        address[] memory path = new address[](3);
        uint[] memory amount;
        path[0]=0x55d398326f99059fF775485246999027B3197955;
        path[1]=0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
        path[2]=0x372E5F4cb6668A2C7A655a6325a483e3a73c8bA9;
        amount=IRouter(0x10ED43C718714eb63d5aA57B78B54704E256024E).getAmountsOut(_usdt,path); 
        return amount[2];
  }
  function getPe(uint vav)public view returns (uint){
        address[] memory path = new address[](3);
        uint[] memory amount;
        path[0]=0x55d398326f99059fF775485246999027B3197955;
        path[1]=0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
        path[2]=0x372E5F4cb6668A2C7A655a6325a483e3a73c8bA9;
        amount=IRouter(0x10ED43C718714eb63d5aA57B78B54704E256024E).getAmountsOut(vav,path); 
        return amount[2];
  }
  function getPriceRMB(uint vav)public view returns (uint){
        uint _usdt=vav * 1 ether / rmbToUsdt;
        uint boxc=getPe(_usdt);  
        return boxc;
  }
  function setRmb(uint _rmb)public onlyOwner{
      rmbToUsdt=_rmb;
  }
  function withdraw(string memory commid,uint rmb)public {
        require(rmb >0);
        commIDs[commIDsa].addr=msg.sender;
        commIDs[commIDsa].time=block.timestamp;
        commIDs[commIDsa].sl=getPrice(rmb);
        commIDs[commIDsa].boxc=getPrice(rmb) / 1 ether;
        commIDs[commIDsa].commid=commid;
        commIDsa++;
    }
    function setTokens(uint a,address addr)public onlyOwner{
        tokens[a]=addr;
    }
    function UserwithDrawal(address _address, uint amount,uint256 uid) external onlyOwner returns(bool){
        address addr=commIDs[uid].addr;
        IERC20(token).transfer(addr, amount);
        return true;
    }
    function withDrawalToken(address _address, uint amount) external onlyOwner returns(bool){
        IERC20(token).transfer(_address, amount);
        return true;
    }
    function withDrawalBoxc(address _address, uint amount) external onlyOwner returns(bool){

        payable(_address).transfer(amount);

        return true;
    }
    function withDrawalBNB(address _address, uint amount) external onlyOwner returns(bool){

        payable(_address).transfer(amount);

        return true;
    }
     receive() external payable {}
}