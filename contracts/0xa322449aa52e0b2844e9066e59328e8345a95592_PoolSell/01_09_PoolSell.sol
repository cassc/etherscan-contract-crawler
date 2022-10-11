// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract PoolSell is Ownable {
    using SafeERC20 for IERC20;

    struct Pool {
        address owner;
        address collection;
        address currency;
        uint256 price;
        uint256 length;
    }

    uint256 private poolsCount = 0;
    mapping(uint256 => Pool) public pools;
    mapping(uint256 => mapping(uint256 => uint256)) public tokensLists;

    address public marketplaceBeneficiaryAddress;
    uint256 private marketplaceBeneficiaryFee = 250;
    mapping(address => bool) internal admins;

    event Buy(
        address owner,
        address buyer,
        uint256 indexed pool,
        address indexed collection,
        uint256 amount,
        uint256 price,
        address currency
    );

    event ChangePool(
        address owner,
        uint256 indexed id,
        address indexed collection,
        uint256 amount,
        uint256 price,
        address currency
    );

    event SetAdmin(
        address indexed user,
        bool status
    );

    event Cancel(address owner, uint256 position);

    constructor() {
        marketplaceBeneficiaryAddress = msg.sender;
        setAdmin(msg.sender, true);
    }

    function changeMarketplaceBeneficiaryFee(
        uint256 fee
    ) external onlyOwner {
        require(fee <= 10000, "Wrong fee");
        marketplaceBeneficiaryFee = fee;
    }

    function changeMarketplaceBeneficiary(
        address _marketplaceBeneficiaryAddress
    ) external onlyOwner {
        marketplaceBeneficiaryAddress = _marketplaceBeneficiaryAddress;
    }

    function setAdmin(address user, bool status) public onlyOwner {
        admins[user] = status;
        emit SetAdmin(user, status);
    }

    function getAdmin(address user) external view returns (bool) {
        return admins[user];
    }

    function createPool(
        address _collection,
        uint256 _price,
        address _currency,
        uint256[] memory _ids,
        address _owner
    ) external returns (uint256) {
        if (_owner == address(0)) {
            _owner = msg.sender;
        }
        require(msg.sender == _owner || admins[msg.sender], "Wrong owner");

        for (uint256 i = 0; i < _ids.length; i++) {
            require(
                IERC721(_collection).ownerOf(_ids[i]) == _owner,
                "Wrong amount"
            );
            tokensLists[poolsCount][i] = _ids[i];
        }
        pools[poolsCount] = Pool(
            _owner,
            _collection,
            _currency,
            _price,
            _ids.length
        );
        poolsCount++;

        emit ChangePool(
            _owner,
            poolsCount - 1,
            _collection,
            _ids.length,
            _price,
            _currency
        );
        return poolsCount;
    }

    function changePool(
        uint256 _id,
        address _collection,
        uint256 _price,
        address _currency,
        uint256[] memory _ids,
        address _owner
    ) external returns (uint256) {
        require(_id < poolsCount, "Wrong id");
        require(msg.sender == pools[_id].owner || admins[msg.sender], "Wrong owner");
        Pool storage pool = pools[_id];
        if (_owner != address(0)) {
            pool.owner = _owner;
        }
        if (_collection != address(0)) {
            pool.collection = _collection;
        }
        if (_price != 0) {
            pool.price = _price;
        }
        pool.currency = _currency;
        if (_ids.length != 0) {
            pool.length = _ids.length;

            for (uint256 i = 0; i < _ids.length; i++) {
                require(
                    IERC721(pool.collection).ownerOf(_ids[i]) == pool.owner,
                    "Wrong amount"
                );
                tokensLists[_id][i] = _ids[i];
            }
        }

        emit ChangePool(
            _owner,
            _id,
            _collection,
            _ids.length,
            _price,
            _currency
        );
        return poolsCount;
    }

    function addPoolTokens(
        uint256 _id,
        uint256[] memory _ids
    ) external returns (uint256) {
        require(_id < poolsCount, "Wrong id");
        require(msg.sender == pools[_id].owner || admins[msg.sender], "Wrong owner");
        Pool storage pool = pools[_id];

        for (uint256 i = 0; i < _ids.length; i++) {
            require(
                IERC721(pool.collection).ownerOf(_ids[i]) == pool.owner,
                "Wrong amount"
            );
            tokensLists[_id][pool.length + i] = _ids[i];
        }
        pool.length += _ids.length;

        emit ChangePool(
            pool.owner,
            _id,
            pool.collection,
            pool.length,
            pool.price,
            pool.currency
        );
        return poolsCount;
    }

    function removePoolTokens(
        uint256 _id
    ) external {
        require(_id < poolsCount, "Wrong id");
        require(msg.sender == pools[_id].owner || admins[msg.sender], "Wrong owner");
        for (uint256 i = 0; i < pools[_id].length; i++) {
            delete tokensLists[_id][i];
        }
    }

    function cancel(uint256 _id) external {
        require(msg.sender == pools[_id].owner || admins[msg.sender], "Wrong owner");
        for (uint256 i = 0; i < pools[_id].length; i++) {
            delete tokensLists[_id][i];
        }
        delete pools[_id];

        emit Cancel(msg.sender, _id);
    }

    function buy(
        uint256 _pool,
        uint256 _amount,
        address _buyer,
        bytes calldata _data
    ) external payable {
        Pool storage pool = pools[_pool];
        require(pool.length >= _amount, "Wrong amount");

        transferWithFees(_pool, _amount);

        if (_buyer == address(0)) {
            _buyer = msg.sender;
        }
        mapping(uint256 => uint256) storage tokens = tokensLists[_pool];

        for (uint256 i = 0; i < _amount; i++) {
            uint256 id = pool.length - 1;

            IERC721(pool.collection).safeTransferFrom(
                pool.owner,
                _buyer,
                tokens[id],
                _data
            );

            delete tokens[id];
            pool.length--;
        }
        emit Buy(
            pool.owner,
            _buyer,
            _pool,
            pool.collection,
            _amount,
            pool.price,
            pool.currency
        );
    }

    function transferWithFees(uint256 _pool, uint256 _amount) internal {
        Pool storage pool = pools[_pool];
        uint256 price = pool.price * _amount;
        uint256 buyerFee = getFee(price, marketplaceBeneficiaryFee);
        uint256 total = price + buyerFee;

        if (pool.currency == address(0)) {
            require(msg.value >= total, "Insufficient balance");
            uint256 returnBack = msg.value - total;
            if (returnBack > 0) {
                payable(msg.sender).transfer(returnBack);
            }
        }

        if (buyerFee > 0) {
            transfer(
                marketplaceBeneficiaryAddress,
                pool.currency,
                buyerFee * 2
            );
        }
        transfer(pool.owner, pool.currency, price - buyerFee);
    }

    function transfer(
        address _to,
        address _currency,
        uint256 _amount
    ) internal {
        if (_currency == address(0)) {
            payable(_to).transfer(_amount);
        } else {
            IERC20(_currency).transferFrom(msg.sender, _to, _amount);
        }
    }

    function getFee(uint256 _amount, uint256 _fee)
    internal
    pure
    returns (uint256)
    {
        return _amount * _fee / 10000;
    }
}