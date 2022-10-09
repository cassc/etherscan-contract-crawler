//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./imports/State.sol";

contract LaunchpadIDO is State, Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    address[] private _contributors;
    mapping (address => uint256) private _contributions;
    mapping (address => uint256) private _claimable;

    address private _platformOwner;

    IERC20 private _saleToken;

    uint8 private _decimals;
    
    bytes[10] private _details;

    uint256 private _startDate;
    uint256 private _endDate;

    uint256 private _liquidityPercent;
    uint256 private _liquidityLockupTime;

    bool private _whitelist;
    address[] private _whitelistedUsers;
    mapping(address => bool) private _isWhitelisted;
    
    uint256 private _price;
    uint256 private _sellQty;
    uint256 private _lpQty;
    uint256 private _listingPrice;

    uint256 private _softCap;
    uint256 private _hardCap;
    
    uint256 private _minBuy;
    uint256 private _maxBuy;

    uint256 private _ethRaised;
    uint256 private _tokenSold;
    uint256 private _additionalFee;

    event ToggleWhitelist(bool status);
    event Claim(address indexed account, uint256 amount);
    event TokenDeposited(address indexed sender, uint256 amount);
    event Purchase(address indexed account, uint256 amount);
    event Refund(address indexed account, uint256 amount);
    event Pullout(uint256 amount);

    constructor(
        address[2] memory transferAccounts,
        uint256 additionalFee,
        address saleToken,
        bytes[10] memory info,
        uint256[2] memory date,
        uint256[3] memory prices,
        uint256[2] memory cap,
        uint256[2] memory minmaxBuy,
        bool whitelist
    ) {
        _additionalFee = additionalFee;
        _platformOwner = transferAccounts[1];

        _saleToken = IERC20(saleToken);

        _decimals = IERC20Metadata(saleToken).decimals();
        _details = info;

        _startDate = date[0];
        _endDate = date[1];

        _price = prices[0];
        _listingPrice = prices[1];
        _sellQty = prices[2];
        _lpQty = 0;

        _softCap = cap[0];
        _hardCap = cap[1];
        _minBuy = minmaxBuy[0];
        _maxBuy = minmaxBuy[1];
        _liquidityPercent = 0;
        _liquidityLockupTime = 0;
      
        _whitelist = whitelist;

        _transferOwnership(transferAccounts[0]);
    }

    function setDetails(bytes[10] memory info) external {
        _details = info;
    }  

    /****************************|
    |       View Functions       |
    |___________________________*/   

    function saleDetails() external view returns (address, bytes[10] memory, uint256[13] memory, uint256[2] memory, bool) {
        return (
            address(_saleToken),
            _details,
            [
                _decimals,
                _price, 
                _sellQty, 
                _softCap, 
                _hardCap, 
                _minBuy, 
                _maxBuy,
                _startDate,
                _endDate,
                _listingPrice,
                _lpQty,
                _liquidityPercent,
                _liquidityLockupTime
            ],
            [
                _ethRaised,
                state()
            ],
            _whitelist       
        );
    }

    function raised() external view returns (uint256) {
        return _ethRaised;
    }

    /***********************|
    |         State         |
    |______________________*/

    function activate() external onlyOwner {
        uint duration = _activate();
        _endDate = _endDate.add(duration);
    } 

    function pause() external onlyOwner {
        _pause();
    } 

    function cancel() external onlyOwner {
        _cancel();
    }

    function finalize() external nonReentrant onlyOwner {
        _finalized();
        uint256 platformFeeEth = _ethRaised.mul(_additionalFee).div(1 ether);

        //transfer the platform fee to platform owner
        payable(_platformOwner).transfer(platformFeeEth);

        //transfer the remaining balance to owner
        payable(owner()).transfer(address(this).balance);
        _saleToken.safeTransfer(owner(), balance().sub(_tokenSold));
    } 

    /************************|
    |        Whitelist       |
    |_______________________*/

    /**
    * @dev Enable whitelist feature
    */
    function toogleWhiteList(bool status) external onlyOwner whenActive {
        _whitelist = status;
        emit ToggleWhitelist(status);
    }

    /**
     * @dev Return whitelisted users
     * The result array can include zero address
     */
    function whitelistedUsers() external view returns (address[] memory) {
        address[] memory __whitelistedUsers = new address[](_whitelistedUsers.length);
        for (uint256 i = 0; i < _whitelistedUsers.length; i++) {
            if (!_isWhitelisted[_whitelistedUsers[i]]) {
                continue;
            }
            __whitelistedUsers[i] = _whitelistedUsers[i];
        }

        return __whitelistedUsers;
    }

    /**
     * @dev Add wallet to whitelist
     * If wallet is added, removed and added to whitelist, the account is repeated
     */
    function addWhitelist(address[] memory accounts) external onlyOwner whenActive {
        for (uint256 i = 0; i < accounts.length; i++) {
            require(accounts[i] != address(0), "IDOSale: ZERO_ADDRESS");
            if (!_isWhitelisted[accounts[i]]) {
                _isWhitelisted[accounts[i]] = true;
                _whitelistedUsers.push(accounts[i]);
            }
        }
    }

    /**
     * @dev Remove wallet from whitelist
     * Removed wallets still remain in `_whitelistedUsers` array
     */
    function removeWhitelist(address[] memory accounts) external onlyOwner whenActive {
        for (uint256 i = 0; i < accounts.length; i++) {
            require(accounts[i] != address(0), "IDOSale: ZERO_ADDRESS");
            if (_isWhitelisted[accounts[i]]) {
                _isWhitelisted[accounts[i]] = false;
            }
        }
    }
    /************************|
    |     Contributions      |
    |_______________________*/

    function totalContributions(address account) external view returns (uint256, uint256) {
        return (_contributions[account], _claimable[account]);
    }

    function contributors() external view returns (address[] memory) {
        return _contributors;
    }

    /************************|
    |        Purchase        |
    |_______________________*/

    /**
     * @dev purchase _saleToken token to the sale contract
     */
    function purchase() payable external nonReentrant whenActive  {
       if(_whitelist) {
            require(_isWhitelisted[_msgSender()], "Sale: USER_NOT_WHITELISTED");
        }
        
        uint256 minbuy = _minBuy;

        if(_hardCap.sub(_ethRaised) < _minBuy) {
            minbuy = _hardCap.sub(_ethRaised);
        }
        
        require(
            (block.timestamp >= _startDate && block.timestamp <= _endDate) && 
            _hardCap >= _ethRaised.add(msg.value) && 
            msg.value >= minbuy && _contributions[_msgSender()].add(msg.value) <= _maxBuy, 
            "Sale: INVALID"
        );

        if(_contributions[_msgSender()] == 0) {
            _contributors.push(_msgSender());
        }
        uint256 total =  msg.value.mul( 10**_decimals ).div( 1 ether ).mul( _price ).div( 10**_decimals );

        _contributions[_msgSender()] = _contributions[_msgSender()].add(msg.value);
        _claimable[_msgSender()] = _claimable[_msgSender()].add(total);

        _ethRaised = _ethRaised.add(msg.value);
        _tokenSold = _tokenSold.add(total);

        emit Purchase(_msgSender(), msg.value);
    }
    
    /************************|
    |    Claim Investment    |
    |_______________________*/

    /**
     * @dev claim _contributions from the contract
     */
    function claim() external nonReentrant whenFinalized {
        require(_claimable[_msgSender()] > 0, "Sale: ZERO_PURCHASED");
        
        uint256 total = _claimable[_msgSender()];

       _claimable[_msgSender()] = 0;

        _saleToken.safeTransfer(_msgSender(), total);
        emit Claim(_msgSender(), total);
    }
    
    /************************|
    |         Deposit        |
    |_______________________*/
    
    /**
     * @dev Deposit _saleToken token to the sale contract
     */
    function depositTokens(uint256 amount) external onlyOwner whenActive {
        require(amount > 0, "Sale: DEPOSIT_AMOUNT_INVALID");
        _saleToken.safeTransferFrom(_msgSender(), address(this), amount);

        emit TokenDeposited(_msgSender(), amount);
    }

    /************************|
    |        Pull out        |
    |_______________________*/
    
    /** 
    * @dev `Owner` pull out token from this contract
    * contract must be cancelled or the sale is not completed
    */
    function pullOutTokens() external nonReentrant onlyOwner {
        require(state() == 2, "Refund: SALE_NOT_CANCELLED");

        uint256 amount = balance();
        _saleToken.safeTransfer(_msgSender(), amount);

        emit Pullout(amount);
    }

    /************************|
    |   Internal functions   |
    |_______________________*/
    
    function balance() internal view returns(uint256) {
        return _saleToken.balanceOf(address(this));
    }
}