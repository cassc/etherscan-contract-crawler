//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "hardhat/console.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract Escrow is ReentrancyGuard {
    using SafeERC20 for IERC20;

    /*==============================================================
                            VARIABLES
    ==============================================================*/

    enum DepositType {
        ETH,
        ERC20,
        ERC721
    }

    /// @notice The deposit struct
    struct Deposit {
        /// @notice The depositor address
        address depositor;
        /// @notice The receiver address
        address receiver;
        /// @notice The amount of the deposit (applies when deposit type is ETH or ERC20)
        uint256 amount;
        /// @notice The token address (if the deposit is ERC20 or ERC721)
        address token;
        /// @notice The token IDs (if the deposit is ERC721)
        uint256[] tokenIds;
        /// @notice The deposit type (ETH, ERC20, ERC721)
        DepositType depositType;
        /// @notice Receiver release request
        bool releaseRequested;
        /// @notice Depositor cancel request
        bool cancelRequested;
    }

    /// @notice Contract owner
    address public owner;

    /// @notice Deposit ID counter
    uint256 public depositId;

    /// @notice The arbitration fee
    uint256 public fee;

    /// @notice Accrued fees in ETH
    uint256 public accruedFeesETH;

    /// @notice Accrued fees in given ERC20 tokens
    mapping(address => uint256) public accruedFeesERC20;

    /// @notice The deposits mapping
    mapping(uint256 => Deposit) public deposits;

    /*==============================================================
                            MODIFIERS
    ==============================================================*/

    /// @notice Only owner can execute
    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert OnlyOwner();
        }
        _;
    }

    /*==============================================================
                            FUNCTIONS
    ==============================================================*/

    constructor() {
        owner = msg.sender;
        fee = 5_000;
    }

    /// @notice Creates a new ETH deposit
    /// @param _receiver The receiver address
    function createDepositETH(address _receiver) external payable {
        if (_receiver == address(0)) {
            revert ReceiverAddressEmpty();
        }

        if (msg.value == 0) {
            revert DepositAmountZero();
        }

        Deposit memory deposit;
        deposit.depositor = msg.sender;
        deposit.receiver = _receiver;
        deposit.amount = msg.value;
        deposit.depositType = DepositType.ETH;
        deposits[++depositId] = deposit;

        emit NewDepositETH(depositId, msg.sender, _receiver, msg.value);
    }

    /// @notice Creates a new ERC20 deposit
    /// @param _receiver The receiver address
    /// @param _token The token address
    /// @param _amount The amount of tokens
    function createDepositERC20(
        address _receiver,
        address _token,
        uint256 _amount
    ) external {
        if (_receiver == address(0)) {
            revert ReceiverAddressEmpty();
        }

        if (_token == address(0)) {
            revert TokenAddressEmpty();
        }

        if (_amount == 0) {
            revert DepositAmountZero();
        }

        Deposit memory deposit;
        deposit.depositor = msg.sender;
        deposit.receiver = _receiver;
        deposit.amount = _amount;
        deposit.token = _token;
        deposit.depositType = DepositType.ERC20;
        deposits[++depositId] = deposit;

        IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);

        emit NewDepositERC20(depositId, msg.sender, _receiver, _token, _amount);
    }

    /// @notice Creates a new ERC721 deposit
    /// @param _receiver The receiver address
    /// @param _token The token address
    /// @param _tokenIds The token IDs
    function createDepositERC721(
        address _receiver,
        address _token,
        uint256[] calldata _tokenIds
    ) external {
        if (_receiver == address(0)) {
            revert ReceiverAddressEmpty();
        }

        if (_token == address(0)) {
            revert TokenAddressEmpty();
        }

        if (_tokenIds.length == 0) {
            revert NoTokenIds();
        }

        deposits[++depositId] = Deposit({
            depositor: msg.sender,
            receiver: _receiver,
            token: _token,
            tokenIds: _tokenIds,
            depositType: DepositType.ERC721,
            amount: 0,
            releaseRequested: false,
            cancelRequested: false
        });

        uint256 length = _tokenIds.length;
        for (uint256 i = 0; i < length; ++i) {
            IERC721(_token).safeTransferFrom(
                msg.sender,
                address(this),
                _tokenIds[i]
            );
        }

        emit NewDepositERC721(
            depositId,
            msg.sender,
            _receiver,
            _token,
            _tokenIds
        );
    }

    /// @notice Approves deposit release to the receiver
    /// @param _id The deposit ID
    function releaseDeposit(uint256 _id) external {
        Deposit storage deposit = deposits[_id];
        if (deposit.depositor == address(0)) {
            revert DepositDoesNotExist();
        }

        if (deposit.depositor != msg.sender) {
            revert OnlyDepositor();
        }

        _transfer(_id, deposit.receiver);

        emit DepositReleased(_id);
    }

    /// @notice Requests the cancellation of the deposit
    /// @param _id The deposit ID
    function requestCancel(uint256 _id) external {
        Deposit storage deposit = deposits[_id];
        if (deposit.depositor == address(0)) {
            revert DepositDoesNotExist();
        }

        if (deposit.depositor != msg.sender) {
            revert OnlyDepositor();
        }

        deposit.cancelRequested = true;

        emit CancelRequested(_id);
    }

    /// @notice Requests the release of the deposit to the receiver
    /// @param _id The deposit ID
    function requestRelease(uint256 _id) external {
        Deposit storage deposit = deposits[_id];
        if (deposit.depositor == address(0)) {
            revert DepositDoesNotExist();
        }

        if (deposit.receiver != msg.sender) {
            revert OnlyReceiver();
        }

        deposit.releaseRequested = true;

        emit ReleaseRequested(_id);
    }

    /// @notice Approves the cancellation of the deposit to the depositor
    /// @param _id The deposit ID
    function approveCancel(uint256 _id) external onlyOwner {
        if (!deposits[_id].cancelRequested) {
            revert CancelNotRequested();
        }

        _transfer(_id, deposits[_id].depositor);

        emit DepositCancelled(_id);
    }

    /// @notice Approves the release of the deposit to the receiver
    /// @param _id The deposit ID
    function approveRelease(uint256 _id) external onlyOwner {
        if (!deposits[_id].releaseRequested) {
            revert ReleaseNotRequested();
        }

        _transfer(_id, deposits[_id].receiver);

        emit DepositReleased(_id);
    }

    /// @notice Transfers the deposit to the receiver or depositor,
    /// @notice depending whether it was released or cancelled.
    /// @param _id The deposit ID
    /// @param _to The address to transfer the deposit to
    function _transfer(uint256 _id, address _to) internal {
        Deposit memory deposit = deposits[_id];
        bool applyFee = deposit.cancelRequested || deposit.releaseRequested;
        uint256 transferAmount = deposit.amount;
        uint256 feeAmount = 0;

        if (applyFee) {
            feeAmount = (transferAmount * fee) / 100_000;
            transferAmount -= feeAmount;
        }

        DepositType depositType = deposit.depositType;

        delete deposits[_id];

        if (depositType == DepositType.ETH) {
            if (feeAmount > 0) {
                accruedFeesETH += feeAmount;
            }

            _transferETH(transferAmount, _to);
        } else if (depositType == DepositType.ERC20) {
            if (feeAmount > 0) {
                accruedFeesERC20[deposit.token] += feeAmount;
            }

            _transferERC20(deposit.token, transferAmount, _to);
        } else if (depositType == DepositType.ERC721) {
            _transferERC721(deposit.token, deposit.tokenIds, _to);
        }
    }

    /// @notice Allows the depositor to release the ETH deposit
    /// @param _amount The amount of ETH
    /// @param _to The address to transfer the ETH to
    function _transferETH(uint256 _amount, address _to) internal {
        (bool success, ) = payable(_to).call{value: _amount}("");
        if (!success) {
            revert FailedEthTransfer();
        }
    }

    /// @notice Allows the depositor to release the ERC20 deposit
    /// @param _token The token address
    /// @param _amount The amount of tokens
    /// @param _to The address to transfer the tokens to
    function _transferERC20(
        address _token,
        uint256 _amount,
        address _to
    ) internal {
        IERC20(_token).safeTransfer(_to, _amount);
    }

    /// @notice Allows the depositor to release the ERC721 deposit
    /// @param _token The token address
    /// @param _tokenIds The token IDs
    /// @param _to The address to transfer the tokens to
    function _transferERC721(
        address _token,
        uint256[] memory _tokenIds,
        address _to
    ) internal {
        uint256 length = _tokenIds.length;
        for (uint256 i = 0; i < length; ++i) {
            IERC721(_token).safeTransferFrom(address(this), _to, _tokenIds[i]);
        }
    }

    /// @notice Allows the owner to withdraw the accrued ETH fees
    /// @param _to The address to send the fees to
    function withdrawFeesETH(address _to) external onlyOwner {
        if (accruedFeesETH == 0) {
            revert NoFeesAccrued();
        }

        uint256 feesToTransfer = accruedFeesETH;
        accruedFeesETH = 0;

        (bool success, ) = payable(_to).call{value: feesToTransfer}("");
        if (!success) {
            revert FailedEthTransfer();
        }
    }

    /// @notice Allows the owner to withdraw the accrued ERC20 fees
    /// @param _to The address to send the fees to
    /// @param _token The token address
    function withdrawFeesERC20(address _to, address _token) external onlyOwner {
        if (accruedFeesERC20[_token] == 0) {
            revert NoFeesAccrued();
        }

        uint256 feesToTransfer = accruedFeesERC20[_token];
        accruedFeesERC20[_token] = 0;

        IERC20(_token).safeTransfer(_to, feesToTransfer);
    }

    /// @notice Set the new owner
    /// @param _newOwner The new owner address
    function setOwner(address _newOwner) external onlyOwner {
        owner = _newOwner;

        emit OwnerChanged(_newOwner);
    }

    /// @notice Allows the contract to receive ERC721 tokens
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function getTokenIds(
        uint256 _depositId
    ) external view returns (uint256[] memory tokenIds) {
        tokenIds = deposits[_depositId].tokenIds;
    }

    /*==============================================================
                            EVENTS
    ==============================================================*/

    /// @notice Emitted when a new deposit is created
    /// @param depositId The current deposit id
    /// @param depositor The depositor address
    /// @param receiver The receiver address
    /// @param amount The amount of the deposit
    event NewDepositETH(
        uint256 indexed depositId,
        address indexed depositor,
        address indexed receiver,
        uint256 amount
    );

    /// @notice Emitted when a new deposit is created
    /// @param depositId The current deposit id
    /// @param depositor The depositor address
    /// @param receiver The receiver address
    /// @param token The token address
    /// @param amount The amount of the deposit
    event NewDepositERC20(
        uint256 indexed depositId,
        address indexed depositor,
        address indexed receiver,
        address token,
        uint256 amount
    );

    /// @notice Emitted when a new deposit is created
    /// @param depositId The current deposit id
    /// @param depositor The depositor address
    /// @param receiver The receiver address
    /// @param token The token address
    /// @param tokenIds The token ids
    event NewDepositERC721(
        uint256 indexed depositId,
        address indexed depositor,
        address indexed receiver,
        address token,
        uint256[] tokenIds
    );

    /// @notice Emitted when a deposit release is requested
    /// @param id Deposit id
    event ReleaseRequested(uint256 indexed id);

    /// @notice Emitted when a deposit is cancelled
    /// @param id Deposit id
    event CancelRequested(uint256 indexed id);

    /// @notice Emitted when a deposit is released
    /// @param id Deposit id
    event DepositReleased(uint256 indexed id);

    /// @notice Emitted when a deposit is cancelled
    /// @param id Deposit id
    event DepositCancelled(uint256 indexed id);

    /// @notice Emitted when the owner is changed
    /// @param newOwner The new owner address
    event OwnerChanged(address indexed newOwner);

    /*==============================================================
                            ERRORS
    ==============================================================*/

    error OnlyOwner();

    error OnlyDepositor();

    error OnlyReceiver();

    error DepositDoesNotExist();

    error FailedEthTransfer();

    error NoFeesAccrued();

    error NoTokenIds();

    error DepositAmountZero();

    error TokenAddressEmpty();

    error ReceiverAddressEmpty();

    error ReleaseNotRequested();

    error CancelNotRequested();
}