// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract TokenV1V2Upgrade is Ownable, AccessControl {
    using SafeERC20 for IERC20;
    using SafeERC20 for IERC20;

    IERC20  private  _tokenV1;
    IERC20  private  _tokenV2;
    
    uint8   private _rateV1       = 5;             // per dollor
    uint8   private _rateV2       = 4;             // times
    uint8   private _bonus        = 2;             // times
    uint256 private _extraAmount  = 0;             // in tokens,
    bool    private _enabled      = false;
    address private _fundsAccount = address(0x0);

    event AdonxV1DepositComplete(address _sender, uint256 amount);
    event AdonxV2TransferComplete(address _sender, uint256 amount);

    constructor()
    {
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    receive() external payable {
        revert("Not allowed"); //not accepting unsolicited ether
    }

    function upgrade(uint256 v1_amount) external {
        require(_enabled, "V1 V2 upgrade unavailable.");

        require( _tokenV1.balanceOf(_msgSender()) >= v1_amount, "Dont have enough V1 Tokens" );
        require( _tokenV1.allowance(_msgSender(), address(this)) >= v1_amount, "Dont have enough V1 allowance" );

        uint256 _v2_amount = calculateV2Amount(v1_amount);
        
        require( _v2_amount > 0, "V2 Amount can't be zero" );
        require( _tokenV2.allowance(_fundsAccount, address(this)) >= _v2_amount, "Dont have enough V2 allowance" );

        _tokenV1.safeTransferFrom(_msgSender(), _fundsAccount, v1_amount);
        emit AdonxV1DepositComplete(_msgSender(), v1_amount);

        _tokenV2.safeTransferFrom(_fundsAccount, _msgSender(), _v2_amount);
        emit AdonxV2TransferComplete(_msgSender(), _v2_amount);
    }

    function calculateV2Amount(
        uint256 _v1_amount
    ) public view returns (uint256) {
        require(_v1_amount > 0, "V1 Amount can't be zero");
        return ((_v1_amount) * (_rateV2 + _bonus)) + _extraAmount;
    }

    function tokenV1() public view returns (IERC20) {
        return _tokenV1;
    }

    function tokenV2() public view returns (IERC20) {
        return _tokenV2;
    }

    function rateV1() public view returns (uint8) {
        return _rateV1;
    }

    function rateV2() public view returns (uint8) {
        return _rateV2;
    }

    function bonus() public view returns (uint8) {
        return _bonus;
    }

    function extraAmount() public view returns (uint256) {
        return _extraAmount;
    }

    function enabled() public view returns (bool) {
        return _enabled;
    }

    function fundingAccount() public view onlyRole(DEFAULT_ADMIN_ROLE) returns (address) {
        return _fundsAccount;
    }

    function setEnabled(bool value) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _enabled = value;
    }

    function setRateV1(uint8 value) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _rateV1 = value;
    }

    function setRateV2(uint8 value) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _rateV2 = value;
    }

    function setBonus(uint8 value) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _bonus = value;
    }

    function setExtraAmount(uint256 value) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _extraAmount = value;
    }

    function setTokenV1(IERC20 token) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _tokenV1 = IERC20(token);
    }

    function setTokenV2(IERC20 token) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _tokenV2 = IERC20(token);
    }

    function setFundingAccount(address _account) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _fundsAccount = _account;
    }
}


    // require(IERC20(tokenV1).balanceOf(msg.sender) >= amount, "Usdt amount must be greater than deposit.");
    // uint256 tokenAmount = amount.mul(rate).mul(1000000000000);                  //usdt have 6 and this token have 18 decimal places
    // require(IERC20(tokenV1).allowance(msg.sender, address(this)) >= amount);
    // IERC20(tokenV1).safeTransferFrom(msg.sender, development, amount);
    // userUsdtSpent[msg.sender][usdt] += amount;
    // emit AdonxV1DepositComplete(tokenV1, amount);
    // require(IERC20(tokenV2).allowance(development, address(this)) >= tokenAmount);
    // IERC20(tokenV2).safeTransferFrom(development, msg.sender, tokenAmount);
    // userTokenBalance[msg.sender][token] += tokenAmount;
    // emit AdonxV2TransferComplete(tokenV2, amount);