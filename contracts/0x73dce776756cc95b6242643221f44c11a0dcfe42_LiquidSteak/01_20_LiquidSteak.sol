// SPDX-License-Identifier: BUSL-1.1
// Licensor: Flashstake DAO
// Licensed Works: (this contract, source below)
// Change Date: The earlier of 2027-05-23 or a date specified by Flashstake DAO publicly
// Change License: GNU General Public License v2.0 or later
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/Flashstake/IFlashNFT.sol";
import "./interfaces/Flashstake/IFlashStrategy.sol";
import "./interfaces/Flashstake/IFlashProtocol.sol";
import "./FlashZToken.sol";

contract LiquidSteak is Ownable {
    using SafeERC20 for IERC20Metadata;

    // Immutable/constant variables
    address immutable public flashProtocolAddress;
    address immutable public flashNFTAddress;
    address constant public auctionExchangeToken = 0xB1f1F47061A7Be15C69f378CB3f69423bD58F2F8;
    uint256 constant public auctionDuration = 604838;                // 7 days and 38 seconds
    uint256 constant public auctionStartBid = 1500000 * (10**18);    // 1.5M
    uint256 constant public auctionDecayPerSecond = 248 * (10**16);  // (2.48)
    uint256 constant public flashtronautDiscountBp = 9000;           // 9000 = 90% of original price (10% discount)

    // Dynamic variables
    mapping(address => address) public strategyZTokenAddresses;
    mapping(uint256 => address) public originalDepositorAddress;

    // Owner controlled
    address public auctionTokensDestination;
    address public flashtronautNFTAddress;

    // Events
    event AuctionTokensDestinationUpdated(address _newAuctionTokensDestination);
    event PositionDeposit(uint256 _nftId);
    event PositionWithdraw(uint256 _nftId);
    event PositionPartialWithdraw(uint256 _nftId, uint256 _fTokensBurned, uint256 _zTokensBurned);
    event AuctionPurchase(uint256 _nftId, uint256 _flashtronautNftId, uint256 _zTokensBurned, uint256 _premiumPaid);

    constructor(address _flashProtocolAddress) {
        flashProtocolAddress = _flashProtocolAddress;
        flashNFTAddress = IFlashProtocol(_flashProtocolAddress).flashNFTAddress();
    }

    /// @notice Allows user to deposit FlashNFT to mint zTokens
    /// @dev this can be called by anyone
    function depositPosition(uint256 _nftId, address _zTokensTo) public returns(address, uint256) {
        IFlashNFT(flashNFTAddress).transferFrom(msg.sender, address(this), _nftId);

        IFlashProtocol.StakeStruct memory stakeInfo = IFlashProtocol(flashProtocolAddress).getStakeInfo(_nftId, true);

        address flashZToken = strategyZTokenAddresses[stakeInfo.strategyAddress];
        require(flashZToken != address(0), "STRATEGY NOT INIT");
        originalDepositorAddress[_nftId] = msg.sender;

        uint256 remainingPrincipal = stakeInfo.stakedAmount - stakeInfo.totalStakedWithdrawn;
        FlashZToken(flashZToken).mint(_zTokensTo, remainingPrincipal);

        emit PositionDeposit(_nftId);

        return (flashZToken, remainingPrincipal);
    }

    /// @notice Allows original depositor to pay back zToken in return for FlashNFT
    /// @dev this can be called by anyone but only original depositor can withdraw FlashNFT
    function withdrawPositionOwner(uint256 _nftId, address _nftTo) external {
        IFlashProtocol.StakeStruct memory stakeInfo = IFlashProtocol(flashProtocolAddress).getStakeInfo(_nftId, true);

        address flashZToken = strategyZTokenAddresses[stakeInfo.strategyAddress];
        require(flashZToken != address(0), "STRATEGY NOT INIT");

        require(originalDepositorAddress[_nftId] == msg.sender, "ONLY ORIGINAL DEPOSITOR");

        uint256 remainingPrincipal = stakeInfo.stakedAmount - stakeInfo.totalStakedWithdrawn;
        FlashZToken(flashZToken).burnOwner(msg.sender, remainingPrincipal);
        IFlashNFT(flashNFTAddress).transferFrom(address(this), _nftTo, _nftId);

        emit PositionWithdraw(_nftId);
    }

    /// @notice Allows original depositor to pay back zToken and fTokens to partially withdraw principal from FlashNFT
    /// @dev this can be called by anyone but only original depositor can partial withdraw from FlashNFT
    function partialWithdrawOwner(uint256 _nftId, uint256 _fTokensToBurn, address _withdrawTo) external returns (uint256) {
        IFlashProtocol.StakeStruct memory stakeInfo = IFlashProtocol(flashProtocolAddress).getStakeInfo(_nftId, true);

        address flashZToken = strategyZTokenAddresses[stakeInfo.strategyAddress];
        require(flashZToken != address(0), "STRATEGY NOT INIT");

        require(originalDepositorAddress[_nftId] == msg.sender, "ONLY ORIGINAL DEPOSITOR");

        address flashFTokenAddress = IFlashStrategy(stakeInfo.strategyAddress).getFTokenAddress();
        IERC20Metadata(flashFTokenAddress).safeTransferFrom(msg.sender, address(this), _fTokensToBurn);

        IERC20Metadata(flashFTokenAddress).approve(flashProtocolAddress, _fTokensToBurn);
        IFlashProtocol(flashProtocolAddress).unstake(_nftId, true, _fTokensToBurn);

        address principalTokenAddress = IFlashStrategy(stakeInfo.strategyAddress).getPrincipalAddress();
        uint256 principalBalance = IERC20Metadata(principalTokenAddress).balanceOf(address(this));

        FlashZToken(flashZToken).burnOwner(msg.sender, principalBalance);

        IERC20Metadata(principalTokenAddress).safeTransfer(_withdrawTo, principalBalance);

        uint256 remainingFTokenBalance = IERC20Metadata(flashFTokenAddress).balanceOf(address(this));
        IERC20Metadata(flashFTokenAddress).safeTransfer(msg.sender, remainingFTokenBalance);

        emit PositionPartialWithdraw(_nftId, (_fTokensToBurn - remainingFTokenBalance), principalBalance);

        return principalBalance;
    }

    /// @notice Deploys a zToken for a given strategy address
    /// @dev this can be called by anyone. Should be called once per strategy address
    function initialiseStrategy(address _fsAddress) external returns(address) {
        require(strategyZTokenAddresses[_fsAddress] == address(0), "STRATEGY ALREADY INIT");

        string memory principalSymbol = IERC20Metadata(IFlashStrategy(_fsAddress).getPrincipalAddress()).symbol();
        uint8 principalDecimals = IERC20Metadata(IFlashStrategy(_fsAddress).getPrincipalAddress()).decimals();

        string memory tokenName = string(abi.encodePacked("Flashstake Collateral ", principalSymbol));
        string memory tokenSymbol = string(abi.encodePacked("fc-", principalSymbol));

        FlashZToken flashZToken = new FlashZToken(tokenName, tokenSymbol, principalDecimals);
        strategyZTokenAddresses[_fsAddress] = address(flashZToken);

        return strategyZTokenAddresses[_fsAddress];
    }

    /// @notice Computes and returns current auction cost, returns zTokensRequired and currentPremium
    /// @dev this can be called by anyone
    function getCurrentAuctionCost(uint256 _nftId, uint256 _flashtronautNftId) public view returns(uint256 zTokensRequired, uint256 currentPremium) {
        IFlashProtocol.StakeStruct memory stakeInfo = IFlashProtocol(flashProtocolAddress).getStakeInfo(_nftId, true);
        zTokensRequired = stakeInfo.stakedAmount - stakeInfo.totalStakedWithdrawn;

        uint256 startOfAuctionTs = stakeInfo.stakeStartTs + stakeInfo.stakeDuration;
        require(block.timestamp >= startOfAuctionTs, "AUCTION NOT STARTED");

        uint256 endOfAuctionTs = startOfAuctionTs + auctionDuration;

        if(block.timestamp > endOfAuctionTs) {
            return (zTokensRequired, currentPremium);
        }

        currentPremium = auctionStartBid - ((block.timestamp - startOfAuctionTs) * auctionDecayPerSecond);

        if(_flashtronautNftId > 0) {
            require(msg.sender == IFlashNFT(flashtronautNFTAddress).ownerOf(_flashtronautNftId), "MISSING FLASHTRONAUT");

            // Compute discount
            currentPremium = (currentPremium * flashtronautDiscountBp) / 10000;
        }
    }

    /// @notice Purchases FlashNFT by burning zTokens from User
    /// @dev this can be called by anyone
    function auctionPurchase(uint256 _nftId, uint256 _flashtronautNftId) external {
        (uint256 zTokensRequired, uint256 premium) = getCurrentAuctionCost(_nftId, _flashtronautNftId);
        IFlashProtocol.StakeStruct memory stakeInfo = IFlashProtocol(flashProtocolAddress).getStakeInfo(_nftId, true);

        address flashZToken = strategyZTokenAddresses[stakeInfo.strategyAddress];
        require(flashZToken != address(0), "STRATEGY NOT INIT");

        IERC20Metadata(auctionExchangeToken).safeTransferFrom(msg.sender, auctionTokensDestination, premium);

        FlashZToken(flashZToken).burnOwner(msg.sender, zTokensRequired);

        IFlashNFT(flashNFTAddress).transferFrom(address(this), msg.sender, _nftId);

        emit AuctionPurchase(_nftId, _flashtronautNftId, zTokensRequired, premium);
    }

    // =================================
    // Owner Functions
    // =================================

    /// @notice Sets the destination address for where auction premiums are sent
    /// @dev this can only be called by the Owner
    function setAuctionTokensDestination(address _newAuctionTokensDestination) external onlyOwner {
        auctionTokensDestination = _newAuctionTokensDestination;
        emit AuctionTokensDestinationUpdated(_newAuctionTokensDestination);
    }

    /// @notice Sets the Flashtronaut NFT address (which give auction discounts)
    /// @dev this can only be called by the Owner
    function setFlashtronautNFTAddress(address _newFlashtronautNFTAddress) external onlyOwner {
        flashtronautNFTAddress = _newFlashtronautNFTAddress;
    }

    // =================================
    // Helper/Frontend View Functions
    // =================================

    /// @notice Returns the number of zTokens minted
    /// @dev this can be called by anyone
    function quoteZTokens(uint256 _nftId) external view returns(uint256 _zTokensMinted) {
        IFlashProtocol.StakeStruct memory stakeInfo = IFlashProtocol(flashProtocolAddress).getStakeInfo(_nftId, true);

        return stakeInfo.stakedAmount - stakeInfo.totalStakedWithdrawn;
    }

    /// @notice Returns whether the auction has started along with the timestamp when the auction starts
    /// @dev this can be called by anyone
    function getAuctionStartDetails(uint256 _nftId) external view returns(bool _started, uint256 _startTimestamp) {
        IFlashProtocol.StakeStruct memory stakeInfo = IFlashProtocol(flashProtocolAddress).getStakeInfo(_nftId, true);

        require(IFlashNFT(flashNFTAddress).ownerOf(_nftId) == address(this), "POSITION NOT AVAILABLE");

        _started = false;
        if(block.timestamp > stakeInfo.stakeStartTs + stakeInfo.stakeDuration) {
            _started = true;
        }

        _startTimestamp = stakeInfo.stakeStartTs + stakeInfo.stakeDuration;
    }
}