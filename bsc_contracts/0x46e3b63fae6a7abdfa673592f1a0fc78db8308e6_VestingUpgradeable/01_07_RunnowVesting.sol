// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "./IRunnow.sol";

contract VestingUpgradeable is OwnableUpgradeable {
    address public runnow;

    event SetRUNNOW(address runnowAddress);
    event SetDistributeTime(uint256 time);

    uint256 public distributeTime;

    uint256 private constant SECONDS_PER_MONTH = 30 days; //mainnet
    // uint256 private constant SECONDS_PER_MONTH = 1 minutes; //testet


    uint256 private constant decimals = 18;

    uint256 public lastestDistributeMonth;

    address public seedSales;
    address public privateSales;
    address public publicSales;
    address public advisorsAndPartners;
    address public teamAndOperations;
    address public mktAndCommunity;
    address public gameTreasury;
    address public farmingAndStaking;
    address public liquidity;

    function initialize() public virtual initializer {
        __vesting_init(
            0x818Dc066163900591E4b52C3536A713D5d701eD3,
            1665824400,
            0x900B2491Be791b95561E0d3C283E18b0AE755E70,
            0x84AbF5D1CAE81cB7C661cba58Fc4d15757911128,
            0x71121E3eaFCb6a1e9b58BBF37C6B7a2E3e93e07d,
            0x15cB19F2DA6302Dc82ef3bbdfb11A37bD64D346d,
            0x04394a103f91C0389F9211811dfDCDBE81747924,
            0x32AdcEE090f422964D8b25b408c95a3623Da0E6B,
            0xF76A047E8d7D82BE61d21c73a54528D394fc828c,
            0x7A991826ac855d203b950411513E21990750C08C,
            0x83e973AF186b7515Cf6Eb9FDdF861b59E49942Fe
        );
        __Ownable_init();
    }

    function __vesting_init(
        address _runnowAddr,
        uint256 _distributeTime,
        address _seedSales,
        address _privateSales,
        address _publicSales,
        address _advisorsAndPartners,
        address _teamAndOperations,
        address _mktAndCommunity,
        address _gameTreasury,
        address _farmingAndStaking,
        address _liquidity
    ) internal {
        runnow = _runnowAddr;
        distributeTime = _distributeTime;
        require(
            _privateSales != address(0),
            "_privateSales cannot be address 0"
        );
        privateSales = _privateSales;
        require(_publicSales != address(0), "_publicSales cannot be address 0");
        publicSales = _publicSales;
        require(
            _advisorsAndPartners != address(0),
            "_advisorsAndPartners cannot be address 0"
        );
        advisorsAndPartners = _advisorsAndPartners;
        require(
            _teamAndOperations != address(0),
            "_teamAndOperations cannot be address 0"
        );
        teamAndOperations = _teamAndOperations;
        require(
            _mktAndCommunity != address(0),
            "_mktAndCommunity cannot be address 0"
        );
        mktAndCommunity = _mktAndCommunity;
        require(
            _gameTreasury != address(0),
            "_gameTreasury cannot be address 0"
        );
        gameTreasury = _gameTreasury;
        require(
            _farmingAndStaking != address(0),
            "_farmingAndStaking cannot be address 0"
        );
        farmingAndStaking = _farmingAndStaking;
        require(_seedSales != address(0), "_seedSales cannot be address 0");
        seedSales = _seedSales;
        require(_liquidity != address(0), "_liquidity cannot be address 0");
        liquidity = _liquidity;
    }

    function setAddress(
        address _seedSales,
        address _privateSales,
        address _publicSales,
        address _advisorsAndPartners,
        address _teamAndOperations,
        address _mktAndCommunity,
        address _gameTreasury,
        address _farmingAndStaking,
        address _liquidity
    ) external onlyOwner {
        require(
            _privateSales != address(0),
            "_privateSales cannot be address 0"
        );
        privateSales = _privateSales;
        require(_publicSales != address(0), "_publicSales cannot be address 0");
        publicSales = _publicSales;
        require(
            _advisorsAndPartners != address(0),
            "_advisorsAndPartners cannot be address 0"
        );
        advisorsAndPartners = _advisorsAndPartners;
        require(
            _teamAndOperations != address(0),
            "_teamAndOperations cannot be address 0"
        );
        teamAndOperations = _teamAndOperations;
        require(
            _mktAndCommunity != address(0),
            "_mktAndCommunity cannot be address 0"
        );
        mktAndCommunity = _mktAndCommunity;
        require(
            _gameTreasury != address(0),
            "_gameTreasury cannot be address 0"
        );
        gameTreasury = _gameTreasury;
        require(
            _farmingAndStaking != address(0),
            "_farmingAndStaking cannot be address 0"
        );
        farmingAndStaking = _farmingAndStaking;
        require(_seedSales != address(0), "_seedSales cannot be address 0");
        seedSales = _seedSales;
        require(_liquidity != address(0), "_liquidity cannot be address 0");
        liquidity = _liquidity;
    }

    function setRunnow(address newRunnow) external onlyOwner {
        require(address(newRunnow) != address(0));
        runnow = newRunnow;
        emit SetRUNNOW(address(newRunnow));
    }

    function setDistributeTime(uint256 time) external onlyOwner {
        require(distributeTime >= block.timestamp,"Can't set new distribute time");
        distributeTime = time;
        emit SetDistributeTime(time);
    }

    function distribute() external {
        require(
            block.timestamp >= distributeTime,
            "RUNNOWVesting: not claim time"
        );
        uint256 month = (block.timestamp - distributeTime) / SECONDS_PER_MONTH;
        require(
            lastestDistributeMonth <= month,
            "RUNNOWVesting: already claimed in this month"
        );

        uint256 amountForSeedSale;
        uint256 amountForPrivateSale;
        uint256 amountForPublicSale;
        uint256 amountForAdvisorsAndPartners;
        uint256 amountForTeamAndOperations;
        uint256 amountForMktAndCommunity;
        uint256 amountForGameTreasury;
        uint256 amountForFarmingAndStaking;
        uint256 amountForLiquidity;

        for (uint256 i = lastestDistributeMonth; i <= month; i++) {
            amountForPrivateSale += getAmountForPrivateSales(i);
            amountForPublicSale += getAmountForPublicSales(i);
            amountForAdvisorsAndPartners += getAmountForAdvisorsAndPartners(i);
            amountForTeamAndOperations += getAmountForTeamAndOperations(i);
            amountForMktAndCommunity += getAmountForMktAndCommunity(i);
            amountForGameTreasury += getAmountForGameTreasury(i);
            amountForFarmingAndStaking += getAmountForFarmingAndStaking(i);
            amountForSeedSale += getAmountForSeedSale(i);
            amountForLiquidity += getAmountForLiquidity(i);
        }
        bool remainVesting = amountForSeedSale == 0 &&
            amountForPrivateSale == 0 &&
            amountForPublicSale == 0 &&
            amountForAdvisorsAndPartners == 0 &&
            amountForTeamAndOperations == 0 &&
            amountForMktAndCommunity == 0 &&
            amountForGameTreasury == 0 &&
            amountForFarmingAndStaking == 0 &&
            amountForLiquidity == 0;
        require(
            month <= 36 || (month > 36 && !remainVesting),
            "RUNNOWVesting: expiry time"
        );
        if (amountForSeedSale > 0)
            IRunnow(runnow).mint(seedSales, amountForSeedSale);
        if (amountForPrivateSale > 0)
            IRunnow(runnow).mint(privateSales, amountForPrivateSale);
        if (amountForPublicSale > 0)
            IRunnow(runnow).mint(publicSales, amountForPublicSale);
        if (amountForAdvisorsAndPartners > 0)
            IRunnow(runnow).mint(
                advisorsAndPartners,
                amountForAdvisorsAndPartners
            );
        if (amountForTeamAndOperations > 0)
            IRunnow(runnow).mint(teamAndOperations, amountForTeamAndOperations);
        if (amountForMktAndCommunity > 0)
            IRunnow(runnow).mint(mktAndCommunity, amountForMktAndCommunity);
        if (amountForGameTreasury > 0)
            IRunnow(runnow).mint(gameTreasury, amountForGameTreasury);
        if (amountForFarmingAndStaking > 0)
            IRunnow(runnow).mint(farmingAndStaking, amountForFarmingAndStaking);
        if (amountForLiquidity > 0)
            IRunnow(runnow).mint(liquidity, amountForLiquidity);
        if (
            amountForSeedSale != 0 ||
            amountForPrivateSale != 0 ||
            amountForPublicSale != 0 ||
            amountForAdvisorsAndPartners != 0 ||
            amountForTeamAndOperations != 0 ||
            amountForMktAndCommunity != 0 ||
            amountForGameTreasury != 0 ||
            amountForFarmingAndStaking != 0 ||
            amountForLiquidity != 0
        ) lastestDistributeMonth = month + 1;
    }

    function getAmountForSeedSale(uint256 month)
        public
        view
        returns (uint256 amount)
    {
        uint256 maxAmount = 100_000_000 * 10**decimals;
        uint256 publicSaleAmount = 10_000_000 * 10**decimals;
        uint256 linearAmount = (maxAmount - publicSaleAmount) / 12;
        if (month == 0) amount = publicSaleAmount;
        else if (month >= 1 && month <= 5 ) amount = 0;
        else if (month >= 18 ) amount = 0;
        else if (month >= 6 && month <=16 ) amount = linearAmount;
        else if (month == 17)
            amount = maxAmount - publicSaleAmount - linearAmount * 11;
    }

    function getAmountForPrivateSales(uint256 month)
        public
        view
        returns (uint256 amount)
    {
        uint256 maxAmount = 200_000_000 * 10**decimals;
        uint256 publicSaleAmount = 30_000_000 * 10**decimals;
        uint256 linearAmount = (maxAmount - publicSaleAmount) / 12;
        if (month == 0) amount = publicSaleAmount;
        else if (month >= 1 && month <= 4 ) amount = 0;
        else if (month >= 18 ) amount = 0;
        else if (month >= 5 && month <=15 ) amount = linearAmount;
        else if (month == 16)
            amount = maxAmount - publicSaleAmount - linearAmount * 11;
    }

    function getAmountForPublicSales(uint256 month)
        public
        view
        returns (uint256 amount)
    {
        uint256 maxAmount = 400_000_000 * 10**decimals;
        uint256 publicSaleAmount = 80_000_000 * 10**decimals;
        uint256 linearAmount = (maxAmount - publicSaleAmount) / 6;
        if (month == 0) amount = publicSaleAmount;
        else if (month == 1 ) amount = 0;
        else if (month >= 8 ) amount = 0;
        else if (month >= 2 && month <=6 ) amount = linearAmount;
        else if (month == 7)
            amount = maxAmount - publicSaleAmount - linearAmount * 5;
    }

    function getAmountForAdvisorsAndPartners(uint256 month)
        public
        view
        returns (uint256 amount)
    {
        uint256 maxAmount = 250_000_000 * 10**decimals;
        uint256 linearAmount = maxAmount / 24;
        if (month >= 0 && month < 12) amount = 0;
        else if (month >= 12 && month <= 34) amount = linearAmount;
        else if (month == 35) amount = maxAmount - linearAmount * 23;
        else if (month >= 36) amount = 0;
    }

    function getAmountForTeamAndOperations(uint256 month)
        public
        view
        returns (uint256 amount)
    {
        uint256 maxAmount = 1_000_000_000 * 10**decimals;
        uint256 linearAmount = maxAmount / 24;
        if (month >= 0 && month < 12) amount = 0;
        else if (month >= 12 && month <= 34) amount = linearAmount;
        else if (month == 35) amount = maxAmount - linearAmount * 23;
        else if (month >= 36) amount = 0;
    }

    function getAmountForMktAndCommunity(uint256 month)
        public
        view
        returns (uint256 amount)
    {
        uint256 maxAmount = 500_000_000 * 10**decimals;
        uint256 publicSaleAmount = 5_000_000 * 10**decimals;
        uint256 linearAmount = (maxAmount - publicSaleAmount) / 36;
        if (month > 36) amount = 0;
        else if (month == 0) amount = publicSaleAmount;
        else if (month >= 1 && month <= 35) amount = linearAmount;
        else if (month == 36) amount = maxAmount - publicSaleAmount - linearAmount * 35;
    }

    function getAmountForGameTreasury(uint256 month)
        public
        view
        returns (uint256 amount)
    {
        uint256 maxAmount = 1_750_000_000 * 10**decimals;
        uint256 linearAmount = maxAmount / 36;
        if (month > 36 || month == 0) amount = 0;
        else if (month >= 1 && month < 36) amount = linearAmount;
        else if (month == 36) amount = maxAmount - linearAmount * 35;
    }

    function getAmountForFarmingAndStaking(uint256 month)
        public
        view
        returns (uint256 amount)
    {
        uint256 maxAmount = 750_000_000 * 10**decimals;
        uint256 linearAmount = maxAmount / 32;
        if (month > 36 || month <= 4) amount = 0;
        else if (month >= 5 && month <= 35) amount = linearAmount;
        else if (month == 36) amount = maxAmount - linearAmount * 31;
    }

    function getAmountForLiquidity(uint256 month)
        public
        view
        returns (uint256 amount)
    {
        uint256 maxAmount = 50_000_000 * 10**decimals;
        uint256 publicSaleAmount = 10_000_000 * 10**decimals;
        uint256 linearAmount = (maxAmount - publicSaleAmount) / 2;
        if (month == 0) amount = publicSaleAmount;
        else if (month > 2) amount = 0;
        else if (month == 1 ) amount = linearAmount;
        else if (month == 2)
            amount = maxAmount - publicSaleAmount - linearAmount;
    }

    function getDistributeAmountForSeedSale() external view returns (uint256) {
        uint256 month = (block.timestamp - distributeTime) / SECONDS_PER_MONTH;
        uint256 amountForSeedSale;
        for (uint256 i = lastestDistributeMonth; i <= month; i++) {
            amountForSeedSale += getAmountForSeedSale(i);
        }
        return amountForSeedSale;
    }

    function getDistributeAmountForPrivateSales()
        external
        view
        returns (uint256)
    {
        uint256 month = (block.timestamp - distributeTime) / SECONDS_PER_MONTH;
        uint256 amountForPrivateSale;
        for (uint256 i = lastestDistributeMonth; i <= month; i++) {
            amountForPrivateSale += getAmountForPrivateSales(i);
        }
        return amountForPrivateSale;
    }

    function getDistributeAmountForPublicSales()
        external
        view
        returns (uint256)
    {
        uint256 month = (block.timestamp - distributeTime) / SECONDS_PER_MONTH;
        uint256 amountForPublicSale;
        for (uint256 i = lastestDistributeMonth; i <= month; i++) {
            amountForPublicSale += getAmountForPublicSales(i);
        }
        return amountForPublicSale;
    }

    function getDistributeAmountForAdvisorsAndPartners()
        external
        view
        returns (uint256)
    {
        uint256 month = (block.timestamp - distributeTime) / SECONDS_PER_MONTH;
        uint256 amountForAdvisorsAndPartner;
        for (uint256 i = lastestDistributeMonth; i <= month; i++) {
            amountForAdvisorsAndPartner += getAmountForAdvisorsAndPartners(i);
        }
        return amountForAdvisorsAndPartner;
    }

    function getDistributeAmountForTeamAndOperation()
        external
        view
        returns (uint256)
    {
        uint256 month = (block.timestamp - distributeTime) / SECONDS_PER_MONTH;
        uint256 amountForTeamAndOperations;
        for (uint256 i = lastestDistributeMonth; i <= month; i++) {
            amountForTeamAndOperations += getAmountForTeamAndOperations(i);
        }
        return amountForTeamAndOperations;
    }

    function getDistributeAmountForMktAndCommunity()
        external
        view
        returns (uint256)
    {
        uint256 month = (block.timestamp - distributeTime) / SECONDS_PER_MONTH;
        uint256 amountForMktAndCommunity;
        for (uint256 i = lastestDistributeMonth; i <= month; i++) {
            amountForMktAndCommunity += getAmountForMktAndCommunity(i);
        }
        return amountForMktAndCommunity;
    }

    function getDistributeAmountForGameTreasury()
        external
        view
        returns (uint256)
    {
        uint256 month = (block.timestamp - distributeTime) / SECONDS_PER_MONTH;
        uint256 amountForGameTreasury;
        for (uint256 i = lastestDistributeMonth; i <= month; i++) {
            amountForGameTreasury += getAmountForGameTreasury(i);
        }
        return amountForGameTreasury;
    }

    function getDistributeAmountForFarmingAndStaking()
        external
        view
        returns (uint256)
    {
        uint256 month = (block.timestamp - distributeTime) / SECONDS_PER_MONTH;
        uint256 amountForFarmingAndStaking;
        for (uint256 i = lastestDistributeMonth; i <= month; i++) {
            amountForFarmingAndStaking += getAmountForFarmingAndStaking(i);
        }
        return amountForFarmingAndStaking;
    }

    function getDistributeAmountForLiquidity() external view returns (uint256) {
        uint256 month = (block.timestamp - distributeTime) / SECONDS_PER_MONTH;
        uint256 amountForLiquidity;
        for (uint256 i = lastestDistributeMonth; i <= month; i++) {
            amountForLiquidity += getAmountForLiquidity(i);
        }
        return amountForLiquidity;
    }

    function setNewRunnowOwnership(address newRunnow) external onlyOwner {
        require(address(newRunnow) != address(0));
        IRunnow(runnow).transferOwnership(newRunnow);
        // emit SetRUNNOW(address(newRunnow));
    }
}