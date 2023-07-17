/*
██   ██ ██████   █████   ██████      ██      ██████  
 ██ ██  ██   ██ ██   ██ ██    ██     ██      ██   ██ 
  ███   ██   ██ ███████ ██    ██     ██      ██████  
 ██ ██  ██   ██ ██   ██ ██    ██     ██      ██      
██   ██ ██████  ██   ██  ██████      ███████ ██      
*/
// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "../interfaces/IDao.sol";

contract LP is ReentrancyGuard, ERC20, ERC20Permit {
    address public immutable dao;

    address public immutable shop;

    bool public mintable = true;
    bool public burnable = true;
    bool public mintableStatusFrozen = false;
    bool public burnableStatusFrozen = false;

    constructor(
        string memory _name,
        string memory _symbol,
        address _dao
    ) ERC20(_name, _symbol) ERC20Permit(_name) {
        dao = _dao;
        shop = msg.sender;
    }

    modifier onlyDao() {
        require(msg.sender == dao, "LP: caller is not the dao");
        _;
    }

    modifier onlyShop() {
        require(msg.sender == shop, "LP: caller is not the shop");
        _;
    }

    function mint(address _to, uint256 _amount)
        external
        onlyShop
        returns (bool)
    {
        require(mintable, "LP: minting is disabled");
        _mint(_to, _amount);
        return true;
    }

    function burn(
        uint256 _amount,
        address[] memory _tokens,
        address[] memory _adapters,
        address[] memory _pools
    ) external nonReentrant returns (bool) {
        require(burnable, "LP: burning is disabled");
        require(msg.sender != dao, "LP: DAO can't burn LP");
        require(_amount <= balanceOf(msg.sender), "LP: insufficient balance");
        require(totalSupply() > 0, "LP: Zero share");

        uint256 _share = (1e18 * _amount) / (totalSupply());

        _burn(msg.sender, _amount);

        bool b = IDao(dao).burnLp(
            msg.sender,
            _share,
            _tokens,
            _adapters,
            _pools
        );

        require(b, "LP: burning error");

        return true;
    }

    function changeMintable(bool _mintable) external onlyDao returns (bool) {
        require(!mintableStatusFrozen, "LP: minting status is frozen");
        mintable = _mintable;
        return true;
    }

    function changeBurnable(bool _burnable) external onlyDao returns (bool) {
        require(!burnableStatusFrozen, "LP: burnable status is frozen");
        burnable = _burnable;
        return true;
    }

    function freezeMintingStatus() external onlyDao returns (bool) {
        mintableStatusFrozen = true;
        return true;
    }

    function freezeBurningStatus() external onlyDao returns (bool) {
        burnableStatusFrozen = true;
        return true;
    }
}