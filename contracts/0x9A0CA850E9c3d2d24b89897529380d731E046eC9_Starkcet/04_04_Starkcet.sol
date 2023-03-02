// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "openzeppelin/contracts/access/Ownable.sol";
import "openzeppelin/contracts/security/Pausable.sol";

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);

    function balanceOf(address account) external view returns (uint256);
}

contract Starkcet is Ownable, Pausable {
    struct Tx {
        address from;
        bytes32 to;
        uint8 network;
    }

    uint256 public lastIdx;
    mapping(uint256 => Tx) public transaction;
    event StarkcetTx(
        address indexed _from,
        bytes32 indexed _to,
        uint8 indexed _network,
        uint256 _idx
    );

    function starkcetFaucet(bytes32 _StarknetAddress, uint8 _network)
        public
        whenNotPaused
    {
        Tx memory newTransaction = Tx(msg.sender, _StarknetAddress, _network);
        lastIdx += 1;
        transaction[lastIdx] = newTransaction;
        emit StarkcetTx(msg.sender, _StarknetAddress, _network, lastIdx);
    }

    function setPause(bool pause) public onlyOwner {
        if (pause) {
            _pause();
        }
        if (!pause) {
            _unpause();
        }
    }

    function withdraw(address _token) public onlyOwner {
        uint256 balance = IERC20(_token).balanceOf(address(this));
        IERC20(_token).transfer(owner(), balance);
    }
}