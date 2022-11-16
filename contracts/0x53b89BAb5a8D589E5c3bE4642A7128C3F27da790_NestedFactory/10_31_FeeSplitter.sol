// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.14;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./interfaces/external/IWETH.sol";

/// @title Manage the fees between shareholders
/// @notice Receives fees collected by the NestedFactory, and splits the income among
/// shareholders (the NFT owners, Nested treasury and a NST buybacker contract).
contract FeeSplitter is Ownable, ReentrancyGuard {
    /* ------------------------------ EVENTS ------------------------------ */

    /// @dev Emitted when a payment is released
    /// @param to The address receiving the payment
    /// @param token The token transfered
    /// @param amount The amount paid
    event PaymentReleased(address to, address token, uint256 amount);

    /// @dev Emitted when a payment is received
    /// @param from The address sending the tokens
    /// @param token The token received
    /// @param amount The amount received
    event PaymentReceived(address from, address token, uint256 amount);

    /// @dev Emitted when the royalties weight is updated
    /// @param weight The new weight
    event RoyaltiesWeightUpdated(uint256 weight);

    /// @dev Emitted when a new shareholder is added
    /// @param account The new shareholder account
    /// @param weight The shareholder weight
    event ShareholdersAdded(address account, uint256 weight);

    /// @dev Emitted when a shareholder weight is updated
    /// @param account The shareholder address
    /// @param weight The new weight
    event ShareholderUpdated(address account, uint256 weight);

    /// @dev Emitted when royalties are claim released
    /// @param to The address claiming the royalties
    /// @param token The token received
    /// @param value The amount received
    event RoyaltiesReceived(address to, address token, uint256 value);

    /* ------------------------------ STRUCTS ------------------------------ */

    /// @dev Represent a shareholder
    /// @param account Shareholders address that can receive income
    /// @param weight Determines share allocation
    struct Shareholder {
        address account;
        uint96 weight;
    }

    /// @dev Registers shares and amount release for a specific token or ETH
    struct TokenRecords {
        uint256 totalShares;
        uint256 totalReleased;
        mapping(address => uint256) shares;
        mapping(address => uint256) released;
    }

    /* ----------------------------- VARIABLES ----------------------------- */

    /// @dev Map of tokens with the tokenRecords
    mapping(address => TokenRecords) private tokenRecords;

    /// @dev All the shareholders (array)
    Shareholder[] private shareholders;

    /// @dev Royalties part weights when applicable
    uint256 public royaltiesWeight;

    uint256 public totalWeights;

    address public immutable weth;

    /* ---------------------------- CONSTRUCTOR ---------------------------- */

    constructor(
        address[] memory _accounts,
        uint96[] memory _weights,
        uint256 _royaltiesWeight,
        address _weth
    ) {
        require(_weth != address(0), "FS: INVALID_ADDRESS");
        // Initial shareholders addresses and weights
        setShareholders(_accounts, _weights);
        setRoyaltiesWeight(_royaltiesWeight);
        weth = _weth;
    }

    /// @dev Receive ether after a WETH withdraw call
    receive() external payable {
        require(msg.sender == weth, "FS: ETH_SENDER_NOT_WETH");
    }

    /* -------------------------- OWNER FUNCTIONS -------------------------- */

    /// @notice Sets the weight assigned to the royalties part for the fee
    /// @param _weight The new royalties weight
    function setRoyaltiesWeight(uint256 _weight) public onlyOwner {
        require(_weight != 0, "FS: WEIGHT_ZERO");
        totalWeights = totalWeights + _weight - royaltiesWeight;
        royaltiesWeight = _weight;
        emit RoyaltiesWeightUpdated(_weight);
    }

    /// @notice Sets a new list of shareholders
    /// @param _accounts Shareholders accounts list
    /// @param _weights Weight for each shareholder. Determines part of the payment allocated to them
    function setShareholders(address[] memory _accounts, uint96[] memory _weights) public onlyOwner {
        delete shareholders;
        uint256 accountsLength = _accounts.length;
        require(accountsLength != 0, "FS: EMPTY_ARRAY");
        require(accountsLength == _weights.length, "FS: INPUTS_LENGTH_MUST_MATCH");
        totalWeights = royaltiesWeight;

        for (uint256 i = 0; i < accountsLength; i++) {
            _addShareholder(_accounts[i], _weights[i]);
        }
    }

    /// @notice Updates weight for a shareholder
    /// @param _accountIndex Account to change the weight of
    /// @param _weight The new weight
    function updateShareholder(uint256 _accountIndex, uint96 _weight) external onlyOwner {
        require(_weight != 0, "FS: INVALID_WEIGHT");
        require(_accountIndex < shareholders.length, "FS: INVALID_ACCOUNT_INDEX");
        Shareholder storage _shareholder = shareholders[_accountIndex];
        totalWeights = totalWeights + _weight - _shareholder.weight;
        require(totalWeights != 0, "FS: TOTAL_WEIGHTS_ZERO");
        _shareholder.weight = _weight;
        emit ShareholderUpdated(_shareholder.account, _weight);
    }

    /* -------------------------- USERS FUNCTIONS -------------------------- */

    /// @notice Release multiple tokens and handle ETH unwrapping
    /// @param _tokens ERC20 tokens to release
    function releaseTokens(IERC20[] calldata _tokens) external nonReentrant {
        uint256 amount;
        for (uint256 i = 0; i < _tokens.length; i++) {
            amount = _releaseToken(_msgSender(), _tokens[i]);
            if (address(_tokens[i]) == weth) {
                IWETH(weth).withdraw(amount);
                (bool success, ) = _msgSender().call{ value: amount }("");
                require(success, "FS: ETH_TRANFER_ERROR");
            } else {
                SafeERC20.safeTransfer(_tokens[i], _msgSender(), amount);
            }
            emit PaymentReleased(_msgSender(), address(_tokens[i]), amount);
        }
    }

    /// @notice Release multiple tokens without ETH unwrapping
    /// @param _tokens ERC20 tokens to release
    function releaseTokensNoETH(IERC20[] calldata _tokens) external nonReentrant {
        uint256 amount;
        for (uint256 i = 0; i < _tokens.length; i++) {
            amount = _releaseToken(_msgSender(), _tokens[i]);
            SafeERC20.safeTransfer(_tokens[i], _msgSender(), amount);
            emit PaymentReleased(_msgSender(), address(_tokens[i]), amount);
        }
    }

    /// @notice Sends a fee to this contract for splitting, as an ERC20 token. No royalties are expected.
    /// @param _token Currency for the fee as an ERC20 token
    /// @param _amount Amount of token as fee to be claimed by this contract
    function sendFees(IERC20 _token, uint256 _amount) external nonReentrant {
        uint256 weights;
        unchecked {
            weights = totalWeights - royaltiesWeight;
        }

        uint256 balanceBeforeTransfer = _token.balanceOf(address(this));
        SafeERC20.safeTransferFrom(_token, _msgSender(), address(this), _amount);

        _sendFees(_token, _token.balanceOf(address(this)) - balanceBeforeTransfer, weights);
    }

    /// @notice Sends a fee to this contract for splitting, as an ERC20 token
    /// @param _royaltiesTarget The account that can claim royalties
    /// @param _token Currency for the fee as an ERC20 token
    /// @param _amount Amount of token as fee to be claimed by this contract
    function sendFeesWithRoyalties(
        address _royaltiesTarget,
        IERC20 _token,
        uint256 _amount
    ) external nonReentrant {
        require(_royaltiesTarget != address(0), "FS: INVALID_ROYALTIES_TARGET");

        uint256 balanceBeforeTransfer = _token.balanceOf(address(this));
        SafeERC20.safeTransferFrom(_token, _msgSender(), address(this), _amount);
        uint256 amountReceived = _token.balanceOf(address(this)) - balanceBeforeTransfer;

        uint256 _totalWeights = totalWeights;
        uint256 royaltiesAmount = (amountReceived * royaltiesWeight) / _totalWeights;

        _sendFees(_token, amountReceived, _totalWeights);
        _addShares(_royaltiesTarget, royaltiesAmount, address(_token));

        emit RoyaltiesReceived(_royaltiesTarget, address(_token), royaltiesAmount);
    }

    /* ------------------------------- VIEWS ------------------------------- */

    /// @notice Returns the amount due to an account. Call releaseToken to withdraw the amount.
    /// @param _account Account address to check the amount due for
    /// @param _token ERC20 payment token address
    /// @return The total amount due for the requested currency
    function getAmountDue(address _account, IERC20 _token) public view returns (uint256) {
        TokenRecords storage _tokenRecords = tokenRecords[address(_token)];
        uint256 _totalShares = _tokenRecords.totalShares;
        if (_totalShares == 0) return 0;

        uint256 totalReceived = _tokenRecords.totalReleased + _token.balanceOf(address(this));
        return (totalReceived * _tokenRecords.shares[_account]) / _totalShares - _tokenRecords.released[_account];
    }

    /// @notice Getter for the total shares held by shareholders.
    /// @param _token Payment token address
    /// @return The total shares count
    function totalShares(address _token) external view returns (uint256) {
        return tokenRecords[_token].totalShares;
    }

    /// @notice Getter for the total amount of token already released.
    /// @param _token Payment token address
    /// @return The total amount release to shareholders
    function totalReleased(address _token) external view returns (uint256) {
        return tokenRecords[_token].totalReleased;
    }

    /// @notice Getter for the amount of shares held by an account.
    /// @param _account Account the shares belong to
    /// @param _token Payment token address
    /// @return The shares owned by the account
    function shares(address _account, address _token) external view returns (uint256) {
        return tokenRecords[_token].shares[_account];
    }

    /// @notice Getter for the amount of Ether already released to a shareholders.
    /// @param _account The target account for this request
    /// @param _token Payment token address
    /// @return The amount already released to this account
    function released(address _account, address _token) external view returns (uint256) {
        return tokenRecords[_token].released[_account];
    }

    /// @notice Finds a shareholder and return its index
    /// @param _account Account to find
    /// @return The shareholder index in the storage array
    function findShareholder(address _account) external view returns (uint256) {
        for (uint256 i = 0; i < shareholders.length; i++) {
            if (shareholders[i].account == _account) return i;
        }
        revert("FS: SHAREHOLDER_NOT_FOUND");
    }

    /* ------------------------- PRIVATE FUNCTIONS ------------------------- */

    /// @notice Transfers a fee to this contract
    /// @dev This method calculates the amount received, to support deflationary tokens
    /// @param _token Currency for the fee
    /// @param _amount Amount of token sent
    /// @param _totalWeights Total weights to determine the share count to allocate
    function _sendFees(
        IERC20 _token,
        uint256 _amount,
        uint256 _totalWeights
    ) private {
        Shareholder[] memory shareholdersCache = shareholders;
        for (uint256 i = 0; i < shareholdersCache.length; i++) {
            _addShares(
                shareholdersCache[i].account,
                (_amount * shareholdersCache[i].weight) / _totalWeights,
                address(_token)
            );
        }
        emit PaymentReceived(_msgSender(), address(_token), _amount);
    }

    /// @dev Increase the shares of a shareholder
    /// @param _account The shareholder address
    /// @param _shares The shares of the holder
    /// @param _token The updated token
    function _addShares(
        address _account,
        uint256 _shares,
        address _token
    ) private {
        TokenRecords storage _tokenRecords = tokenRecords[_token];
        _tokenRecords.shares[_account] += _shares;
        _tokenRecords.totalShares += _shares;
    }

    function _releaseToken(address _account, IERC20 _token) private returns (uint256) {
        uint256 amountToRelease = getAmountDue(_account, _token);
        require(amountToRelease != 0, "FS: NO_PAYMENT_DUE");

        TokenRecords storage _tokenRecords = tokenRecords[address(_token)];
        _tokenRecords.released[_account] += amountToRelease;
        _tokenRecords.totalReleased += amountToRelease;

        return amountToRelease;
    }

    function _addShareholder(address _account, uint96 _weight) private {
        require(_weight != 0, "FS: ZERO_WEIGHT");
        require(_account != address(0), "FS: INVALID_ADDRESS");
        for (uint256 i = 0; i < shareholders.length; i++) {
            require(shareholders[i].account != _account, "FS: ALREADY_SHAREHOLDER");
        }

        shareholders.push(Shareholder(_account, _weight));
        totalWeights += _weight;
        emit ShareholdersAdded(_account, _weight);
    }
}