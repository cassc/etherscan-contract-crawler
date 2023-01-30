// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

interface PriceContract {
    // this getPrice must return price of 1 WEI (on BNB network) in USDT.
    function getPrice() external view returns (uint256);
}

/// @custom:security-contact [email protected]
contract NEXTUSD is Initializable, ERC20Upgradeable, OwnableUpgradeable {
    uint256 deployedAt;
    uint256 presaleFinishDate;
    bool isPresale;
    address _baseCoinPriceContract;
    mapping(address => bool) _allowedPresellers;
    mapping(address => uint256) _unpaidRewards;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() public initializer {
        __ERC20_init("NEXTUSD", "NUSD");
        __Ownable_init();

        _mint(msg.sender, 60000000 * 10 ** decimals());
        presaleFinishDate = block.timestamp + 90 days;
        isPresale = false;
    }

    function isPresaleActive() public view returns (bool) {
        return (block.timestamp <= presaleFinishDate) ? isPresale : false;
    }

    function transfer(
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        uint256 startingGas = gasleft();
        address owner = _msgSender();
        _transfer(owner, to, amount);
        _incrementReward(
            owner,
            _calculateUsedFee(startingGas - gasleft(), tx.gasprice)
        );
        return true;
    }

    function togglePresellerAbility(
        address presellerAddress
    ) public virtual onlyOwner returns (bool) {
        _allowedPresellers[presellerAddress] = !(_allowedPresellers[
            presellerAddress
        ] || false);
        return true;
    }

    function togglePresale() public virtual onlyOwner returns (bool) {
        isPresale = !isPresale;
        return isPresale;
    }

    function baseCoinPriceContract() public view returns (PriceContract) {
        return PriceContract(_baseCoinPriceContract);
    }

    function setBaseCoinPriceContract(
        address baseCoinPriceContractAddress
    ) public virtual onlyOwner returns (bool) {
        _baseCoinPriceContract = baseCoinPriceContractAddress;
        return true;
    }

    function feeRewardAmount(
        address walletAddress
    ) public view returns (uint256) {
        return _unpaidRewards[walletAddress];
    }

    function takeFeeReward() public virtual returns (bool) {
        address owner = _msgSender();
        uint256 unpaidRewardAmount = feeRewardAmount(owner);
        require(
            (unpaidRewardAmount) > (1 * 10 ** decimals()),
            "Reward should be higher than $1."
        );
        _unpaidRewards[owner] = 0;
        _mint(owner, unpaidRewardAmount);
        return true;
    }

    function _isPreseller(address walletAddress) internal view returns (bool) {
        return _allowedPresellers[walletAddress] == true;
    }

    function _beforeTokenTransfer(
        address from,
        address,
        uint256
    ) internal virtual override {
        if (isPresaleActive()) {
            require(
                _isPreseller(from),
                "You can't transfer your assets until Presale is finished."
            );
        }
    }

    function _getBaseAmountInUsd(
        uint256 baseAmount
    ) internal view returns (uint256) {
        return (baseAmount * baseCoinPriceContract().getPrice());
    }

    function _calculateUsedFee(
        uint256 gasUsed,
        uint256 gasPrice
    ) internal virtual returns (uint256) {
        return gasUsed * gasPrice;
    }

    function _incrementReward(
        address receiver,
        uint256 amount
    ) internal returns (bool) {
        _unpaidRewards[receiver] += _getBaseAmountInUsd(amount);
        return true;
    }
}