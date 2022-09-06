//SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import "./utils/Address.sol";
import "./interfaces/IYFIAGNftMarketplace.sol";
import "./interfaces/IERC20.sol";
import "./utils/Ownable.sol";
import "./interfaces/IYFIAGNftPool.sol";
import "./utils/ReentrancyGuard.sol";

contract YFIAGNftPool is IYFIAGNftPool, Ownable, ReentrancyGuard {
    IYFIAGNftMarketplace public yfiagMKT;
    using Address for address;

    mapping(address => mapping(address => uint256)) public amountWithdrawn;

    constructor(address _yfiagNftMarketplace, address _owner) {
        yfiagMKT = IYFIAGNftMarketplace(_yfiagNftMarketplace);
        transferOwnership(_owner);
    }

    modifier onlyEOA() {
        require(tx.origin == msg.sender, "Only EOA");
        _;
    }

    modifier onlyOwnerOrMarketplace() {
        require(
            _msgSender() == owner() || _msgSender() == address(yfiagMKT),
            "Already inprocess"
        );
        _;
    }

    function getBalance() public view override returns (uint256) {
        address _self = address(this);
        uint256 _balance = _self.balance;
        return _balance;
    }

    function getAmountEarn(address _user, address _tokenAddress)
        public
        view
        override
        returns (uint256)
    {
        return yfiagMKT.getAmountEarn(_user, _tokenAddress);
    }

    function getAmountWithdrawn(address _user, address _tokenAddress)
        public
        view
        override
        returns (uint256)
    {
        return amountWithdrawn[_user][_tokenAddress];
    }

    function withdraw(address _tokenAddress)
        external
        override
        nonReentrant
        onlyEOA
    {
        uint256 subOwnerFee = yfiagMKT.getAmountEarn(msg.sender, _tokenAddress);
        if (_tokenAddress == address(0)) {
            require(subOwnerFee > 0, "Earn = 0");
            require(address(this).balance >= subOwnerFee, "Balance invalid");
            amountWithdrawn[msg.sender][_tokenAddress] += subOwnerFee;
            yfiagMKT.setDefaultAmountEarn(msg.sender, _tokenAddress);
            payable(msg.sender).transfer(subOwnerFee);
        } else {
            require(subOwnerFee > 0, "Earn = 0");
            require(
                IERC20(_tokenAddress).balanceOf(address(this)) >= subOwnerFee,
                "Balance invalid"
            );
            amountWithdrawn[msg.sender][_tokenAddress] += subOwnerFee;
            yfiagMKT.setDefaultAmountEarn(msg.sender, _tokenAddress);
            IERC20(_tokenAddress).transfer(msg.sender, subOwnerFee);
        }
    }

    function subOwnerFeeBalance() public payable override {}

    function setMarketplaceAddress(address marketPlaceAddress)
        external
        override
        onlyOwner
    {
        require(marketPlaceAddress != address(0), "Bad address");
        require(marketPlaceAddress.isContract(), "Not contract");
        yfiagMKT = IYFIAGNftMarketplace(marketPlaceAddress);
    }

    function migratePool(address newPool, address _tokenAddress)
        public
        onlyOwnerOrMarketplace
    {
        require(newPool != address(0), "Bad address");
        require(newPool.isContract(), "Not contract");
        if (getBalance() > 0) {
            payable(newPool).transfer(getBalance());
        }
    }

    receive() external payable {}
}