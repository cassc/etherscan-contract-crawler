// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ARTHValuecoin is Ownable, ERC20, ERC20Permit {
    constructor() ERC20("ARTH Valuecoin", "ARTH") ERC20Permit("ARTH") {}

    mapping (address => bool) public borrowerOperationAddresses;
    mapping (address => bool) public troveManagerAddresses;
    mapping (address => bool) public stabilityPoolAddresses;

    // --- Events ---
    event BorrowerOperationsAddressToggled(address indexed boAddress, bool oldFlag, bool newFlag, uint256 timestamp);
    event TroveManagerToggled(address indexed tmAddress, bool oldFlag, bool newFlag, uint256 timestamp);
    event StabilityPoolToggled(address indexed spAddress, bool oldFlag, bool newFlag, uint256 timestamp);

    function toggleBorrowerOperations(address borrowerOperations) external onlyOwner {
        bool oldFlag = borrowerOperationAddresses[borrowerOperations];
        borrowerOperationAddresses[borrowerOperations] = !oldFlag;
        emit BorrowerOperationsAddressToggled(borrowerOperations, oldFlag, !oldFlag, block.timestamp);
    }

    function toggleTroveManager(address troveManager) external onlyOwner {
        bool oldFlag = troveManagerAddresses[troveManager];
        troveManagerAddresses[troveManager] = !oldFlag;
        emit TroveManagerToggled(troveManager, oldFlag, !oldFlag, block.timestamp);
    }

    function toggleStabilityPool(address stabilityPool) external onlyOwner {
        bool oldFlag = stabilityPoolAddresses[stabilityPool];
        stabilityPoolAddresses[stabilityPool] = !oldFlag;
        emit StabilityPoolToggled(stabilityPool, oldFlag, !oldFlag, block.timestamp);
    }

    // --- Functions for intra-Liquity calls ---

    function mint(address _account, uint256 _amount) external {
        _requireCallerIsBorrowerOperations();
        _mint(_account, _amount);
    }

    function burn(address _account, uint256 _amount) external {
        _requireCallerIsBOorTroveMorSP();
        _burn(_account, _amount);
    }

    function sendToPool(address _sender,  address _poolAddress, uint256 _amount) external {
        _requireCallerIsStabilityPool();
        _transfer(_sender, _poolAddress, _amount);
    }

    function returnFromPool(address _poolAddress, address _receiver, uint256 _amount) external {
        _requireCallerIsTroveMorSP();
        _transfer(_poolAddress, _receiver, _amount);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);
        require(address(to) != address(this), "dont send to token contract");
    }

    // --- 'require' functions ---

    function _requireValidRecipient(address _recipient) internal view {
        require(
            _recipient != address(0) &&
            _recipient != address(this),
            "ARTH: Cannot transfer tokens directly to the ARTH token contract or the zero address"
        );
        require(
            !stabilityPoolAddresses[_recipient] &&
            !troveManagerAddresses[_recipient] &&
            !borrowerOperationAddresses[_recipient],
            "ARTH: Cannot transfer tokens directly to the StabilityPool, TroveManager or BorrowerOps"
        );
    }

    function _requireCallerIsBorrowerOperations() internal view {
        require(borrowerOperationAddresses[msg.sender], "ARTH: Caller is not BorrowerOperations");
    }

    function _requireCallerIsBOorTroveMorSP() internal view {
        require(
           borrowerOperationAddresses[msg.sender] ||
           troveManagerAddresses[msg.sender] ||
           stabilityPoolAddresses[msg.sender],
            "ARTH: Caller is neither BorrowerOperations nor TroveManager nor StabilityPool"
        );
    }

    function _requireCallerIsStabilityPool() internal view {
        require(stabilityPoolAddresses[msg.sender], "ARTH: Caller is not the StabilityPool");
    }

    function _requireCallerIsTroveMorSP() internal view {
        require(
            troveManagerAddresses[msg.sender] || stabilityPoolAddresses[msg.sender],
            "ARTH: Caller is neither TroveManager nor StabilityPool");
    }
}