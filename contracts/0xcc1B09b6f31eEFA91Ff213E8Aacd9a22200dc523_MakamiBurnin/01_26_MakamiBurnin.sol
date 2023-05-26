// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/access/AccessControl.sol';
import './TalismanPaperOfMakami.sol';
import './interface/ICNP.sol';

contract MakamiBurnin is Ownable, AccessControl, ReentrancyGuard {
    bytes32 public constant PAUSER_ROLE = keccak256('PAUSER_ROLE');

    event BurninMakami(address indexed sender, uint256 indexed tokenId);

    ICNP public immutable CNP;
    TalismanPaperOfMakami public immutable TPM;

    bool public paused = true;

    mapping(uint256 => bool) public burnedTokenId;

    modifier onlyPauser() {
        require(hasRole(PAUSER_ROLE, msg.sender), 'Caller is not a minter');
        _;
    }

    constructor(ICNP _CNP, TalismanPaperOfMakami _TPM) {
        CNP = _CNP;
        TPM = _TPM;
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(PAUSER_ROLE, msg.sender);
    }

    // external
    function burnin(uint256[] memory tokenIds) external nonReentrant {
        require(!paused, 'Paused');
        TPM.burn(_msgSender(), 1, tokenIds.length);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            require(_msgSender() == CNP.ownerOf(tokenId), 'address is not owner');
            require(!burnedTokenId[tokenId], "Makami can't Burnin");

            burnedTokenId[tokenId] = true;

            emit BurninMakami(_msgSender(), tokenId);
        }
    }

    function pause(bool _state) external onlyPauser {
        paused = _state;
    }

    function withdraw(address payable withdrawAddress) external onlyOwner {
        (bool os, ) = withdrawAddress.call{value: address(this).balance}('');
        require(os);
    }

    function checkBurned(uint256[] calldata tokenIds) external view returns (bool[] memory res) {
        res = new bool[](tokenIds.length);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            res[i] = burnedTokenId[tokenIds[i]];
        }
    }
}