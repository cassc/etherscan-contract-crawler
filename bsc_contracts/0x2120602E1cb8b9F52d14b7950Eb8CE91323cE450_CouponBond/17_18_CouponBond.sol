// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/ICouponBond.sol";

// import "../lib/forge-std/src/console.sol";

/// @notice This repays the interest monthly. At the maturity date, lenders receive the principal and one-month interest.
contract CouponBond is ICouponBond, ERC1155Supply, ERC1155Burnable, ERC1155Pausable, Ownable {
    using SafeERC20 for IERC20;

    mapping(uint256 => Product) public products;
    uint256 public numProducts;

    mapping(uint256 => mapping(address => uint256)) public lastUpdatedTs;
    mapping(uint256 => mapping(address => uint256)) public unclaimedInterest;

    constructor() ERC1155("") Pausable() {}

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function addProduct(
        address _token,
        uint256 _value,
        uint256 _baseInterestPerSecond,
        uint256 _overdueInterestPerSecond,
        string memory _uri,
        uint64 _startTs,
        uint64 _endTs
    )
        external
        onlyOwner
    {
        Product memory newProduct = Product({
            token: _token,
            value: _value,
            baseInterestPerSecond: _baseInterestPerSecond,
            overdueInterestPerSecond: _overdueInterestPerSecond,
            uri: _uri,
            totalRepaid: 0,
            startTs: _startTs,
            endTs: _endTs,
            repaidTs: 0
        });
        products[numProducts] = newProduct;

        numProducts++;

        emit ProductAdded(numProducts - 1);
    }

    function mintBatch(uint256 _id, address[] memory _addresses, uint256[] memory _amounts) external onlyOwner {
        for (uint256 i = 0; i < _addresses.length; ++i) {
            address to = _addresses[i];
            _updateInterestBeforeMint(to, _id, _amounts[i]);
        }

        for (uint256 i = 0; i < _addresses.length; ++i) {
            _mint(_addresses[i], _id, _amounts[i], "");
        }
    }

    function setURI(uint256 _id, string memory _uri) external onlyOwner {
        products[_id].uri = _uri;
    }

    /// @inheritdoc ICouponBond
    function repay(uint256 _id, uint256 _amount) external override {
        Product storage product = products[_id];
        uint256 repayingAmount = _amount;

        if (isRepaid(_id)) {
            revert AlreadyRepaid(_id);
        }

        uint256 unpaidDebt = getUnpaidDebt(_id);
        if (_amount == type(uint256).max || unpaidDebt <= repayingAmount) {
            repayingAmount = unpaidDebt;
        }

        product.totalRepaid += repayingAmount;

        if (getTotalDebt(_id) <= product.totalRepaid) {
            product.repaidTs = uint64(block.timestamp);
        }

        IERC20(product.token).safeTransferFrom(_msgSender(), address(this), repayingAmount);

        emit Repaid(_id, repayingAmount, unpaidDebt - repayingAmount);
    }

    /// @inheritdoc ICouponBond
    function claim(address _to, uint256 _id) external override whenNotPaused {
        Product storage product = products[_id];
        uint256 receiveAmount;

        _updateInterest(_to, _id);

        if (isRepaid(_id)) {
            uint256 balance = balanceOf(_to, _id);

            // Both interest & principal
            receiveAmount = (product.value * balance) + unclaimedInterest[_id][_to];

            _burn(_to, _id, balance);
        } else {
            // only interest
            receiveAmount = unclaimedInterest[_id][_to];
        }

        unclaimedInterest[_id][_to] = 0;
        // Already done in _updateInterest
        // lastUpdatedTs[_id][_to] = block.timestamp;

        IERC20(product.token).safeTransfer(_to, receiveAmount);

        emit Claimed(_id, receiveAmount);
    }

    // ********** view ********** //
    function uri(uint256 _id) public view override returns (string memory) {
        return products[_id].uri;
    }

    function isRepaid(uint256 _id) public view override returns (bool) {
        return products[_id].repaidTs != 0;
    }

    function isOverdue(uint256 _id) public view override returns (bool) {
        return products[_id].endTs < block.timestamp;
    }

    function previewClaim(address _account, uint256 _id) external view override returns (uint256) {
        if (isRepaid(_id)) {
            return balanceOf(_account, _id) * products[_id].value + getUnclaimedInterest(_account, _id);
        } else {
            return getUnclaimedInterest(_account, _id);
        }
    }

    /// @dev ERC-1155 totalSupply has no decimal. Therefore, just multiply totalSupply * debt per token
    function getTotalDebt(uint256 _id) public view override returns (uint256) {
        return totalSupply(_id) * getUnitDebt(_id);
    }

    /// @inheritdoc ICouponBond
    function getUnitDebt(uint256 _id) public view override returns (uint256) {
        Product storage product = products[_id];
        return product.value
            + _calculateInterest(
                product.baseInterestPerSecond,
                product.overdueInterestPerSecond,
                product.startTs, // calculate from the start
                product.endTs,
                product.repaidTs
            );
    }

    /// @inheritdoc ICouponBond
    function getUnpaidDebt(uint256 _id) public view override returns (uint256) {
        Product storage product = products[_id];
        return getTotalDebt(_id) - product.totalRepaid;
    }

    /// @inheritdoc ICouponBond
    function getUnclaimedInterest(address _to, uint256 _id) public view override returns (uint256) {
        return unclaimedInterest[_id][_to] + _getAdditionalInterest(_to, _id);
    }

    // ****** internal ****** //
    function _updateInterestBeforeMint(address _to, uint256 _id, uint256 _amount) internal {
        Product storage product = products[_id];

        if (product.startTs < block.timestamp) {
            unclaimedInterest[_id][_to] = _amount * (getUnitDebt(_id) - product.value);
            lastUpdatedTs[_id][_to] = block.timestamp;
        }
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    )
        internal
        virtual
        override (ERC1155, ERC1155Supply, ERC1155Pausable)
    {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);

        if (from != address(0)) {
            for (uint256 i = 0; i < ids.length; ++i) {
                uint256 id = ids[i];
                _updateInterest(from, id);
            }
        }

        if (to != address(0)) {
            for (uint256 i = 0; i < ids.length; ++i) {
                uint256 id = ids[i];
                _updateInterest(to, id);
            }
        }
    }

    function _getAdditionalInterest(address _to, uint256 _id) internal view returns (uint256) {
        Product storage product = products[_id];
        uint256 userLastUpdatedTs = lastUpdatedTs[_id][_to];

        // Since a user may have transferred before startTs, userLastUpdatedTs may not be zero and less than product.startTs.
        if (userLastUpdatedTs < product.startTs) {
            userLastUpdatedTs = product.startTs;
        }

        return balanceOf(_to, _id)
            * _calculateInterest(
                product.baseInterestPerSecond,
                product.overdueInterestPerSecond,
                userLastUpdatedTs,
                product.endTs,
                product.repaidTs
            );
    }

    /// @notice Save the current unclaimed interest and the updated timestamp.
    function _updateInterest(address _to, uint256 _id) internal {
        if (block.timestamp < products[_id].startTs) {
            return;
        }
        // if (products[_id].repaidTs <= lastUpdatedTs[_id][_to]) return;

        unclaimedInterest[_id][_to] = getUnclaimedInterest(_to, _id);
        lastUpdatedTs[_id][_to] = block.timestamp;
    }

    function _calculateInterest(
        uint256 _interestPerSecond,
        uint256 _overdueInterestPerSecond,
        uint256 _lastUpdatedTs,
        uint256 _endTs,
        uint256 _repaidTs
    )
        internal
        view
        returns (uint256)
    {
        uint256 currentTs = _repaidTs == 0 ? block.timestamp : _repaidTs;
        if (currentTs <= _lastUpdatedTs) {
            return 0;
        }

        uint256 timeDelta = currentTs - _lastUpdatedTs;
        uint256 interest = _interestPerSecond * timeDelta;
        if (_endTs < currentTs) {
            uint256 latest = _endTs > _lastUpdatedTs ? _endTs : _lastUpdatedTs;
            interest += _overdueInterestPerSecond * (currentTs - latest);
        }

        return interest;
    }
}