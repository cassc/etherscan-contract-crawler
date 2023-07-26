/**
 *Submitted for verification at Etherscan.io on 2023-07-05
*/

// SPDX-License-Identifier: MIT

// File: dappsocial_contracts/src/Context.sol


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
// File: dappsocial_contracts/src/Ownable.sol


pragma solidity ^0.8.19;


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

// File: dappsocial_contracts/src/IERC20.sol



pragma solidity ^0.8.19;

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function transferFromWithPermit(address sender, address recipient, uint256 amount, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external returns (bool);
}

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}
// File: dappsocial_contracts/src/DAppSocialPoolController.sol


pragma solidity ^0.8.19;



interface IDAppSocialPoolModel {
    function depositNative() external payable;
    function depositTokens(address tokenAddress, uint256 amount) external;
    function withdrawNative(uint256 amount) external;
    function withdrawTokens(address tokenAddress, uint256 amount) external;
    function withdrawNativeWithAlt(address from, uint256 amount) external;
    function withdrawTokensWithAlt(address tokenAddress, address from, uint256 amount) external;
    function transferNative(address from, address to, uint256 amount) external;
    function transferTokens(address tokenAddress, address from, address to, uint256 amount, bool isWalletTransfer) external;
    function transferPendingTokens(address tokenAddress, address from, address to, uint256 amount) external;
    function transferETH(address from, address to, uint256 amount, uint256 feeAmount) external;
    function transferPendingETH(address from, address to, uint256 amount, uint256 feeAmount) external;
    function holdNative(address fromAddress, uint256 amount) external;
    function holdNativeWithFee(address from, uint256 amount, uint256 feeAmount) external;
    function releaseNative(address fromAddress, uint256 amount) external;
    function holdTokens(address tokenAddress, address fromAddress, uint256 amount) external;
    function holdTokensWithFee(address tokenAddress, address from, uint256 amount, uint256 feeAmount) external;
    function releaseTokens(address tokenAddress, address fromAddress, uint256 amount) external;
    function getTokenBalances(address tokenAddress, address account) external;
    function getNativeBalances(address account) external;
}

contract DAppSocialPoolController is Ownable {

    mapping (address => bool) _supportedTokens;
    mapping (address => bool) _adminList;

    mapping (address => mapping(uint256 => uint256)) _sourceRecords; // Address => Id => Amount
    mapping (address => mapping(uint256 => uint256)) _targetRecords; // Address => Id => Amount
    mapping (address => mapping(uint256 => bool)) _deliveryMethods;

    bool private _isCrossXRunning;

    event TokenSwapRequested(address indexed tokenAddress, address indexed fromAddress, uint256 amount);
    event TokenSwapAccepted(address indexed tokenAddress, address indexed fromAddress, address toAddress, uint256 amount);
    event TokenSwapCancelled(address indexed tokenAddress, address indexed fromAddress, uint256 amount);
    event TokenSwapCompleted(address indexed tokenAddress, address indexed fromAddress, address toAddress, uint256 amount);
    event AdminAddressAdded(address indexed oldAdderess, bool flag);
    event AdminAddressRemoved(address indexed oldAdderess, bool flag);
    event TokenSupportAdded(address indexed, bool);
    event TokenSupportRemoved(address indexed, bool);

    error InvalidRecord();
    error TokenNotSupported();

    IDAppSocialPoolModel poolModel;

    constructor() {
        _adminList[msg.sender] = true;
    }

    function name() public pure returns (string memory) {
        return "DAppSocialPoolController";
    }

    modifier adminOnly() {
        require(_adminList[msg.sender], "only Admin action");
        _;
    }

    modifier crossXRunning() {
        require(_isCrossXRunning == true, "CrossX is not running");
        _;
    }

    modifier validRecord(uint256 value) {
        if (value == 0) revert InvalidRecord();
        _;
    }

    function setCrossXOpen(bool isOpen) external onlyOwner {
        _isCrossXRunning = isOpen;
    }

    function setPoolModel(address newModel) external onlyOwner {
        poolModel = IDAppSocialPoolModel(newModel);
    }

    function addSupportedToken(address tokenAddress) external onlyOwner {
        _supportedTokens[tokenAddress] = true;
        emit TokenSupportAdded(tokenAddress, true);
    }

    function removeSupportedToken(address tokenAddress) external onlyOwner {
        _supportedTokens[tokenAddress] = false;
        emit TokenSupportRemoved(tokenAddress, false);
    }

    function addAdmin(address newAddress) external onlyOwner{
        require(!_adminList[newAddress], "Address is already Admin");
        _adminList[newAddress] = true;
        emit AdminAddressAdded(newAddress, true);
    }

    function removeAdmin(address oldAddress) external onlyOwner {
        require(_adminList[oldAddress], "The Address is not admin");
        _adminList[oldAddress] = false;
        emit AdminAddressRemoved(oldAddress, false);
    }

    function requestTokens(uint256 id, address tokenAddress, uint256 amount, uint256 feeAmount) external crossXRunning {
        if (!_supportedTokens[tokenAddress]) revert TokenNotSupported();
        require(amount > 0, "Amount should be greater than 0");
        _sourceRecords[msg.sender][id] = amount;
        poolModel.holdTokensWithFee(tokenAddress, msg.sender, amount, feeAmount);
        emit TokenSwapRequested(tokenAddress, msg.sender, amount);
    }

    // Create a record for accept on Target
    function createTgtRecord(uint256 id, address tokenAddress, address toAddress, uint256 amount, bool isWalletTransfer) external adminOnly {
        if (!_supportedTokens[tokenAddress]) revert TokenNotSupported();
        _targetRecords[toAddress][id] = amount;
        if (isWalletTransfer) {
            _deliveryMethods[toAddress][id] = isWalletTransfer;
        }
        emit TokenSwapRequested(tokenAddress, toAddress, amount);
    }

    function acceptRequest(uint256 id, address tokenAddress, address toAddress) external crossXRunning validRecord(_targetRecords[toAddress][id]) {
        uint256 amount = _targetRecords[toAddress][id];
        poolModel.transferTokens(tokenAddress, msg.sender, toAddress, amount, _deliveryMethods[toAddress][id]);
        _targetRecords[toAddress][id] = 0;
        emit TokenSwapAccepted(tokenAddress, msg.sender, toAddress, amount);
    }

    function updateSrcAmount(uint256 id, address tokenAddress, address fromAddress, address toAddress, uint256 amount) external adminOnly validRecord(_sourceRecords[fromAddress][id]) {
        poolModel.transferPendingTokens(tokenAddress, fromAddress, toAddress, amount);
        _sourceRecords[fromAddress][id] = 0;
        emit TokenSwapCompleted(tokenAddress, fromAddress, toAddress, amount);
    }

    function cancelSrcRequest(uint256 id, address tokenAddress, address fromAddress, uint256 amount) external adminOnly validRecord(_sourceRecords[fromAddress][id]) {
        poolModel.releaseTokens(tokenAddress, fromAddress, amount);
        _sourceRecords[fromAddress][id] = 0;
        emit TokenSwapCancelled(tokenAddress, fromAddress, amount);
    }

    function cancelTgtRequest(uint256 id, address tokenAddress, address fromAddress, uint256 amount) external adminOnly validRecord(_targetRecords[fromAddress][id]) {
        _targetRecords[fromAddress][id] = 0;
        emit TokenSwapCancelled(tokenAddress, fromAddress, amount);
    }

}