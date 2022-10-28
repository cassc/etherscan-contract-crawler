// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./abstracts/BaseContract.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
// Interfaces.
import "./interfaces/IFurBetToken.sol";
import "./interfaces/IVault.sol";

/**
 * @title FurbetStake
 * @notice This is the staking contract for Furbet
 */

/// @custom:security-contact [email protected]
contract FurBetMaxStake is BaseContract, ERC721Upgradeable
{
    /**
     * Contract initializer.
     * @dev This intializes all the parent contracts.
     */
    function initialize() initializer public
    {
        __BaseContract_init();
        __ERC721_init("FurBetMaxStake", "$FURBMS");
    }

    using Strings for uint256;

    /**
     * Properties.
     */
    uint256 private _tokenIdTracker; // Keeps track of staking tokens.
    uint256 public totalSupply; // Total supply of staking tokens.
    uint256 public totalStaked; // Total amount of staked tokens.
    uint256 public totalDividends; // Total dividends paid out.
    uint256 public totalDividendsClaimed; // Total dividends claimed.
    uint256 public lastDistribution; // Last time dividends were distributed.
    uint256 public stakingPeriod; // The staking period.

    /**
     * Mappings.
     */
    mapping (uint256 => uint256) public tokenEntryDate; // The date the token was staked.
    mapping (uint256 => uint256) public tokenExitDate; // The date the token can be unstaked.
    mapping (uint256 => uint256) public tokenStakeValue; // Value of the stake.
    mapping (uint256 => uint256) public tokenDividendsClaimed; // The amount of dividends claimed.

    /**
     * External contracts.
     */
    IFurBetToken public furBetToken;
    address public furMaxAddress;
    IVault public vault;

    /**
     * Setup.
     */
    function setup() external
    {
        stakingPeriod = 90 days;
        furBetToken = IFurBetToken(addressBook.get("furbettoken"));
        furMaxAddress = addressBook.get("furmax");
        vault = IVault(addressBook.get("vault"));
    }

    /**
     * Stake.
     * @param participant_ Participant address.
     * @param amount_ Staking amount.
     */
    function stake(address participant_, uint256 amount_) external
    {
        require(vault.participantMaxed(participant_), "Participant is not maxed");
        require(furBetToken.transferFrom(msg.sender, address(this), amount_), "Failed to transfer tokens");
        uint256 _balance_ = balanceOf(participant_);
        if(_balance_ == 0) {
            _tokenIdTracker ++;
            _mint(participant_, _tokenIdTracker);
            tokenEntryDate[_tokenIdTracker] = block.timestamp;
            totalSupply ++;
            _balance_ = 1;
        }
        uint256 _valuePerNft_ = amount_ / _balance_;
        for(uint256 i = 1; i <= _tokenIdTracker; i++) {
            if(ownerOf(i) == participant_) {
                tokenStakeValue[i] += _valuePerNft_;
                tokenExitDate[i] = block.timestamp + stakingPeriod;
                totalStaked += _valuePerNft_;
            }
        }
    }

    /**
     * Staked.
     * @param participant_ Participant address.
     * @return uint256 Amount staked.
     */
    function staked(address participant_) external view returns (uint256)
    {
        uint256 _staked_ = 0;
        for(uint256 i = 1; i <= _tokenIdTracker; i ++) {
            if(super.ownerOf(i) == participant_) {
                _staked_ += tokenStakeValue[i];
            }
        }
        return _staked_;
    }

    /**
     * Disable transfers for now.
     * @param from From address.
     * @param to To address.
     * @param tokenId Token id.
     */
    function _transfer(address from, address to, uint256 tokenId) internal pure override {
        require(true == false, "Transfers are disabled");
    }

    /**
     * Token URI.
     * @param tokenId_ The token ID.
     * @return string The metadata json.
     */
    function tokenURI(uint256 tokenId_) public view override returns(string memory)
    {
        require(tokenId_ > 0 && tokenId_ <= _tokenIdTracker, "Invalid token ID");
        bytes memory _meta_ = abi.encodePacked(
            '{',
            '"name": "FurBetMax #', tokenId_.toString(), '",',
            '"description":"FurBetMax NFT",',
            '"attributes": [',
            abi.encodePacked(
                '{"trait_type":"Entry Date", "value":"', tokenEntryDate[tokenId_].toString(), '"},',
                '{"trait_type":"Exit Date","value":"', tokenExitDate[tokenId_].toString(), '"},',
                '{"trait_type":"Staked","value":"', tokenStakeValue[tokenId_].toString(), '"},',
                '{"trait_type":"Dividends Claimed","value":"', tokenDividendsClaimed[tokenId_].toString(), '"}'
            ),
            ']',
            '}'
        );
        return string(
            abi.encodePacked(
                "data:application/json;base64,",
                Base64.encode(_meta_)
            )
        );
    }

}