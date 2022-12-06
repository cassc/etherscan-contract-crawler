// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract ShopNEXT_Token_Withdrawal  is Ownable {
    event ClaimToken(
        address indexed user,
        uint256 indexed amount,
        uint256 indexed nonce,
        bytes signature,
        address token
    );
    event ChangeMaximumPerUintTime(
        uint256 indexed maximumPerUintTime,
        address indexed token
    );
    event ChangeUintTime(uint256 indexed uintTime, address indexed token);
    event ChangeLockTimeWithdrawPerUser(
        uint256 indexed lockTimeWithdrawPerUser,
        address indexed token
    );
    using SafeERC20 for IERC20;
    mapping(address => bool) public signers;
    mapping(address => bool) public tokenAllow;
    mapping(address => address) public storeToken;
    mapping(bytes => bool) public isClaimed;
    mapping(address => mapping(address => uint256)) public lastTimeClaim;
    mapping(address => mapping(uint256 => uint256)) public totalClaim;
    mapping(address => uint256) public maximumPerUintTime;
    mapping(address => uint256) public timeUint;
    mapping(address => uint256) public lockTimeWithdrawPerUser;

    constructor() {}

    function setMaximumPerUint(address token, uint256 _maximumPerUint)
        external
        onlyOwner
    {
        require(tokenAllow[token], "SN: Token not allow");
        maximumPerUintTime[token] = _maximumPerUint;
        emit ChangeMaximumPerUintTime(_maximumPerUint, token);
    }

    function setTimeUint(address token, uint256 _timeUint) external onlyOwner {
        require(tokenAllow[token], "SN: Token not allow");
        timeUint[token] = _timeUint;
        emit ChangeUintTime(_timeUint, token);
    }

    function setLockTimeWithdrawPerUser(
        address token,
        uint256 _lockTimeWithdrawPerUser
    ) external onlyOwner {
        require(tokenAllow[token], "SN: Token not allow");
        lockTimeWithdrawPerUser[token] = _lockTimeWithdrawPerUser;
        emit ChangeLockTimeWithdrawPerUser(_lockTimeWithdrawPerUser, token);
    }

    function claim(
        address to,
        uint256 amount,
        uint256 nonce,
        address token,
        bytes calldata signature
    ) external {
        require(tokenAllow[token], "SN: Token not allow");
        require(!isClaimed[signature], "SN: token claimed");
        bytes32 _msgHash = keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                keccak256(
                    abi.encodePacked(
                        "SN_WITHDRAW_NEXT",
                        to,
                        amount,
                        nonce,
                        token
                    )
                )
            )
        );
        address signer = getSigner(_msgHash, signature);
        require(signers[signer], "SN: invalid signer");

        
        require(
            totalClaim[token][block.timestamp / timeUint[token]] + amount <=
                maximumPerUintTime[token],
            "SN: over quota"
        );
        require(
            lastTimeClaim[token][to] + lockTimeWithdrawPerUser[token] <
                block.timestamp,
            "SN: limit time withdraw"
        );
        isClaimed[signature] = true;
        totalClaim[token][block.timestamp / timeUint[token]] += amount;
        lastTimeClaim[token][to] = block.timestamp;

        IERC20(token).safeTransferFrom(storeToken[token], to, amount);
        
        emit ClaimToken(to, amount, nonce, signature, token);
    }

    function addSigner(address _signer) external onlyOwner {
        require(
            _signer != address(0) && !signers[_signer],
            "SN: invalid address"
        );
        signers[_signer] = true;
    }

    function setAllowToken(address _token,bool _allow) external onlyOwner {
        tokenAllow[_token] = _allow;
    }

    function setstoreTokenAddress(address user, address token)
        external
        onlyOwner
    {
        require(tokenAllow[token], "SN: Token not allow");
        storeToken[token] = user;
    }

    function removeSigner(address _signer) external onlyOwner {
        require(
            _signer != address(0) && signers[_signer],
            "SN: invalid address"
        );
        signers[_signer] = false;
    }

    function getSigner(bytes32 msgHash, bytes memory _signature)
        private
        pure
        returns (address)
    {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);

        return ecrecover(msgHash, v, r, s);
    }

    function splitSignature(bytes memory signature)
        private
        pure
        returns (
            bytes32 r,
            bytes32 s,
            uint8 v
        )
    {
        require(signature.length == 65, "SN: invalid signature length");
        assembly {
            r := mload(add(signature, 32))
            s := mload(add(signature, 64))
            v := byte(0, mload(add(signature, 96)))
        }
    }
}