//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IFactory.sol";

contract LimitedTokenV3 is ERC20, Ownable {
    mapping(address => bool) public isTransferLimited;

    mapping(address => bool) public isAmmPair;

    address[] private _transferLimited;

    mapping(address => bool) public isSaleLimited;

    address[] private _saleLimited;

    bool public isGlobalSaleLimited;

    // EVENTS

    event TransferLimitedSet(address account, bool isLimited);

    event SaleLimitedSet(address account, bool isLimited);

    // CONSTRUCTOR

    constructor(
        string memory name,
        string memory symbol,
        uint256 totalSupply,
        address admin,
        IFactory factory,
        address[] memory limitedTokens
    ) ERC20(name, symbol) Ownable() {
        _mint(admin, totalSupply * 10**decimals());

        for (uint256 i = 0; i < limitedTokens.length; i++) {
            address pair = factory.createPair(address(this), limitedTokens[i]);
            setAmmPair(pair, true);
        }

        transferOwnership(admin);
    }

    // RESTRICTED

    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }

    function setTransferLimited(address account, bool isLimited)
        external
        onlyOwner
    {
        require(
            isLimited != isTransferLimited[account],
            "Already in this state"
        );

        isTransferLimited[account] = isLimited;

        emit TransferLimitedSet(account, isLimited);

        if (isLimited) {
            _transferLimited.push(account);
        } else {
            for (uint256 i = 0; i < _transferLimited.length; i++) {
                if (_transferLimited[i] == account) {
                    _transferLimited[i] = _transferLimited[
                        _transferLimited.length - 1
                    ];
                    _transferLimited.pop();
                    return;
                }
            }
        }
    }

    function setSaleLimited(address account, bool isLimited)
        external
        onlyOwner
    {
        require(isLimited != isSaleLimited[account], "Already in this state");

        isSaleLimited[account] = isLimited;

        emit SaleLimitedSet(account, isLimited);

        if (isLimited) {
            _saleLimited.push(account);
        } else {
            for (uint256 i = 0; i < _saleLimited.length; i++) {
                if (_saleLimited[i] == account) {
                    _saleLimited[i] = _saleLimited[_saleLimited.length - 1];
                    _saleLimited.pop();
                    return;
                }
            }
        }
    }

    function setGlobalSaleLimited(bool isLimited) external onlyOwner {
        isGlobalSaleLimited = isLimited;
    }

    function setAmmPair(address account, bool isPair) public onlyOwner {
        isAmmPair[account] = isPair;
    }

    // VIEW

    function decimals() public pure override returns (uint8) {
        return 9;
    }

    function transferLimitedAccounts()
        external
        view
        returns (address[] memory)
    {
        return _transferLimited;
    }

    function saleLimitedAccounts() external view returns (address[] memory) {
        return _saleLimited;
    }

    // INTERNAL

    function _transfer(
        address from,
        address to,
        uint256 value
    ) internal override {
        require(!isTransferLimited[from], "Sender is transfer limited");
        require(!isTransferLimited[to], "Recipient is transfer limited");
        require(
            from == owner() ||
                !isAmmPair[to] ||
                (!isGlobalSaleLimited && !isSaleLimited[from]),
            "Recipient is AMM pair"
        );
        super._transfer(from, to, value);
    }
}