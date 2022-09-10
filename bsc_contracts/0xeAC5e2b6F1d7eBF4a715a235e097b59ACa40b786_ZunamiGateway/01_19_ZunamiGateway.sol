//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/security/Pausable.sol';

import "./interfaces/stargate/IStargateReceiver.sol";
import "./interfaces/stargate/IStargateRouter.sol";

import "./LzApp.sol";

contract ZunamiGateway is ERC20, Pausable, LzApp, IStargateReceiver {
    using SafeERC20 for IERC20Metadata;

    bytes32 public constant OPERATOR_ROLE = keccak256('OPERATOR_ROLE');

    enum MessageType {
        Deposit,
        Withdrawal
    }

    struct CrossDeposit {
        uint256 id;
        uint256 totalTokenAmount;
        address[] users;
        uint256[] tokenAmounts;
        uint256 totalLpShares;
    }

    struct CrossWithdrawal {
        uint256 id;
        uint256 totalLpShares;
        address[] users;
        uint256[] lpSharesAmounts;
        uint256 totalTokenAmount;
    }

    IStargateRouter public immutable stargateRouter;

    IERC20Metadata public immutable token;
    uint256 public immutable tokenPoolId;

    uint8 public constant USDT_TOKEN_ID = 2;

    uint256 public constant SG_SLIPPAGE_DIVIDER = 10000;
    uint256 public stargateSlippage = 20;

    uint16 public forwarderChainId;
    address public forwarderAddress;
    uint256 public forwarderTokenPoolId;

    uint256 public totalDepositedAmount;

    CrossDeposit public currentCrossDeposit;
    CrossWithdrawal public currentCrossWithdrawal;

    mapping(address => uint256) internal _pendingDeposits;
    mapping(address => uint256) internal _pendingWithdrawals;

    uint256 public crossDepositGas = 130000;
    uint256 public crossWithdrawalGas = 100000;
    uint256 public crossProvisionGas = 40000;

    event CreatedPendingDeposit(address indexed depositor, uint256 amount);
    event RemovedPendingDeposit(address indexed depositor);
    event Deposited(address indexed depositor, uint256 tokenAmount, uint256 lpShares);

    event SentCrossDeposit(uint256 indexed id, uint256 totalTokenAmount);
    event ReceivedCrossDepositResult(uint256 indexed id, uint256 lpShares);
    event ResetCrossDeposit(uint256 indexed id, uint256 tokenAmount);

    event CreatedPendingWithdrawal(address indexed withdrawer, uint256 lpShares);
    event RemovedPendingWithdrawal(address indexed depositor);
    event Withdrawn(
        address indexed withdrawer,
        uint256 tokenAmount,
        uint256 lpShares
    );

    event SentCrossWithdrawal(uint256 indexed id, uint256 totalLpShares);
    event ReceivedCrossWithdrawalProvision(uint256 tokenAmount);
    event ReceivedCrossWithdrawalResult(uint256 indexed id, uint256 tokenAmount);
    event ResetCrossWithdrawal(uint256 indexed id, uint256 tokenAmount);

    event SetForwarderParams(
        uint256 _chainId,
        address _address,
        uint256 _tokenPoolId
    );

    event SetStargateSlippage(
        uint256 slippage
    );

    event SetLayerZeroMessagesGas(
        uint256 crossDepositGas,
        uint256 crossWithdrawalGas,
        uint256 crossProvisionGas
);

    constructor(
        address _token,
        uint256 _tokenPoolId,
        address _stargateRouter,
        address _layerZeroEndpoint
    ) ERC20('Gateway Zunami LP', 'GZLP') LzApp(_layerZeroEndpoint) {
        _setupRole(OPERATOR_ROLE, _msgSender());

        token = IERC20Metadata(_token);
        tokenPoolId = _tokenPoolId;

        stargateRouter = IStargateRouter(_stargateRouter);
    }

    receive() external payable {}

    function setForwarderParams(
        uint16 _chainId,
        address _address,
        uint256 _tokenPoolId
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        forwarderChainId = _chainId;
        forwarderAddress = _address;
        forwarderTokenPoolId =  _tokenPoolId;

        emit SetForwarderParams(_chainId, _address, _tokenPoolId);
    }

    function setStargateSlippage(
        uint16 _slippage
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_slippage <= SG_SLIPPAGE_DIVIDER,"Gateway: wrong stargate slippage");
        stargateSlippage = _slippage;

        emit SetStargateSlippage(_slippage);
    }

    function setLayerZeroMessagesGas(
        uint256 _crossDepositGas,
        uint256 _crossWithdrawalGas,
        uint256 _crossProvisionGas
) public onlyRole(DEFAULT_ADMIN_ROLE) {
        crossDepositGas = _crossDepositGas;
        crossProvisionGas = _crossProvisionGas;
        crossWithdrawalGas = _crossWithdrawalGas;
        emit SetLayerZeroMessagesGas(_crossDepositGas, _crossWithdrawalGas, _crossProvisionGas);
    }

    function pendingDeposits(address user) external view returns (uint256) {
        return _pendingDeposits[user];
    }

    function pendingWithdrawals(address user) external view returns (uint256) {
        return _pendingWithdrawals[user];
    }

    function pause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

    function sgReceive(
        uint16 _srcChainId,              // the remote chainId sending the tokens
        bytes memory _srcAddress,        // the remote Bridge address
        uint256 _nonce,
        address _token,                  // the token contract on the local chain
        uint256 _amountLD,                // the qty of local _token contract tokens
        bytes memory _payload
    ) external {
        require(
            _msgSender() == address(stargateRouter),
            "Gateway: only stargate router can call sgReceive!"
        );

        require(_srcChainId == forwarderChainId, "Gateway: wrong source chain id");

        emit ReceivedCrossWithdrawalProvision(_amountLD);
    }

    function _lzReceive(uint16 _srcChainId, bytes calldata _srcAddress, uint64 _nonce, bytes calldata _payload) internal override {
        require(_srcChainId == forwarderChainId, "Gateway: wrong source chain id");

        (uint8 messageType, uint256 messageId, uint256 tokenAmount, uint8 tokenDecimals) =
            abi.decode(_payload, (uint8, uint256, uint256, uint8));

        if(messageType == uint8(MessageType.Deposit)) {
            currentCrossDeposit.totalLpShares = tokenAmount;
            emit ReceivedCrossDepositResult(messageId, tokenAmount);
        } else if(messageType == uint8(MessageType.Withdrawal)) {
            currentCrossWithdrawal.totalTokenAmount = convertDecimals(tokenAmount, tokenDecimals, token.decimals());
            emit ReceivedCrossWithdrawalResult(messageId, currentCrossWithdrawal.totalTokenAmount);
        }
    }

    /**
     * @dev in this func user sends funds to the contract and then waits for the completion
     * of the transaction for all users
     * @param amount - deposit amounts by user
     */
    function delegateDeposit(uint256 amount) external whenNotPaused {
        delegateDepositInternal(_msgSender(), _msgSender(), amount);
    }

    function delegateDepositFor(address beneficiary, uint256 amount) external whenNotPaused {
        delegateDepositInternal(_msgSender(), beneficiary, amount);
    }

    function delegateDepositInternal(address tokenOwner, address beneficiary, uint256 amount) internal {
        if (amount > 0) {
            token.safeTransferFrom(tokenOwner, address(this), amount);
            _pendingDeposits[beneficiary] += amount;
            totalDepositedAmount += amount;
        }

        emit CreatedPendingDeposit(beneficiary, amount);
    }

    /**
     * @dev Zunami protocol owner complete all active pending deposits of users
     * @param userList - dev send array of users from pending to complete
     */
    function sendCrossDeposit(address[] memory userList)
    external
    payable
    onlyRole(OPERATOR_ROLE)
    {
        require(userList.length > 0, 'Gateway: empty user list');
        require(currentCrossDeposit.id == 0, "Gateway: only one deposit available");
        require(currentCrossWithdrawal.id == 0, "Gateway: no withdrawal during deposit");

        uint256 depositId = block.number;

        uint256 totalTokenAmount = 0;
        uint256[] memory tokenAmounts = new uint256[](userList.length);

        for (uint256 i = 0; i < userList.length; i++) {
            address user = userList[i];
            uint256 deposit = _pendingDeposits[user];
            tokenAmounts[i] = deposit;
            require(deposit > 0, "Gateway: wrong deposit token amount");
            totalTokenAmount += deposit;
            delete _pendingDeposits[user];
        }
        currentCrossDeposit = CrossDeposit(depositId, totalTokenAmount, userList, tokenAmounts, 0);

        token.safeIncreaseAllowance(address(stargateRouter), totalTokenAmount);

        // send cloned deposits to forwarder by stargate
        // the address(this).balance is the "fee" that Stargate needs to pay for the cross chain message
        stargateRouter.swap{value:address(this).balance}(
            forwarderChainId,                       // LayerZero chainId
            tokenPoolId,                            // source pool id
            forwarderTokenPoolId,                   // dest pool id
            payable(address(this)),                 // refund address. extra gas (if any) is returned to this address
            totalTokenAmount,                       // quantity to swap
            totalTokenAmount * (SG_SLIPPAGE_DIVIDER - stargateSlippage) / SG_SLIPPAGE_DIVIDER,                                      // the min qty you would accept on the destination
            IStargateRouter.lzTxObj(crossProvisionGas, 0, "0x"),     // 150000 additional gasLimit increase, 0 airdrop, at 0x address
            abi.encodePacked(forwarderAddress),     // the address to send the tokens to on the destination
            ""                                      // bytes param, if you wish to send additional payload you can abi.encode() them here
        );

        totalDepositedAmount -= totalTokenAmount;

        bytes memory payload = abi.encode(uint8(MessageType.Deposit), depositId, totalTokenAmount, token.decimals());
        _lzSend(forwarderChainId, payload, crossDepositGas);

        emit SentCrossDeposit(depositId, totalTokenAmount);
    }

    function finalizeCrossDeposit()
    external
    onlyRole(OPERATOR_ROLE)
    {
        require(currentCrossDeposit.id != 0, "Gateway: deposit was not sent");
        require(currentCrossDeposit.totalLpShares != 0, "Gateway: callback wasn't received");

        for (uint256 i = 0; i < currentCrossDeposit.users.length; i++) {
            uint256 tokenAmount = currentCrossDeposit.tokenAmounts[i];
            uint256 lpShares = (currentCrossDeposit.totalLpShares * tokenAmount) / currentCrossDeposit.totalTokenAmount;
            _mint(currentCrossDeposit.users[i], lpShares);

            emit Deposited(currentCrossDeposit.users[i], tokenAmount, lpShares);
        }

        delete currentCrossDeposit;
    }

    function resetCrossDeposit()
    external
    onlyRole(DEFAULT_ADMIN_ROLE)
    {
        emit ResetCrossDeposit(currentCrossDeposit.id, currentCrossDeposit.totalTokenAmount);
        delete currentCrossDeposit;
    }

    /**
     * @dev user remove his active pending deposit
     */
    function removePendingDeposit() external {
        address depositor = _msgSender();
        if (_pendingDeposits[depositor] > 0) {
            token.safeTransfer(
                depositor,
                _pendingDeposits[depositor]
            );
            totalDepositedAmount -= _pendingDeposits[depositor];
        }
        delete _pendingDeposits[depositor];

        emit RemovedPendingDeposit(depositor);
    }

    function delegateWithdrawal(uint256 lpShares)
        external
        whenNotPaused
    {
        require(lpShares > 0, 'Gateway: lpAmount must be higher 0');

        IERC20Metadata(address(this)).safeTransferFrom(_msgSender(), address(this), lpShares);

        address userAddr = _msgSender();
        _pendingWithdrawals[userAddr] += lpShares;

        emit CreatedPendingWithdrawal(userAddr, lpShares);
    }

    function sendCrossWithdrawal(address[] memory userList)
        external
        payable
        onlyRole(OPERATOR_ROLE)
    {
        require(userList.length > 0, 'Gateway: empty user list');
        require(currentCrossWithdrawal.id == 0, "Gateway: only one withdrawal available");
        require(currentCrossDeposit.id == 0, "Gateway: no deposit during withdrawal");

        // clone withdrawals
        uint256 withdrawalId = block.number;

        uint256 totalLpShares = 0;
        uint256[] memory lpSharesAmounts = new uint256[](userList.length);

        // create crosschain withdrawal
        for (uint256 i = 0; i < userList.length; i++) {
            address user = userList[i];
            uint256 lpShares = _pendingWithdrawals[user];
            require(lpShares > 0, "Gateway: wrong withdrawal token amount");
            lpSharesAmounts[i] = lpShares;
            totalLpShares += lpShares;
            delete _pendingWithdrawals[user];
        }
        _burn(address(this), totalLpShares);
        currentCrossWithdrawal = CrossWithdrawal(withdrawalId, totalLpShares, userList, lpSharesAmounts, 0);

        // send withdrawal by zero layer request to forwarder with total withdrawing ZLP amount
        bytes memory payload = abi.encode(uint8(MessageType.Withdrawal), withdrawalId, totalLpShares, 18);
        _lzSend(forwarderChainId, payload, crossWithdrawalGas);

        emit SentCrossWithdrawal(withdrawalId, totalLpShares);
    }

    function finalizeCrossWithdrawal()
    external
    onlyRole(OPERATOR_ROLE)
    {
        require(currentCrossWithdrawal.id != 0, "Gateway: withdrawal was not sent");

        uint256 realWithdrawalAmount = token.balanceOf(address(this)) - totalDepositedAmount;
        require( realWithdrawalAmount >=
            currentCrossWithdrawal.totalTokenAmount * (SG_SLIPPAGE_DIVIDER - stargateSlippage) / SG_SLIPPAGE_DIVIDER,
            "Gateway: callback wasn't received"
        );

        for (uint256 i = 0; i < currentCrossWithdrawal.users.length; i++) {
            uint256 lpShares = currentCrossWithdrawal.lpSharesAmounts[i];
            address user = currentCrossWithdrawal.users[i];
            uint256 tokenAmount = (realWithdrawalAmount * lpShares) / currentCrossWithdrawal.totalLpShares;
            token.safeTransfer(user, tokenAmount);
            emit Withdrawn(user, tokenAmount, lpShares);
        }

        delete currentCrossWithdrawal;
    }

    function resetCrossWithdrawal()
    external
    onlyRole(DEFAULT_ADMIN_ROLE)
    {
        emit ResetCrossWithdrawal(currentCrossWithdrawal.id, currentCrossWithdrawal.totalLpShares);
        delete currentCrossWithdrawal;
    }

    function removePendingWithdrawal() external {
        address withdrawer = _msgSender();
        if (_pendingWithdrawals[withdrawer] > 0) {
            IERC20Metadata(address(this)).safeTransfer(
                withdrawer,
                _pendingWithdrawals[withdrawer]
            );
        }

        delete _pendingWithdrawals[withdrawer];
        emit RemovedPendingWithdrawal(withdrawer);
    }

    /**
     * @dev governance can withdraw all stuck funds in emergency case
     * @param _token - IERC20Metadata token that should be fully withdraw from ZunamiGateway
     */
    function withdrawStuckToken(IERC20Metadata _token) external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 tokenBalance = _token.balanceOf(address(this));
        if (tokenBalance > 0) {
            _token.safeTransfer(_msgSender(), tokenBalance);
        }
    }

    function withdrawStuckNative() external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 balance = address(this).balance;
        if (balance > 0) {
            payable(_msgSender()).transfer(balance);
        }
    }

    function convertDecimals(
        uint256 _value,
        uint8 _decimalsFrom,
        uint8 _decimalsTo
    ) public view returns (uint256) { // pure
        if(_decimalsFrom == _decimalsTo) return _value;
        if(_decimalsFrom > _decimalsTo) return convertDownDecimals(_value, _decimalsFrom, _decimalsTo);
        return convertUpDecimals(_value, _decimalsFrom, _decimalsTo);
    }

    function convertUpDecimals(
        uint256 _value,
        uint8 _decimalsFrom,
        uint8 _decimalsTo
    ) public pure returns (uint256) {
        require(_decimalsFrom <= _decimalsTo, "BADDECIM");
        return _value * (10**(_decimalsTo - _decimalsFrom));
    }

    function convertDownDecimals(
        uint256 _value,
        uint8 _decimalsFrom,
        uint8 _decimalsTo
    ) public pure returns (uint256) {
        require(_decimalsFrom >= _decimalsTo, "BADDECIM");
        return _value / (10**(_decimalsFrom - _decimalsTo));
    }
}