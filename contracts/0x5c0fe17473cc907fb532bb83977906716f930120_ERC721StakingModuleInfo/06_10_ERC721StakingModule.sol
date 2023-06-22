/*
ERC721StakingModule

https://github.com/gysr-io/core

SPDX-License-Identifier: MIT
*/

pragma solidity 0.8.18;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "./interfaces/IStakingModule.sol";
import "./OwnerController.sol";

/**
 * @title ERC721 staking module
 *
 * @notice this staking module allows users to deposit one or more ERC721
 * tokens in exchange for shares credited to their address. When the user
 * unstakes, these shares will be burned and a reward will be distributed.
 */
contract ERC721StakingModule is IStakingModule, OwnerController {
    // constant
    uint256 public constant SHARES_PER_TOKEN = 1e6;

    // members
    IERC721 private immutable _token;
    address private immutable _factory;

    mapping(address => uint256) public counts;
    mapping(uint256 => address) public owners;
    mapping(address => mapping(uint256 => uint256)) public tokenByOwner;
    mapping(uint256 => uint256) public tokenIndex;

    /**
     * @param token_ the token that will be rewarded
     * @param factory_ address of module factory
     */
    constructor(address token_, address factory_) {
        require(IERC165(token_).supportsInterface(0x80ac58cd), "smn1");
        _token = IERC721(token_);
        _factory = factory_;
    }

    /**
     * @inheritdoc IStakingModule
     */
    function tokens()
        external
        view
        override
        returns (address[] memory tokens_)
    {
        tokens_ = new address[](1);
        tokens_[0] = address(_token);
    }

    /**
     * @inheritdoc IStakingModule
     */
    function balances(
        address user
    ) external view override returns (uint256[] memory balances_) {
        balances_ = new uint256[](1);
        balances_[0] = counts[user];
    }

    /**
     * @inheritdoc IStakingModule
     */
    function factory() external view override returns (address) {
        return _factory;
    }

    /**
     * @inheritdoc IStakingModule
     */
    function totals()
        external
        view
        override
        returns (uint256[] memory totals_)
    {
        totals_ = new uint256[](1);
        totals_[0] = _token.balanceOf(address(this));
    }

    /**
     * @inheritdoc IStakingModule
     */
    function stake(
        address sender,
        uint256 amount,
        bytes calldata data
    ) external override onlyOwner returns (bytes32, uint256) {
        // validate
        require(amount > 0, "smn2");
        require(amount <= _token.balanceOf(sender), "smn3");
        require(data.length == 32 * amount, "smn4");

        uint256 count = counts[sender];

        // stake
        for (uint256 i; i < amount; ) {
            // get token id
            uint256 id;
            uint256 pos = 132 + 32 * i;
            assembly {
                id := calldataload(pos)
            }

            // ownership mappings
            owners[id] = sender;
            uint256 len = count + i;
            tokenByOwner[sender][len] = id;
            tokenIndex[id] = len;

            // transfer to module
            _token.transferFrom(sender, address(this), id);

            unchecked {
                ++i;
            }
        }

        // update position
        counts[sender] = count + amount;

        // emit
        bytes32 account = bytes32(uint256(uint160(sender)));
        uint256 shares = amount * SHARES_PER_TOKEN;
        emit Staked(account, sender, address(_token), amount, shares);

        return (account, shares);
    }

    /**
     * @inheritdoc IStakingModule
     */
    function unstake(
        address sender,
        uint256 amount,
        bytes calldata data
    ) external override onlyOwner returns (bytes32, address, uint256) {
        // validate
        require(amount > 0, "smn5");
        uint256 count = counts[sender];
        require(amount <= count, "smn6");
        require(data.length == 32 * amount, "smn7");

        // unstake
        for (uint256 i; i < amount; ) {
            // get token id
            uint256 id;
            {
                uint256 pos = 132 + 32 * i;
                assembly {
                    id := calldataload(pos)
                }
            }

            // ownership
            require(owners[id] == sender, "smn8");
            delete owners[id];

            // clean up ownership mappings
            uint256 lastIndex = count - 1 - i;
            if (amount != count) {
                // reindex on partial unstake
                uint256 index = tokenIndex[id];
                if (index != lastIndex) {
                    uint256 lastId = tokenByOwner[sender][lastIndex];
                    tokenByOwner[sender][index] = lastId;
                    tokenIndex[lastId] = index;
                }
            }
            delete tokenByOwner[sender][lastIndex];
            delete tokenIndex[id];

            // transfer to user
            _token.safeTransferFrom(address(this), sender, id);

            unchecked {
                ++i;
            }
        }

        // update position
        counts[sender] = count - amount;

        // emit
        bytes32 account = bytes32(uint256(uint160(sender)));
        uint256 shares = amount * SHARES_PER_TOKEN;
        emit Unstaked(account, sender, address(_token), amount, shares);

        return (account, sender, shares);
    }

    /**
     * @inheritdoc IStakingModule
     */
    function claim(
        address sender,
        uint256 amount,
        bytes calldata
    ) external override onlyOwner returns (bytes32, address, uint256) {
        // validate
        require(amount > 0, "smn9");
        require(amount <= counts[sender], "smn10");

        bytes32 account = bytes32(uint256(uint160(sender)));
        uint256 shares = amount * SHARES_PER_TOKEN;
        emit Claimed(account, sender, address(_token), amount, shares);
        return (account, sender, shares);
    }

    /**
     * @inheritdoc IStakingModule
     */
    function update(
        address sender,
        bytes calldata
    ) external pure override returns (bytes32) {
        return (bytes32(uint256(uint160(sender))));
    }

    /**
     * @inheritdoc IStakingModule
     */
    function clean(bytes calldata) external override {}
}