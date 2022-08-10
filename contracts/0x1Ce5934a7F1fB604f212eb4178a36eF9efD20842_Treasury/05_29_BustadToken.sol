// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "./WithFee.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";

contract BustadToken is ERC20, ERC20Burnable, AccessControl, WithFee, Pausable, ERC20Permit {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant MAINTAINER_ROLE = keccak256("MAINTAINER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    address public feeCollector;

    constructor(
        string memory name,
        string memory symbol,
        uint256 initialSupply,
        uint256 transferFee,
        uint256 mintingFee,
        address _feeCollector,
        FeeType transferFeeType,
        FeeType mintingFeeType
    )
        ERC20(name, symbol)
        WithFee(transferFee, mintingFee, transferFeeType, mintingFeeType)
        ERC20Permit(name)
    {
        require(_feeCollector != address(0), "feeCollector is zero address");

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _mint(msg.sender, initialSupply);
        feeCollector = _feeCollector;
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function mint(address to, uint256 amount) public onlyRole(MINTER_ROLE) {
        uint256 mintingFee = _calculateMintingFee(amount);
        amount -= mintingFee;

        if (mintingFee > 0) {
            _mint(feeCollector, mintingFee);
        }

        _mint(to, amount);
    }

    function transfer(address to, uint256 amount)
        public
        override
        returns (bool)
    {
        address owner = _msgSender();
        uint256 transferFee = _calculateTransferFee(amount);

        amount -= transferFee;

        if (transferFee > 0) {
            _transfer(owner, feeCollector, transferFee);
        }

        _transfer(owner, to, amount);

        return true;
    }

    function setFeeCollector(address _feeCollector)
        external
        onlyRole(MAINTAINER_ROLE)
    {
        feeCollector = _feeCollector;
    }

    function pause() external onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function calculateMintingFee(uint256 amount)
        external
        view
        returns (uint256)
    {
        return _calculateMintingFee(amount);
    }

    function setMintingFee(uint256 _fee) external onlyRole(MAINTAINER_ROLE) {
        _setMintingFee(_fee);
    }

    function setMintingFeeType(FeeType feeType)
        external
        onlyRole(MAINTAINER_ROLE)
    {
        _setMintingFeeType(feeType);
    }

    function setTransferFee(uint256 _fee) external onlyRole(MAINTAINER_ROLE) {
        _setTransferFee(_fee);
    }

    function setTransferFeeType(FeeType _feeType)
        external
        onlyRole(MAINTAINER_ROLE)
    {
        _setTransferFeeType(_feeType);
    }

    function getMintingFee() external view returns (uint256) {
        return _mintingFee;
    }

    function getTransferFee() external view returns (uint256) {
        return _transferFee;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override whenNotPaused {
        super._beforeTokenTransfer(from, to, amount);
    }
}