// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.15;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "abdk-libraries-solidity/ABDKMath64x64.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// StandardTokenGateway holds TSTs and acts as a standard token data feed with:
// - price per token in sEURO;
// - amount of obtainable tokens as bonding rewards left
contract StandardTokenGateway is AccessControl {

    // Reward token (TST)
    IERC20 public immutable TOKEN;

    uint256 public priceTstEur = 5500000;
    uint8 public priceDec = 8;

    // The amount of TST available to get as bond reward
    uint256 public bondRewardPoolSupply = 0;

    // By default enabled.
    // False when token transfers are disabled.
    bool private isActive = true;

    // The storage address
    address public storageAddress;

    bytes32 public constant TST_TOKEN_GATEWAY = keccak256("TST_TOKEN_GATEWAY");

    event Reward(address indexed user, uint256 amount);
    event RewardSupply(uint256 amount);

    constructor(address _tokenAddress) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(TST_TOKEN_GATEWAY, msg.sender);
        TOKEN = IERC20(_tokenAddress);
    }

    modifier onlyGatewayOwner {
        require(hasRole(TST_TOKEN_GATEWAY, msg.sender), "invalid-gateway-owner");
        _;
    }

    modifier onlyStorageOwner {
        require(msg.sender == storageAddress, "err-not-storage-caller");
        _;
    }

    modifier isActivated {
        require(isActive == true, "err-in-maintenance");
        _;
    }

    function deactivateSystem() external onlyGatewayOwner {
        isActive = false;
    }

    function activateSystem() external onlyGatewayOwner {
        isActive = true;
    }

    function setTstEurPrice(uint256 _price, uint8 _dec) external onlyGatewayOwner {
        priceTstEur = _price;
        priceDec = _dec;
    }

    function updateRewardSupply() external {
        bondRewardPoolSupply = TOKEN.balanceOf(address(this));

        emit RewardSupply(bondRewardPoolSupply);
    }

    modifier enoughBalance(uint256 _toSend) {
        uint256 currBalance = TOKEN.balanceOf(address(this));
        require(currBalance > _toSend, "err-insufficient-tokens");
        _;
    }

    function setStorageAddress(address _newAddress) external onlyGatewayOwner {
        require(_newAddress != address(0), "err-zero-address");
        storageAddress = _newAddress;
    }

    function decreaseRewardSupply(uint256 _amount) external onlyStorageOwner enoughBalance(_amount) {
        require(bondRewardPoolSupply - _amount > 0, "dec-supply-uf");
        bondRewardPoolSupply -= _amount;

        emit RewardSupply(bondRewardPoolSupply);
    }

    function transferReward(address _toUser, uint256 _amount) external onlyStorageOwner isActivated enoughBalance(_amount) {
        TOKEN.transfer(_toUser, _amount);

        emit Reward(_toUser, _amount);
    }
}