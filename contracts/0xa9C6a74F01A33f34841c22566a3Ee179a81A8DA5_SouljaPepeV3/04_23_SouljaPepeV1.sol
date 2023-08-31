// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract SouljaPepe is
    Initializable,
    ERC20Upgradeable,
    OwnableUpgradeable,
    ERC20BurnableUpgradeable,
    UUPSUpgradeable,
    ReentrancyGuard
{
    using SafeMath for uint256;

    address public marketingWallet;
    uint256 public burnPercentage = 1;
    uint256 public reflectionPercentage = 1;
    uint256 public marketingPercentage = 3;
    uint256 public maxSupply;
    uint256 public minSupply;
    uint256 public constant MAX_HOLDERS = 5000;

    mapping(address => bool) public blacklists;

    // Holder management
    address[] private _holders;
    mapping(address => uint256) private _holderIndices;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address _marketingWallet) public initializer {
        __ERC20_init("SouljaPepe", "YAH");
        __ERC20Burnable_init();
        __Ownable_init();
        __UUPSUpgradeable_init();
        marketingWallet = _marketingWallet;
        uint256 initialSupply = 420698008911 * 10**decimals();
        _mint(msg.sender, initialSupply);
        maxSupply = totalSupply();
        minSupply = maxSupply.div(2);

        // Add the marketing wallet and contract address to the holders list
        _holders.push(_marketingWallet);
        _holderIndices[_marketingWallet] = 0;

        burnPercentage = 1;
        reflectionPercentage = 1;
        marketingPercentage = 3;
    }

    function blacklist(address _address, bool _isBlacklisting)
        external
        onlyOwner
    {
        blacklists[_address] = _isBlacklisting;
    }

    modifier notBlacklisted(address sender, address recipient) {
        require(
            !blacklists[sender] && !blacklists[recipient],
            "Address blacklisted"
        );
        _;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual override notBlacklisted (sender, recipient) nonReentrant {
        if (_getTotalHolders() <= MAX_HOLDERS) {
            uint256 burnAmount = amount.mul(burnPercentage).div(100);
            uint256 reflectionAmount = amount.mul(reflectionPercentage).div(
                100
            );
            uint256 marketingAmount = amount.mul(marketingPercentage).div(100);
            uint256 transferAmount = amount
                .sub(burnAmount)
                .sub(reflectionAmount)
                .sub(marketingAmount);

            super._transfer(sender, recipient, transferAmount);
            super._transfer(sender, marketingWallet, marketingAmount);
            super._burn(sender, burnAmount);
            super._transfer(sender, address(this), reflectionAmount);

            // Distribute the reflection amount among all token holders
            uint256 totalReflectionAmount = 0;
            for (uint256 i = 0; i < _getTotalHolders(); i++) {
                address holder = _getHolder(i);
                if (holder != address(this)) {
                    uint256 holderBalance = balanceOf(holder);
                    uint256 holderShare = reflectionAmount
                        .mul(holderBalance)
                        .div(totalSupply().sub(reflectionAmount));
                    totalReflectionAmount = totalReflectionAmount.add(
                        holderShare
                    );
                    super._transfer(address(this), holder, holderShare);
                }
            }

            // If there is any remaining reflection amount, burn it
            if (totalReflectionAmount < reflectionAmount) {
                super._burn(
                    address(this),
                    reflectionAmount.sub(totalReflectionAmount)
                );
            }
        } else {
            super._transfer(sender, recipient, amount);
        }
        _updateHolders(sender, recipient);
    }

    function _getTotalHolders() private view returns (uint256) {
        return _holders.length;
    }

    function _getHolder(uint256 index) private view returns (address) {
        return _holders[index];
    }

    function _updateHolders(address sender, address recipient) private {
        if (balanceOf(sender) == 0) {
            uint256 senderIndex = _holderIndices[sender];
            uint256 lastIndex = _holders.length.sub(1);
            address lastHolder = _holders[lastIndex];

            _holders[senderIndex] = lastHolder;
            _holderIndices[lastHolder] = senderIndex;
            _holders.pop();
        }

        if (
            _holderIndices[recipient] == 0 &&
            (_holders.length == 0 || recipient != _holders[0])
        ) {
            _holders.push(recipient);
            if (_holders.length > 0) {
                _holderIndices[recipient] = _holders.length.sub(1);
            } else {
                _holderIndices[recipient] = 0;
            }
        }
    }

    // Bridge functions
    event BridgeEnter(address indexed user, uint256 amount);
    event BridgeExit(address indexed user, uint256 amount);

    function bridgeEnter(uint256 amount) external nonReentrant {
        _transfer(msg.sender, address(this), amount);
        emit BridgeEnter(msg.sender, amount);
    }

    function bridgeExit(address user, uint256 amount)
        external
        onlyOwner
        nonReentrant
    {
        _transfer(address(this), user, amount);
        emit BridgeExit(user, amount);
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyOwner
    {}
}