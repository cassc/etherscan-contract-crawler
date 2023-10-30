/**
 *Submitted for verification at Etherscan.io on 2023-08-24
*/

pragma solidity >=0.8.0 <0.9.0;

// Lock Year contract for Ownbit.
//
// Lock your assets for 1 year. This is an active lock-up behavior. Why do this? 
// Because in investment, human nature is difficult to overcome. You may sell in a hurry because the market plummets,
// or you can't help but rush into the Binance contract service and return to zero in an instant. 
// The lock-up contract helps you overcome these problems, allowing you to passively hold the spot of a certain token for a long time.

// Warning: Once locked into the contract, the assets cannot be transferred in advance under any circumstances.
// Users should carefully evaluate and recognize this limitation.

// Refresh Lock: re-lock the assets to one year from the current time.
//
// Last update time: 2023-08-18.
// [email protected]

contract OwnbitContractAccount {
  uint constant public MAX_SPENDER_COUNT = 9;
  uint constant public LOCK_ONE_YEAR = 365 days; 

  // The owner of this contract (who creates it). 
  address private owner;

  // Who can spend this money.
  address[] private spenders;

  // The timestamp the current lock to time. From when the assets can be spent.
  uint256 private lockToTime = 0; 
  
  // An event sent when funds are received.
  event Funded(address from, uint value);
  
  // An event sent when spend is executed.
  event Spent(address to, uint value);

  // An event sent when the lock is refreshed.
  event LockRefreshed();

  modifier validRequirement(uint spenderCount) {
    require (spenderCount <= MAX_SPENDER_COUNT
            && spenderCount >= 1);
    _;
  }
  
  /// @dev Contract constructor sets initial spenders and contract owner.
  /// @param _spenders List of address of spenders.
  /// @param _owner Owner address.
  constructor(address[] memory _spenders, address _owner) validRequirement(_spenders.length) {
    for (uint i = 0; i < _spenders.length; i++) {
        //spender must be non-zero
        if (_spenders[i] == address(0x0)) {
            revert();
        }
    }
    owner = _owner;
    spenders = _spenders;
  }

  // The fallback function for this contract.
  fallback() external payable {
    if (msg.value > 0) {
        emit Funded(msg.sender, msg.value);
    }
  }
  
  // @dev Returns list of spenders.
  // @return List of spender addresses.
  function getSpenders() public view returns (address[] memory) {
    return spenders;
  }

  function getOwner() public view returns (address) {
    return owner;
  }
    
  function getLockToTime() public view returns (uint256) {
    return lockToTime;
  }

  function getVersion() public pure returns(uint) {
      return 1;
  }
  
  //destination can be a normal address or an ERC20 contract address.
  //value is the wei transferred to the destination.
  //data for transfer ether: 0x
  //data for transfer erc20 example: 0xa9059cbb000000000000000000000000ac6342a7efb995d63cc91db49f6023e95873d25000000000000000000000000000000000000000000000000000000000000003e8
  //data for transfer erc721 example: 0x42842e0e00000000000000000000000097b65ad59c8c96f2dd786751e6279a1a6d34a4810000000000000000000000006cb33e7179860d24635c66850f1f6a5d4f8eee6d0000000000000000000000000000000000000000000000000000000000042134
  //data can contain any data to be executed. 
  function spend(address destination, uint256 value, bytes calldata data) external {
    require(destination != address(this), "Not allow sending to yourself");
    require(isSpender(msg.sender), "Not a spender");
    require(block.timestamp >= lockToTime, "lockToTime is not yet reached");

    //transfer tokens from this contract to the destination address
    (bool sent,) = destination.call{value: value}(data);
    if (sent) {
        emit Spent(destination, value);
    }
  }
  
  //send a tx from the owner address to refresh the lock
  //Allow the owner to transfer some ETH, although this is not necessary.
  function refreshLock() external payable {
    require(owner == msg.sender, "Not the owner");
    lockToTime = block.timestamp + LOCK_ONE_YEAR;
    emit LockRefreshed();
  }
  
  // Is this address a spender
  function isSpender(address addr) private view returns (bool) {
    for (uint i = 0; i < spenders.length; i++) {
        if (addr == spenders[i]) {
            return true;
        }
    }
    return false;
  }

  //support ERC721 safeTransferFrom
  function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes calldata _data) external returns(bytes4) {
      return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
  }

  function onERC1155Received(address _operator, address _from, uint256 _id, uint256 _value, bytes calldata _data) external returns(bytes4) {
      return bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"));
  }
}