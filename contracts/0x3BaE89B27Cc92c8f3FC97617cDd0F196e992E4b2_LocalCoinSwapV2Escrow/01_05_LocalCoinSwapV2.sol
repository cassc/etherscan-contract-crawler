pragma solidity ^0.5.17;

import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


contract Token is IERC20 {
    function transferWithAuthorization(
        address from,
        address to,
        uint256 value,
        uint256 validAfter,
        uint256 validBefore,
        bytes32 nonce,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}


contract LocalCoinSwapV2Escrow {

    using SafeERC20 for Token;

    /***********************
    +       Globals        +
    ***********************/

    address public arbitrator;
    address public owner;
    address public relayer;

    uint16 public minimumTradeValue = 1; // Token

    struct Escrow {
      bool exists;
      uint128 totalGasFeesSpentByRelayer;
      address tokenContract;
    }

    mapping (bytes32 => Escrow) public escrows;
    mapping (address => uint256) public feesAvailableForWithdraw;

    uint256 MAX_INT = 2**256 - 1;

    /***********************
    +     Instructions     +
    ***********************/

    uint8 constant RELEASE_ESCROW = 0x01;
    uint8 constant BUYER_CANCELS = 0x02;
    uint8 constant RESOLVE_DISPUTE = 0x03;

    /***********************
    +       Events        +
    ***********************/

    event Created(bytes32 _tradeHash);
    event CancelledByBuyer(bytes32 _tradeHash, uint128 totalGasFeesSpentByRelayer);
    event Released(bytes32 _tradeHash, uint128 totalGasFeesSpentByRelayer);
    event DisputeResolved(bytes32 _tradeHash, uint128 totalGasFeesSpentByRelayer);

    /***********************
    +     Constructor      +
    ***********************/

    constructor(address initialAddress) public {
        owner = initialAddress;
        arbitrator = initialAddress;
        relayer = initialAddress;
    }

    /***********************
    +     Open Escrow     +
    ***********************/

    function createEscrow(
      bytes16 _tradeID,
      address _currency,
      address _seller,
      address _buyer,
      uint256 _value,
      uint16 _fee, // Our fee in 1/10000ths of a token
      uint8 _v, // Signature value
      bytes32 _r, // Signature value
      bytes32 _s // Signature value
    ) external payable {
        bytes32 _tradeHash = keccak256(abi.encodePacked(_tradeID, _seller, _buyer, _value, _fee));
        require(!escrows[_tradeHash].exists, "Trade already exists");
        bytes32 _invitationHash = keccak256(abi.encodePacked(_tradeHash));
        require(_value > minimumTradeValue, "Escrow value must be greater than minimum value"); // Check escrow value is greater than minimum value
        require(recoverAddress(_invitationHash, _v, _r, _s) == relayer, "Transaction signature did not come from relayer");

        Token(_currency).safeTransferFrom(msg.sender, address(this), _value);

        escrows[_tradeHash] = Escrow(true, 0, _currency);
        emit Created(_tradeHash);
    }

    function relayEscrow(
      bytes16 _tradeID,
      address _currency,
      address _seller,
      address _buyer,
      uint256 _value,
      uint16 _fee, // Our fee in 1/10000ths of a token
      uint8 _v, // Signature value for trade invitation by LocalCoinSwap
      bytes32 _r, // Signature value for trade invitation by LocalCoinSwap
      bytes32 _s, // Signature value for trade invitation by LocalCoinSwp
      bytes32 _nonce, // Random nonce used for gasless send
      uint8 _v_gasless, // Signature value for GasLess send
      bytes32 _r_gasless, // Signature value for GasLess send
      bytes32 _s_gasless // Signature value for GasLess send
    ) external payable {
        bytes32 _tradeHash = keccak256(abi.encodePacked(_tradeID, _seller, _buyer, _value, _fee));
        require(!escrows[_tradeHash].exists, "Trade already exists in escrow mapping");
        bytes32 _invitationHash = keccak256(abi.encodePacked(_tradeHash));
        require(_value > minimumTradeValue, "Escrow value must be greater than minimum value"); // Check escrow value is greater than minimum value
        require(recoverAddress(_invitationHash, _v, _r, _s) == relayer, "Transaction signature did not come from relayer");

        // Perform gasless send from seller to contract
        Token(_currency).transferWithAuthorization(
            msg.sender,
            address(this),
            _value,
            0,
            MAX_INT,
            _nonce,
            _v_gasless,
            _r_gasless,
            _s_gasless
        );

        escrows[_tradeHash] = Escrow(true, 0, _currency);
        emit Created(_tradeHash);
    }

    /***********************
    +   Complete Escrow    +
    ***********************/

    function release(
        bytes16 _tradeID,
        address payable _seller,
        address payable _buyer,
        uint256 _value,
        uint16 _fee
    ) external returns (bool){
        require(msg.sender == _seller, "Must be seller");
        return doRelease(_tradeID, _seller, _buyer, _value, _fee, 0);
    }

    uint16 constant GAS_doRelease = 3658;
    function doRelease(
        bytes16 _tradeID,
        address payable _seller,
        address payable _buyer,
        uint256 _value,
        uint16 _fee,
        uint128 _additionalGas
    ) private returns (bool) {
        Escrow memory _escrow;
        bytes32 _tradeHash;
        (_escrow, _tradeHash) = getEscrowAndHash(_tradeID, _seller, _buyer, _value, _fee);
        if (!_escrow.exists) return false;
        uint128 _gasFees = _escrow.totalGasFeesSpentByRelayer + (msg.sender == relayer
                ? (GAS_doRelease + _additionalGas ) * uint128(tx.gasprice)
                : 0
            );
        delete escrows[_tradeHash];
        emit Released(_tradeHash, _gasFees);
        transferMinusFees(_escrow.tokenContract, _buyer, _value, _fee);
        return true;
    }

    uint16 constant GAS_doResolveDispute = 14060;
    function resolveDispute(
        bytes16 _tradeID,
        address payable _seller,
        address payable _buyer,
        uint256 _value,
        uint16 _fee,
        uint8 _v,
        bytes32 _r,
        bytes32 _s,
        uint8 _buyerPercent
    ) external onlyArbitrator {
        address _signature = recoverAddress(keccak256(abi.encodePacked(
            _tradeID,
            RESOLVE_DISPUTE
        )), _v, _r, _s);
        require(_signature == _buyer || _signature == _seller, "Must be buyer or seller");

        Escrow memory _escrow;
        bytes32 _tradeHash;
        (_escrow, _tradeHash) = getEscrowAndHash(_tradeID, _seller, _buyer, _value, _fee);
        require(_escrow.exists, "Escrow does not exist");
        require(_buyerPercent <= 100, "_buyerPercent must be 100 or lower");

        _escrow.totalGasFeesSpentByRelayer += (GAS_doResolveDispute * uint128(tx.gasprice));

        delete escrows[_tradeHash];
        emit DisputeResolved(_tradeHash, _escrow.totalGasFeesSpentByRelayer);
        if (_buyerPercent > 0) {
          // If dispute goes to buyer take the fee
          uint256 _totalFees = (_value * _fee / 10000);
          // Prevent underflow
          require(_value * _buyerPercent / 100 - _totalFees <= _value, "Overflow error");
          feesAvailableForWithdraw[_escrow.tokenContract] += _totalFees;
          Token(_escrow.tokenContract).safeTransfer(_buyer, _value * _buyerPercent / 100 - _totalFees);
        }
        if (_buyerPercent < 100) {
          Token(_escrow.tokenContract).safeTransfer(_seller, _value * (100 - _buyerPercent) / 100);
        }
    }

    function buyerCancel(
      bytes16 _tradeID,
      address payable _seller,
      address payable _buyer,
      uint256 _value,
      uint16 _fee
    ) external returns (bool) {
        require(msg.sender == _buyer, "Must be buyer");
        return doBuyerCancel(_tradeID, _seller, _buyer, _value, _fee, 0);
    }

    function increaseGasSpent(bytes32 _tradeHash, uint128 _gas) private {
        escrows[_tradeHash].totalGasFeesSpentByRelayer += _gas * uint128(tx.gasprice);
    }

    uint16 constant GAS_doBuyerCancel = 2367;
    function doBuyerCancel(
        bytes16 _tradeID,
        address payable _seller,
        address payable _buyer,
        uint256 _value,
        uint16 _fee,
        uint128 _additionalGas
    ) private returns (bool) {
        Escrow memory _escrow;
        bytes32 _tradeHash;
        (_escrow, _tradeHash) = getEscrowAndHash(_tradeID, _seller, _buyer, _value, _fee);
        require(_escrow.exists, "Escrow does not exist");
        if (!_escrow.exists) {
            return false;
        }
        uint128 _gasFees = _escrow.totalGasFeesSpentByRelayer + (msg.sender == relayer
                ? (GAS_doBuyerCancel + _additionalGas ) * uint128(tx.gasprice)
                : 0
            );
        delete escrows[_tradeHash];
        emit CancelledByBuyer(_tradeHash, _gasFees);
        transferMinusFees(_escrow.tokenContract, _seller, _value, 0);
        return true;
    }

    /***********************
    +        Relays        +
    ***********************/

    uint16 constant GAS_batchRelayBaseCost = 30000;
    function batchRelay(
        bytes16[] memory _tradeID,
        address payable[] memory _seller,
        address payable[] memory _buyer,
        uint256[] memory _value,
        uint16[] memory _fee,
        uint128[] memory _maximumGasPrice,
        uint8[] memory _v,
        bytes32[] memory _r,
        bytes32[] memory _s,
        uint8[] memory _instructionByte
    ) public returns (bool[] memory) {
        bool[] memory _results = new bool[](_tradeID.length);
        uint128 _additionalGas = uint128(msg.sender == relayer ? GAS_batchRelayBaseCost / _tradeID.length : 0);
        for (uint8 i = 0; i < _tradeID.length; i++) {
            _results[i] = relay(
                _tradeID[i],
                _seller[i],
                _buyer[i],
                _value[i],
                _fee[i],
                _maximumGasPrice[i],
                _v[i],
                _r[i],
                _s[i],
                _instructionByte[i],
                _additionalGas
            );
        }
        return _results;
    }

    function relay(
        bytes16 _tradeID,
        address payable _seller,
        address payable _buyer,
        uint256 _value,
        uint16 _fee,
        uint128 _maximumGasPrice,
        uint8 _v,
        bytes32 _r,
        bytes32 _s,
        uint8 _instructionByte,
        uint128 _additionalGas
    ) public returns (bool) {
        address _relayedSender = getRelayedSender(
            _tradeID,
            _instructionByte,
            _maximumGasPrice,
            _v,
            _r,
            _s
        );
        if (_relayedSender == _buyer) {
            if (_instructionByte == BUYER_CANCELS) {
                return doBuyerCancel(_tradeID, _seller, _buyer, _value, _fee, _additionalGas);
            }
        } else if (_relayedSender == _seller) {
            if (_instructionByte == RELEASE_ESCROW) {
                return doRelease(_tradeID, _seller, _buyer, _value, _fee, _additionalGas);
            }
        } else {
            require(msg.sender == _seller, "Unrecognised party");
            return false;
        }
    }

    /***********************
    +      Management      +
    ***********************/

    function setArbitrator(address _newArbitrator) external onlyOwner {
        arbitrator = _newArbitrator;
    }

    function setOwner(address _newOwner) external onlyOwner {
        owner = _newOwner;
    }

    function setRelayer(address _newRelayer) external onlyOwner {
        relayer = _newRelayer;
    }

    function setMinimumValue(uint16 _newMinimumValue) external onlyOwner {
        minimumTradeValue = _newMinimumValue;
    }

    /***********************
    +   Helper Functions   +
    ***********************/

    function transferMinusFees(
        address _currency,
        address payable _to,
        uint256 _value,
        uint16 _fee
    ) private {
        uint256 _totalFees = (_value * _fee / 10000);
        // Prevent underflow
        if(_value - _totalFees > _value) {
            return;
        }
        // Add fees to the pot for localcoinswap to withdraw
        feesAvailableForWithdraw[_currency] += _totalFees;
        Token(_currency).safeTransfer(_to, _value - _totalFees);
    }

    function withdrawFees(address payable _to, address _currency, uint256 _amount) external onlyOwner {
        // This check also prevents underflow
        require(_amount <= feesAvailableForWithdraw[_currency], "Amount is higher than amount available");
        feesAvailableForWithdraw[_currency] -= _amount;
        Token(_currency).safeTransfer(_to, _amount);
    }

    function getEscrowAndHash(
      bytes16 _tradeID,
      address _seller,
      address _buyer,
      uint256 _value,
      uint16 _fee
    ) private view returns (Escrow storage, bytes32) {
        bytes32 _tradeHash = keccak256(abi.encodePacked(_tradeID, _seller, _buyer, _value, _fee));
        return (escrows[_tradeHash], _tradeHash);
    }

    function recoverAddress(
        bytes32 _h,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) private pure returns (address) {
        bytes memory _prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 _prefixedHash = keccak256(abi.encodePacked(_prefix, _h));
        return ecrecover(_prefixedHash, _v, _r, _s);
    }

    function getRelayedSender(
      bytes16 _tradeID,
      uint8 _instructionByte,
      uint128 _maximumGasPrice,
      uint8 _v,
      bytes32 _r,
      bytes32 _s
    ) private view returns (address) {
        bytes32 _hash = keccak256(abi.encodePacked(_tradeID, _instructionByte, _maximumGasPrice));
        require(tx.gasprice < _maximumGasPrice, "Gas price is higher than maximum gas price");
        return recoverAddress(_hash, _v, _r, _s);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the current owner can change the owner");
        _;
    }

    modifier onlyArbitrator() {
        require(msg.sender == arbitrator, "Only the current owner can change the arbitrator");
        _;
    }
}