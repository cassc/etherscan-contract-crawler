// SPDX-License-Identifier: MIT

pragma solidity =0.8.15;

import "./interfaces/IBaseSale.sol";
import "./interfaces/ICollectible.sol";
import "./interfaces/IWhitelist.sol";
import "./AccessControlPermissible.sol";

abstract contract BaseSale is IBaseSale, AccessControlPermissible {
    // @dev status of the sale.
    bool public isActive;

    address public override whitelist;
    address payable public override treasury;

    address public immutable nft;
    uint256 public maxTokenPurchase = 1;

    uint256 internal _defaultPrice;

    constructor(address _nft) {
        nft = _nft;
    }

    // @dev Start sales.
    function start() external override onlyRole(ADMIN_ROLE) {
        require(!isActive, "Already active");

        isActive = true;
    }

    // @dev Stop sales.
    function stop() external override onlyRole(ADMIN_ROLE) {
        require(isActive, "Already inactive");

        isActive = false;
    }

    function getPrice() public view override returns (uint256 price) {
        price = _defaultPrice;
    }

    function setDefaultPrice(uint256 _price)
        external
        override
        onlyRole(ADMIN_ROLE)
    {
        require(_defaultPrice != 0, "Zero price");

        _defaultPrice = _price;
    }

    function setWhitelist(address _whitelist) external onlyRole(ADMIN_ROLE) {
        whitelist = _whitelist;
    }

    function setTreasury(address payable _treasury)
        external
        onlyRole(ADMIN_ROLE)
    {
        require(_treasury != address(0), "Zero address");

        treasury = _treasury;
    }

    function setMaxTokenPurchase(uint256 _amount)
        external
        onlyRole(ADMIN_ROLE)
    {
        require(_amount != 0, "Incorrect amount");

        maxTokenPurchase = _amount;
    }

    function _buy(
        address _buyer,
        uint256 _amount,
        uint256 _deposit
    ) internal {
        require(_deposit == _defaultPrice * _amount, "Incorrect ether value");
        Address.sendValue(treasury, _deposit);
        _mint(_buyer, _amount);
    }

    function _mint(address _to, uint256 _amount) internal {
        ICollectible(nft).mint(_to, _amount);
    }

    modifier isCorrectAmount(uint256 _amount) {
        require(
            _amount != 0 && _amount <= maxTokenPurchase,
            "Market: invalid amount set, to much or too low"
        );
        _;
    }

    modifier checkStatus() {
        require(isActive, "Sales disabled");
        _;
    }
}