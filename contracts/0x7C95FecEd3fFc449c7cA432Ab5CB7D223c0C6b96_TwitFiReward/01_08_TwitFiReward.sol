// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract TwitFiReward is Pausable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    address private _owner;

    mapping (address => bool) private _validators;
    mapping(address => Counters.Counter) private _nonces;

    IERC20 public _erc20;

    struct Reward {
        uint256 _amount;
        address _holder;
        uint256 _deadline;
        bytes _signature;
        string _ref;
    }

    event CliamReward(uint256 amount, address account, string ref, uint256 timestamp);

    constructor(IERC20 _token) {
        _owner = msg.sender;
        _erc20 = _token;
        _validators[msg.sender] = true;
    }

    function setErc20(IERC20 _token) public onlyOwner {
        _erc20 = _token;
    }

    function setValidator(address _validator, bool _enable) public whenNotPaused onlyOwner {
        _validators[_validator] = _enable;
    }

    function isValidator(address _validator) public view returns (bool) {
        return _validators[_validator];
    }

    function claimReward(bytes memory _data, uint _deadline) external whenNotPaused {
        require(block.timestamp <= _deadline, "Deadline exceeded");

        Reward memory reward;
        (reward) = abi.decode(_data, (Reward));
        address approver = approverSignature(reward);

        require(_validators[approver], 'Unauthorized Opetator!');
        require(reward._holder == msg.sender, 'Unauthorized!');
        require(_erc20.balanceOf(address(this)) >= reward._amount, 'INSUFFICIENT_BALANCE');

        _erc20.transfer(msg.sender, reward._amount);
        _increaseNounce(reward._holder);
        emit CliamReward(reward._amount, reward._holder, reward._ref, block.timestamp);
    }

    function approverSignature(Reward memory reward) internal view virtual returns (address signer) {
        bytes32 structHash = keccak256(abi.encode(reward._amount, reward._holder, address(this), reward._ref, _nonces[reward._holder].current(), reward._deadline));
        signer = recover(structHash, reward._signature);
    }

    function recover(bytes32 structHash, bytes memory _signature) internal view virtual returns (address signer) {
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 prefixedHash = keccak256(abi.encodePacked(prefix, structHash));
        signer = ECDSA.recover(prefixedHash, _signature);
    }

    function nonces(address _account) public view virtual returns (uint256) {
        return _nonces[_account].current();
    }

    function setOwner(address _newOwner) public onlyOwner {
        _owner = _newOwner;
    }

    function _increaseNounce(address _account) private {
        Counters.Counter storage nonce = _nonces[_account];
        nonce.increment();
    }

    function withdraw() public onlyOwner {
        uint amount = address(this).balance;
        require(amount > 0, "Insufficient balance");
        (bool success, ) = payable(_owner).call {
            value: amount
        }("");

        require(success, "Failed to send Matic");
    }

    function emergencyWithdraw() external onlyOwner {
        _erc20.transfer(_owner, _erc20.balanceOf(address(this)));
    }

    modifier onlyOwner {
        require(msg.sender == _owner, "UNAUTHORIZED");
        _;
    }

    receive() payable external {}
}