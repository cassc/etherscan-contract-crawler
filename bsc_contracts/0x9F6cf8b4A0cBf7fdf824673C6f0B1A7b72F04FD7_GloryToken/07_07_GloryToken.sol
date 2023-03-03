// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract GloryToken is ERC20, Ownable, Pausable {
    uint256 public constant MAX_SUPPLY = 150_000_000 * 10 ** 18;
    uint256 public constant MAX_COMMUNITY_SUPPLY = 105_000_000 * 10 ** 18;
    uint256 public constant MAX_TEAM_SUPPLY = 15_000_000 * 10 ** 18;
    uint256 public constant COMPANY_RESERVE_AMOUNT = 11_250_000 * 10 ** 18;
    uint256 public constant LIQUIDITY_AMOUNT = 3_375_000 * 10 ** 18;
    uint256 public constant OG_AIRDROP_AMOUNT = 125_000 * 10 ** 18;
    uint256 public constant AIRDROP_AMOUNT = 250_000 * 10 ** 18;
    uint256 public constant WHITELIST_SALE_AMOUNT = 15_000_000 * 10 ** 18;

    uint256 public constant TIME_MINT_TO_TEAM = 1709391066; //Saturday, March 2, 2024 2:51:06 PM GMT

    uint256 public aidropDistributed;
    uint256 public whitelistSaleDistributed;
    uint256 public initialSupplyMinted;

    mapping(address => bool) public dexes;

    address public receiveFeeAddress;
    address public treasuryContract;

    bool public teamMinted;

    event TreasuryContractChanged(
        address indexed previusAAddress,
        address indexed newAddress
    );

    event DexAddressAdded(address dexAddress);

    event DexAddressRemoved(address dexAddress);

    modifier onlyTreasury() {
        require(_msgSender() == treasuryContract, "Only Treasury");
        _;
    }

    constructor(string memory name, string memory symbol) ERC20(name, symbol) {}

    function mintToTeam(address _receiver) external onlyOwner {
        require(!teamMinted, "Team minted");
        require(block.timestamp >= TIME_MINT_TO_TEAM, "Time mint invalid");
        teamMinted = true;
        _mint(_receiver, MAX_TEAM_SUPPLY);
    }

    // mint initial token for marketing, liquidity and OG airdrop
    function mintInitialSupply(address _receiver, uint256 _amount) external onlyOwner {
        require(initialSupplyMinted + _amount <= COMPANY_RESERVE_AMOUNT + LIQUIDITY_AMOUNT + OG_AIRDROP_AMOUNT, "exceeds max initial supply");
        _mint(_receiver, _amount);
    }

    function mint(address _receiver, uint256 _amount) external onlyTreasury {
        require(
            totalSupply() + _amount <= MAX_SUPPLY,
            "Total supply over max supply public"
        );
        _mint(_receiver, _amount);
    }

    function distributeAirdrop(
        address[] memory _receivers,
        uint256 _value
    ) external onlyOwner {
        aidropDistributed = aidropDistributed + (_receivers.length * _value);
        require(
            aidropDistributed <= AIRDROP_AMOUNT,
            "exceeds max airdrop amount"
        );
        for (uint i = 0; i < _receivers.length; i++) {
            super._mint(_receivers[i], _value);
            emit Transfer(address(0), _receivers[i], _value);
        }
    }

    function distributeWhitelistSale(
        address _receiver,
        uint256 _value
    ) external onlyOwner {
        whitelistSaleDistributed = whitelistSaleDistributed + _value;
        require(
            whitelistSaleDistributed <= WHITELIST_SALE_AMOUNT,
            "exceeds max whitelist sale amount"
        );
        super._mint(_receiver, _value);
        emit Transfer(address(0), _receiver, _value);
    }

    function setTreasuryAddress(address _newAddress) external onlyOwner {
        emit TreasuryContractChanged(treasuryContract, _newAddress);
        treasuryContract = _newAddress;
    }

    function setReceiveFeeAddress(
        address _receiveFeeAddress
    ) external onlyOwner {
        require(
            _receiveFeeAddress != address(0),
            "Receive fee addresses cannot be zero address"
        );
        receiveFeeAddress = _receiveFeeAddress;
    }

    function addDexAddress(address dex) external onlyOwner {
        dexes[dex] = true;
        emit DexAddressAdded(dex);
    }

    function removeDexAddress(address dex) external onlyOwner {
        dexes[dex] = false;
        emit DexAddressRemoved(dex);
    }

    // Owner can drain tokens that are sent here by mistake
    function drainBEP20Token(
        IERC20 _token,
        uint256 _amount,
        address _to
    ) external onlyOwner {
        _token.transfer(_to, _amount);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function _transfer(
        address sender,
        address receiver,
        uint256 amount
    ) internal virtual override {
        if (dexes[sender] || dexes[receiver]) {
            _receiveToken(sender, receiver, amount);
        } else {
            super._transfer(sender, receiver, amount);
        }
    }

    function _receiveToken(address from, address to, uint256 amount) private {
        uint256 balance = balanceOf(from);
        require(amount <= balance, "Balance not enough");
        uint256 amountTransfer = (amount * 99) / 100;
        uint256 amountFee = amount - amountTransfer;
        super._transfer(from, receiveFeeAddress, amountFee);
        super._transfer(from, to, amountTransfer);
    }
}