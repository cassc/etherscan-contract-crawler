// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

import "./BatchNFT.sol";

abstract contract PreOrder is BatchNFT {
    using Counters for Counters.Counter;

    // record the number of NFTs ordered per addresses
    mapping(address => uint256) private _preOrders;
    // record the number of NFTs minted during pre-order
    Counters.Counter private _preOrderMintIndex;

    // number of NTFs per participant can order
    uint256 public constant preOrderLimit = 5;
    // determine whether there is an ongoing pre-order
    bool public inPreOrder;
    // unit (wei)
    uint256 public preOrderMinAmount;
    // participants allowed
    uint256 public preOrderSupply;

    event PreOrderMinted(address sender, uint256 n);

    // set minimum contribution amount
    function setPreOrderMinAmount(uint256 amount_) public onlyOwner {
        preOrderMinAmount = amount_;
    }

    // set the number of pre-order supplied NFTs
    function setPreOrderSupply(uint256 supply_) public onlyOwner {
        require(supply_ <= totalSupply, "incorrect pre-order supply");
        preOrderSupply = supply_;
    }

    // start or stop pre-order
    // @param start_: start or end pre-order flag
    // @param amount_: minimum contribution amount
    // @param supply_: pre-order supply
    function setInPreOrder(
        bool start_,
        uint256 amount_,
        uint256 supply_
    ) public onlyOwner {
        if (start_ == true) {
            require(amount_ > 0, "zero amount");
            // number of pre-order supply shall be less or equal to the number of total supply
            require(
                supply_ > 0 && supply_ <= totalSupply,
                "incorrect pre-order supply"
            );
            preOrderMinAmount = amount_;
            preOrderSupply = supply_;
            inPreOrder = true;
        } else {
            inPreOrder = false;
        }
    }

    // place a pre-order
    // @param n - number of NFTs to order
    function preOrder(uint256 n) public payable {
        require(inPreOrder == true, "pre-order not started");
        require(preOrderMinAmount > 0, "zero minimum amount");
        // validation against the minimum contribution amount
        require(
            n > 0 && msg.value >= preOrderMinAmount * n,
            "amount too small"
        );
        // shall not exceed pre-order supply
        require(
            _preOrderMintIndex.current() + n <= preOrderSupply,
            "reach pre-order supply"
        );

        if (_preOrders[msg.sender] <= 0) {
            // shall not exceed pre-order limit
            require(n <= preOrderLimit, "reach order limit");

            _preOrders[msg.sender] = n;
        } else {
            // shall not exceed pre-order limit
            require(
                n + _preOrders[msg.sender] <= preOrderLimit,
                "reach order limit"
            );

            // if the participant has ordered before
            _preOrders[msg.sender] += n;
        }

        for (uint256 i = 0; i < n; i++) {
            _tokenIds.increment();
            _preOrderMintIndex.increment();

            uint256 newItemId = _tokenIds.current();
            _safeMint(msg.sender, newItemId);
        }
        emit PreOrderMinted(msg.sender, n);
    }

    // check if an address has placed an order
    function preOrderExist(address addr_) public view virtual returns (bool) {
        return _preOrders[addr_] > 0;
    }

    // return participant's pre-order detail
    function preOrderGet(address addr_) public view virtual returns (uint256) {
        uint256 p = _preOrders[addr_];
        return p;
    }

    // return the number NFTs of minted in pre-order
    function preOrderMintIndex() public view virtual returns (uint256) {
        return _preOrderMintIndex.current();
    }
}