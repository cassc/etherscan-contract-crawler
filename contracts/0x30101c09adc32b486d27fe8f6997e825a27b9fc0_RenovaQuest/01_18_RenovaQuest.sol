// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol';
import '@openzeppelin/contracts/utils/Address.sol';
import '@openzeppelin/contracts/utils/Context.sol';

import '../interfaces/core/IRenovaCommandDeckBase.sol';
import '../interfaces/core/IRenovaQuest.sol';
import '../interfaces/nft/IRenovaAvatarBase.sol';

/// @title RenovaQuest
/// @author Victor Ionescu
/// @notice See {IRenovaQuest}
contract RenovaQuest is
    IRenovaQuest,
    IERC721Receiver,
    Context,
    ReentrancyGuard
{
    using SafeERC20 for IERC20;
    using Address for address payable;

    address private immutable _renovaCommandDeck;
    address private immutable _renovaAvatar;
    address private immutable _hashflowRouter;

    /// @inheritdoc IRenovaQuest
    uint256 public immutable startTime;

    /// @inheritdoc IRenovaQuest
    uint256 public immutable endTime;

    /// @inheritdoc IRenovaQuest
    address public immutable depositToken;

    /// @inheritdoc IRenovaQuest
    uint256 public immutable minDepositAmount;

    /// @inheritdoc IRenovaQuest
    address public immutable questOwner;

    /// @inheritdoc IRenovaQuest
    mapping(address => bool) public registered;

    /// @inheritdoc IRenovaQuest
    mapping(address => bool) public allowedTokens;

    /// @inheritdoc IRenovaQuest
    uint256 public numRegisteredPlayers;

    /// @inheritdoc IRenovaQuest
    mapping(IRenovaAvatarBase.RenovaFaction => uint256)
        public numRegisteredPlayersPerFaction;

    /// @inheritdoc IRenovaQuest
    mapping(address => mapping(address => uint256))
        public portfolioTokenBalances;

    constructor(
        address renovaAvatar,
        address hashflowRouter,
        uint256 _startTime,
        uint256 _endTime,
        address _depositToken,
        uint256 _minDepositAmount,
        address _questOwner
    ) {
        _renovaCommandDeck = _msgSender();

        require(
            _startTime > block.timestamp,
            'RenovaQuest::constructor Start time should be in the future.'
        );
        require(
            _endTime > _startTime,
            'RenovaQuest::constructor End time should be after start time.'
        );
        require(
            (_endTime - _startTime) <= (1 days) * 31 * 4,
            'RenovaQuest::constructor Quest too long.'
        );

        startTime = _startTime;
        endTime = _endTime;
        depositToken = _depositToken;
        minDepositAmount = _minDepositAmount;

        allowedTokens[depositToken] = true;

        questOwner = _questOwner;

        _renovaAvatar = renovaAvatar;
        _hashflowRouter = hashflowRouter;

        emit UpdateTokenAuthorizationStatus(depositToken, true);
    }

    /// @dev Fallback function to receive native token.
    receive() external payable {}

    /// @inheritdoc IRenovaQuest
    function updateTokenAuthorization(
        address token,
        bool status
    ) external override {
        require(
            _msgSender() == questOwner,
            'RenovaQuest::updateTokenAuthorization Sender must be quest owner.'
        );

        allowedTokens[token] = status;

        emit UpdateTokenAuthorizationStatus(token, status);
    }

    /// @inheritdoc IERC721Receiver
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    /// @inheritdoc IRenovaQuest
    function depositAndEnter(
        uint256 depositAmount
    ) external payable override nonReentrant {
        _depositAndEnter(_msgSender(), depositAmount);
    }

    /// @inheritdoc IRenovaQuest
    function withdrawTokens(
        address[] memory tokens
    ) external override nonReentrant {
        for (uint256 i = 0; i < tokens.length; i++) {
            uint256 amount = portfolioTokenBalances[_msgSender()][tokens[i]];
            if (amount == 0) {
                continue;
            }
            portfolioTokenBalances[_msgSender()][tokens[i]] = 0;

            emit WithdrawToken(_msgSender(), tokens[i], amount);

            if (tokens[i] == address(0)) {
                payable(_msgSender()).sendValue(amount);
            } else {
                IERC20(tokens[i]).safeTransfer(_msgSender(), amount);
            }
        }
    }

    /// @inheritdoc IRenovaQuest
    function trade(
        IHashflowRouter.RFQTQuote memory quote
    ) external payable override nonReentrant {
        require(
            block.timestamp >= startTime && block.timestamp < endTime,
            'RenovaQuest::trade Quest is not ongoing.'
        );
        require(
            allowedTokens[quote.quoteToken],
            'RenovaQuest::trade Quote Token not allowed.'
        );

        require(
            registered[_msgSender()],
            'RenovaQuest::trade Player not registered.'
        );

        require(
            portfolioTokenBalances[_msgSender()][quote.baseToken] >=
                quote.effectiveBaseTokenAmount,
            'RenovaQuest::trade Insufficient balance'
        );

        require(
            quote.trader == address(this),
            'RenovaQuest::trade Trader should be Quest contract.'
        );

        require(
            quote.effectiveTrader == _msgSender(),
            'RenovaQuest::trade Effective Trader should be player.'
        );

        uint256 quoteTokenAmount = quote.quoteTokenAmount;
        if (quote.effectiveBaseTokenAmount < quote.baseTokenAmount) {
            quoteTokenAmount =
                (quote.effectiveBaseTokenAmount * quote.quoteTokenAmount) /
                quote.baseTokenAmount;
        }

        portfolioTokenBalances[_msgSender()][quote.baseToken] -= quote
            .effectiveBaseTokenAmount;
        portfolioTokenBalances[_msgSender()][
            quote.quoteToken
        ] += quoteTokenAmount;

        emit Trade(
            _msgSender(),
            quote.baseToken,
            quote.quoteToken,
            quote.effectiveBaseTokenAmount,
            quoteTokenAmount
        );

        uint256 msgValue = 0;

        if (quote.baseToken == address(0)) {
            msgValue = quote.effectiveBaseTokenAmount;
        } else {
            require(
                IERC20(quote.baseToken).approve(
                    _hashflowRouter,
                    quote.effectiveBaseTokenAmount
                ),
                'RenovaQuest::trade Could not approve token.'
            );
        }

        uint256 balanceBefore = _questBalanceOf(quote.quoteToken);

        IHashflowRouter(_hashflowRouter).tradeRFQT{value: msgValue}(quote);

        uint256 balanceAfter = _questBalanceOf(quote.quoteToken);

        require(
            balanceBefore + quoteTokenAmount == balanceAfter,
            'RenovaQuest::trade Did not receive enough quote token.'
        );
    }

    /// @notice Deposits tokens and registers the player for the Quest.
    /// @param player The address of the player depositing tokens.
    /// @param depositAmount The amount of token to deposit.
    function _depositAndEnter(address player, uint256 depositAmount) internal {
        require(
            block.timestamp < endTime,
            'RenovaQuest::_depositAndEnter Can only deposit before the quest ends.'
        );
        require(
            depositAmount >= minDepositAmount,
            'RenovaQuest::_depositAndEnter Deposit amount too low.'
        );
        require(
            !registered[player],
            'RenovaQuest::_depositAndEnter Player has already entered the quest.'
        );

        uint256 avatarTokenId = IRenovaAvatarBase(_renovaAvatar).tokenIds(
            player
        );
        require(
            avatarTokenId != 0,
            'RenovaQuest::_depositAndEnter Player has not minted Avatar.'
        );

        if (depositToken == address(0)) {
            require(
                msg.value == depositAmount,
                'RenovaQuest::_depositAndEnter msg.value should equal amount.'
            );
        } else {
            require(
                msg.value == 0,
                'RenovaQuest::_depositAndEnter msg.value should be 0.'
            );
        }

        registered[player] = true;
        portfolioTokenBalances[player][depositToken] += depositAmount;
        numRegisteredPlayers++;

        emit DepositToken(player, depositToken, depositAmount);
        emit RegisterPlayer(player);

        if (depositToken != address(0)) {
            IRenovaCommandDeckBase(_renovaCommandDeck).depositTokenForQuest(
                player,
                depositAmount
            );
        }
    }

    /// @notice Returns the amount of token that this Quest currently holds.
    /// @param token The token to return the balance for.
    /// @return The balance.
    function _questBalanceOf(address token) internal view returns (uint256) {
        if (token == address(0)) {
            return address(this).balance;
        } else {
            return IERC20(token).balanceOf(address(this));
        }
    }
}