// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";


contract GloryToken is ERC20Upgradeable, PausableUpgradeable, AccessControlUpgradeable {

    uint256 public constant  MAX_SUPPLY = 150_000_000 * 10 ** 18;

    uint256 public constant  MAX_SUPPLY_PUBLIC = 135_000_000 * 10 ** 18;

    uint256 public constant  MAX_SUPPLY_TEAM = 15_000_000 * 10 ** 18;

    uint256 public constant TIME_MINT_TO_TEAM = 1707238111;//Tue, 06 Feb 2024 16:48:31 GMT

    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    bytes32 public constant OPERATOR_TEAM = keccak256("OPERATOR_TEAM");

    mapping(address => bool) public dexes;

    address public  receiveFeeAddress;

    bool public teamMinted;

    event DexAddressAdded(address dexAddress);

    event DexAddressRemoved(address dexAddress);

    modifier onlyOperator {
      require(hasRole(OPERATOR_ROLE, _msgSender()), "Must have OPERATOR_ROLE role");
      _;
    }
    modifier onlyOperatorTeam {
      require(hasRole(OPERATOR_TEAM, _msgSender()), "must have OPERATOR_TEAM role");
      _;
    }

    function initialize()
        public
        initializer
    {
        __ERC20_init("Glory", "GLR");
    }
    function pause() public onlyOperator {
        _pause();
    }

    function unpause() public onlyOperator {
        _unpause();
    }
    function mintToTeam(address to) public onlyOperatorTeam {
        require(!teamMinted, "Team minted");
        require(block.timestamp >= TIME_MINT_TO_TEAM, "Time mint invalid");
        teamMinted = true;
        super._mint(to, MAX_SUPPLY_TEAM);
    }

    function mintPublic(address to, uint256 amount) public onlyOperator{
        require(totalSupply() + amount <= MAX_SUPPLY_PUBLIC, "Total supply over max supply public");
        super._mint(to, amount);
    }

    function _transfer(address sender, address receiver, uint256 amount) internal virtual override {
        if (dexes[sender] || dexes[receiver]) {
            _receiveToken(sender, receiver, amount);
        } else {
            super._transfer(sender, receiver, amount);
        }
    }


    function _receiveToken(address from,
        address to,
        uint256 amount) private {
        uint256 balance = balanceOf(from);
        require(amount <= balance, "Balance not enough");
        uint256 amountTransfer = amount * 99 / 100;
        uint256 amountFee = amount- amountTransfer;
        super._transfer(from, receiveFeeAddress, amountFee);
        super._transfer(from, to, amountTransfer);
    }

    function setReceiveFeeAddress(address _receiveFeeAddress) external onlyOperator{
        require(_receiveFeeAddress != address(0),"Receive fee addresses cannot be zero address");
        receiveFeeAddress = _receiveFeeAddress;
    }


    function addDexAddress(address dex) external onlyOperator{
        dexes[dex] = true;
        emit DexAddressAdded(dex);
    }
    function removeDexAddress(address dex) external onlyOperator{
        dexes[dex] = false;
        emit DexAddressRemoved(dex);
    }

    function mintAirdrop() public onlyOperator {}
}