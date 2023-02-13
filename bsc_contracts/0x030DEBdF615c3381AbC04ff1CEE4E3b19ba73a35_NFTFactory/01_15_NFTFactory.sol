// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "../interfaces/IPlaybuxQuestNFT.sol";
import "../meta-transactions/ContextMixin.sol";
import "../meta-transactions/NativeMetaTransaction.sol";

contract NFTFactory is ContextMixin, AccessControl, Pausable, ReentrancyGuard, NativeMetaTransaction {
    string public constant name = "Playbux NFT Factory";
    uint256 public constant BLOCK_PER_DAY = 28000;

    IPlaybuxQuestNFT public immutable nft;

    address public admin;
    uint256 public mintLimitPerDay = 10;

    mapping(address => uint256) public mintAmount;
    mapping(address => uint256) public lastMint;

    event Mint(string _transactionId, address indexed _receiver, uint256 _value, uint256 _type);
    event MintLimitPerDayChanged(uint256 oldLimit, uint256 newLimit);
    event AdminChanged(address oldAdmin, address newAdmin);

    constructor(IPlaybuxQuestNFT _nft, address _admin) {
        require(address(_nft) != address(0), "NFT address is invalid");
        require(_admin != address(0), "Admin address is invalid");
        nft = _nft;
        admin = _admin;
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _initializeEIP712(name);
        _pause();
    }

    modifier onlyAdmin() {
        require(_msgSender() == admin, "Only admin can call this function");
        _;
    }

    function mint(
        string memory _transactionId,
        uint256 _expirationBlock,
        address _receiver,
        uint256 _amount,
        uint256 _type
    ) external nonReentrant whenNotPaused onlyAdmin {
        require(block.number < _expirationBlock, "Meta transaction is expired");

        if (block.number - lastMint[_receiver] > BLOCK_PER_DAY) {
            require(_amount <= mintLimitPerDay, "Minting limit exceeded");
            mintAmount[_receiver] = 0; // reset amount
            lastMint[_receiver] = block.number;
        } else {
            require(mintAmount[_receiver] + _amount <= mintLimitPerDay, "Minting limit per day is exceeded");
        }

        mintAmount[_receiver] += _amount;

        for (uint256 i = 0; i < _amount; i++) {
            nft.mintTo(_receiver, _type);
        }

        emit Mint(_transactionId, _receiver, _amount, _type);
    }

    function pause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

    function setMintLimitPerDay(uint256 _limit) external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 _oldLimit = mintLimitPerDay;
        mintLimitPerDay = _limit;

        emit MintLimitPerDayChanged(_oldLimit, _limit);
    }

    function setAdmin(address _admin) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_admin != address(0), "Admin address is invalid");
        address _oldAdmin = admin;
        admin = _admin;

        emit AdminChanged(_oldAdmin, _admin);
    }

    function _msgSender() internal view override returns (address sender) {
        return ContextMixin.msgSender();
    }

    fallback() external {}
}