/**
 *Submitted for verification at BscScan.com on 2023-05-13
*/

//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;



/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}



/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies in extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value: weiValue}(data);
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
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
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor (){
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


contract Auth is Ownable{
    using Address for address;

    // the contract address is true , so to be called
    mapping(address => bool)  contractAddrList;

    // the address is true , so to not be called
    mapping(address => bool)  blackList;

    // the address is true , so to be called
    mapping(address => bool) whiteAddressList;


    modifier onlyPerson(){
        address caller = _msgSender();
        require(tx.origin == caller, "onlyPerson: The caller is person");
        _;
    }

    modifier notContract(){
        address caller = _msgSender();
        require(!caller.isContract(), "notContract: The caller can not be a contract.");
        _;
    }

    modifier notBlackList(){
        address caller = _msgSender();
        require(!blackList[caller], "notBlackList: The caller can not be a black list.");
        _;
    }

    modifier onlyWhiteList(){
        address caller = _msgSender();
        require(whiteAddressList[caller], "onlyWhiteList: The caller can be a white list.");
        _;
    }

    modifier onlyDesigneeContract() {
        address caller = _msgSender();
        require(contractAddrList[caller], "OnlyDesigneeContract: The caller can be a designee contract");
        _;
    }

    function changeContractAddrList(address contractAddr, bool status) external onlyOwner {
        require(contractAddrList[contractAddr] != status, "AuthContract: the same status");
        contractAddrList[contractAddr] = status;
    }

    function changeBlackList(address addr, bool status) external onlyOwner {
        require(blackList[addr] != status, "AuthContract: the same status");
        blackList[addr] = status;
    }

    function changeWhiteAddrList(address whiteAddr, bool status) external onlyOwner {
        require(whiteAddressList[whiteAddr] != status, "AuthContract: the same status");
        whiteAddressList[whiteAddr] = status;
    }

}




interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}


contract PublicOffering is Auth{
    using Address for address;

    constructor(address payable receiveETHAddress_) {
        receiveETHAddress = receiveETHAddress_;
    }

    //  TODO total PublicOffering count
    // uint256 public targetPublicOfferingCount = 5000;
    uint256 public targetPublicOfferingCount = 3;

    // real publicOffering count
    uint256  public realPublicOfferingCount;

    uint256 public startTimeStamp = 2500000000;

    uint256 public hour24 = 24 hours;

    uint256 public hour1 = 1 hours;

    uint256 public endTimeStamp;

    uint256 public publicOfferingETH = 10 ** 16;

    uint256 public ANTSpaceAmountPerPerson = 180 * 10 ** 8 * 10 ** 9;


    address payable public receiveETHAddress;


    mapping(address => bool) isPublicOffering;

    address public ANTSpaceAddress;

    bool isFirst = true;

    event JoinPublicOffering(
        address indexed userAddress,
        uint256 amount,
        uint256 timestamp
    );


    /**
     * @dev Can users participate in publicOffering
     */
    function canJoinPublicOffering(address userAddress) public view returns(bool){
        if(block.timestamp < startTimeStamp || block.timestamp > endTimeStamp || targetPublicOfferingCount <= realPublicOfferingCount || isPublicOffering[userAddress]){
            return false;
        }
        return true;
    }

    /**
     * @dev Participate in publicOffering
     */
    function joinPublicOffering() external payable onlyPerson{
        require(canJoinPublicOffering(_msgSender()), "PublicOffering Error: can not join publicOffering.");
        require(msg.value == 0.01 ether, "PublicOffering Error: Please send exactly 0.01 ETH");

        isPublicOffering[_msgSender()] = true;
        realPublicOfferingCount += 1;

        emit JoinPublicOffering(_msgSender(), 0.01 ether, block.timestamp);
    }

    function canWithdraw(address userAddress) view external returns(bool res) {
        res = isPublicOffering[userAddress] && block.timestamp >= endTimeStamp + hour1;
    }

    function withdraw() external onlyPerson {
        require(isPublicOffering[_msgSender()], "PublicOffering Error: You didn't participate in publicOffering.");
        require(block.timestamp >= endTimeStamp + hour1, "PublicOffering Error: Not now.");
        if(isFirst) {
            uint256 amount2Burn = IERC20(ANTSpaceAddress).balanceOf(address(this)) - ANTSpaceAmountPerPerson * realPublicOfferingCount;
            if(amount2Burn > 0) {
                IERC20(ANTSpaceAddress).transfer(address(0), amount2Burn);
            }
            isFirst = false;
        }
        IERC20(ANTSpaceAddress).transfer(_msgSender(), ANTSpaceAmountPerPerson);
    }

    function updateTotalPublicOfferingCount(uint256 targetPublicOfferingCount_) external onlyOwner {
        require(targetPublicOfferingCount_ > 0 && targetPublicOfferingCount_ >= realPublicOfferingCount, "PublicOffering Contract: totalPublicOfferingCount must be greater than realPublicOfferingCount.");
        targetPublicOfferingCount = targetPublicOfferingCount_;
    }

    function updateStartTimeStamp(uint256 startTimeStamp_) external onlyOwner {
        require(startTimeStamp_ > block.timestamp, "PublicOffering Contract: startTimeStamp_ must be greater than 0.");
        startTimeStamp = startTimeStamp_;
        endTimeStamp = startTimeStamp_ + hour24;
    }

    function updateHour24(uint256 hour24_) external onlyOwner {
        require(hour24_ > 0, "PublicOffering Contract: hours must be greater than 0.");
        hour24 = hour24_;
    }

    function updateHour1(uint256 hour1_) external onlyOwner {
        require(hour1_ > 0, "PublicOffering Contract: hours must be greater than 0.");
        hour1 = hour1_;
    }

    function updatePublicOfferingETH(uint256 publicOfferingETH_) external onlyOwner {
        require(publicOfferingETH_ > 0, "PublicOffering Contract: publicOfferingETH_ must be greater than 0.");
        publicOfferingETH = publicOfferingETH_;
    }

    function updateANTSpaceAddress(address ANTSpaceAddress_) external onlyOwner {
        require(ANTSpaceAddress_ != address(0), "PublicOffering Contract: The tokenAddress can not be address(0).");
        ANTSpaceAddress = ANTSpaceAddress_;
    }

    function updateReceiveETHAddress(address payable receiveETHAddress_) external onlyOwner {
        require(receiveETHAddress_ != address(0), "PublicOffering Contract: The receiveETHAddress_ can not be address(0).");
        receiveETHAddress = receiveETHAddress_;
    }

    function withdrawETH() external onlyOwner{
        require(receiveETHAddress != address(0), "PublicOffering Contract: The receiveETHAddress can not be address(0).");
        receiveETHAddress.transfer(address(this).balance);
    }

    function emergencyANTSpace() external onlyOwner {
        IERC20(ANTSpaceAddress).transfer(_msgSender(), IERC20(ANTSpaceAddress).balanceOf(address(this)));
    }

}