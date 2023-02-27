// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

contract BSCPaymentSplitter is
    Initializable,
    UUPSUpgradeable,
    OwnableUpgradeable
{
    using AddressUpgradeable for address;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    // Reentrancy Guard
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status;

    // Deprecated. It exists only for upgradability.
    mapping(string => address) private symAddrMap;
    // Remaining balance of escrow for each asset
    /// @custom:oz-renamed-from _escrowBalances
    mapping(address => uint256) public escrowBalances;
    // Remaining balance of gas fee that is used to send escrow
    /// @custom:oz-renamed-from _gasFee
    uint256 public gasFee;
    // Remaining balance of pip fee
    /// @custom:oz-renamed-from _pipFees
    mapping(address => uint256) public pipFees;
    // Deprecated. It exists only for upgradability.
    uint256 private _intMax;
    // Deprecated. It exists only for upgradability. 
    address private _owner;
    // Address of Admin #1 to which gasfee will be withdrawn.
    /// @custom:oz-renamed-from _gasFeeAddress
    address public gasFeeAddress;
    // Address of Admin #2 to which pipfee will be withdrawn.
    /// @custom:oz-renamed-from _pipFeeAddress
    address public pipFeeAddress;
    // Deprecated. It exists only for upgradability.
    address private _pipAdminAddress;
    // Key for BNB used in pipFees and escrowBalances
    // @custom:oz-renamed-from wbnb
    address private forBnb;
    // Whitelist for PIP Service. The Token in whitelist is Non Tax Token.
    /// @custom:oz-renamed-from grantee
    mapping(address => bool) public tokenWhitelist;
    // The fee rate about tip amount
    uint256 public pipFeeRatio;
    // The gas fee amount when sender send tip for escrow 
    uint256 public gasFeeAmount;
    // Tokens with decimals other than 18
    mapping(address => uint8) public tokenDecimals;

    event FeeAddressChanged(
        string feeType,
        address indexed prevAddr,
        address indexed newAddr
    );
    event ReceiveAsset(
        string receiveType,
        address indexed toContract,
        address indexed recipient,
        uint256 sendAmount,
        uint256 feeAmount,
        uint256 gasAmount
    );
    event SendAsset(
        string sendType,
        address toContract,
        address indexed from,
        address indexed to,
        uint256 amount
    );
    event SendDirect(
        string sendMsg,
        address indexed toContract,
        address indexed from,
        address indexed to,
        uint256 tipAmount,
        uint256 feeAmount
    );
    event PipService(
        address indexed toContract,
        address indexed from,
        address indexed to,
        uint256 amount,
        string payload
    );

    event Transfer(
        string transferType,  // ESCROW, INSTANT
        address indexed sender,
        address indexed receiver,
        address token,
        uint256 amount,
        uint256 serviceFee,
        uint256 escrowGas,
        string payload
    );

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() public initializer {
        __Ownable_init();
        __UUPSUpgradeable_init();
        pipFeeAddress = address(0);
        gasFeeAddress = address(0);
        _status = _NOT_ENTERED;
        _intMax = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
        // Unique address used as a key to point to the BNB balance
        forBnb = 0x5ACbf3E2715D95D56d472eBE660106791C8E0C9e;
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}

    modifier onlyAdmin() {
        require(
            msg.sender == owner() 
                || (msg.sender == gasFeeAddress && gasFeeAddress != address(0)) 
                || (msg.sender == pipFeeAddress && pipFeeAddress != address(0)),
             "Only Allowed to Admin"
        );
        _;
    }

    modifier nonReentrant() {
        require(_status != _ENTERED, "ReEntrancyGuard : ReEntrant Call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }

    // Check The Token is Whitelisted token
    // @token : The token address for handling in this contract
    modifier onlyWhitelisted(address token) {
        require(tokenWhitelist[token], "Only Allowed to Token in Whitelist");
        _;
    }

    // Calculate fee amount with entered tipAmount and feeRatio
    // @tipAmount : The tip amount
    // @feeRatio : The fee ratio
    function _calculateFeeAmount(uint256 tipAmount, uint256 feeRatio, uint8 decimals) public pure returns (uint256) {
        require(decimals <= 76, "_calculateFeeAmount(): Decimal can not be bigger than 76");

        uint256 feeAmount = (tipAmount * feeRatio) / (100 - feeRatio);
        if (decimals > 8) {
            uint8 roundDownDecimals = decimals - 8;
            return (feeAmount / 10 ** roundDownDecimals) * (10 ** roundDownDecimals);
        }
        else 
          return feeAmount;
    }

    // Transfer token and assert if the receiver's balance has increased by the amount transfered.
    // @token : The contract address of token to transfer
    // @from : The address of Sender
    // @to : The address of Receiver
    // @amount : The amount of token transfer
    function safeTransferFromAndCheckBalance(address token, address from, address to, uint256 amount) internal {
        IERC20Upgradeable tokenObject = IERC20Upgradeable(token);
        uint256 initialBalance = tokenObject.balanceOf(to);
        tokenObject.safeTransferFrom(from, to, amount);
        uint256 afterBalance = tokenObject.balanceOf(to);
        require(from == to ? (afterBalance - initialBalance == 0) : (afterBalance - initialBalance == amount), "safeTransferFromAndCheckBalance(): transferred amount is incorrect");
    }

    // Replace the address of gasfee
    // @feeAddress: Address of Admin #1 to which gasfee will be withdrawn.
    function setGasFeeAddress(address feeAddress) external onlyAdmin {
        require(feeAddress != gasFeeAddress, "SetGasFeeAddress : The new address is the same as the old one");

        emit FeeAddressChanged("gasFee", gasFeeAddress, feeAddress);
        gasFeeAddress = feeAddress;
    }

    // Return the address of gasfee
    function getGasFeeAddress() external view returns (address) {
        return gasFeeAddress;
    }

    // Replace the address of pipfee
    // @feeAddress: Address of Admin #2 to which pipfee will be withdrawn.
    function setPipFeeAddress(address feeAddress) external onlyAdmin {
        require(feeAddress != pipFeeAddress, "SetPipFeeAddress : The new address is the same as the old one");

        emit FeeAddressChanged("pipFee", pipFeeAddress, feeAddress);
        pipFeeAddress = feeAddress;
    }

    // Return the address of gasfee
    function getPipFeeAddress() external view returns (address) {
        return pipFeeAddress;
    }

    // Replace the value of pip fee ratio
    // @ratio : Ratio of pip fee for tip
    function setPipFeeRatio(uint256 ratio) external onlyAdmin {
        require(ratio > 0, "SetPipFeeRatio : The Ratio Value is only for positive value");
        require(ratio < 100, "SetPipFeeRatio: The Ratio can not be equal to nor bigger than 100");
        require(ratio != pipFeeRatio, "SetPipFeeRatio : The new ratio value is same with old ratio value");
        pipFeeRatio = ratio;
    }

    // Return the value of pip fee ratio
    function getPipFeeRatio() external view returns (uint256) {
        return pipFeeRatio;
    }

    // Replace the amount of gas fee
    // @feeAmount : The amount of gas fee
    function setGasFeeAmount(uint256 feeAmount) external onlyAdmin {
        require(feeAmount > 0, "SetGasFeeAmount : The gas fee amount is only for positive amount");
        require(feeAmount < 100000000000000000000, "SetGasFeeAmount : The gas fee amount cat not be bigger than 100 BNB");
        require(feeAmount != gasFeeAmount, "SetGasFeeAmount : The new gas fee amount is same with old gas fee amount");
        gasFeeAmount = feeAmount;
    }

    // Return the amount of gas fee
    function getGasFeeAmount() external view returns (uint256) {
        return gasFeeAmount;
    }

    // Add the token to whitelist, or Remove from the whitelist
    // @token : The contract address to add/remove for whitelist
    // @value : true - add to whitelist, false - remove from whitelist
    function setTokenWhitelist(address token, bool value) external onlyAdmin {
        require(tokenWhitelist[token] != value, "SetTokenWhitelist : The new value is already same with the old value");
        tokenWhitelist[token] = value;
    }

    // Return whether the token is whitelisted token
    function getTokenWhitelist(address token) external view returns (bool) {
        require(token.isContract(), "GetTokenWhitelist : Address is not Contract Address" );
        return tokenWhitelist[token];
    }

    // Return the balance of gasfee
    function chkGasFee() external view returns (uint256) {
        return gasFee;
    }

    // Return the balance of pipfee of the specified asset
    // @target: The contract address of the asset
    function chkPipFee(address token) external view onlyWhitelisted(token) returns (uint256) {
        return pipFees[token];
    }

    // Return the balance of escrow of the specified asset
    // @target: The contract address of the asset
    function chkEscrowBalance(address token) external view onlyWhitelisted(token) returns (uint256) {
        return escrowBalances[token];
    }

    // Set the decimals of a token
    // @address: The contract address of the asset
    // @decimals: Decimals of a token
    function setTokenDecimals(address token, uint8 decimals) external onlyAdmin {
        tokenDecimals[token] = decimals;
    }

    // Get the decimals of a token
    // @address: The contract address of the asset
    function getTokenDecimals(address token) public view returns (uint8) {
        require(token.isContract(), "_getTokenDecimal(): Token must be a Contract");

        if (tokenDecimals[token] > 0) return tokenDecimals[token];
        else return 18;
    }    

    // Withdraw 'amount' of gasfee to the specified address
    // @to: The address to receive the withdrawn gasfee. it should be Admin
    // @amount: The amount to be withdrawn
    function withdrawGasFee(uint256 amount) external nonReentrant onlyAdmin {
        require(gasFeeAddress != address(0), "Withdraw Gas : Gas Fee Address Cannot be Zero-Address");
        require(amount <= gasFee, "Withdraw Gas: Amount must be less than Gas Balance");
        gasFee -= amount;

        payable(gasFeeAddress).transfer(amount);
        emit SendAsset("wGasFee", forBnb, address(this), gasFeeAddress, amount);
    }

    // Withdraw 'amount' of pipfee to the specified address
    // @symbol: The contract address of the asset to be withdrawn
    // @to: The address to receive the withdrawn pipfee. it should be Admin
    // @amount: The amount to be withdrawn
    function withdrawPipFee(address token, uint256 amount) external nonReentrant onlyAdmin onlyWhitelisted(token) {
        require(pipFeeAddress != address(0), "Withdraw Pip Fee : Pip Fee Address Cannot be Zero-Address");
        require(amount <= pipFees[token], "Withdraw Pip Fee: Required Pip Fee Amount must be less than Pip Fee Balance");

        pipFees[token] -= amount;
        if (token == forBnb) {
            payable(pipFeeAddress).transfer(amount);
        } else {
            IERC20Upgradeable tokenObject = IERC20Upgradeable(token);
            tokenObject.safeTransfer(pipFeeAddress, amount);
        }
        emit SendAsset("wPipFee", token, address(this), pipFeeAddress, amount);
    }

    // Send 'amount' of escrow to the specified address
    // @symbol: The contract address of the asset to be sent
    // @to: The address to receive the withdrawn balance
    // @amount: The amount to be sent
    function sendEscrow(address token, address payable to, uint256 amount) external nonReentrant onlyAdmin onlyWhitelisted(token) {
        require(to != address(0), "Send Escrow : Recipient Address cannot be zero-address");
        require((amount <= escrowBalances[token]) && (amount > 0), "Send Escrow : Required User Balance must be less than User Balance");

        escrowBalances[token] -= amount;
        if (token == forBnb) {
            // withdraw BNB (Native)
            to.transfer(amount);
            emit SendAsset("sEscrowNative", token, address(this), to, amount);
        } else {
            // withdraw Token
            IERC20Upgradeable tokenObject = IERC20Upgradeable(token);
            tokenObject.safeTransfer(to, amount);
            emit SendAsset("sEscrowToken", token, address(this), to, amount);
        }
    }

    // Deposit BNB
    // @isEscrow: If true the deposited balance is owned by the contract.
    //            If false the contract sends the balance to the recipient immediately
    // @recipient: If isEscrow is true, the address to receive the deposited asset
    //             If not, not used
    // @tipAmount: The asset amount to be sent to the receiver
    // @feeAmount: The asset amount to be sent to the service provider(= Admin)
    // @gasAmount: The network fee to be used when sending the escrow to the receiver
    function receiveNative(uint256 isEscrow, address payable recipient, uint256 amount, uint256 serviceFee, uint256 escrowGas) external payable nonReentrant {
        // require(msg.value == tipAmount + feeAmount + gasAmount, "Send Native: Tip, Fee, Gas Summation Not Equal to Sended msg.value");
        // require(recipient != address(0), "Send Native: Recipient Cannot be Zero Address");
        // require(tipAmount > 0, "Send Native: Send Amount Cannot be Negative");
        // require(feeAmount > 0, "Send Native: Fee Amount Cannot be Negative");

        // if (isEscrow == 1) {
        //     // gas > 0
        //     require(gasFeeAmount == gasAmount, "Send Native : Gas Amount is different");

        //     gasFee += gasAmount;
        //     pipFees[forBnb] += feeAmount;
        //     escrowBalances[forBnb] += tipAmount;
        //     emit ReceiveAsset("rEscrowNative", forBnb, recipient, tipAmount, feeAmount, gasAmount);
        // } else {
        //     require(gasAmount == 0, "Send Native: Gas amount should be 0 for non-escrow");

        //     recipient.transfer(tipAmount);
        //     pipFees[forBnb] += feeAmount;
        //     emit SendDirect("sDirectNative", forBnb, msg.sender, recipient, tipAmount, feeAmount);
        // }
        return _transferNative(isEscrow == 1, recipient, amount, serviceFee, escrowGas, "");
    }

    // Deposit token
    // @isEscrow: If true the deposited balance is owned by the contract.
    //            If false the contract sends the balance to the recipient immediately
    // @token: The contract address of the asset
    // @recipient: If isEscrow is true, the address to receive the deposited asset
    //             If not, not used
    // @tipAmount: The asset amount to be sent to the receiver
    // @feeAmount: The asset amount to be sent to the service provider(= Admin)
    // @gasAmount: The network fee to be used when sending the escrow to the receiver.
    function receiveToken(uint256 isEscrow, address token, address recipient, uint256 amount, uint256 serviceFee, uint256 escrowGas) external payable onlyWhitelisted(token) nonReentrant {
        // require(msg.value == gasAmount, "Send Token: Gas Not Equal to msg.value");
        // require(token.isContract(), "Send Token: Address is not Contract Address" );
        // require(recipient != address(0), "Send Token: Recipient Cannot be Zero Address");
        // require(tipAmount > 0, "Send Token: Send Amount Cannot be Negative");
        // require(feeAmount > 0, "Send Token: Fee Amount Cannot be Negative");

        // uint8 decimals = getTokenDecimals(token);

        // if (isEscrow == 1) {
        //     // Escrow
        //     // gas > 0
        //     require(gasFeeAmount == gasAmount, "Send Token : Gas Amount is different");
        //     safeTransferFromAndCheckBalance(token, msg.sender, address(this), tipAmount + feeAmount);
        //     gasFee += gasAmount;
        //     pipFees[token] += feeAmount;
        //     escrowBalances[token] += tipAmount;
        //     emit ReceiveAsset("rEscrowToken", token, recipient, tipAmount, feeAmount, gasAmount);
        // } else {
        //     // Direct
        //     // gas == 0
        //     require(gasAmount == 0, "Send Token: Gas amount should be 0 for non-escrow");
        //     safeTransferFromAndCheckBalance(token, msg.sender, recipient, tipAmount);
        //     safeTransferFromAndCheckBalance(token, msg.sender, address(this), feeAmount);
        //     pipFees[token] += feeAmount;
        //     emit SendDirect("sDirectToken", token, msg.sender, recipient, tipAmount, feeAmount);
        // }
        return _transferToken(isEscrow == 1, recipient, token, amount, serviceFee, escrowGas, "");
    }

    // Send BNB through PIP Service
    // @recipient: The Wallet address to receive funds through transaction execution
    // @amount: The asset amount to be sent to the recipient
    // @payload: The Data transmitted to be used by the server that detects the contract and receives the data, not used in the contract (Exchange rate at the time, remittance history ID, remittance service ID ... )
    function receiveNativeByPipService(address payable recipient, uint256 amount, string memory payload) external payable nonReentrant {
        // require(msg.value == amount, "rNativeByPipService: Amount Not Equal to Sended msg.value");
        // require(recipient != address(0), "rNativeByPipService: Recipient Cannot be Zero Address");
        // require(amount > 0, "rNativeByPipService: Amount Cannot be Negative");
        // recipient.transfer(amount);
        // emit PipService(forBnb, msg.sender, recipient, amount, payload);
        return _transferNative(false, recipient, amount, 0, 0, payload);
    }

    // Send BEP20 Token through PIP Service
    // @token: The contract address of the asset
    // @recipient: The Wallet address to receive funds through transaction execution
    // @amount: The asset amount to be sent to the recipient
    // @payload: The Data transmitted to be used by the server that detects the contract and receives the data, not used in the contract (Exchange rate at the time, remittance history ID, remittance service ID ... )
    function receiveTokenByPipService(address token, address recipient, uint256 amount, string memory payload) external onlyWhitelisted(token) nonReentrant {
        // require(token.isContract(), "rTokenByPipService: Address is not Contract Address");
        // require(recipient != address(0), "rTokenByPipService: Recipient Cannot be Zero Address");
        // require(amount > 0, "rTokenByPipService: Send Amount Cannot be Negative");
        // safeTransferFromAndCheckBalance(token, msg.sender, recipient, amount);
        // emit PipService(token, msg.sender, recipient, amount, payload);
        return _transferToken(false, recipient, token, amount, 0, 0, payload);
    }


    function _transferNative(bool isEscrow, address payable recipient, uint256 amount, uint256 serviceFee, uint256 escrowGas, string memory payload) internal {
        require(recipient != address(0), "_transferNative(): recipient with zero address is not allowed");
        require(amount > 0, "_transferNative(): amount should be greater than 0");
        require(serviceFee >= 0, "_transferNative(): serviceFee should be greater than or equal to 0");
        require(msg.value == amount + serviceFee + escrowGas, "_transferNative(): the sum of amount, serviceFee, and escrowGas is not equal to msg.value");

        if (isEscrow) {
            require(gasFeeAmount == escrowGas, "_transferNative(): escrowGas is not correct");

            gasFee += escrowGas;
            pipFees[forBnb] += serviceFee;
            escrowBalances[forBnb] += amount;

            emit Transfer("ESCROW", msg.sender, recipient, forBnb, amount, serviceFee, escrowGas, payload);
        } else {
            require(escrowGas == 0, "_transferNative(): escrowGas should be 0");

            recipient.transfer(amount);
            pipFees[forBnb] += serviceFee;

            emit Transfer("INSTANT", msg.sender, recipient, forBnb, amount, serviceFee, 0, payload);
        }
    }


    function _transferToken(bool isEscrow, address recipient, address token, uint256 amount, uint256 serviceFee, uint256 escrowGas, string memory payload) internal {
        require(recipient != address(0), "_transferToken(): recipient with zero address is not allowed");
        require(token.isContract(), "_transferToken(): token should be address type");
        require(amount > 0, "_transferToken(): amount should be greater than 0");
        require(serviceFee >= 0, "_transferToken(): serviceFee should be greater than or equal to 0");
        require(msg.value == escrowGas, "_transferToken(): escrowGas is not equal to msg.value");

        if (isEscrow) {
            require(gasFeeAmount == escrowGas, "_transferToken(): escrowGas is not correct");

            safeTransferFromAndCheckBalance(token, msg.sender, address(this), amount + serviceFee);
            gasFee += escrowGas;
            pipFees[token] += serviceFee;
            escrowBalances[token] += amount;

            emit Transfer("ESCROW", msg.sender, recipient, token, amount, serviceFee, escrowGas, payload);
        } else {
            require(escrowGas == 0, "_transferToken(): escrowGas should be 0");

            safeTransferFromAndCheckBalance(token, msg.sender, recipient, amount);
            safeTransferFromAndCheckBalance(token, msg.sender, address(this), serviceFee);
            pipFees[token] += serviceFee;

            emit Transfer("INSTANT", msg.sender, recipient, token, amount, serviceFee, 0, payload);
        }
    }

    // transfer native coin or tokens
    // @isEscrow: It sends to this contract if true.
    //            It sends to the recipient if false.
    // @recipient: If isEscrow is true, the address to receive the deposited asset
    //             If not, not used
    // @token: The address of token contract. It sends native coin if the token is forBnb, if not, it sends a token.
    // @amount: The amount of the asset to be sent to the receiver
    // @serviceFee: The asset amount to be sent to the service provider(= Admin)
    // @escrowGas: The network fee to be used when sending the escrow to the receiver
    // @payload: The payload data that pip service embeds so that pip server can recognize its context
    function transfer(bool isEscrow, address payable recipient, address token, uint256 amount, uint256 serviceFee, uint256 escrowGas, string memory payload) external payable onlyWhitelisted(token) nonReentrant {
        if (token == forBnb) {
          return _transferNative(isEscrow, recipient, amount, serviceFee, escrowGas, payload);
        } else {
          return _transferToken(isEscrow, recipient, token, amount, serviceFee, escrowGas, payload);
        }
    }
}