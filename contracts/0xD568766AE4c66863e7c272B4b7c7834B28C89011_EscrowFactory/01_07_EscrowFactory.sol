// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./interfaces/IEscrow.sol";

contract EscrowFactory {
    using SafeERC20 for IERC20;
    address public immutable implementation;

    uint256 public escrowCount;
    mapping(uint256 => address) internal _escrows;
    event EscrowCreated(
        uint256 indexed index,
        address escrow,
        address client,
        address talent,
        address resolver,
        string proposal
    );

    constructor(address _implementation) {
        require(_implementation != address(0), "Invalid implementation");

        implementation = _implementation;
    }

    function create(
        address _client,
        address _talent,
        address _resolver,
        uint256 _fee,
        string memory _proposal
    ) external payable returns (address) {
        address escrow = Clones.clone(implementation);
        IEscrow(escrow).init(_client, _talent, _resolver, _fee);
        uint256 escrowId = escrowCount;
        _escrows[escrowId] = escrow;
        escrowCount = escrowCount + 1;

        emit EscrowCreated(
            escrowId,
            escrow,
            _client,
            _talent,
            _resolver,
            _proposal
        );

        return escrow;
    }

    function getEscrow(uint256 index) external view returns (address) {
        return _escrows[index];
    }
}