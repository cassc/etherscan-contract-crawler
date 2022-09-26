// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./lib/TokenHolder.sol";

contract Pool is EIP712, TokenHolder {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    address public tokenIn;
    address public signAddress;
    IERC20 public token;
    uint256 public safeAmount;
    mapping(address => uint256) public nonces;
    event Recharge(address indexed user, uint256 amount);
    event Withdraw(
        address indexed user,
        uint256 amount,
        uint256 nonce,
        uint256 deadline
    );

    bytes32 public constant _TYPEHASH =
        keccak256(
            "Withdraw(address user,uint256 amount,uint256 deadline,uint256 nonce)"
        );

    constructor() EIP712("POOL", "1.0") {}

    function changeSafeAmount(uint256 _amount) public onlyOwner {
        safeAmount = _amount;
    }

    function getReward(
        address user,
        uint256 amount,
        uint256 deadline,
        uint256 nonce,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public returns (bool) {
        require(amount > 0 && deadline > block.timestamp, "time expired!");
        require(nonce == nonces[user], "user nonce error");
        bytes32 digest = _hashTypedDataV4(
            keccak256(abi.encode(_TYPEHASH, user, amount, deadline, nonce))
        );
        address recoveredAddress = ecrecover(digest, v, r, s);
        require(recoveredAddress == signAddress, "sign error!");
        safeAmount = safeAmount.sub(amount);
        token.safeTransfer(user, amount);
        nonces[user]++;
        emit Withdraw(user, amount, nonce, deadline);
        return true;
    }

    function recharge(uint256 amount) public {
        token.safeTransferFrom(msg.sender, tokenIn, amount);
        emit Recharge(msg.sender, amount);
    }

    function getChainId() external view returns (uint256) {
        return block.chainid;
    }

    function domainSeparatorV4() external view returns (bytes32) {
        return _domainSeparatorV4();
    }

    function setSignAddress(address _signAddress) public onlyOwner {
        signAddress = _signAddress;
    }

    function setTokenAddress(address _token) public onlyOwner {
        token = IERC20(_token);
    }

    function setTokenIn(address _tokenIn) public onlyOwner {
        tokenIn = _tokenIn;
    }
}