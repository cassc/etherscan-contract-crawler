// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/**
 * @dev A token holder contract that will allow a beneficiary to extract the
 * tokens after a given release time.
 *
 * Useful for simple vesting schedules like "advisors get all of their tokens
 * after 2 year".
 */

contract TokenTimelock is Context {
    using SafeERC20 for IERC20;

    // ERC20 basic token contract being held
    IERC20 public immutable token;
    uint public lockedupSupply;

    // beneficiary of tokens after they are released
    mapping(uint => address) public beneficiary;

    uint public beneficiaryId;
    mapping(address => uint) public quota;

    // timestamp when token release is enabled
    mapping(address => uint) public releaseTime;

    address[] public beneficiaryList;
    bool boolean;

    /**
     * @dev Deploys a timelock instance that is able to hold the token specified, and will only release it to
     * `beneficiary` when {release} is invoked after `releaseTime`. The release time is specified as a Unix timestamp
     * (in seconds).
     */
    constructor(IERC20 _token) {
        token = _token;

        /**
        * @dev Initializes the contract setting the deployer as the initial owner.
        */        
        _transferOwnership(_msgSender());        
    }

    function setBeneficiary(address _beneficiary, uint _quota, uint _releaseTime) public onlyOwner {
        require(quota[_beneficiary] == 0, "Aready registered: Can be re-registered after release");
        require(_quota > 0 && _quota <= token.totalSupply(), "Invalid quota");
        require(_releaseTime > block.timestamp, "TokenTimelock: release time is before current time");
        beneficiary[beneficiaryId] = _beneficiary;
        beneficiaryId++;
        quota[_beneficiary] = _quota;
        lockedupSupply += _quota;
        releaseTime[_beneficiary] = _releaseTime;
        duplicateCheck(_beneficiary, beneficiaryList);
        if(!boolean) {
            beneficiaryList.push(_beneficiary);
        }
        boolean = false;
        emit Beneficiary(_beneficiary, _quota, _releaseTime);
    }

    function extendReleaseTime(address _beneficiary, uint _releaseTime) public onlyOwner {
        require(quota[_beneficiary] > 0, "no quota to release");
        require(_releaseTime > releaseTime[_beneficiary], "TokenTimelock: release time is before registered time");
        releaseTime[_beneficiary] = _releaseTime;
        emit ExtendedReleaseTime(_beneficiary, _releaseTime);
    }

    /**
     * @dev Returns the beneficiary that will receive the tokens.
     */
    function getAllBeneficiaryWithoutDuplicate() public view returns (address[] memory) {
        return beneficiaryList;
    }
    // Check for duplication of beneficiary list
    function duplicateCheck(address _check, address[] storage _list) internal {
        for(uint i = 0; i < _list.length; i++) {
            if(_list[i] == _check) {
                 boolean = true;
            }
        }
    }    

    /**
     * @dev Returns the time when the tokens are released in seconds since Unix epoch (i.e. Unix timestamp).
     */
    function canRelease(address _beneficiary) public view returns (bool) {
        require(quota[_beneficiary] > 0, "no quota to release");
        return block.timestamp >= releaseTime[_beneficiary];
    }

    /**
     * @dev Transfers tokens held by the timelock to the beneficiary. Will only succeed if invoked after the release
     * time.
     */
    function release(address _beneficiary) public onlyOwner {
        require(quota[_beneficiary] > 0, "no quota to release");
        require(block.timestamp >= releaseTime[_beneficiary], "TokenTimelock: current time is before release time");

        uint256 amount = token.balanceOf(address(this));
        require(amount > 0, "No tokens to release");

        token.safeTransfer(_beneficiary, quota[_beneficiary]);
        emit Released(_beneficiary, quota[_beneficiary]);

        lockedupSupply -= quota[_beneficiary];
        quota[_beneficiary] = 0;
    }

    // Lookup function for token amount in the contract address
    function caBalance() public view returns (uint) {
        return token.balanceOf(address(this));
    }

    // Lookup function for token deposited by mistake (without registration)
    function unregisteredSupply() public view returns (uint) {
        require(caBalance() > lockedupSupply, "caBalance is lacking");
        return caBalance() - lockedupSupply;
    }

    function transferUnregisteredSupply(uint _amount) public onlyOwner {
        require(unregisteredSupply() >= _amount, "Exceeded unregisteredSupply amount");
        token.safeTransfer(msg.sender, _amount);
        emit TransferUnregisteredSupply(msg.sender, _amount);
    }

    function recoverERC20(address _tokenAddress, uint256 _tokenAmount) external onlyOwner {
        require(_tokenAddress != address(token), "Cannot withdraw the release token");        
        IERC20(_tokenAddress).safeTransfer(msg.sender, _tokenAmount);
        emit RecoveredERC20(_tokenAddress, _tokenAmount);
    }

    function recoverERC721(address _tokenAddress, uint256 _tokenId) external onlyOwner {
        IERC721(_tokenAddress).safeTransferFrom(address(this), msg.sender, _tokenId);
        emit RecoveredERC721(_tokenAddress, _tokenId);
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
    address private _owner;

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
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    // ------------------ EVENTS ------------------ //
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event Beneficiary(address indexed beneficiary, uint quota, uint releaseTime);
    event ExtendedReleaseTime(address indexed beneficiary, uint releaseTime);
    event TransferUnregisteredSupply(address indexed to, uint amount);
    event Released(address beneficiary, uint quota);
    event RecoveredERC20(address token, uint amount);
    event RecoveredERC721(address token, uint tokenId);   
}