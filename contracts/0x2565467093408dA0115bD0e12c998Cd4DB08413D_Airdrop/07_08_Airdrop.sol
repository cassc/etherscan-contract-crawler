// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./EIP712Verifier.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";

contract Airdrop is EIP712Verifier {
    uint constant UNLOCKED = 1;
    uint constant LOCKED = 2;
    uint reentryLockStatus = UNLOCKED;

    address public immutable owner;
    IERC20 public rewardToken;

    // record of already processed claims
    mapping(uint => bool) public processedClaims;


    event Claimed(address indexed trader, uint indexed amount);
    event WithdrawTo(address indexed to, uint indexed amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "ONLY_OWNER");
        _;
    }

    modifier nonReentrant() {
        require(reentryLockStatus == UNLOCKED, "NO_REENTRY");
        reentryLockStatus = LOCKED;
        _;
        reentryLockStatus = UNLOCKED;
    }

    constructor(address _owner, 
    address _rewardToken, 
    address _signer) EIP712Verifier("RabbitxAirdrop", "1", _signer) {
        owner = _owner;
        rewardToken = IERC20(_rewardToken);

        require(owner != address(0), "ZERO_OWNER");
        require(address(rewardToken) != address(0), "ZERO_TOKEN");
    }

    function claim(uint id, address trader, uint amount, uint8 v, bytes32 r, bytes32 s) external nonReentrant {
        require(amount > 0, "WRONG_AMOUNT");
        require(processedClaims[id] == false, "ALREADY_PROCESSED");
        processedClaims[id] = true;

        bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
            keccak256("claim(uint id,address trader,uint amount)"),
            id,
            trader,
            amount
        )));

        bool is_valid = verify(digest, v, r, s);
        require(is_valid, "INVALID_SIGNATURE");

        bool success = makeTransfer(trader, amount);
        require(success, "TRANSFER_FAILED");

        emit Claimed(trader, amount);
    }


    function withdrawTokensTo(uint amount, address to) external onlyOwner {
        require(amount > 0, "WRONG_AMOUNT");
        require(to != address(0), "ZERO_ADDRESS");
        bool success = makeTransfer(to, amount);
        require(success, "TRANSFER_FAILED");
        emit WithdrawTo(to, amount);
    }

    function changeSigner(address new_signer) external onlyOwner {
        require(new_signer != address(0), "ZERO_SIGNER");

        external_signer = new_signer;
    }


    function makeTransfer(address to, uint256 amount) private returns (bool success) {
        return tokenCall(abi.encodeWithSelector(rewardToken.transfer.selector, to, amount));
    }

    function makeTransferFrom(address from, address to, uint256 amount) private returns (bool success) {
        return tokenCall(abi.encodeWithSelector(rewardToken.transferFrom.selector, from, to, amount));
    }

    function tokenCall(bytes memory data) private returns (bool) {
        (bool success, bytes memory returndata) = address(rewardToken).call(data);
        if (success && returndata.length > 0) {
            success = abi.decode(returndata, (bool));
        }
        return success;
    }




}