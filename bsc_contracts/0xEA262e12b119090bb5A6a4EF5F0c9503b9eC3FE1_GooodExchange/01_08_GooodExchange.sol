// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Address.sol";

/** 
 * @notice GooodExchange to allow redeeming GOOOD tokens for BNB at a fixed rate 
 */
contract GooodExchange is Ownable, Pausable {
    event Redeem(address indexed user, uint256 gooodAmount, uint256 bnbAmount);
    event Deposit(address indexed user, uint256 bnbAmount);
    event Withdraw(address indexed user, uint256 bnbAmount);
    event ExchangeRateChanged(address indexed user, uint256 oldRate, uint256 newRate);

    uint256 public constant RATE_BASE = 1e12;
    address public constant BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;

    /** @notice Exchange rate BNB per GOOOD amount, with base `RATE_BASE` */
    uint256 public bnbPerGoood = 0;
    /** @notice GOOOD Token */
    address public immutable gooodToken;
    mapping(address => bool) public isDepositor;

    constructor(address _gooodToken) {
        gooodToken = _gooodToken;
    }

    /**
     * @notice Redeem `_amount` GOOOD Tokens for BNB.
     */
    function redeem(uint256 _amount) external whenNotPaused {
        require(bnbPerGoood != 0, "No exchange rate set");
        require(IERC20(gooodToken).balanceOf(msg.sender) > _amount, "Insufficient GOOOD amount");
        uint256 bnbAmount = _amount * bnbPerGoood / RATE_BASE;
        require(bnbAmount <= address(this).balance, "Insufficient BNB available");

        emit Redeem(msg.sender, _amount, bnbAmount);

        IERC20(gooodToken).transferFrom(msg.sender, BURN_ADDRESS, _amount);
        Address.sendValue(payable(msg.sender), bnbAmount);
    }

    /**
     * @notice Maximum `_amount` of GOOOD Tokens redeemable for BNB considering current BNB balance.
     */
    function redeemable() external view returns (uint256) {
        return address(this).balance * RATE_BASE / bnbPerGoood;
    }

    /**
     * @notice Available BNB for redemption. 
     */
    function available() external view returns (uint256) {
        return address(this).balance;
    }

    /* Admin interface */

    /**
     * @notice Deposit BNB to be redeemable by exchanging for GOOOD.
     * @dev Only allowed for registered depositors to avoid user mistakes
     */
    function depositBNB() external payable {
        require(msg.sender == owner() || isDepositor[msg.sender], "Only depositor role");
        emit Deposit(msg.sender, msg.value);
    }

    /**
     * @notice Withdraw BNB from available balance. Only used for contract migration.
     */
    function withdrawBNB(uint256 _amount) external onlyOwner {
        emit Withdraw(msg.sender, _amount);
        Address.sendValue(payable(msg.sender), _amount);
    }
    
    /**
     * @notice Set exchange rate BNB per GOOOD with base `RATE_BASE`.
     */
    function setExchangeRate(uint256 _rate, uint256 _validateGoood, uint256 _validateBNB) external onlyOwner {
        require(_validateBNB == _validateGoood * _rate / RATE_BASE, "Rate does not pass validation");
        emit ExchangeRateChanged(msg.sender, bnbPerGoood, _rate);
        bnbPerGoood = _rate;
    }

    function setDepositor(address _user, bool _isDepositor) external onlyOwner {
        isDepositor[_user] = _isDepositor;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function recoverERC721(address _token, address _to, uint256[] calldata _tokenIds) external onlyOwner {
        for (uint256 i = 0; i < _tokenIds.length; ++i) {
            IERC721(_token).transferFrom(address(this), _to, _tokenIds[i]);
        }
    }

    function recoverERC20(address _token, address _to) external onlyOwner {
        uint256 balance = IERC20(_token).balanceOf(address(this));
        IERC20(_token).transferFrom(address(this), _to, balance);
    }
}