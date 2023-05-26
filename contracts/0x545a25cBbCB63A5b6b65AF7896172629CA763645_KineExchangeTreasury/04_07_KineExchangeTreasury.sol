pragma solidity ^0.5.16;

import "./Ownable.sol";
import "./KineSafeMath.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";

pragma experimental ABIEncoderV2;

contract KineExchangeTreasury is Ownable {
    using KineSafeMath for uint;
    using SafeERC20 for IERC20;

    event ReceiveEther(uint amount);
    event Claimed(uint256 indexed id, address indexed to, bool isETH, address currency, uint256 amount, uint256 deadline);
    event TransferToCounterParty(bool isETH, address currency, uint256 amount);
    event Paused();
    event Unpaused();
    event NewTruthHolder(address oldTruthHolder, address newTruthHolder);
    event NewOperator(address oldOperator, address newOperator);
    event NewCounterParty(address oldCounterParty, address newCounterParty);
    event AddCurrency(address indexed currency);
    event RemoveCurrency(address indexed currency);

    bool public paused;
    address public truthHolder;
    address public operator;
    address payable public counterParty;
    mapping(address => bool) public supportCurrency;
    mapping(uint => uint) public claimHistory;

    modifier notPaused() {
        require(!paused, "paused");
        _;
    }

    modifier onlyOperator() {
        require(msg.sender == operator, "only operator can call");
        _;
    }

    constructor (address truthHolder_, address operator_, address payable counterParty_) public {
        paused = false;
        truthHolder = truthHolder_;
        operator = operator_;
        counterParty = counterParty_;
    }

    function() external payable {
        if (msg.value > 0) {
            emit ReceiveEther(msg.value);
        }
    }

    function _transfer(address payable to, bool isETH, address currency, uint amount) internal {
        if(isETH) {
            require(address(this).balance >= amount, "not enough ether balance");
            require(to.send(amount), "ether transfer failed");
        } else {
            IERC20 token = IERC20(currency);
            uint balance = token.balanceOf(address(this));
            require(balance >= amount, "not enough currency balance");
            token.safeTransfer(to, amount);
        }
    }

    function transferToCounterParty(bool isETH, address currency, uint amount) external onlyOperator {
        _transfer(counterParty, isETH, currency, amount);
        emit TransferToCounterParty(isETH, currency, amount);
    }

    function claim(bytes calldata message, bytes calldata signature) external notPaused {
        address source = source(message, signature);
        require(source == truthHolder, "only accept truthHolder signed message");

        (uint256 id, address payable to, bool isETH, address currency, uint256 amount, uint256 deadline) = abi.decode(message, (uint256, address, bool, address, uint256, uint256));
        require(claimHistory[id] == 0, "already claimed");
        require(isETH || supportCurrency[currency], "currency not support");
        require(block.timestamp < deadline, "already passed deadline");

        claimHistory[id] = block.number;
        _transfer(to, isETH, currency, amount);
        emit Claimed(id, to, isETH, currency, amount, deadline);
    }

    function source(bytes memory message, bytes memory signature) public pure returns (address) {
        (bytes32 r, bytes32 s, uint8 v) = abi.decode(signature, (bytes32, bytes32, uint8));
        bytes32 hash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", keccak256(message)));
        return ecrecover(hash, v, r, s);
    }

    function _pause() external onlyOwner {
        paused = true;
        emit Paused();
    }

    function _unpause() external onlyOwner {
        paused = false;
        emit Unpaused();
    }

    function _changeTruthHolder(address newTruthHolder) external onlyOwner {
        address oldHolder = truthHolder;
        truthHolder = newTruthHolder;
        emit NewTruthHolder(oldHolder, newTruthHolder);
    }

    function _setOperator(address newOperator) external onlyOwner {
        address oldOperator = operator;
        operator = newOperator;
        emit NewOperator(oldOperator, newOperator);
    }

    function _setCounterParty(address payable newCounterParty) external onlyOwner {
        address payable oldCounterParty = counterParty;
        counterParty = newCounterParty;
        emit NewCounterParty(oldCounterParty, newCounterParty);
    }

    function _addCurrency(address currency) external onlyOwner {
        supportCurrency[currency] = true;
        emit AddCurrency(currency);
    }

    function _removeCurrency(address currency) external onlyOwner {
        delete supportCurrency[currency];
        emit RemoveCurrency(currency);
    }

}