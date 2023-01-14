// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0; 

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";


contract ZippaToken is Initializable, ERC20Upgradeable, OwnableUpgradeable , ReentrancyGuardUpgradeable{
    using SafeMathUpgradeable for uint256;

    mapping(address => bool) public _isBlacklisted;
    address public mintMaster;
    address public feeCollector;
    uint public price;
    uint public tokensSold;
    uint public minimumAmount;
    // Emitted when tokens are sold
    event TokenSold(address indexed account, uint indexed price, uint tokensGot);

    // store addresses that a automatic market maker pairs. Any transfer *to* these addresses
    function initialize() external virtual initializer {
        __Ownable_init();
        __ReentrancyGuard_init_unchained();
        __ERC20_init("Zippa Token", "ZIPPA");
         mintMaster = owner();  //initial owner=mintmaster (set to piston race contract later)
         minimumAmount  = 20000;
    }

    function mint(address _to, uint256 _amount) external {
        require(msg.sender == mintMaster); // only allowed for mint master
        _mint(_to, _amount);
    }

    receive() external payable {}

    function transferBnb() external onlyOwner {
        // withdraw accidentally sent bnb
        payable(owner()).transfer(address(this).balance);
    }

    function blacklistAddress(address account, bool value) external onlyOwner {
        _isBlacklisted[account] = value;
    }

    function setMintMasterAddress(address _value) external {
        require(
            msg.sender == mintMaster,
            "only the current mint master is allowed to do this"
        );
        mintMaster = _value;
    }

    function buyToken(uint256 _tokenAmount) external payable nonReentrant{ 
        require(_tokenAmount >= minimumAmount, "Minimum Amount to purchase required");
        require(!_isBlacklisted[_msgSender()], "This address is whitelisted");
        uint256 cost = (_tokenAmount.mul(price)).div(10e18);
        require(cost <= msg.value , "Insufficient amount provided for token purchase");
        uint256 tokensToGet = _tokenAmount.mul(10**18);
        payable(feeCollector).transfer(msg.value);
        _mint(_msgSender(),tokensToGet);
        tokensSold = tokensSold.add(tokensToGet);
        emit TokenSold(_msgSender(), price, tokensToGet);
    }

    // If the intended price is 0.01 per token, call this function with the result of 0.01 * 10**18 (_price = intended price * 10**18; calc this in a calculator).
    function tokenPrice(uint _price) external onlyOwner {
        price = _price;
    }

    function changeFeeCollector(address _feeCollector) external onlyOwner {
        feeCollector = _feeCollector;
    }

    function setMinimumAmount(uint amount) external onlyOwner{
        minimumAmount = amount;
    }
}