// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/access/AccessControl.sol';
import './TalismanPaperOfYama.sol';

contract YamaBurnin is Ownable, AccessControl, ReentrancyGuard {
    bytes32 public constant PAUSER_ROLE = keccak256('PAUSER_ROLE');

    IERC721 public immutable CNP;
    TalismanPaperOfYama public immutable TPY;

    uint256 public currentTokenId = 24445;
    uint256 public maxTokenId = 24745;
    address public poolAddress = 0x1bF41851E4Bd044022Dfa7E9c678809F5197A56f;
    address public returnAddress = 0x1bF41851E4Bd044022Dfa7E9c678809F5197A56f;
    bool public paused = true;

    modifier onlyPauser() {
        require(hasRole(PAUSER_ROLE, msg.sender), 'Caller is not a minter');
        _;
    }

    constructor(IERC721 _CNP, TalismanPaperOfYama _TPY) {
        CNP = _CNP;
        TPY = _TPY;
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(PAUSER_ROLE, msg.sender);
    }

    // external
    function burnin(uint256[] memory tpyTokenIds, uint256[] memory cnpTokenIds) external nonReentrant {
        require(!paused, 'Paused');
        require(tpyTokenIds.length == cnpTokenIds.length, 'Wrong length');
        require(currentTokenId + tpyTokenIds.length <= maxTokenId, 'Pool not enough');
        uint256 startTokenId = currentTokenId;
        TPY.burnerBurn(_msgSender(), tpyTokenIds);
        for (uint256 i = 0; i < cnpTokenIds.length; i++) {
            uint256 cnpTokenId = cnpTokenIds[i];
            require(_msgSender() == CNP.ownerOf(cnpTokenId));

            CNP.safeTransferFrom(_msgSender(), returnAddress, cnpTokenId);
            CNP.safeTransferFrom(poolAddress, _msgSender(), startTokenId++);
        }
        currentTokenId = startTokenId;
    }

    function pause(bool _state) external onlyPauser {
        paused = _state;
    }

    function setPoolAddress(address _poolAddress) external onlyOwner {
        poolAddress = _poolAddress;
    }

    function setReturnAddress(address _returnAddress) external onlyOwner {
        returnAddress = _returnAddress;
    }

    function setCurrentTokenId(uint256 _currentTokenId) external onlyOwner {
        currentTokenId = _currentTokenId;
    }

    function setMaxTokenId(uint256 _maxTokenId) external onlyOwner {
        maxTokenId = _maxTokenId;
    }

    function withdraw(address payable withdrawAddress) external onlyOwner {
        (bool os, ) = withdrawAddress.call{value: address(this).balance}('');
        require(os);
    }
}