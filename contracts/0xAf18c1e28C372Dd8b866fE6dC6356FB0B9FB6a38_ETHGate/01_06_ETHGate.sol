pragma solidity >=0.5.16;

import "openzeppelin-solidity/contracts/access/Ownable.sol";
import "openzeppelin-solidity/contracts/utils/ReentrancyGuard.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "../TransferHelper.sol";

contract ETHGate is ReentrancyGuard, Ownable {
    using SafeMath for uint;

    address public signWallet;
    address public feeWallet;

    uint public feeAvailable;
    uint public fee;

    // key: payback_id
    mapping (bytes32 => bool) public executedMap;

    event Transit(address indexed from, address indexed token, uint amount);
    event Withdraw(bytes32 paybackId, address indexed to, address indexed token, uint amount);
    event CollectFee(address indexed handler, uint amount);

    constructor(address _signer, address _feeWallet) ReentrancyGuard() Ownable() public {
        signWallet = _signer;
        feeWallet = _feeWallet;
    }

    function changeSigner(address _wallet) external onlyOwner {
        signWallet = _wallet;
    }

    function changeFeeWallet(address _feeWallet) external onlyOwner {
        feeWallet = _feeWallet;
    }

    function changeFee(uint _amount) external onlyOwner {
        fee = _amount;
    }

    function collectFee() external onlyOwner {
        require(feeWallet != address(0), "SETUP_FEE_WALLET");
        require(feeAvailable > 0, "NO_FEE");
        TransferHelper.safeTransferETH(feeWallet, feeAvailable);
        feeAvailable = 0;
    }

    function transitForBSC(address _token, uint _amount) external {
        require(_amount > 0, "INVALID_AMOUNT");
        TransferHelper.safeTransferFrom(_token, msg.sender, address(this), _amount);
        emit Transit(msg.sender, _token, _amount);
    }

    function withdrawFromBSC(bytes calldata _signature, bytes32 _paybackId, address _token, uint _amount) external nonReentrant payable {
        require(executedMap[_paybackId] == false, "ALREADY_EXECUTED");
        executedMap[_paybackId] = true;

        require(_amount > 0, "NOTHING_TO_WITHDRAW");
        require(msg.value == fee, "INSUFFICIENT_VALUE");

        bytes32 message = keccak256(abi.encodePacked(_paybackId, _token, msg.sender, _amount));
        require(_verify(message, _signature), "INVALID_SIGNATURE");

        TransferHelper.safeTransfer(_token, msg.sender, _amount);
        feeAvailable = feeAvailable.add(fee);

        emit Withdraw(_paybackId, msg.sender, _token, _amount);
    }

    function _verify(bytes32 _message, bytes memory _signature) internal view returns (bool) {
        bytes32 hash = _toEthBytes32SignedMessageHash(_message);
        address[] memory signList = _recoverAddresses(hash, _signature);
        return signList[0] == signWallet;
    }

    function _toEthBytes32SignedMessageHash (bytes32 _msg) pure internal returns (bytes32 signHash)
    {
        signHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _msg));
    }

    function _recoverAddresses(bytes32 _hash, bytes memory _signatures) pure internal returns (address[] memory addresses)
    {
        uint8 v;
        bytes32 r;
        bytes32 s;
        uint count = _countSignatures(_signatures);
        addresses = new address[](count);
        for (uint i = 0; i < count; i++) {
            (v, r, s) = _parseSignature(_signatures, i);
            addresses[i] = ecrecover(_hash, v, r, s);
        }
    }

    function _parseSignature(bytes memory _signatures, uint _pos) pure internal returns (uint8 v, bytes32 r, bytes32 s)
    {
        uint offset = _pos * 65;
        assembly {
            r := mload(add(_signatures, add(32, offset)))
            s := mload(add(_signatures, add(64, offset)))
            v := and(mload(add(_signatures, add(65, offset))), 0xff)
        }

        if (v < 27) v += 27;

        require(v == 27 || v == 28);
    }

    function _countSignatures(bytes memory _signatures) pure internal returns (uint)
    {
        return _signatures.length % 65 == 0 ? _signatures.length / 65 : 0;
    }
}