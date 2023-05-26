// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.7.6;

import "../../dependencies/openzeppelin/contracts/SafeMath.sol";
import "../../dependencies/openzeppelin/contracts/Ownable.sol";
import "../../dependencies/openzeppelin/contracts/ERC20Capped.sol";
import "../../dependencies/governance/TreasuryOwnable.sol";

contract PhiatToken is Ownable, ERC20Capped, TreasuryOwnable {
    using SafeMath for uint256;

    uint256 public immutable mintLockTime; // no more mint amount change
    // can mint between start time and expiration time
    uint256 public immutable mintStartTime;
    uint256 public immutable mintExpirationTime;

    mapping(address => uint256) private _mints;

    event Mint(
        address indexed minter,
        address indexed onBehalfOf,
        uint256 amount
    );

    constructor(
        string memory symbol,
        string memory name,
        uint256 mintLockTime_,
        uint256 mintStartTime_,
        uint256 mintExpirationTime_,
        address treasury_
    )
        Ownable()
        TreasuryOwnable(treasury_)
        ERC20(name, symbol)
        ERC20Capped(55555000000000000000000000)
    {
        require(
            mintLockTime_ < mintStartTime_,
            "PHIAT: Mint should not start before mint amounts are locked"
        );
        require(
            mintStartTime_ < mintExpirationTime_,
            "PHIAT: Mint Should not expire before it starts"
        );
        mintLockTime = mintLockTime_;
        mintStartTime = mintStartTime_;
        mintExpirationTime = mintExpirationTime_;

        uint256 maxSupply = 55555000000000000000000000;
        _mints[treasury_] = maxSupply;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal override {
        require(
            block.timestamp >= mintStartTime,
            "PHIAT: Cannot transfer before mint starts"
        );
        super._transfer(sender, recipient, amount);
    }

    function transferTreasury(
        address newTreasury
    ) external override onlyTreasury {
        require(
            newTreasury != address(0),
            "TreasuryOwnable: new treasury is the zero address"
        );
        // transfer mintable amount
        uint256 mintAmount = _mints[treasury()];
        if (mintAmount > 0) {
            delete _mints[treasury()];
            _mints[newTreasury] = _mints[newTreasury].add(mintAmount);
        }
        _transferTreasury(newTreasury);
    }

    function mintOf(address account) external view returns (uint256) {
        return _mints[account];
    }

    function mint() external {
        require(
            block.timestamp >= mintStartTime,
            "PHIAT: Cannot mint before mint started"
        );
        require(
            block.timestamp < mintExpirationTime,
            "PHIAT: Cannot mint after mint expired"
        );

        address sender = _msgSender();
        uint256 mintAmount = _mints[sender];
        require(mintAmount > 0, "PHIAT: nothing to mint");

        delete _mints[sender];
        _mint(sender, mintAmount);
        emit Mint(sender, sender, mintAmount);
    }

    function mintByTreasury(address account) external onlyTreasury {
        require(
            block.timestamp >= mintExpirationTime,
            "PHIAT: No expired token for treasury to mint before mint expired"
        );

        uint256 mintAmount = _mints[account];
        require(mintAmount > 0, "PHIAT: nothing to mint");

        delete _mints[account];
        _mint(treasury(), mintAmount);
        emit Mint(treasury(), account, mintAmount);
    }

    function setMint(address account, uint256 amount) external onlyOwner {
        require(
            block.timestamp < mintLockTime,
            "PHIAT: Cannot set mint amount after mint locked"
        );
        require(
            account != treasury(),
            "PHIAT: Should not adjust mint amount for treasury"
        );
        uint256 currentAmount = _mints[account];
        // adjust treasury's mintable amount
        _mints[treasury()] = _mints[treasury()].add(currentAmount).sub(
            amount,
            "PHIAT: amount exceeds maximum allowance"
        );
        // record new amount
        if (amount == 0) {
            delete _mints[account];
        } else {
            _mints[account] = amount;
        }
    }

    function setMints(
        address[] memory accounts,
        uint256[] memory amounts
    ) external onlyOwner {
        require(
            block.timestamp < mintLockTime,
            "PHIAT: Cannot set mint amount after mint locked"
        );
        require(accounts.length == amounts.length, "PHIAT: input mismatch");
        uint256 treasuryAmount = _mints[treasury()];
        for (uint256 i = 0; i < accounts.length; i++) {
            address account = accounts[i];
            uint256 amount = amounts[i];
            require(
                account != treasury(),
                "PHIAT: Should not adjust mint amount for treasury"
            );
            uint256 currentAmount = _mints[account];
            // adjust treasury's mintable amount
            treasuryAmount = treasuryAmount.add(currentAmount).sub(
                amount,
                "PHIAT: amount exceeds maximum allowance"
            );
            // record new amount
            if (amount == 0) {
                delete _mints[account];
            } else {
                _mints[account] = amount;
            }
        }
        // record new treasury amount
        _mints[treasury()] = treasuryAmount;
    }

    function addMint(address account, uint256 amount) external onlyOwner {
        require(
            block.timestamp < mintLockTime,
            "PHIAT: Cannot add mint amount after mint locked"
        );
        require(amount > 0, "PHIAT: Meaningless to add zero amount");
        require(
            account != treasury(),
            "PHIAT: Should not adjust mint amount for treasury"
        );

        // adjust treasury's mintable amount
        _mints[treasury()] = _mints[treasury()].sub(
            amount,
            "PHIAT: amount exceeds maximum allowance"
        );
        // record new amount
        _mints[account] = _mints[account].add(amount);
    }
}