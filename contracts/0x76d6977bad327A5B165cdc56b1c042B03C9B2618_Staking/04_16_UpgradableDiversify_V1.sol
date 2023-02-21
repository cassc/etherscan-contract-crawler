// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;
import '@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol';
import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';
import '../interfaces/IERC20UpgradeableBurnable.sol';

/**
 * @title Contract for the ERC20 Diversify token
 * @author Diversify.io
 * @notice This contract handles the implementation fo the Diversify token
 */
contract UpgradableDiversify_V1 is Initializable, ERC20Upgradeable, OwnableUpgradeable, IERC20UpgradeableBurnable {
    // Foundation Events
    event FoundationChanged(address indexed previousAddress, address indexed newAddress);
    event FoundationRateChanged(uint256 previousRate, uint256 newRate);

    // Community Events
    event CommunityChanged(address indexed previousAddress, address indexed newAddress);
    event CommunityRateChanged(uint256 previousRate, uint256 newRate);

    // Immutable burn stop supply
    uint256 private constant BURN_STOP_SUPPLY = 45000000 * 10**18;

    // the address of the foundation
    address private _foundation;

    // the rate that goes to the foundation per transaction
    uint256 private _foundationRate;

    // the address of the community
    address private _community;

    // the rate that goes to the community per transaction
    uint256 private _communityRate;

    // total burned amount
    uint256 private _amountBurned;

    // total amount transfered to foundation
    uint256 private _amountFounded;

    // total amount transfered to community
    uint256 private _amountCommunity;

    /**
     * Initialize
     */
    function initialize(
        address[] memory addresses,
        uint256[] memory amounts,
        address foundation_,
        address community_
    ) public initializer {
        __ERC20_init('Diversify', 'DIV');
        __Ownable_init();

        // loop through the addresses array and send tokens to each address
        // the corresponding amount to sent is taken from the amounts array
        for (uint8 i = 0; i < addresses.length; i++) {
            _mint(addresses[i], amounts[i] * 10**18);
        }

        // Set foundation rate (25 basis points = 0.25 pct)
        _foundationRate = 25;
        _foundation = foundation_;

        // Set community rate (100 basis points = 1 pct)
        _communityRate = 100;
        _community = community_;
    }

    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual override returns (bool) {
        _burn(_msgSender(), amount);
        return true;
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual override returns (bool) {
        uint256 currentAllowance = allowance(account, _msgSender());
        require(currentAllowance >= amount, 'ERC20: burn amount exceeds allowance');
        unchecked {
            _approve(account, _msgSender(), currentAllowance - amount);
        }
        _burn(account, amount);
        return true;
    }

    /**
     * @dev Returns the address of the community.
     */
    function community() public view returns (address) {
        return _community;
    }

    /**
     * @dev Returns the address of the foundation.
     */
    function foundation() public view returns (address) {
        return _foundation;
    }

    /**
     * @dev Returns the rate of the community.
     */
    function communityRate() public view returns (uint256) {
        return _communityRate;
    }

    /**
     * @dev Returns the rate of the foundation.
     */
    function foundationRate() public view returns (uint256) {
        return _foundationRate;
    }

    /**
     * @dev Returns the amount of tokens transfered to community
     */
    function amountCommunity() public view returns (uint256) {
        return _amountCommunity;
    }

    /**
     * @dev Returns the amount of tokens, transfered to the foundation
     */
    function amountFounded() public view returns (uint256) {
        return _amountFounded;
    }

    /**
     * @dev Returns the amount of burned tokens
     */
    function amountBurned() public view returns (uint256) {
        return _amountBurned;
    }

    /**
     * @dev Sets the address of the foundation wallet.
     */
    function setFoundation(address newAddress) public onlyOwner {
        address oldWallet = _foundation;
        _foundation = newAddress;
        emit FoundationChanged(oldWallet, newAddress);
    }

    /**
     * @dev Sets the foundation rate, maximal allowance of 250 basis points (2.5 pct)
     */
    function setFoundationRate(uint256 newRate) public onlyOwner {
        require(newRate > 0 && newRate <= 250);
        uint256 oldRate = _foundationRate;
        _foundationRate = newRate;
        emit FoundationRateChanged(oldRate, newRate);
    }

    /**
     * @dev Sets the address of the community wallet.
     */
    function setCommunity(address newAddress) public onlyOwner {
        address oldCommunity = _community;
        _community = newAddress;
        emit CommunityChanged(oldCommunity, newAddress);
    }

    /**
     * @dev Sets the comunity rate, maximal allowance of 250 basis points (2.5 pct)
     */
    function setCommunityRate(uint256 newRate) public onlyOwner {
        require(newRate > 0 && newRate <= 250);
        uint256 oldRate = _communityRate;
        _communityRate = newRate;
        emit CommunityRateChanged(oldRate, newRate);
    }

    /**
     * @dev Returns the burn stop supply.
     */
    function burnStopSupply() public pure returns (uint256) {
        return BURN_STOP_SUPPLY;
    }

    /**
     * Extend transfer with limit burn, foundation and community
     */
    function _transfer(
        address from,
        address to,
        uint256 value
    ) internal override {
        uint256 tFound = (value * _foundationRate) / 10**4;
        uint256 tCommunity = (value * _communityRate) / 10**4;
        uint256 tBurn = 0;

        // Burn
        if (totalSupply() != BURN_STOP_SUPPLY) {
            tBurn = value / 100; // 1 pct per transaction
            // Reduce burn amount to burn limit
            if (totalSupply() < BURN_STOP_SUPPLY + value) {
                tBurn = totalSupply() - BURN_STOP_SUPPLY;
            }
            _burn(from, tBurn);
        }

        // Transfer to foundation, community and receiver
        super._transfer(from, _foundation, tFound);
        super._transfer(from, _community, tCommunity);
        super._transfer(from, to, value - tFound - tCommunity - tBurn);

        // Update amounts
        _amountFounded += tFound;
        _amountCommunity += tCommunity;
    }

    /**
     * Extend burn with  burn limit
     */
    function _burn(address account, uint256 amount) internal override {
        require(!(totalSupply() < BURN_STOP_SUPPLY + amount), 'burn overreaches burn stop supply');
        super._burn(account, amount);
        _amountBurned += amount;
    }
}