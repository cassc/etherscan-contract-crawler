// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./abstracts/BaseContract.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
// Interfaces.
import "./interfaces/IFurBetToken.sol";
import "./interfaces/IFurfiPresale.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";

/**
 * @title FurbetStake
 * @notice This is the staking contract for Furbet
 */

/// @custom:security-contact [email protected]
contract FurBetStake is BaseContract, ERC721Upgradeable
{
    /**
     * Contract initializer.
     * @dev This intializes all the parent contracts.
     */
    function initialize() initializer public
    {
        __BaseContract_init();
        __ERC721_init("FurBetStake", "$FURBS");
        _periods[0] = block.timestamp;
        _periods[1] = 1669852800; // 12:00:00 AM on December 1, 2022 GMT+0000
        _periods[2] = 1677628800; // 12:00:00 AM on March 1, 2023 GMT+0000
        _periods[3] = 1685577600; // 12:00:00 AM on June 1, 2023 GMT+0000
        _periods[4] = 1693526400; // 12:00:00 AM on September 1, 2023 GMT+0000
        _periodTracker = 4;
    }

    /**
     * Properties.
     */
    uint256 private _periodTracker; // Keeps track of staking periods.
    uint256 private _tokenTracker; // Keeps track of staking tokens.

    /**
     * Mappings.
     */
    mapping (uint256 => uint256) private _periods; // Maps period to end timestamp.
    mapping (uint256 => uint256) private _totalStake; // Maps period to total staked.
    mapping (uint256 => uint256) private _tokens; // Maps token id to staking period.
    mapping (uint256 => uint256) private _tokenAmount; // Maps token id to staked amount.
    mapping (uint256 => uint256) private _tokenEntryDate; // Maps token id to entry date.
    mapping (uint256 => bool) private _isMax; // True if part of FurMax.
    mapping (uint256 => uint256) private _furMaxExitDate; // Maps token id to FurMax staking period.

    /**
     * External contracts.
     */
    IFurBetToken private _furBetToken;
    address private _furMaxAddress;

    IERC20 private _usdc;
    mapping (uint256 => bool) private _refunded; // Maps token id to refunded status.

    uint256 public refundStart;
    uint256 public refundEnd;

    /**
     * Setup.
     */
    function setup() external
    {
        _furBetToken = IFurBetToken(addressBook.get("furbettoken"));
        _furMaxAddress = addressBook.get("furmax");
        _usdc = IERC20(addressBook.get("payment"));
        refundStart = 1670860800;
        refundEnd = 1671033600;
    }

    /**
     * Mint.
     * @param amount_ Amount to stake.
     */
    function mint(uint256 amount_) external onlyOwner
    {
        _tokenTracker ++;
        _tokens[_tokenTracker] = 4;
        _tokenAmount[_tokenTracker] = amount_;
        _tokenEntryDate[_tokenTracker] = block.timestamp;
        _totalStake[4] += amount_;
        _mint(msg.sender, _tokenTracker);
    }

    /**
     * Get block time.
     * @return uint256 The current block time.
     */
    function getBlockTime() external view returns(uint256)
    {
        return block.timestamp;
    }

    /**
     * Value.
     * @param token_ Token id.
     * @return uint256 Token value.
     */
    function _value(uint256 token_) internal view returns (uint256)
    {
        uint256 _value_ = 0;
        if(token_ < 4429) _value_ = _tokenAmount[token_] * 50 / 100;
        if(token_ >= 4429) _value_ = _tokenAmount[token_] * 75 / 100;
        return _value_;
    }

    /**
     * Staked.
     * @param participant_ Participant address.
     * @return uint256 Amount staked.
     */
    function staked(address participant_) external view returns (uint256)
    {
        uint256 _staked_ = 0;
        for(uint256 i = 1; i <= _tokenTracker; i ++) {
            if(super.ownerOf(i) == participant_) {
                _staked_ += _value(i);
            }
        }
        return _staked_;
    }

    /**
     * Total staked.
     */
    function totalStaked() external view returns (uint256)
    {
        uint256 _staked_ = 0;
        for(uint256 i = 1; i <= _tokenTracker; i ++) {
            _staked_ += _value(i);
        }
        return _staked_;
    }

    /**
     * Refund.
     */
    function refund() external whenNotPaused
    {
        require(block.timestamp >= refundStart, "FurBetStake: Refund not available yet");
        require(block.timestamp <= refundEnd, "FurBetStake: Refund period has ended");
        uint256 _staked_ = 0;
        for(uint256 i = 1; i <= _tokenTracker; i ++) {
            if(super.ownerOf(i) == msg.sender && !_refunded[i]) {
                 _staked_ += _value(i);
                _refunded[i] = true;
                super._transfer(msg.sender, address(0), i);
            }
        }
        require(_staked_ > 0, "FurBetStake: No tokens to refund");
        require(_usdc.balanceOf(address(this)) >= _staked_, "FurBetStake: Insufficient balance");
        _usdc.transfer(msg.sender, _staked_);
    }

    /**
     * Refund to furfi.
     */
    function refundToFurfi() external whenNotPaused
    {
        require(block.timestamp >= refundStart, "FurBetStake: Refund not available yet");
        uint256 _staked_ = 0;
        for(uint256 i = 1; i <= _tokenTracker; i ++) {
            if(super.ownerOf(i) == msg.sender && !_refunded[i]) {
                 _staked_ += _value(i);
                _refunded[i] = true;
                super._transfer(msg.sender, address(0), i);
            }
        }
        require(_staked_ > 0, "FurBetStake: No tokens to refund");
        require(_usdc.balanceOf(address(this)) >= _staked_, "FurBetStake: Insufficient balance");
        IFurfiPresale _furfiPresale_ = IFurfiPresale(addressBook.get("furfiPresale"));
        _usdc.approve(address(_furfiPresale_), _staked_);
        _furfiPresale_.buyWithUsdcFor(msg.sender, _staked_);
    }
}