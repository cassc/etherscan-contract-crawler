// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import {ERC20} from "openzeppelin/token/ERC20/ERC20.sol";
import {ERC20Burnable} from "openzeppelin/token/ERC20/extensions/ERC20Burnable.sol";
import {AccessControl} from "openzeppelin/access/AccessControl.sol";

contract Kuma is ERC20, ERC20Burnable, AccessControl {
    event BlacklistUpdated(address indexed _address, bool _isBlacklisting);

    uint256 public constant MAX_SUPPLY = 5e15 ether;
    uint256 public constant LIQUIDITY_SUPPLY = 2.5e15 ether;
    uint256 public constant INITIAL_SUPPLY = 2e10 ether;
    uint256 public constant AIRDROP_MINIMUM_TRANSFER_REQUIREMENT = 3e9 ether;
    uint256 public constant AIRDROP_RECIPIENT_ETH_REQUIREMENT = 0.005 ether;
    uint256 public constant AIRDROP_WHALE_THRESHOLD = 5e10 ether;
    uint256 public constant AIRDROP_HOLDER_THRESHOLD = 30000;
    bytes32 public constant GUARD_ROLE = keccak256("GUARD_ROLE");
    bytes32 public constant LIQUIDITY_ROLE = keccak256("LIQUIDITY_ROLE");

    uint128 public totalMint = 0;
    uint128 public airdropCount = 0;
    uint128 public holderCountBeforeThreshold = 0;
    bool public airdropHolderThresholdReached = false;
    bool public liquidityMinted = false;
    mapping(address => bool) public blacklists;
    mapping(address => bool) public holdHistory;

    constructor(address _admin, address _genesis) ERC20("Kuma", "KUMA") {
        _grantRole(DEFAULT_ADMIN_ROLE, _admin);
        _mint(_genesis, INITIAL_SUPPLY);
    }

    function blacklist(address _address, bool _isBlacklisting) external onlyRole(GUARD_ROLE) {
        blacklists[_address] = _isBlacklisting;
        emit BlacklistUpdated(_address, _isBlacklisting);
    }

    /**
     * All minted tokens are used for providing liquidity.
     */
    function mintLiquidity() external onlyRole(LIQUIDITY_ROLE) {
        if (!liquidityMinted) {
            liquidityMinted = true;
            super._mint(_msgSender(), LIQUIDITY_SUPPLY);
        }
    }

    function isAirdropEnded() public view returns (bool) {
        return airdropHolderThresholdReached || totalMint >= (MAX_SUPPLY - LIQUIDITY_SUPPLY);
    }

    function _getAirdropAmount() internal view returns (uint256) {
        if (airdropCount < 1000) {
            return 2e10 ether;
        } else if (airdropCount < 20000) {
            return 1e10 ether;
        } else {
            return 5e9 ether;
        }
    }

    function _mint(address account, uint256 amount) internal virtual override {
        unchecked {
            totalMint += uint128(amount);
        }
        super._mint(account, amount);
    }

    function _beforeTokenTransfer(address _from, address _to, uint256 _amount) internal override {
        require(!blacklists[_from], "Kuma: sender is blacklisted");
        require(!blacklists[_to], "Kuma: recipient is blacklisted");

        if (_amount > 0 && !airdropHolderThresholdReached) {
            if (_to != address(0) && balanceOf(_to) == 0) {
                holderCountBeforeThreshold++;
                holdHistory[_to] = true;
                if (holderCountBeforeThreshold == AIRDROP_HOLDER_THRESHOLD) {
                    airdropHolderThresholdReached = true;
                }
            } else if (_from != address(0) && balanceOf(_from) == _amount) {
                holderCountBeforeThreshold--;
            }
        }

        super._beforeTokenTransfer(_from, _to, _amount);
    }

    function _transfer(address _from, address _to, uint256 _amount) internal override {
        bool hasAirdrop = false;
        if (
            !isAirdropEnded() &&
            !holdHistory[_to] &&
            _amount >= AIRDROP_MINIMUM_TRANSFER_REQUIREMENT &&
            _to.balance >= AIRDROP_RECIPIENT_ETH_REQUIREMENT &&
            balanceOf(_from) < AIRDROP_WHALE_THRESHOLD
        ) {
            hasAirdrop = true;
        }

        super._transfer(_from, _to, _amount);

        if (hasAirdrop) {
            _mint(_from, _getAirdropAmount());
            airdropCount++;
        }
    }
}