// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import {IERC20} from "../libraries/openzeppelin/token/ERC20/IERC20.sol";
import {SettingStorage} from "../libraries/proxy/SettingStorage.sol";
import {OwnableUpgradeable} from "../libraries/openzeppelin/upgradeable/access/OwnableUpgradeable.sol";
import {PausableUpgradeable} from "../libraries/openzeppelin/upgradeable/security/PausableUpgradeable.sol";
import {SafeMath} from "../libraries/openzeppelin/math/SafeMath.sol";
import {IVault} from "../interfaces/IVault.sol";
import {ISettings} from "../interfaces/ISettings.sol";
import {TransferHelper} from "../libraries/helpers/TransferHelper.sol";

contract TokenVaultPresale is
    SettingStorage,
    OwnableUpgradeable,
    PausableUpgradeable
{
    using SafeMath for uint256;
    // data
    mapping(address => bool) public presaleTokens;
    mapping(address => address) public curators;
    mapping(address => uint256) public caps; // max presale
    mapping(address => uint256) public rates; // in ETH
    mapping(address => uint256) public maxs; // in ETH

    /// @notice  gap for reserve, minus 1 if use
    uint256[10] public __gapUint256;
    /// @notice  gap for reserve, minus 1 if use
    uint256[5] public __gapAddress;

    constructor(address _settings) SettingStorage(_settings) {}

    function initialize() public initializer {
        __Ownable_init();
        __Pausable_init();
    }

    event PresaleCreated(
        address indexed curator,
        address indexed token,
        uint256 cap,
        uint256 rate
    );

    event PresalePurchased(
        address indexed curator,
        address indexed buyer,
        address indexed token,
        uint256 principal,
        uint256 amount
    );

    function createPresale(
        address _token,
        uint256 _cap,
        uint256 _rate
    ) external whenNotPaused {
        require(!presaleTokens[_token], "invalid token");
        require(_cap > 0, "invalid cap");
        require(_rate > 0, "invalid rate");
        require(IVault(_token).curator() == msg.sender, "invalid rate");
        require(
            IERC20(_token).allowance(msg.sender, address(this)) >= _cap,
            "invalid allowance"
        );
        presaleTokens[_token] = true;
        caps[_token] = _cap;
        maxs[_token] = _cap;
        rates[_token] = _rate;
        curators[_token] = msg.sender;

        emit PresaleCreated(msg.sender, _token, _cap, _rate);
    }

    // revert
    receive() external payable {
        revert();
    }

    function buyTokens(address _token) external payable whenNotPaused {
        require(presaleTokens[_token], "invalid token");
        uint256 amount = msg.value;
        // update valid for amount
        uint256 validAmount = amount.mul(10000) /
            (10000 + ISettings(settings).presaleFeePercentage());
        // compute amount of tokens
        uint256 tokens = validAmount.mul(10**IVault(_token).decimals()).div(
            rates[_token]
        );
        uint256 cap = caps[_token];
        require(cap >= tokens, "max cap");
        // transfer token
        TransferHelper.safeTransferFrom(
            IERC20(_token),
            curators[_token],
            msg.sender,
            tokens
        );
        // transfer ETH to cruator
        TransferHelper.safeTransferETHOrWETH(
            ISettings(settings).weth(),
            curators[_token],
            validAmount
        );
        // transfer WETH to vault exchange
        TransferHelper.safeTransferETHOrWETH(
            ISettings(settings).weth(),
            IVault(_token).exchange(),
            amount.sub(validAmount)
        );

        caps[_token] = cap.sub(tokens);

        emit PresalePurchased(
            curators[_token],
            msg.sender,
            _token,
            validAmount,
            tokens
        );
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }
}