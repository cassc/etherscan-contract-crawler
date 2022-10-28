// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./abstracts/BaseContract.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
// Interfaces
import "./interfaces/IVault.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";

/**
 * @title FurBot
 * @notice This is the NFT contract for FurBot.
 */

/// @custom:security-contact [email protected]
contract FurBotMax is BaseContract, ERC721Upgradeable
{
    /**
     * Contract initializer.
     * @dev This intializes all the parent contracts.
     */
    function initialize() initializer public
    {
        __BaseContract_init();
        __ERC721_init("FurBotMax", "$FURBOTM");
    }

    using Strings for uint256;

    /**
     * Global stats.
     */
    uint256 public totalSupply;
    uint256 public totalPendingInvestment;
    uint256 public totalInvestment;
    uint256 public totalDividends;
    uint256 public totalDividendsClaimed;
    uint256 public lastDistribution;

    /**
     * External contracts.
     */
    IERC20 private _paymentToken;
    IVault private _vault;
    address private _furmarket;
    address private _treasury;
    address private _furmax;

    /**
     * NFTs
     */
    uint256 private _tokenIdTracker;
    mapping(uint256 => uint256) private _tokenPendingInvestment;
    mapping(uint256 => uint256) private _tokenInvestment;
    mapping(uint256 => uint256) private _tokenDividendsClaimed;

    /**
     * Setup.
     */
    function setup() external
    {
        _paymentToken = IERC20(addressBook.get("payment"));
        _vault = IVault(addressBook.get("vault"));
        _furmarket = addressBook.get("furmarket");
        _treasury = addressBook.get("safe");
        _furmax = addressBook.get("furmax");
    }

    /**
     * Deposit.
     * @param participant_ Participant address.
     * @param amount_ Amount of USDC to deposit.
     */
    function deposit(address participant_, uint256 amount_) external canDeposit
    {
        require(_paymentToken.transferFrom(msg.sender, _treasury, amount_), "FurBotMax: Transfer failed");
        uint256 _balance_ = balanceOf(participant_);
        if(_balance_ == 0) {
            _tokenIdTracker++;
            _mint(participant_, _tokenIdTracker);
            _balance_ = 1;
        }
        uint256 _valuePerNft_ = amount_ / _balance_;
        for(uint256 i = 1; i <= _tokenIdTracker; i++) {
            if(ownerOf(i) == participant_) {
                _tokenPendingInvestment[i] += _valuePerNft_;
                totalPendingInvestment += _valuePerNft_;
            }
        }
    }

    /**
     * Approve.
     * @param to_ The address to approve.
     * @param tokenId_ The token ID.
     * @dev Overridden to prevent token sales through third party marketplaces.
     */
    function approve(address to_, uint256 tokenId_) public virtual override whenNotPaused
    {
        require(to_ == _furmarket, "FurBotMax: Third party marketplaces not allowed.");
        super.approve(to_, tokenId_);
    }

    /**
     * Set approval for all.
     * @param operator_ The operator address.
     * @param approved_ The approval status.
     * @dev Overridden to prevent token sales through third party marketplaces.
     */
    function setApprovalForAll(address operator_, bool approved_) public virtual override whenNotPaused
    {
        require(operator_ == _furmarket, "FurBotMax: Third party marketplaces not allowed.");
        super.setApprovalForAll(operator_, approved_);
    }

    /**
     * Token URI.
     * @param tokenId_ The token ID.
     * @return string The metadata json.
     */
    function tokenURI(uint256 tokenId_) public view override returns(string memory)
    {
        require(tokenId_ > 0 && tokenId_ <= totalSupply, "FurBotMax: Invalid token ID");
        bytes memory _meta_ = abi.encodePacked(
            '{',
            '"name": "FurBot #', tokenId_.toString(), '",',
            '"description":"Automated market trading through NFTs. Earn monthly passive income by simply holding. NFTs increase in value monthly as the trading pools they are connected to compounds their monthly interest.",',
            '"attributes": [',
            abi.encodePacked(
                '{"trait_type":"Pending Investment", "value":"', _tokenPendingInvestment[tokenId_].toString(), '"},',
                '{"trait_type":"Investment","value":"', _tokenInvestment[tokenId_].toString(), '"},',
                '{"trait_type":"Dividends Available","value":"', availableDividendsByToken(tokenId_).toString(), '"},',
                '{"trait_type":"Dividends Claimed","value":"', _tokenDividendsClaimed[tokenId_].toString(), '"}'
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

    /**
     * Available dividends by token.
     * @param tokenId_ The token ID.
     * @return uint256 The available dividends.
     */
    function availableDividendsByToken(uint256 tokenId_) public view returns(uint256)
    {
        require(tokenId_ > 0 && tokenId_ <= totalSupply, "FurBotMax: Invalid token ID");
        return ((_tokenInvestment[tokenId_] * totalDividends) / totalInvestment) - _tokenDividendsClaimed[tokenId_];
    }

    /**
     * Can deposit modifier.
     */
    modifier canDeposit()
    {
        require(msg.sender == _furmax, "FurBotMax: Only the Furmax contract can deposit.");
        _;
    }
}