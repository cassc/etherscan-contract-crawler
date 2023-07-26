// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./libraries/TransferHelper.sol";

/**
 * @title XplusBridge
 *
 * @dev An upgradeable contract for moving ERC20 and Native tokens across blockchains. An
 * off-chain relayer is responsible for signing proofs of deposits to be used on destination
 * chains of the transactions. A multi-relayer set up can be used for enhanced security and
 * decentralization.
 *
 * @dev The relayer should wait for finality on the source chain before generating a deposit
 * proof. Otherwise a double-spending attack is possible.
 *
 *
 * @dev Note that transaction hashes shall NOT be used for re-entrance prevention as doing
 * so will result in false negatives when multiple transfers are made in a single
 * transaction (with the use of contracts).
 *
 * @dev Chain IDs in this contract currently refer to the ones introduced in EIP-155. However,
 * a list of custom IDs might be used instead when non-EVM compatible chains are added.
 */
contract XplusBridge is OwnableUpgradeable {
    using ECDSAUpgradeable for bytes32;

    /**
     * @dev Emits when a deposit is made.
     *
     * @dev Addresses are represented with bytes32 to maximize compatibility with
     * non-Ethereum-compatible blockchains.
     *
     * @param srcChainId Chain ID of the source blockchain (current chain)
     * @param destChainId Chain ID of the destination blockchain
     * @param depositId Unique ID of the deposit on the current chain
     * @param depositor Address of the account on the current chain that made the deposit
     * @param recipient Address of the account on the destination chain that will receive the amount
     * @param currency A bytes32-encoded universal currency key
     * @param amount Amount of tokens being deposited to recipient's address.
     */
    event TokenDeposited(
        uint256 srcChainId,
        uint256 destChainId,
        uint256 depositId,
        bytes32 depositor,
        bytes32 recipient,
        bytes32 currency,
        uint256 amount
    );
    event TokenWithdrawn(
        uint256 srcChainId,
        uint256 destChainId,
        uint256 depositId,
        bytes32 depositor,
        bytes32 recipient,
        bytes32 currency,
        uint256 amount
    );
    event RelayerChanged(address oldRelayer, address newRelayer);
    event OperatorChanged(address oldOperator, address newOperator);
    event MinDepositUpdated(bytes32 tokenKey, uint256 oldMin, uint256 newMin);
    event DailyMaxWithdrawUpdated(bytes32 tokenKey, uint256 oldDailyMax, uint256 newDailyMax);
    event ExemptedAddressUpdated(address _address, bool _allowed);
    event TokenAdded(bytes32 tokenKey, address tokenAddress, uint256 minDeposit, uint256 dailyMaxWithdraw);
    event TokenRemoved(bytes32 tokenKey, address tokenAddress);
    event ChainSupportForTokenUpdated(bytes32 tokenKey, uint256 chainId, bool allowed);

    struct TokenInfo {
        address tokenAddress;
        uint256 minDeposit;
        uint256 dailyMaxWithdraw;
    }

    struct WithdrawData {
        uint256 dailyWithdrawCount;
        uint256 lastWithdrawDay;
    }

    modifier onlyOperator() {
        require(
            msg.sender == operator || msg.sender == owner(),
            "XplusBridge: operator only"
        );
        _;
    }

    uint256 public currentChainId;
    address public relayer;
    address public operator;

    mapping(address => bool) public exemptedAddress;

    uint256 public depositCount;
    // tokenKey => TokenInfo
    mapping(bytes32 => TokenInfo) public tokenInfos;
    // tokenKey => WithdrawData
    mapping(bytes32 => WithdrawData) public withdrawDatas;
    // tokenKey => chainId => allowed
    mapping(bytes32 => mapping(uint256 => bool)) public tokenSupportedOnChain;
    // scrChainId => depositId => withdrawn
    mapping(uint256 => mapping(uint256 => bool)) public withdrawnDeposits;
    // tokenAddress => whitelisted, for checking to prevent different tokenKey but same address from being added
    mapping(address => bool) public whitelistedTokens;

    bytes32 public DOMAIN_SEPARATOR; // For EIP-712
    bytes32 public constant DEPOSIT_TYPEHASH =
        keccak256(
            "Deposit(uint256 srcChainId,uint256 destChainId,uint256 depositId,bytes32 depositor,bytes32 recipient,bytes32 currency,uint256 amount)"
        );

    function getTokenAddress(bytes32 tokenKey) public view returns (address) {
        return tokenInfos[tokenKey].tokenAddress;
    }

    function isTokenSupportedOnChain(bytes32 tokenKey, uint256 chainId) public view returns (bool) {
        return tokenSupportedOnChain[tokenKey][chainId];
    }

    function __XplusBridge_init(
        address _relayer,
        address _operator
    ) public initializer {
        __Ownable_init();
        _setRelayer(_relayer);
        _setOperator(_operator);

        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        currentChainId = chainId;
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes("Xplus")),
                keccak256(bytes("1")),
                chainId,
                address(this)
            )
        );
    }

    receive() external payable {}

    function setRelayer(address _relayer) external onlyOwner {
        _setRelayer(_relayer);
    }

    function setOperator(address _operator) external onlyOwner {
        _setOperator(_operator);
    }

    function setMinDeposit(bytes32 _tokenKey, uint256 _min) external onlyOperator {
        _setMinDeposit(_tokenKey, _min);
    }

    function setDailyMaxWithdraw(bytes32 _tokenKey, uint256 _dailyMax) external onlyOperator {
        _setDailyMaxWithdraw(_tokenKey, _dailyMax);
    }

    function setExemptedAddress(address _user, bool _allowed) external onlyOperator {
        require(_user != address(0), "XplusBridge: zero address");
        exemptedAddress[_user] = _allowed;
        emit ExemptedAddressUpdated(_user, _allowed);
    }

    function addToken(
        bytes32 tokenKey,
        address tokenAddress,
        uint256 _minDeposit,
        uint256 _dailyMaxWithdraw
    ) external onlyOperator {
        require(!whitelistedTokens[tokenAddress], "XplusBridge: token already exist");
        require(tokenKey != bytes32(0), "XplusBridge: invalid tokenKey");
        require(_minDeposit > 0, "XplusBridge: invalid minDeposit");
        require(_dailyMaxWithdraw > 0, "XplusBridge: invalid dailyMaxWithdraw");

        tokenInfos[tokenKey] = TokenInfo({
            tokenAddress: tokenAddress,
            minDeposit: _minDeposit,
            dailyMaxWithdraw: _dailyMaxWithdraw
        });
        whitelistedTokens[tokenAddress] = true;

        emit TokenAdded(tokenKey, tokenAddress, _minDeposit, _dailyMaxWithdraw);
    }

    function removeToken(bytes32 tokenKey) external onlyOperator {
        TokenInfo memory tokenInfo = tokenInfos[tokenKey];
        address tokenAddress = tokenInfo.tokenAddress;
        require(tokenInfo.minDeposit != 0, "XplusBridge: token not exist");
        
        whitelistedTokens[tokenAddress] = false;
        tokenInfos[tokenKey] = TokenInfo({
            tokenAddress: address(0),
            minDeposit: 0,
            dailyMaxWithdraw: 0
        });
        withdrawDatas[tokenKey] = WithdrawData({
            dailyWithdrawCount: 0,
            lastWithdrawDay: 0
        });

        emit TokenRemoved(tokenKey, tokenAddress);
    }

    function updateChainSupportForToken(bytes32 tokenKey, uint256 chainId, bool allowed) external onlyOperator {
        tokenSupportedOnChain[tokenKey][chainId] = allowed;
        emit ChainSupportForTokenUpdated(tokenKey, chainId, allowed);
    }

    function deposit(
        bytes32 token,
        uint256 amount,
        uint256 destChainId,
        bytes32 recipient
    ) external payable {
        TokenInfo memory tokenInfo = tokenInfos[token];
        require(tokenInfo.minDeposit > 0, "XplusBridge: token not found");

        require(amount >= tokenInfo.minDeposit, "XplusBridge: deposit less than minimum amount");
        require(destChainId != currentChainId, "XplusBridge: dest must be different from src");
        require(isTokenSupportedOnChain(token, destChainId), "XplusBridge: token not supported on chain");
        require(recipient != 0, "XplusBridge: zero address");

        depositCount = depositCount + 1;

        address tokenAddress = tokenInfo.tokenAddress;
        if (tokenAddress == address(0)) {
            require(msg.value >= amount, "XplusBridge: insufficient deposit");
        } else {
            TransferHelper.safeTransferFrom(tokenInfo.tokenAddress, msg.sender, address(this), amount);
        }

        emit TokenDeposited(
            currentChainId,
            destChainId,
            depositCount,
            bytes32(uint256(uint160(msg.sender))),
            recipient,
            token,
            amount
        );
    }

    function withdraw(
        uint256 srcChainId,
        uint256 destChainId,
        uint256 depositId,
        bytes32 depositor,
        bytes32 recipient,
        bytes32 currency,
        uint256 amount,
        bytes calldata signature
    ) external {
        require(destChainId == currentChainId, "XplusBridge: wrong chain");
        require(!withdrawnDeposits[srcChainId][depositId], "XplusBridge: already withdrawn");
        require(recipient != 0, "XplusBridge: zero address");

        TokenInfo memory tokenInfo = tokenInfos[currency];
        WithdrawData storage withdrawData = withdrawDatas[currency];
        require(whitelistedTokens[tokenInfo.tokenAddress], "XplusBridge: token not exist");
        _updateLastWithdrawDay(currency);

        address decodedRecipient = address(uint160(uint256(recipient)));
        if (!exemptedAddress[decodedRecipient]) {
            require(
                withdrawData.dailyWithdrawCount + amount <= tokenInfo.dailyMaxWithdraw, 
                "XplusBridge: exceed max daily withdraw"
            );
        }

        // Verify EIP-712 signature
        bytes32 digest =
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    DOMAIN_SEPARATOR,
                    keccak256(
                        abi.encode(
                            DEPOSIT_TYPEHASH,
                            srcChainId,
                            destChainId,
                            depositId,
                            depositor,
                            recipient,
                            currency,
                            amount
                        )
                    )
                )
            );
        address recoveredAddress = digest.recover(signature);
        require(recoveredAddress == relayer, "XplusBridge: invalid signature");

        _withdraw(
            srcChainId,
            destChainId,
            depositId,
            depositor,
            recipient,
            currency,
            amount
        );
    }

    function _withdraw(
        uint256 srcChainId,
        uint256 destChainId,
        uint256 depositId,
        bytes32 depositor,
        bytes32 recipient,
        bytes32 currency,
        uint256 amount
    ) private {
        withdrawnDeposits[srcChainId][depositId] = true;
        address tokenAddress = tokenInfos[currency].tokenAddress;
        address recipientAddress = address(uint160(uint256(recipient)));

        if (tokenAddress == address(0)) {
            (bool sent,) = payable(recipientAddress).call{value: amount}("");
            require(sent, "XplusBridge: send failed");
        } else {
            TransferHelper.safeTransfer(tokenAddress, recipientAddress, amount);
        }
        withdrawDatas[currency].dailyWithdrawCount += amount;

        emit TokenWithdrawn(srcChainId, destChainId, depositId, depositor, recipient, currency, amount);
    }

    function _updateLastWithdrawDay(bytes32 tokenKey) private {
        WithdrawData storage withdrawData = withdrawDatas[tokenKey];
        uint256 day = block.timestamp / 1 days;
        if (day != withdrawData.lastWithdrawDay) {
            withdrawData.lastWithdrawDay = day;
            withdrawData.dailyWithdrawCount = 0;
        }
    }

    function _setRelayer(address _relayer) private {
        require(_relayer != address(0), "XplusBridge: zero address");
        require(_relayer != relayer, "XplusBridge: relayer not changed");

        address oldRelayer = relayer;
        relayer = _relayer;

        emit RelayerChanged(oldRelayer, relayer);
    }

    function _setOperator(address _operator) private {
        require(_operator != address(0), "XplusBridge: zero address");
        require(_operator != operator, "XplusBridge: relayer not changed");

        address oldOperator = operator;
        operator = _operator;

        emit OperatorChanged(oldOperator, _operator);
    }

    function _setMinDeposit(bytes32 _tokenKey, uint256 _min) private {
        require(_min > 0, "XplusBridge: zero min deposit");
        uint256 old = tokenInfos[_tokenKey].minDeposit;
        tokenInfos[_tokenKey].minDeposit = _min;

        emit MinDepositUpdated(_tokenKey, old, _min);
    }

    function _setDailyMaxWithdraw(bytes32 _tokenKey, uint256 _dailyMax) private {
        require(_dailyMax > 0, "XplusBridge: zero daily max withdraw");
        uint256 old = tokenInfos[_tokenKey].dailyMaxWithdraw;
        tokenInfos[_tokenKey].dailyMaxWithdraw = _dailyMax;

        emit DailyMaxWithdrawUpdated(_tokenKey, old, _dailyMax);
    }
}