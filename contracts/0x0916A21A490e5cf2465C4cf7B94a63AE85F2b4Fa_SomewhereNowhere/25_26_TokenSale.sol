// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import './interfaces/ITokenSale.sol';
import './Pausable.sol';
import './Roles.sol';

abstract contract TokenSale is ITokenSale, Pausable, Roles {
    uint256 private immutable _globalSupply;
    uint256 private _globalMinted;

    uint256 private immutable _reserveSupply;
    uint256 private _reserveMinted;

    mapping(uint256 => SaleConfig) private _saleConfigs;
    mapping(uint256 => uint256) private _saleMinted;
    mapping(uint256 => mapping(address => uint256)) private _walletMinted;

    constructor(uint256 globalSupply, uint256 reserveSupply) {
        _globalSupply = globalSupply;
        _reserveSupply = reserveSupply;
    }

    modifier saleIsActive(uint256 saleId) virtual {
        if (isPaused()) revert SaleIsPaused();
        if (!_saleHasBegun(saleId)) revert SaleHasNotBegun();
        if (!_saleHasNotEnded(saleId)) revert SaleHasEnded();
        _;
    }

    function addSale(
        uint256 saleId,
        uint256 saleSupply,
        uint256 walletSupply,
        uint256 transactionSupply,
        uint256 beginBlock,
        uint256 endBlock
    ) public virtual override onlyController {
        _saleConfigs[saleId] = SaleConfig(
            uint64(saleSupply),
            uint64(walletSupply),
            uint64(transactionSupply),
            uint32(beginBlock),
            uint32(endBlock)
        );

        emit SaleAdded(
            saleId,
            saleSupply,
            walletSupply,
            transactionSupply,
            beginBlock,
            endBlock
        );
    }

    function pause() public virtual override onlyController {
        _pause();
    }

    function removeSale(uint256 saleId) public virtual override onlyController {
        delete _saleConfigs[saleId];

        emit SaleRemoved(saleId);
    }

    function unpause() public virtual override onlyController {
        _unpause();
    }

    function getGlobalSupply() public view virtual override returns (uint256) {
        return _globalSupply;
    }

    function getReserveSupply() public view virtual override returns (uint256) {
        return _reserveSupply;
    }

    function getStatus(uint256 saleId, address wallet)
        public
        view
        virtual
        override
        returns (Status memory)
    {
        Status memory status;
        status.globalSupply = _globalSupply;
        status.globalMinted = _globalMinted;
        status.reserveSupply = _reserveSupply;
        status.reserveMinted = _reserveMinted;
        SaleConfig memory saleConfig = _saleConfigs[saleId];
        status.saleSupply = saleConfig.saleSupply;
        status.saleMinted = _saleMinted[saleId];
        status.walletSupply = saleConfig.walletSupply;
        status.walletMinted = _walletMinted[saleId][wallet];
        status.transactionSupply = saleConfig.transactionSupply;
        status.beginBlock = saleConfig.beginBlock;
        status.endBlock = saleConfig.endBlock;
        status.currentBlock = block.number;
        status.isActive = _saleIsActive(saleId);
        return status;
    }

    function _mintReserve(uint256 quantity) internal virtual {
        uint256 reserveMinted = _reserveMinted + quantity;
        if (reserveMinted > _reserveSupply) revert MintExceedsReserveSupply();

        uint256 globalMinted = _globalMinted + quantity;
        if (globalMinted > _globalSupply) revert MintExceedsGlobalSupply();

        _reserveMinted = reserveMinted;
        _globalMinted = globalMinted;
    }

    function _mintSale(uint256 quantity, uint256 saleId)
        internal
        virtual
        saleIsActive(saleId)
    {
        if (quantity > _saleConfigs[saleId].transactionSupply)
            revert MintExceedsTransactionSupply();

        uint256 walletMinted = _walletMinted[saleId][_msgSender()] + quantity;
        if (walletMinted > _saleConfigs[saleId].walletSupply)
            revert MintExceedsWalletSupply();

        uint256 saleMinted = _saleMinted[saleId] + quantity;
        if (saleMinted > _saleConfigs[saleId].saleSupply)
            revert MintExceedsSaleSupply();

        uint256 globalMinted = _globalMinted + quantity;
        if (globalMinted + _reserveSupply - _reserveMinted > _globalSupply)
            revert MintExceedsGlobalSupply();

        _walletMinted[saleId][_msgSender()] = walletMinted;
        _saleMinted[saleId] = saleMinted;
        _globalMinted = globalMinted;
    }

    function _saleHasBegun(uint256 saleId)
        internal
        view
        virtual
        returns (bool)
    {
        return block.number >= _saleConfigs[saleId].beginBlock;
    }

    function _saleHasNotEnded(uint256 saleId)
        internal
        view
        virtual
        returns (bool)
    {
        return block.number < _saleConfigs[saleId].endBlock;
    }

    function _saleIsActive(uint256 saleId)
        internal
        view
        virtual
        returns (bool)
    {
        return !isPaused() && _saleHasBegun(saleId) && _saleHasNotEnded(saleId);
    }
}