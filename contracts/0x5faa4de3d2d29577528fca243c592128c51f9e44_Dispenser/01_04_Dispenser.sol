// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract Dispenser {
    string private constant creator = "Vali Malinoiu <[email protected]>";
    address private _signer;
    address private _owner;
    IERC20 private _contract;
    mapping(bytes32 => uint256) _claims;

    constructor() {
        _signer = msg.sender;
        _owner = msg.sender;
        _contract = IERC20(0x01BE23585060835E02B77ef475b0Cc51aA1e0709);
    }

    event Claim(
        address indexed owner,
        uint256 indexed nonce,
        uint256 indexed amount
    );

    receive() external payable {}

    function Creator() public pure returns (string memory) {
        return creator;
    }

    function Signer() public view returns (address) {
        return _signer;
    }

    function Owner() public view returns (address) {
        return _owner;
    }

    function SetOwner(address newOwner) public {
        require(
            msg.sender == _owner,
            "Dispenser: Only owner can set a new owner"
        );
        _owner = newOwner;
    }

    function SetSigner(address newSigner) public {
        require(
            msg.sender == _owner,
            "Dispenser: Only owner can set a new signer"
        );
        _signer = newSigner;
    }

    function SetContract(IERC20 contractAddress) public {
        require(
            msg.sender == _owner,
            "Dispenser: Only owner can set a new contract"
        );
        _contract = contractAddress;
    }

    function Withdraw() public {
        require(
            msg.sender == _owner,
            "Dispenser: Only owner can force withdraw"
        );
        uint256 balance = _contract.balanceOf(address(this));
        require(balance > 0, "Dispenser: Nothing to withdraw!");

        _contract.transfer(_owner, balance);
    }

    function _hash(
        address _address,
        uint256 _value,
        uint256 _nonce
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_address, _value, _nonce));
    }

    function ClaimTokens(
        uint256 amount,
        uint256 nonce,
        bytes memory signature
    ) public {
        uint256 balance = _contract.balanceOf(address(this));
        require(amount <= balance, "Dispenser: Insufficient funds!");

        bytes32 hash = _hash(msg.sender, amount, nonce);

        require(
            ECDSA.recover(ECDSA.toEthSignedMessageHash(hash), signature) ==
                _signer,
            "Dispenser: Invalid signature!"
        );
        require(_claims[hash] == 0, "Dispenser: Already claimed!");

        _claims[hash] = amount;
        _contract.transfer(msg.sender, amount);

        emit Claim(msg.sender, nonce, amount);
    }
}