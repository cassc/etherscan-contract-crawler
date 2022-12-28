// SPDX-License-Identifier: MIT

pragma solidity 0.7.4;

import '@openzeppelin/contracts/cryptography/MerkleProof.sol';
import '@openzeppelin/contracts/token/ERC20/SafeERC20.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import "@openzeppelin/contracts/access/Ownable.sol";

contract VBabyDispatch is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    event NewRewardToken(IERC20 oldRewardToken, IERC20 newRewardToken);
    event NewVault(address oldVault, address newVault);
    event NewDispatcher(address oldDispatcher, address newDispatcher);
    event NewVerifier(address oldVerifier, address newVerifier);
    event NewCaller(address oldCaller, address newCaller);
    event NewDispatchReward(address from, address to, uint amount);
    event Claim(address user, uint amount, uint totalAmount);
    event NewClaimAmount(address user, uint amount);

    IERC20 public rewardToken;
    address public vault;
    address public dispatcher;
    address public verifier;
    address public caller;
    uint public totalReward;
    uint public remainReward;

    mapping(address => uint) public claimed;

    function setRewardToken(IERC20 _token) external onlyOwner {
        emit NewRewardToken(rewardToken, _token);
        rewardToken = _token;
    }

    function setVault(address _vault) external onlyOwner {
        emit NewVault(vault, _vault);
        vault = _vault;
    }

    function setDispatcher(address _dispatcher) external onlyOwner {
        emit NewDispatcher(dispatcher, _dispatcher);
        dispatcher = _dispatcher;
    }

    function setVerifier(address _verifier) external onlyOwner {
        emit NewVerifier(verifier, _verifier);
        verifier = _verifier;
    }

    function setCaller(address _caller) external onlyOwner {
        emit NewCaller(caller, _caller);
        caller = _caller;
    }

    function setUserClaimed(address _user, uint _amount) external onlyOwner {
        claimed[_user] = _amount;
        emit NewClaimAmount(_user, _amount);
    }

    function setTotalReward(uint _totalReward) external onlyOwner {
        totalReward = _totalReward;
    }

    function setRemainReward(uint _remainReward) external onlyOwner {
        remainReward = _remainReward;
    }

    constructor(IERC20 _token, address _vault, address _dispatcher, address _verifier, address _caller) {
        emit NewRewardToken(rewardToken, _token);
        rewardToken = _token;
        emit NewVault(vault, _vault);
        vault = _vault;
        emit NewDispatcher(dispatcher, _dispatcher);
        dispatcher = _dispatcher;
        emit NewVerifier(verifier, _verifier);
        verifier = _verifier;
        emit NewCaller(caller, _caller);
        caller = _caller;
    }

    modifier onlyCaller() {
        require(msg.sender == caller, "only caller can do this action");
        _;
    }

    function dispatchReward(uint _amount) external onlyCaller {
        rewardToken.safeTransferFrom(vault, dispatcher, _amount);
        totalReward = totalReward.add(_amount);
        remainReward = remainReward.add(_amount);
        emit NewDispatchReward(vault, dispatcher, _amount);
    }

    function getEncodePacked(address user, uint amount) public pure returns (bytes memory) {
        return abi.encodePacked(user, amount);
    }

    function getHash(address user, uint amount) external pure returns (bytes32) {
        return keccak256(abi.encodePacked(user, amount));
    }

    function getHashToSign(address user, uint amount) external pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", keccak256(abi.encodePacked(user, amount))));
    }

    function verify(address user, uint amount, uint8 v, bytes32 r, bytes32 s) external view returns (bool) {
        return ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", keccak256(abi.encodePacked(user, amount)))), v, r, s) == verifier;
    }

    function claim(address user, uint amount, uint8 v, bytes32 r, bytes32 s) external {
        bytes32 hash = keccak256(abi.encodePacked(user, amount));
        bytes32 hashToSign = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
        require(ecrecover(hashToSign, v, r, s) == verifier, "illegal verifier");
        uint realAmount = amount.sub(claimed[user]);
        rewardToken.safeTransferFrom(dispatcher, user, realAmount);
        claimed[user] = claimed[user].add(realAmount);
        remainReward = remainReward.sub(realAmount);
        emit Claim(user, realAmount, amount);
    }
}