// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./IERC20.sol";
import "./TransferHelper.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract DAppSocialPool is Initializable, UUPSUpgradeable, OwnableUpgradeable {

    using TransferHelper for IERC20;

    struct Offer {
        address token;
        uint8 status;
        uint256 amount;
        uint256 remaining;
    }

    struct Balance {
        address tokenAddress;
        uint256 available;
        uint256 pending;
    }

    //Balances
    mapping (address => mapping(address => uint256)) _balances;
    mapping (address => mapping(address => uint256)) _pendingBalances;

    //Exchnage Requests
    mapping (address => mapping(uint256 => uint256)) _sourceRecords; // Address => Id => Amount
    mapping (address => mapping(uint256 => uint256)) _targetRecords; // Address => Id => Amount
    mapping (address => mapping(uint256 => bool)) _deliveryMethods;
    mapping (address => mapping(uint256 => address)) _targetAddresses;

    //Exchange Offers
    mapping(address => mapping(uint256 => Offer)) _offers; //Address => id => Offer

   
    mapping (address => bool) _supportedTokens;
    mapping (address => bool) _adminList;
    address public feeAddress;

    bool public _isCrossXRunning;


    event TokenSupportAdded(address indexed, bool);
    event TokenSupportRemoved(address indexed, bool);

    event TokenDeposited(address indexed, address indexed, uint256);
    event TokenWithdrawn(address indexed, address indexed, uint256);
    event TokenTransferred(address indexed, address indexed, uint256);
    event AdminAddressAdded(address indexed old, bool flag);
    event AdminAddressRemoved(address indexed old, bool flag);
    event ControllerUpdated(address indexed old, address indexed newAddress);
    event UpdatedFeeAddress(address indexed old, address indexed newAddress);

    event TokenSwapRequested(address indexed token, address indexed from, uint256 amount);
    event TokenSwapAccepted(address indexed token, address indexed from, address to, uint256 amount);
    event TokenSwapCancelled(address indexed token, address indexed from, uint256 amount);
    event TokenSwapCompleted(address indexed token, address indexed from, address to, uint256 amount);

    event OfferCreated(address indexed token, address indexed from, uint256 amount);
    event OfferIncreased(address indexed token, address indexed from, uint256 amount);
    event OfferDecreased(address indexed token, address indexed from, uint256 amount);
    event OfferCancelled(address indexed token, address indexed from, uint256 amount);
    event OfferAccepted(address indexed token, address indexed from, address to, uint256 amount);
    event ExchangeCompleted(address token, address from, address to, uint256 amount, uint256 chain);


    error FailedETHSend();
    error NotZeroAddress();
    error TokenNotSupported();
    error NotEnoughBalance(); 
    error NotEnoughAmount();
    error InvalidRecord();
    error UnAuthorizedUser();
    error InvalidOffer();
    error CrossXNotRunning();

    constructor() {}

    function initialize() initializer public {
        __Ownable_init();
        __UUPSUpgradeable_init();
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}

    function name() public pure returns (string memory) {
        return "DAppSocialPool";
    }

    modifier adminOnly() {
        require(_adminList[msg.sender], "Only Admin action");
        _;
    }

    modifier validRecord(uint256 value) {
        if (value == 0) revert InvalidRecord();
        _;
    }

    modifier enoughBalance(uint256 amount, uint256 balance) {
        if (amount > balance) revert NotEnoughBalance();
        _;
    }

    modifier validAmount(uint256 amount) {
        require(amount > 0, "Amount should be greater than 0");
        _;
    }

    modifier crossXRunning() {
        if (!_isCrossXRunning) revert CrossXNotRunning();
        _;
    }

    function setCrossXOpen(bool isOpen) external onlyOwner {
        _isCrossXRunning = isOpen;
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

    function addSupportedToken(address tokenAddress) external onlyOwner {
        require(!_supportedTokens[tokenAddress], "The Address is already supported");
        _supportedTokens[tokenAddress] = true;
        emit TokenSupportAdded(tokenAddress, true);
    }

    function removeSupportedToken(address tokenAddress) external onlyOwner {
        require(_supportedTokens[tokenAddress], "The Address is not supported");
        _supportedTokens[tokenAddress] = false;
        emit TokenSupportRemoved(tokenAddress, false);
    }

    function setFeeAddress(address newAddress) external onlyOwner {
        if (newAddress == address(0)) revert NotZeroAddress();
        emit UpdatedFeeAddress(feeAddress, newAddress);
        feeAddress = newAddress;
    }

    fallback() external payable {
        deposit(address(0), msg.value);
    }

    receive() external payable {
        deposit(address(0), msg.value);
    }

    function deposit(address tokenAddress, uint256 amount) public payable {
        if (tokenAddress == address(0)) {
            amount = msg.value;
            require(amount > 0, "Amount should be greater than 0");
        } else {
            if (!_supportedTokens[tokenAddress]) revert TokenNotSupported();
            require(amount > 0, "Amount should be greater than 0");
            uint256 initial = IERC20(tokenAddress).balanceOf(address(this));
            IERC20(tokenAddress).safeTransferFrom(msg.sender, address(this), amount);
            amount = IERC20(tokenAddress).balanceOf(address(this)) - initial;
        }
        _balances[tokenAddress][msg.sender] += amount;
        emit TokenDeposited(tokenAddress, msg.sender, amount);
        
    }

    function withdraw(address tokenAddress, uint256 amount) public validAmount(amount) enoughBalance(amount, _balances[tokenAddress][msg.sender]) {
        unchecked {
            _balances[tokenAddress][msg.sender] -= amount;
        }
        if (tokenAddress == address(0)) {
            _transfer(msg.sender, amount);
        } else {
            IERC20(tokenAddress).safeTransfer(msg.sender, amount);
        }
        emit TokenWithdrawn(tokenAddress, msg.sender, amount);
    }

    function _transfer(address to, uint256 amount) internal {
        if (to == address(0)) revert NotZeroAddress();
        (bool success, ) = payable(to).call{value: amount}("");
        if (!success) revert FailedETHSend();
    }

    function transfer(address token, address from, address to, uint256 amount, bool isWalletTransfer) internal validAmount(amount) enoughBalance(amount, _balances[token][from]) {
        unchecked {
            _balances[token][from] -= amount;
        }
        if (isWalletTransfer) {
            if (token == address(0)) {
                _transfer(to, amount);
            } else {
                IERC20(token).safeTransfer(to, amount);
            }
        } else {
             _balances[token][to] += amount;
        }

    }

    function transferPending(address token, address from, address to, uint256 amount, bool isWalletTransfer) internal validAmount(amount) enoughBalance(amount, _pendingBalances[token][from]) {
        unchecked {
            _pendingBalances[token][from] -= amount;
        }
        if (isWalletTransfer) {
            if (token == address(0)) {
                _transfer(to, amount);
            } else {
                IERC20(token).safeTransfer(to, amount);
            }
        } else {
             _balances[token][to] += amount;
        }

    }

    function hold(address token, address from, uint256 amount) internal validAmount(amount) enoughBalance(amount, _balances[token][from]) {
        unchecked {
            _balances[token][from] -= amount;
        }
        _pendingBalances[token][from] += amount;
    }

    function holdWithFee(address token, address from, uint256 amount, uint256 feeAmount) internal validAmount(amount) enoughBalance(amount, _balances[token][from]) {
        require(amount > feeAmount, "Fee is greater than the amount");
        unchecked {
            _balances[token][from] -= amount;
        }
        _pendingBalances[token][from] += (amount - feeAmount);
        _balances[token][feeAddress] += feeAmount;
    }

    function release(address token, address from, uint256 amount) internal validAmount(amount) enoughBalance(amount, _pendingBalances[token][from]) {
        unchecked {
            _pendingBalances[token][from] -= amount;
        }
        _balances[token][from] += amount;
    }

    function updateAmountsByAdmin(address token, address from, address to, uint256 amount, bool isPending, bool isWalletTransfer) external adminOnly {
        if (isPending) {
            transferPending(token, from, to, amount, isWalletTransfer);
        } else {
            transfer(token, from, to, amount, isWalletTransfer);
        }
    }

    // Exchange requests

    function requestTokens(uint256 id, address tokenAddress, uint256 amount, uint256 feeAmount) external crossXRunning {
        holdWithFee(tokenAddress,msg.sender, amount, feeAmount);
        _sourceRecords[msg.sender][id] = amount;

        emit TokenSwapRequested(tokenAddress, msg.sender, amount);
    }

    // Create a record for accept on Target
    function createTgtRecord(uint256 id, address tokenAddress, address fromAddress, address toAddress, uint256 amount, bool isWalletTransfer) external adminOnly {
        _targetRecords[toAddress][id] = amount;
        if (isWalletTransfer) {
            _deliveryMethods[toAddress][id] = isWalletTransfer;
        }
        if (fromAddress != address(0)) {
            _targetAddresses[toAddress][id] = fromAddress;
        }
        emit TokenSwapRequested(tokenAddress, toAddress, amount);
    }

    function acceptRequest(uint256 id, address tokenAddress, address toAddress) external crossXRunning validRecord(_targetRecords[toAddress][id]) {
        address fromAddress = _targetAddresses[toAddress][id];
        if ( fromAddress != address(0) && fromAddress != msg.sender) {
            revert UnAuthorizedUser();
        }
        uint256 amount = _targetRecords[toAddress][id];
        _targetRecords[toAddress][id] = 0;
        transfer(tokenAddress, msg.sender, toAddress, amount, _deliveryMethods[toAddress][id]);
        
        emit TokenSwapAccepted(tokenAddress, msg.sender, toAddress, amount);
    }

    function updateSrcAmount(uint256 id, address tokenAddress, address fromAddress, address toAddress, uint256 amount, uint256 releaseAmount, bool isWalletTransfer) external adminOnly validRecord(_sourceRecords[fromAddress][id]) {
        transferPending(tokenAddress, fromAddress, toAddress, amount, isWalletTransfer);

        if (releaseAmount > 0) {
            release(tokenAddress, fromAddress, releaseAmount);
        }
        _sourceRecords[fromAddress][id] = 0;
        emit TokenSwapCompleted(tokenAddress, fromAddress, toAddress, amount);
    }

    function cancelSrcRequest(uint256 id, address tokenAddress, address fromAddress, uint256 amount) external adminOnly validRecord(_sourceRecords[fromAddress][id]) {
        release(tokenAddress, fromAddress, amount);
        _sourceRecords[fromAddress][id] = 0;
        emit TokenSwapCancelled(tokenAddress, fromAddress, amount);
    }

    function cancelTgtRequest(uint256 id, address tokenAddress, address fromAddress, uint256 amount) external adminOnly validRecord(_targetRecords[fromAddress][id]) {
        _targetRecords[fromAddress][id] = 0;
        emit TokenSwapCancelled(tokenAddress, fromAddress, amount);
    }

    // Exchange Offers

    function createOffer(uint256 id, address tokenAddress, uint256 amount, bool isCreateFromPool) external crossXRunning payable {

        if (!isCreateFromPool) {
            deposit(tokenAddress, amount);
        }

        if (amount > _balances[tokenAddress][msg.sender]) revert NotEnoughBalance();
        hold(tokenAddress, msg.sender, amount);

        Offer memory offer = Offer({
            token : tokenAddress,
            status : 1,
            amount : amount,
            remaining : amount
        });
        _offers[msg.sender][id] = offer;
        emit OfferCreated(tokenAddress, msg.sender, amount);
    }

    function increaseOffer(uint256 id, address tokenAddress, uint256 amount, bool isCreateFromPool) external crossXRunning payable {
        Offer storage offer = _offers[msg.sender][id];
        if (offer.status == 2) revert InvalidOffer();
        if (!isCreateFromPool) {
            deposit(tokenAddress, amount);
        }
        if (amount > _balances[tokenAddress][msg.sender]) revert NotEnoughBalance();
        hold(tokenAddress, msg.sender, amount);

        
        offer.amount += amount;
        offer.remaining += amount;

        emit OfferIncreased(tokenAddress, msg.sender, amount);
    }

    function decreaseOffer(uint256 id, address tokenAddress, uint256 amount) external {
        Offer storage offer = _offers[msg.sender][id];
        if (offer.status == 2) revert InvalidOffer();
        if (amount > offer.remaining) revert NotEnoughBalance();
        
        unchecked {
            offer.remaining -= amount;
            offer.amount -= amount;
        }        

        release(tokenAddress, msg.sender, amount);

        emit OfferDecreased(tokenAddress, msg.sender, amount);
    }

    function cancelOffer(uint256 id, address tokenAddress) external {
        
        Offer storage offer = _offers[msg.sender][id];
        uint256 amountToCancel = offer.remaining;
        unchecked {
            offer.amount -= amountToCancel;
        }
        offer.remaining = 0;
        offer.status = 2;

        release(tokenAddress, msg.sender, amountToCancel);

        emit OfferCancelled(tokenAddress, msg.sender, amountToCancel);
    }

    function acceptOfferOnS(address tokenAddress, address from, uint256 amount, uint256 feeAmount, bool isAcceptFromPool) external crossXRunning payable {
        if (!isAcceptFromPool) {
            deposit(tokenAddress, amount);
        }
        if (amount > _balances[tokenAddress][msg.sender]) revert NotEnoughBalance();
        holdWithFee(tokenAddress, msg.sender, amount, feeAmount);
        emit OfferAccepted(tokenAddress,msg.sender, from, amount);
    }

    function completeOfferOnT(uint256 id, address tokenAddress, address from, address to, uint256 amount, bool isWalletTransfer) external adminOnly {
        Offer storage offer = _offers[from][id];
        if (amount > offer.remaining) revert NotEnoughBalance();
        if (offer.status == 2) revert InvalidOffer();
        transferPending(tokenAddress, from, to, amount, isWalletTransfer);
        
        unchecked {
            offer.remaining -= amount;
        }
        emit OfferAccepted(tokenAddress,from, to, amount);
    }

    function completeOfferOnS(address tokenAddress, address from, address to, uint256 amount, bool isWalletTransfer, uint256 chain) external adminOnly {
        transferPending(tokenAddress, from, to, amount, isWalletTransfer);
        emit ExchangeCompleted(tokenAddress, from, to, amount, chain);
    }

    function getBalances(address[] calldata _addresses, address account) external view returns (Balance[] memory) {
        uint length = _addresses.length;
        Balance[] memory balances = new Balance[](length);
        for (uint i; i < length; i++) {
            address token = _addresses[i];
            Balance memory bal = Balance(token, _balances[token][account], _pendingBalances[token][account]);
            balances[i] = bal;
        }
        return balances;
    }

}