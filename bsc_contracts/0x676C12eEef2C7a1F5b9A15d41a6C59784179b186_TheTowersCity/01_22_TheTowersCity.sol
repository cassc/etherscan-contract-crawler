//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "./Token.sol";
import "./Tower.sol";
import "./Airdrop.sol";

contract TheTowersCity is Ownable, Pausable, Initializable {
    Token public token;
    Tower public tower;
    Airdrop public airdrop;

    struct Mortgage {
        address user;
        uint256 paymentsLeft;
        uint256 nextPaymentDue;
        uint256 paymentAmount;
        uint256 totalAmount;
        uint256 startTime;
        uint8 square;
    }

    // tower prices
    uint256 public basePrice;
    uint256 public deltaPrice;
    uint256 public upgradePrice;

    uint256 public VIPChance;

    // rewards
    uint8 public maxDailyClaims;

    uint256 public towerBaseReward;
    uint256 public towerDeltaReward;

    uint256 public investmentRewardsRatio;
    uint256 public investmentRewardsRatioDenom;

    uint256 public towerOwnersCommission;
    uint256 public towerOwnersCommissionDenom;

    uint256 public VIPMultiplier;
    uint256 public VIPMultiplierDenom;

    // mortgage
    uint256 public mortgagePayments;
    uint256 public mortgageInterest;
    uint256 public mortgageInterestDenom;
    uint256 public mortgageMaxAmount;
    uint256 public mortgageMaxAmountDenom;
    uint256 public mortgagePeriod;

    uint8 public buildingCounter;

    bytes32 public difficulty;

    mapping(uint8 => uint256) public lastWorkDay;
    mapping(uint8 => uint256) public lastWorkCount;
    mapping(uint8 => bytes32) public lastWorkHash;

    mapping(uint8 => uint256) public submittedWorksCount;
    mapping(address => mapping(uint8 => uint256)) public claimedRewardsCount; // user -> building -> amount

    mapping(address => mapping(uint8 => uint256)) public funding; // user -> building -> amount

    uint8 public mortgageCounter;

    mapping(uint8 => Mortgage) public mortgages;

    event Create(address indexed creator, uint8 indexed square, uint256 price, bool isVip);
    event Upgrade(address indexed creator, uint8 indexed square, uint256 price, uint8 level);
    event NewMiningCommitted(address indexed creator, uint8 indexed square, uint256 reward, bytes32 nextHash);
    event NewBuildingInfo(address indexed creator, uint8 indexed square);
    event NewBillboard(address indexed creator, uint8 indexed square);
    event NewFunding(address indexed funder, uint8 indexed square, uint256 amount);
    event NewRewards(address indexed funder, uint8 indexed square, uint256 amount);
    event NewMortgage(uint8 indexed id);
    event MortgageLiquidation(uint8 indexed id);
    event ParamsChanged();

    function initialize(Tower _tower, Token _token, Airdrop _airdrop, uint256 _airdropAmount, address _owner) public initializer {
        _transferOwnership(_owner);

        // tower prices
        basePrice = 0 ether;
        deltaPrice = 2500 ether;
        upgradePrice = 100000 ether;
        VIPChance = 0;

        // rewards
        maxDailyClaims = 0;

        towerBaseReward = 0 ether;
        towerDeltaReward = 0 ether;

        investmentRewardsRatio = 0;
        investmentRewardsRatioDenom = 1e8;

        towerOwnersCommission = 10;
        towerOwnersCommissionDenom = 100;

        VIPMultiplier = 1;
        VIPMultiplierDenom = 1;

        // mortgage
        mortgagePayments = 20;
        mortgageInterest = 100;
        mortgageInterestDenom = 100;
        mortgageMaxAmount = 70;
        mortgageMaxAmountDenom = 100;
        mortgagePeriod = 7 days;

        difficulty = bytes32(0x0000100000000000000000000000000000000000000000000000000000000000);

        tower = _tower;
        token = _token;
        airdrop = _airdrop;

        token.setSpender(address(this));
        tower.setMinter(address(this));

        token.mint(_owner, 100_000_000 ether - _airdropAmount);

        // airdrop
        token.mint(address(airdrop), _airdropAmount);

        buildingCounter++;
        tower.mint(0x68001420733bE1F8cA639112108a0Eba7c19A365, 60, false, 0);
        emit Create(0x68001420733bE1F8cA639112108a0Eba7c19A365, 60, 0, false);

        buildingCounter++;
        tower.mint(0xBC0Bb37FA466234A742B460AA93cAeAe59B4b95f, 61, false, 0);
        emit Create(0xBC0Bb37FA466234A742B460AA93cAeAe59B4b95f, 61, 0, false);

        buildingCounter++;
        tower.mint(0x350c991c3B5D4893ffADeDE20393a9A3d96F19CF, 62, false, 0);
        emit Create(0x350c991c3B5D4893ffADeDE20393a9A3d96F19CF, 62, 0, false);
    }

    function createBuilding(uint8 _square, address _to, uint256 _maxToSpend, uint256 _mortgageAmount) whenNotPaused public {
        require(_square > 0 && _square <= 100, "TowersCity: wrong square");
        require(!tower.exists(_square), "TowersCity: square is already occupied");

        uint256 price = getPriceForNextBuilding();

        require(_mortgageAmount < price * mortgageMaxAmount / mortgageMaxAmountDenom, "TowersCity: you cannot borrow more than N% of building cost");

        buildingCounter++;

        uint8 mortgageId = 0;
        if (_mortgageAmount > 0) {
            mortgageCounter++;
            mortgageId = mortgageCounter;
            uint256 paymentAmount = (_mortgageAmount + _mortgageAmount * mortgageInterest / mortgageInterestDenom) / mortgagePayments;

            mortgages[mortgageId] = Mortgage(_to, mortgagePayments, block.timestamp + mortgagePeriod, paymentAmount, _mortgageAmount, block.timestamp, _square);

            emit NewMortgage(mortgageId);
        }

        uint256 toSpend = price - _mortgageAmount;

        require(_maxToSpend == 0 || toSpend <= _maxToSpend, "TowersCity: _maxToSpend limit reached");

        token.fastApprove(msg.sender, toSpend);
        token.transferFrom(msg.sender, address(this), toSpend);
        token.burn(toSpend);

        bool isVIP = uint(keccak256(abi.encode(block.timestamp))) % 100 < VIPChance;

        // do not allow to create VIP buildings from smart contracts
        if (tx.origin != msg.sender || isContract(msg.sender)) {
            isVIP = false;
        }

        tower.mint(_to, _square, isVIP, mortgageId);

        emit Create(msg.sender, _square, price, isVIP);
    }

    function payMortgage(uint8 _mortgageId) whenNotPaused public {
        require(mortgages[_mortgageId].paymentsLeft > 0, "TowersCity: mortgage is already paid");

        uint256 toPay = mortgages[_mortgageId].paymentAmount;

        token.fastApprove(msg.sender, toPay);
        token.transferFrom(msg.sender, address(this), toPay);
        token.burn(toPay);

        mortgages[_mortgageId].nextPaymentDue = mortgages[_mortgageId].nextPaymentDue + mortgagePeriod;
        mortgages[_mortgageId].paymentsLeft--;
    }

    function liquidateOverdueMortgages(uint8[] memory _mortgageIds) whenNotPaused public {
        for (uint256 i = 0; i < _mortgageIds.length; i++) {
            uint8 id = _mortgageIds[i];

            require(mortgages[id].nextPaymentDue < block.timestamp, "TowersCity: mortgage is not overdue");
            require(mortgages[id].paymentsLeft > 0, "TowersCity: Mortgage is paid");

            tower.liquidate(mortgages[id].square);

            emit MortgageLiquidation(id);
        }
    }

    function getPriceForNextBuilding() public view returns(uint256) {
        return basePrice + buildingCounter * deltaPrice;
    }

    function getPriceForUpgrade() public view returns(uint256) {
        return upgradePrice;
    }

    function getMiningReward(uint8 _square) public view returns(uint256 reward) {
        reward = towerBaseReward + towerDeltaReward * (tower.level(_square) - 1);
        if (tower.vip(_square)) {
            reward = reward * VIPMultiplier / VIPMultiplierDenom;
        }
    }

    function getInvestmentReward(address _user, uint8 _square) public view returns(uint256) {
        uint count = submittedWorksCount[_square] - claimedRewardsCount[_user][_square];
        if (count > 30) {
            count = 30;
        }

        return funding[_user][_square] * count * investmentRewardsRatio / investmentRewardsRatioDenom;
    }

    function isContract(address _addr) private view returns (bool) {
        // warning: doesn't always work properly
        return _addr.code.length > 0;
    }

    function commitMiningWork(uint8 _square, uint256 _work) public whenNotPaused notLiquidated(_square) onlyOwnerOfSquare(_square) {
        uint256 day = block.timestamp / 1 days;
        if (lastWorkDay[_square] != day) {
            lastWorkDay[_square] = day;
            lastWorkCount[_square] = 0;
        }

        require(lastWorkCount[_square] < maxDailyClaims, "TowersCity: max work done for today");
        require(keccak256(abi.encode(_work, _square, lastWorkHash[_square])) < difficulty, "TowersCity: wrong work"); // Check if hash is under the difficulty

        lastWorkCount[_square]++;
        lastWorkHash[_square] = blockhash(block.number - 1);

        uint256 reward = getMiningReward(_square);
        token.mint(msg.sender, reward);

        submittedWorksCount[_square]++;

        emit NewMiningCommitted(msg.sender, _square, reward, lastWorkHash[_square]);
    }

    function upgradeBuilding(uint8 _square) public whenNotPaused onlyOwnerOfSquare(_square) {
        uint256 price = getPriceForUpgrade();
        token.fastApprove(msg.sender, price);
        token.transferFrom(msg.sender, address(this), price);
        token.burn(price);

        tower.upgrade(_square);

        emit Upgrade(msg.sender, _square, price, tower.level(_square));
    }

    function setBuildingInfo(uint8 _square, string memory _title, string memory _description, string memory _link) public whenNotPaused onlyOwnerOfSquare(_square) {
        tower.setBuildingInfo(_square, _title, _description, _link);
        emit NewBuildingInfo(msg.sender, _square);
    }

    function setBuildingBillboard(uint8 _square, string memory _billboard) public whenNotPaused onlyOwnerOfSquare(_square) {
        tower.setBuildingBillboard(_square, _billboard);
        emit NewBillboard(msg.sender, _square);
    }

    function fundTower(uint8 _square, uint256 _amount) public whenNotPaused {
        require(tower.exists(_square), "TowersCity: building does not exist");
        require((claimedRewardsCount[msg.sender][_square] == 0 && funding[msg.sender][_square] == 0) || claimedRewardsCount[msg.sender][_square] == submittedWorksCount[_square], "TowersCity: claim rewards before funding tower");

        token.fastApprove(msg.sender, _amount);
        token.transferFrom(msg.sender, address(this), _amount);
        token.burn(_amount);

        tower.addCapital(_square, _amount);

        funding[msg.sender][_square] += _amount;
        claimedRewardsCount[msg.sender][_square] = submittedWorksCount[_square];

        emit NewFunding(msg.sender, _square, _amount);
    }

    function claimRewards(uint8[] calldata _squares) public whenNotPaused {
        for (uint256 i = 0; i < _squares.length; i++) {
            uint8 square = _squares[i];

            require(tower.exists(square), "TowersCity: building does not exist");
            require(funding[msg.sender][square] > 0, "TowersCity: no funding from sender");
            require(claimedRewardsCount[msg.sender][square] < submittedWorksCount[square], "TowersCity: no rewards to claim");

            uint256 amount = getInvestmentReward(msg.sender, square);
            uint256 toOwner = amount * towerOwnersCommission / towerOwnersCommissionDenom;

            token.mint(tower.ownerOf(square), toOwner);
            token.mint(msg.sender, amount - toOwner);

            claimedRewardsCount[msg.sender][square] = submittedWorksCount[square];

            emit NewRewards(msg.sender, square, amount);
        }
    }

    function setDifficulty(bytes32 _difficulty) public onlyOwner {
        difficulty = _difficulty;

        emit ParamsChanged();
    }

    function setRewardParams(uint256 _towerBaseReward, uint256 _towerDeltaReward, uint256 _investmentRewardsRatio, uint256 _investmentRewardsRatioDenom, uint8 _maxDailyClaims, uint256 _towerOwnersCommission, uint256 _towerOwnersCommissionDenom, uint256 _VIPMultiplier, uint256 _VIPMultiplierDenom) public onlyOwner {
        towerBaseReward = _towerBaseReward;
        towerDeltaReward = _towerDeltaReward;

        investmentRewardsRatio = _investmentRewardsRatio;
        investmentRewardsRatioDenom = _investmentRewardsRatioDenom;

        maxDailyClaims = _maxDailyClaims;

        towerOwnersCommission = _towerOwnersCommission;
        towerOwnersCommissionDenom = _towerOwnersCommissionDenom;

        VIPMultiplier = _VIPMultiplier;
        VIPMultiplierDenom = _VIPMultiplierDenom;

        emit ParamsChanged();
    }

    function setMortgageParams(uint256 _mortgagePayments, uint256 _mortgageInterest, uint256 _mortgageInterestDenom, uint256 _mortgageMaxAmount, uint256 _mortgageMaxAmountDenom, uint256 _mortgagePeriod) public onlyOwner {
        mortgagePayments = _mortgagePayments;
        mortgageInterest = _mortgageInterest;
        mortgageInterestDenom = _mortgageInterestDenom;
        mortgageMaxAmount = _mortgageMaxAmount;
        mortgageMaxAmountDenom = _mortgageMaxAmountDenom;
        mortgagePeriod = _mortgagePeriod;

        emit ParamsChanged();
    }

    function setTowerParams(uint256 _basePrice, uint256 _deltaPrice, uint256 _upgradePrice, uint256 _VIPChance) public onlyOwner {
        basePrice = _basePrice;
        deltaPrice = _deltaPrice;
        upgradePrice = _upgradePrice;
        VIPChance = _VIPChance;

        emit ParamsChanged();
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    modifier onlyOwnerOfSquare(uint8 _square) {
        require(msg.sender == tower.ownerOf(_square), "TowersCity: sender is not an owner of the building");
        _;
    }

    modifier notLiquidated(uint8 _square) {
        require(!tower.isLiquidated(_square), "TowersCity: building is liquidated");
        _;
    }
}