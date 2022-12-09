//SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

import "../interfaces/IByalanIsland.sol";
import "../interfaces/IGasPrice.sol";

abstract contract ByalanIsland is Ownable, Pausable, IByalanIsland {
    address public hydra;
    address public unirouter;
    address public override izlude;
    address public kswFeeRecipient;
    address public treasuryFeeRecipient;
    address public harvester;

    address public gasPrice = 0xc558252b50920a21f4AE3225E1Ed7D250E5D5593;

    event SetHydra(address hydra);
    event SetRouter(address router);
    event SetKswFeeRecipient(address kswFeeRecipient);
    event SetTreasuryFeeRecipient(address treasuryFeeRecipient);
    event SetHarvester(address harvester);
    event SetGasPrice(address gasPrice);

    constructor(
        address _hydra,
        address _unirouter,
        address _izlude,
        address _kswFeeRecipient,
        address _treasuryFeeRecipient,
        address _harvester
    ) {
        hydra = _hydra;
        unirouter = _unirouter;
        izlude = _izlude;
        kswFeeRecipient = _kswFeeRecipient;
        treasuryFeeRecipient = _treasuryFeeRecipient;
        harvester = _harvester;
    }

    // checks that caller is either owner or hydra.
    modifier onlyHydra() {
        require(msg.sender == owner() || msg.sender == hydra, "!hydra");
        _;
    }

    // verifies that the caller is not a contract.
    modifier onlyEOA() {
        require(msg.sender == tx.origin, "!EOA");
        _;
    }

    modifier onlyIzlude() {
        require(msg.sender == izlude, "!izlude");
        _;
    }

    modifier onlyEOAandIzlude() {
        require(tx.origin == msg.sender || msg.sender == izlude, "!contract");
        _;
    }

    modifier onlyHarvester() {
        require(harvester == address(0) || msg.sender == harvester, "!harvester");
        _;
    }

    modifier gasThrottle() {
        require(tx.gasprice <= IGasPrice(gasPrice).maxGasPrice(), "gas is too high!");
        _;
    }

    function setHydra(address _hydra) external onlyHydra {
        hydra = _hydra;
        emit SetHydra(_hydra);
    }

    function setUnirouter(address _unirouter) external onlyOwner {
        unirouter = _unirouter;
        emit SetRouter(_unirouter);
    }

    function setIzlude(address _izlude) external onlyOwner {
        require(izlude == address(0), "already set");
        izlude = _izlude;
    }

    function setTreasuryFeeRecipient(address _treasuryFeeRecipient) external onlyOwner {
        treasuryFeeRecipient = _treasuryFeeRecipient;
        emit SetTreasuryFeeRecipient(_treasuryFeeRecipient);
    }

    function setKswFeeRecipient(address _kswFeeRecipient) external onlyOwner {
        kswFeeRecipient = _kswFeeRecipient;
        emit SetKswFeeRecipient(_kswFeeRecipient);
    }

    function setHarvester(address _harvester) external onlyOwner {
        harvester = _harvester;
        emit SetHarvester(_harvester);
    }

    function setGasPrice(address _gasPrice) external onlyHydra {
        gasPrice = _gasPrice;
        emit SetGasPrice(_gasPrice);
    }
}