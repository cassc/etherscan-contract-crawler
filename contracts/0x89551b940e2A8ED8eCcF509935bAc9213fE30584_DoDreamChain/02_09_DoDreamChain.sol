pragma solidity ^0.5.5;

import "./DoDreamChainBase.sol";


/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * This test is non-exhaustive, and there may be false-negatives: during the
     * execution of a contract's constructor, its address will be reported as
     * not containing a contract.
     *
     * IMPORTANT: It is unsafe to assume that an address for which this
     * function returns false is an externally-owned account (EOA) and not a
     * contract.
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies in extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != 0x0 && codehash != accountHash);
    }

    /**
     * @dev Converts an `address` into `address payable`. Note that this is
     * simply a type cast: the actual underlying value is not changed.
     *
     * _Available since v2.4.0._
     */
    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
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
     *
     * _Available since v2.4.0._
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-call-value
        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

/**
 * @title DoDreamChain
 */
contract DoDreamChain is DoDreamChainBase {

  event TransferedToDRMDapp(
        address indexed owner,
        address indexed spender,
        address indexed to, uint256 value, DRMReceiver.DRMReceiveType receiveType);

  string public constant name = "DoDreamChain";
  string public constant symbol = "DRM";
  uint8 public constant decimals = 18;

  uint256 public constant INITIAL_SUPPLY = 250 * 1000 * 1000 * (10 ** uint256(decimals)); // 250,000,000 DRM

  /**
   * @dev Constructor 생성자에게 DRM토큰을 보냅니다.
   */
  constructor() public {
    totalSupply_ = INITIAL_SUPPLY;
    balances[msg.sender] = INITIAL_SUPPLY;
    emit Transfer(address(0), msg.sender, INITIAL_SUPPLY);
  }

  function drmTransfer(address _to, uint256 _value, string memory  _note) public returns (bool ret) {
      ret = super.drmTransfer(_to, _value, _note);
      postTransfer(msg.sender, msg.sender, _to, _value, DRMReceiver.DRMReceiveType.DRM_TRANSFER);
  }

  function drmTransferFrom(address _from, address _to, uint256 _value, string memory _note) public returns (bool ret) {
      ret = super.drmTransferFrom(_from, _to, _value, _note);
      postTransfer(_from, msg.sender, _to, _value, DRMReceiver.DRMReceiveType.DRM_TRANSFER);
  }

  function postTransfer(address owner, address spender, address to, uint256 value,
   DRMReceiver.DRMReceiveType receiveType) internal returns (bool) {
        if (Address.isContract(to)) {
            
            (bool callOk, bytes memory data) = address(to).call(abi.encodeWithSignature("onDRMReceived(address,address,uint256,uint8)", owner, spender, value, receiveType));
            if (callOk) {
                emit TransferedToDRMDapp(owner, spender, to, value, receiveType);
            }
        }

        return true;
    }

  function drmMintTo(address to, uint256 amount, string memory note) public onlyOwner returns (bool ret) {
        ret = super.drmMintTo(to, amount, note);
        postTransfer(address(0), msg.sender, to, amount, DRMReceiver.DRMReceiveType.DRM_MINT);
    }

    function drmBurnFrom(address from, uint256 value, string memory note) public onlyOwner returns (bool ret) {
        ret = super.drmBurnFrom(from, value, note);
        postTransfer(address(0), msg.sender, from, value, DRMReceiver.DRMReceiveType.DRM_BURN);
    }

}

/**
 * @title DRM Receiver
 */
contract DRMReceiver {
    enum DRMReceiveType { DRM_TRANSFER, DRM_MINT, DRM_BURN }
    function onDRMReceived(address owner, address spender, uint256 value, DRMReceiveType receiveType) public returns (bool);
}