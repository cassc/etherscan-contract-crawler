// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/Pausable.sol";


contract ConiTokenStaking is Ownable, Pausable {
    bytes4 ON_APPROVAL_RECEIVED_SUCCESS = bytes4(keccak256("onApprovalReceived(address,uint256,bytes)"));

    event TokensStaked(address from, uint256 amount);
    event TokensUnstaked(address to, uint256 amount);
    error SignatureError(string message);

    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    using ECDSA for bytes32;
    using Counters for Counters.Counter;

    uint256 public contractBalance;
    IERC20 public CONI_TOKEN;
    address private SIGNER_ADDRESS;
    mapping(address => Counters.Counter) private _nonces;
    mapping(address => uint256) public withdrawnBalances;
    mapping(address => uint256) public balances;


    constructor (IERC20 _coniTokenAddress, address _signerAddress) {
        CONI_TOKEN = _coniTokenAddress;
        SIGNER_ADDRESS = _signerAddress;
    }

    function onApprovalReceived(address sender, uint256 amount, bytes calldata) external returns (bytes4) {
        CONI_TOKEN.transferFrom(sender, address(this), amount);

        balances[sender] = balances[sender].add(amount);
        contractBalance = contractBalance.add(amount);

        emit TokensStaked(sender, amount);
        return ON_APPROVAL_RECEIVED_SUCCESS;
    }

    function withdraw(uint256 amount, bytes memory signature) public whenNotPaused {
        require(balances[msg.sender] >= amount, "Not enough tokens to withdraw");

        if (verifySignature(msg.sender, amount, _useNonce(msg.sender), signature) != true) {
            revert SignatureError("Signature is not valid");
        }
        contractBalance = contractBalance.sub(amount);
        balances[msg.sender] = balances[msg.sender].sub(amount);
        withdrawnBalances[msg.sender] = withdrawnBalances[msg.sender].add(amount);

        CONI_TOKEN.transfer(msg.sender, amount);
        emit TokensUnstaked(msg.sender, amount);
    }

    // management    
    function withdrawAll(address destination) public onlyOwner {
        uint256 balance = CONI_TOKEN.balanceOf(address(this));
        CONI_TOKEN.transfer(destination, balance);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

     function setConiTokenAddress(IERC20 _coniTokenAddress) public onlyOwner {
        CONI_TOKEN = _coniTokenAddress;
    }

    function setSignerAddress(address _signerAddress) public onlyOwner {
        SIGNER_ADDRESS = _signerAddress;
    }

    // internal functions
    function verifySignature(
        address _userAddress,
        uint256 _amount,
        uint256 _userNonce,
        bytes memory signature
    ) private view returns (bool) {
        if (_userAddress != msg.sender) {
            revert SignatureError("This signature is not for you");
        }
        
        bytes32 ethSignedMessageHash = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", keccak256(abi.encodePacked(
                _userAddress,
                _amount,
                _userNonce,
                "ConiStake"
            )))
        );
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(signature);

        return ecrecover(ethSignedMessageHash, v, r, s) == SIGNER_ADDRESS;
    }

    function splitSignature(bytes memory sig)
        private
        pure
        returns (
        bytes32 r,
        bytes32 s,
        uint8 v
        )
    {
        if (sig.length != 65) {
        revert SignatureError("Signature length is not 65 bytes");
        }
        assembly {
        r := mload(add(sig, 32))
        s := mload(add(sig, 64))
        v := byte(0, mload(add(sig, 96)))
        }
    }

    function _useNonce(address owner) internal virtual returns (uint256 current) {
        Counters.Counter storage nonce = _nonces[owner];
        current = nonce.current();
        nonce.increment();
    }


    function nonces(address owner) public view virtual returns (uint256) {
        return _nonces[owner].current();
    }
}