/**
 *Submitted for verification at BscScan.com on 2023-03-13
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;



/*
                CCCCCCCCCCCCCUUUUUUUU     UUUUUUUULLLLLLLLLLL             MMMMMMMM               MMMMMMMMBBBBBBBBBBBBBBBBB   LLLLLLLLLLL             EEEEEEEEEEEEEEEEEEEEEE
             CCC::::::::::::CU::::::U     U::::::UL:::::::::L             M:::::::M             M:::::::MB::::::::::::::::B  L:::::::::L             E::::::::::::::::::::E
           CC:::::::::::::::CU::::::U     U::::::UL:::::::::L             M::::::::M           M::::::::MB::::::BBBBBB:::::B L:::::::::L             E::::::::::::::::::::E
          C:::::CCCCCCCC::::CUU:::::U     U:::::UULL:::::::LL             M:::::::::M         M:::::::::MBB:::::B     B:::::BLL:::::::LL             EE::::::EEEEEEEEE::::E
         C:::::C       CCCCCC U:::::U     U:::::U   L:::::L               M::::::::::M       M::::::::::M  B::::B     B:::::B  L:::::L                 E:::::E       EEEEEE
        C:::::C               U:::::D     D:::::U   L:::::L               M:::::::::::M     M:::::::::::M  B::::B     B:::::B  L:::::L                 E:::::E             
        C:::::C               U:::::D     D:::::U   L:::::L               M:::::::M::::M   M::::M:::::::M  B::::BBBBBB:::::B   L:::::L                 E::::::EEEEEEEEEE   
        C:::::C               U:::::D     D:::::U   L:::::L               M::::::M M::::M M::::M M::::::M  B:::::::::::::BB    L:::::L                 E:::::::::::::::E   
        C:::::C               U:::::D     D:::::U   L:::::L               M::::::M  M::::M::::M  M::::::M  B::::BBBBBB:::::B   L:::::L                 E:::::::::::::::E   
        C:::::C               U:::::D     D:::::U   L:::::L               M::::::M   M:::::::M   M::::::M  B::::B     B:::::B  L:::::L                 E::::::EEEEEEEEEE   
        C:::::C               U:::::D     D:::::U   L:::::L               M::::::M    M:::::M    M::::::M  B::::B     B:::::B  L:::::L                 E:::::E             
         C:::::C       CCCCCC U::::::U   U::::::U   L:::::L         LLLLLLM::::::M     MMMMM     M::::::M  B::::B     B:::::B  L:::::L         LLLLLL  E:::::E       EEEEEE
          C:::::CCCCCCCC::::C U:::::::UUU:::::::U LL:::::::LLLLLLLLL:::::LM::::::M               M::::::MBB:::::BBBBBB::::::BLL:::::::LLLLLLLLL:::::LEE::::::EEEEEEEE:::::E
           CC:::::::::::::::C  UU:::::::::::::UU  L::::::::::::::::::::::LM::::::M               M::::::MB:::::::::::::::::B L::::::::::::::::::::::LE::::::::::::::::::::E
             CCC::::::::::::C    UU:::::::::UU    L::::::::::::::::::::::LM::::::M               M::::::MB::::::::::::::::B  L::::::::::::::::::::::LE::::::::::::::::::::E
                CCCCCCCCCCCCC      UUUUUUUUU      LLLLLLLLLLLLLLLLLLLLLLLLMMMMMMMM               MMMMMMMMBBBBBBBBBBBBBBBBB   LLLLLLLLLLLLLLLLLLLLLLLLEEEEEEEEEEEEEEEEEEEEEE
*/



abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data; 
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        _setOwner(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

abstract contract Pausable is Context {
    event Paused(address account);

    event Unpaused(address account);

    bool private _paused;

    constructor() {
        _paused = false;
    }

    function paused() public view virtual returns (bool) {
        return _paused;
    }

    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        _status = _ENTERED;

        _;
        _status = _NOT_ENTERED;
    }
}

interface IRandomNumberGenerator {
    function getRandomNumber() external returns (uint256 requestId);
    function getDiceStatus(uint256 _diceRequestId) external view returns (bool fulfilled);
    function viewRandomResult() external view returns (uint32);
}


contract DiceRollV1 is Ownable, Pausable, ReentrancyGuard {
    IRandomNumberGenerator public randomNumberGenerator;

    address public adminAddress;
    address public manipulatorAddress;

    bool public manipulatorStartOnce = false;

    uint256 public bufferSeconds; 
    uint256 public intervalSeconds; 

    uint256 public currentEpoch;
    uint256 public minBetAmount;
    uint256 public treasuryFee;
    uint256 public treasuryAmount;

    uint256 public constant MAX_TREASURY_FEE = 1500; // 1500 = %15 MAX TREASURY FEE

    mapping(uint256 => mapping(address => BetInfo)) public ledger;
    mapping(uint256 => Dice) public rolledDices;
    mapping(address => uint256[]) public userRolledDices;

    struct Dice {
        uint256 epoch;
        uint256 startTimestamp;
        uint256 lockTimestamp;
        uint256 closeTimestamp;
        Amount amounts;
        uint32 position;
        uint256 requestId;
        uint256 playerCount;
        bool canceled;
    }

    struct Amount {    
        uint256 totalAmount;
        uint256 firstFaceAmount;
        uint256 secondFaceAmount;
        uint256 thirdFaceAmount;
        uint256 fourthFaceAmount;
        uint256 fifthFaceAmount;
        uint256 sixthFaceAmount;
        uint256 rewardBaseCalAmount;
        uint256 rewardAmount;
    }

    struct BetInfo {
        uint32 position;
        uint256 amount;
        bool claimed; 
    }

    event BetFirstFace(
        address indexed sender,
        uint256 indexed epoch,
        uint256 amount
    );

    event BetSecondFace(
        address indexed sender,
        uint256 indexed epoch,
        uint256 amount
    );

    event BetThirdFace(
        address indexed sender,
        uint256 indexed epoch,
        uint256 amount
    );

    event BetFourthFace(
        address indexed sender,
        uint256 indexed epoch,
        uint256 amount
    );

    event BetFifthFace(
        address indexed sender,
        uint256 indexed epoch,
        uint256 amount
    );

    event BetSixthFace(
        address indexed sender,
        uint256 indexed epoch,
        uint256 amount
    );

    event DiceEndedcanceled(uint256 indexed epoch);
    event EndDice(uint256 indexed epoch, uint32 position);
    event RollDice(uint256 indexed epoch, uint256 requestId);
    event StartDice(uint256 indexed epoch);
    event Claim(address indexed sender, uint256 indexed epoch, uint256 amount);
    event NewAdminAddress(address admin);
    event NewMinBetAmount(uint256 indexed epoch, uint256 minBetAmount);
    event NewTreasuryFee(uint256 indexed epoch, uint256 treasuryFee);
    event NewManipulatorAddress(address manipulator);
    event NewBufferAndIntervalSeconds(uint256 bufferSeconds, uint256 intervalSeconds);
    event NewRandomGenerator(address indexed randomGenerator);
    event Pause(uint256 indexed epoch);
    event Unpause(uint256 indexed epoch);
    event TreasuryClaim(uint256 amount);

    event RewardsCalculated(
        uint256 indexed epoch,
        uint256 rewardBaseCalAmount,
        uint256 rewardAmount,
        uint256 treasuryAmount
    );
    

    modifier onlyAdmin() {
        require(msg.sender == adminAddress, "Not admin");
        _;
    }

    modifier onlyAdminOrManipulator() {
        require(
            msg.sender == adminAddress || msg.sender == manipulatorAddress,
            "Not manipulator/admin"
        );
        _;
    }

    modifier onlyManipulator() {
        require(msg.sender == manipulatorAddress, "Not manipulator");
        _;
    }

    modifier notContract() {
        require(!_isContract(msg.sender), "Contract not allowed");
        require(msg.sender == tx.origin, "Proxy contract not allowed");
        _;
    }

    constructor(
        address _adminAddress,
        address _manipulatorAddress,
        address _randomGeneratorAddress,
        uint256 _intervalSeconds,
        uint256 _bufferSeconds,
        uint256 _minBetAmount,
        uint256 _treasuryFee
    ) {
        require(_treasuryFee <= MAX_TREASURY_FEE, "Treasury fee too high");
        randomNumberGenerator = IRandomNumberGenerator(_randomGeneratorAddress);
        adminAddress = _adminAddress;
        manipulatorAddress = _manipulatorAddress;
        intervalSeconds = _intervalSeconds;
        bufferSeconds = _bufferSeconds;
        minBetAmount = _minBetAmount;
        treasuryFee = _treasuryFee;
    }

    function betFirstFace(uint256 epoch)
        external
        payable
        whenNotPaused
        nonReentrant
        notContract
    {
        require(_bettable(epoch), "Dice not bettable");
        require(
            msg.value >= minBetAmount,
            "Bet amount must be greater than minBetAmount"
        );
        require(
            ledger[epoch][msg.sender].amount == 0,
            "Can only bet once per dice"
        );

        uint256 amount = msg.value;
        Dice storage _dice = rolledDices[epoch];
        _dice.amounts.totalAmount = _dice.amounts.totalAmount + amount;
        _dice.amounts.firstFaceAmount = _dice.amounts.firstFaceAmount + amount;
        _dice.playerCount += 1;

        BetInfo storage betInfo = ledger[epoch][msg.sender];
        betInfo.position = 1;
        betInfo.amount = amount;
        userRolledDices[msg.sender].push(epoch);

        emit BetFirstFace(msg.sender, epoch, amount);
    }

    function betSecondFace(uint256 epoch)
        external
        payable
        whenNotPaused
        nonReentrant
        notContract
    {
        require(_bettable(epoch), "Dice not bettable");
        require(
            msg.value >= minBetAmount,
            "Bet amount must be greater than minBetAmount"
        );
        require(
            ledger[epoch][msg.sender].amount == 0,
            "Can only bet once per dice"
        );

        uint256 amount = msg.value;
        Dice storage _dice = rolledDices[epoch];
        _dice.amounts.totalAmount = _dice.amounts.totalAmount + amount;
        _dice.amounts.secondFaceAmount = _dice.amounts.secondFaceAmount + amount;
        _dice.playerCount += 1;

        BetInfo storage betInfo = ledger[epoch][msg.sender];
        betInfo.position = 2;
        betInfo.amount = amount;
        userRolledDices[msg.sender].push(epoch);

        emit BetSecondFace(msg.sender, epoch, amount);
    }

    function betThirdFace(uint256 epoch)
        external
        payable
        whenNotPaused
        nonReentrant
        notContract
    {
        require(_bettable(epoch), "Dice not bettable");
        require(
            msg.value >= minBetAmount,
            "Bet amount must be greater than minBetAmount"
        );
        require(
            ledger[epoch][msg.sender].amount == 0,
            "Can only bet once per dice"
        );

        uint256 amount = msg.value;
        Dice storage _dice = rolledDices[epoch];
        _dice.amounts.totalAmount = _dice.amounts.totalAmount + amount;
        _dice.amounts.thirdFaceAmount = _dice.amounts.thirdFaceAmount + amount;
        _dice.playerCount += 1;

        BetInfo storage betInfo = ledger[epoch][msg.sender];
        betInfo.position = 3;
        betInfo.amount = amount;
        userRolledDices[msg.sender].push(epoch);

        emit BetThirdFace(msg.sender, epoch, amount);
    }

    function betFourthFace(uint256 epoch)
        external
        payable
        whenNotPaused
        nonReentrant
        notContract
    {
        require(_bettable(epoch), "Dice not bettable");
        require(
            msg.value >= minBetAmount,
            "Bet amount must be greater than minBetAmount"
        );
        require(
            ledger[epoch][msg.sender].amount == 0,
            "Can only bet once per dice"
        );

        uint256 amount = msg.value;
        Dice storage _dice = rolledDices[epoch];
        _dice.amounts.totalAmount = _dice.amounts.totalAmount + amount;
        _dice.amounts.fourthFaceAmount = _dice.amounts.fourthFaceAmount + amount;
        _dice.playerCount += 1;

        BetInfo storage betInfo = ledger[epoch][msg.sender];
        betInfo.position = 4;
        betInfo.amount = amount;
        userRolledDices[msg.sender].push(epoch);

        emit BetFourthFace(msg.sender, epoch, amount);
    }

    function betFifthFace(uint256 epoch)
        external
        payable
        whenNotPaused
        nonReentrant
        notContract
    {
        require(_bettable(epoch), "Dice not bettable");
        require(
            msg.value >= minBetAmount,
            "Bet amount must be greater than minBetAmount"
        );
        require(
            ledger[epoch][msg.sender].amount == 0,
            "Can only bet once per dice"
        );

        uint256 amount = msg.value;
        Dice storage _dice = rolledDices[epoch];
        _dice.amounts.totalAmount = _dice.amounts.totalAmount + amount;
        _dice.amounts.fifthFaceAmount = _dice.amounts.fifthFaceAmount + amount;
        _dice.playerCount += 1;

        BetInfo storage betInfo = ledger[epoch][msg.sender];
        betInfo.position = 5;
        betInfo.amount = amount;
        userRolledDices[msg.sender].push(epoch);

        emit BetFifthFace(msg.sender, epoch, amount);
    }

    function betSixthFace(uint256 epoch)
        external
        payable
        whenNotPaused
        nonReentrant
        notContract
    {
        require(_bettable(epoch), "Dice not bettable");
        require(
            msg.value >= minBetAmount,
            "Bet amount must be greater than minBetAmount"
        );
        require(
            ledger[epoch][msg.sender].amount == 0,
            "Can only bet once per dice"
        );

        uint256 amount = msg.value;
        Dice storage _dice = rolledDices[epoch];
        _dice.amounts.totalAmount = _dice.amounts.totalAmount + amount;
        _dice.amounts.sixthFaceAmount = _dice.amounts.sixthFaceAmount + amount;
        _dice.playerCount += 1;

        BetInfo storage betInfo = ledger[epoch][msg.sender];
        betInfo.position = 6;
        betInfo.amount = amount;
        userRolledDices[msg.sender].push(epoch);

        emit BetSixthFace(msg.sender, epoch, amount);
    }

    

    function claim(uint256[] calldata epochs)
        external
        nonReentrant
        notContract
    {
        uint256 reward;

        for (uint256 i = 0; i < epochs.length; i++) {
            require(
                rolledDices[epochs[i]].startTimestamp != 0,
                "Match has not started"
            );
            require(
                rolledDices[epochs[i]].closeTimestamp != 0,
                 "Match has not finished"
            );
            require(
                block.timestamp > rolledDices[epochs[i]].closeTimestamp,
                "Match has not ended"
            );

            uint256 addedReward = 0;

            if (!rolledDices[epochs[i]].canceled) {
                require(claimable(epochs[i], msg.sender), "Not eligible for claim");
                Dice memory _dice = rolledDices[epochs[i]];
                addedReward = (ledger[epochs[i]][msg.sender].amount * _dice.amounts.rewardAmount) / _dice.amounts.rewardBaseCalAmount;
            }
            else {
                require(refundable(epochs[i], msg.sender), "Not eligible for refund");
                addedReward = ledger[epochs[i]][msg.sender].amount;
            }

            ledger[epochs[i]][msg.sender].claimed = true;
            reward += addedReward;

            emit Claim(msg.sender, epochs[i], addedReward);
        }

        if (reward > 0) {
            _safeTransferBNB(address(msg.sender), reward);
        }
    }

    function executeDice() external whenNotPaused onlyManipulator {

        _safeEndDice(currentEpoch);
        _calculateRewards(currentEpoch);

        currentEpoch = currentEpoch + 1;
        _safeStartDice(currentEpoch);
    }

    function rollDice() external whenNotPaused onlyManipulator {
        _safeRollDice(currentEpoch);
    }

    function manipulatorCancelDice() external whenNotPaused onlyManipulator {
        _safeCancelDice(currentEpoch);
        currentEpoch = currentEpoch + 1;
        _safeStartDice(currentEpoch);
    }


    function manipulatorStartDice() external whenNotPaused onlyManipulator {
        require(!manipulatorStartOnce, "Can only run manipulatorStartDice once");

        currentEpoch = currentEpoch + 1;
        _startDice(currentEpoch);
        manipulatorStartOnce = true;
    }

    function manipulatorTriggerDice() external whenNotPaused onlyManipulator {
        _safeTriggerDice(currentEpoch);
    }

    function pause() external whenNotPaused onlyAdminOrManipulator {
        _pause();
        emit Pause(currentEpoch);
    }

    function claimTreasury() external nonReentrant onlyAdmin {
        require(treasuryAmount != 0);
        uint256 currentTreasuryAmount = treasuryAmount;
        treasuryAmount = 0;
        _safeTransferBNB(adminAddress, currentTreasuryAmount);

        emit TreasuryClaim(currentTreasuryAmount);
    }

    function unpause() external whenPaused onlyAdmin {
        manipulatorStartOnce = false;

        _unpause();
        emit Unpause(currentEpoch);
    }

    function setBufferAndIntervalSeconds(uint256 _bufferSeconds, uint256 _intervalSeconds)
        external
        whenPaused
        onlyAdmin
    {
        require(_bufferSeconds < _intervalSeconds, "bufferSeconds must be inferior to intervalSeconds");
        bufferSeconds = _bufferSeconds;
        intervalSeconds = _intervalSeconds;

        emit NewBufferAndIntervalSeconds(_bufferSeconds, _intervalSeconds);
    }

    function setMinBetAmount(uint256 _minBetAmount)
        external
        whenPaused
        onlyAdmin
    {
        require(_minBetAmount != 0, "Must be superior to 0");
        minBetAmount = _minBetAmount;

        emit NewMinBetAmount(currentEpoch,minBetAmount);
    }

    function setManipulator(address _manipulatorAddress) external onlyAdmin {
        require(_manipulatorAddress != address(0), "Cannot be zero address");
        manipulatorAddress = _manipulatorAddress;

        emit NewManipulatorAddress(_manipulatorAddress);
    }

    function setTreasuryFee(uint256 _treasuryFee)
        external
        whenPaused
        onlyAdmin
    {
        require(_treasuryFee <= MAX_TREASURY_FEE, "Treasury fee too high");
        treasuryFee = _treasuryFee;

        emit NewTreasuryFee(currentEpoch,treasuryFee);
    }

    function setAdmin(address _adminAddress) external onlyOwner {
        require(_adminAddress != address(0), "Cannot be zero address");
        adminAddress = _adminAddress;

        emit NewAdminAddress(_adminAddress);
    }

    function changeRandomGenerator(address _randomGeneratorAddress) external onlyAdmin {

        randomNumberGenerator = IRandomNumberGenerator(_randomGeneratorAddress);

        emit NewRandomGenerator(_randomGeneratorAddress);
    }

    function getUserRolledDices(
        address user,
        uint256 cursor,
        uint256 size
    )
        external
        view
        returns (
            uint256[] memory,
            BetInfo[] memory,
            uint256
        )
    {
        uint256 length = size;

        if (length > userRolledDices[user].length - cursor) {
            length = userRolledDices[user].length - cursor;
        }

        uint256[] memory values = new uint256[](length);
        BetInfo[] memory betInfo = new BetInfo[](length);

        for (uint256 i = 0; i < length; i++) {
            values[i] = userRolledDices[user][cursor + i];
            betInfo[i] = ledger[values[i]][user];
        }

        return (values, betInfo, cursor + length);
    }

    function getUserRolledDicesLength(address user)
        external
        view
        returns (uint256)
    {
        return userRolledDices[user].length;
    }

    function claimable(uint256 epoch, address user) public view returns (bool) {
        BetInfo memory betInfo = ledger[epoch][user];
        Dice memory _dice = rolledDices[epoch];
        return
            !_dice.canceled &&
            betInfo.amount != 0 &&
            !betInfo.claimed &&
            ((_dice.position == 1 && betInfo.position == 1) ||
               (_dice.position ==  2 && betInfo.position == 2) ||
               (_dice.position ==  3 && betInfo.position == 3) ||
               (_dice.position ==  4 && betInfo.position == 4) ||
               (_dice.position ==  5 && betInfo.position == 5) ||
               (_dice.position ==  6 && betInfo.position == 6));
    }

    function refundable(uint256 epoch, address user)
        public
        view
        returns (bool)
    {
        BetInfo memory betInfo = ledger[epoch][user];
        Dice memory _dice = rolledDices[epoch];

        return
            _dice.canceled &&
            !betInfo.claimed &&
            _dice.closeTimestamp != 0 &&
            block.timestamp > _dice.closeTimestamp + bufferSeconds &&
            betInfo.amount != 0;
    }

    function _calculateRewards(uint256 epoch) internal {
        require(
            rolledDices[epoch].amounts.rewardBaseCalAmount == 0 &&
                rolledDices[epoch].amounts.rewardAmount == 0,
            "Rewards calculated"
        );
        Dice storage _dice = rolledDices[epoch];
        uint256 rewardBaseCalAmount;
        uint256 treasuryAmt;
        uint256 rewardAmount;

        if (_dice.position == 1) {
            rewardBaseCalAmount = _dice.amounts.firstFaceAmount;
            treasuryAmt = (_dice.amounts.totalAmount * treasuryFee) / 10000;
            rewardAmount = _dice.amounts.totalAmount - treasuryAmt;
        } else if (_dice.position == 2) {
            rewardBaseCalAmount = _dice.amounts.secondFaceAmount;
            treasuryAmt = (_dice.amounts.totalAmount * treasuryFee) / 10000;
            rewardAmount = _dice.amounts.totalAmount - treasuryAmt;
        } else if (_dice.position == 3) {
            rewardBaseCalAmount = _dice.amounts.thirdFaceAmount;
            treasuryAmt = (_dice.amounts.totalAmount * treasuryFee) / 10000;
            rewardAmount = _dice.amounts.totalAmount - treasuryAmt;
        } else if (_dice.position == 4) {
            rewardBaseCalAmount = _dice.amounts.fourthFaceAmount;
            treasuryAmt = (_dice.amounts.totalAmount * treasuryFee) / 10000;
            rewardAmount = _dice.amounts.totalAmount - treasuryAmt;
        } else if (_dice.position == 5) {
            rewardBaseCalAmount = _dice.amounts.fifthFaceAmount;
            treasuryAmt = (_dice.amounts.totalAmount * treasuryFee) / 10000;
            rewardAmount = _dice.amounts.totalAmount - treasuryAmt;
        } else if (_dice.position == 6) {
            rewardBaseCalAmount = _dice.amounts.sixthFaceAmount;
            treasuryAmt = (_dice.amounts.totalAmount * treasuryFee) / 10000;
            rewardAmount = _dice.amounts.totalAmount - treasuryAmt;
        } else {
            rewardBaseCalAmount = 0;
            rewardAmount = 0;
            treasuryAmt = _dice.amounts.totalAmount;
        }
        _dice.amounts.rewardBaseCalAmount = rewardBaseCalAmount;
        _dice.amounts.rewardAmount = rewardAmount;

        treasuryAmount += treasuryAmt;

        emit RewardsCalculated(
            epoch,
            rewardBaseCalAmount,
            rewardAmount,
            treasuryAmt
        );
    }

  function _safeEndDice(
        uint256 epoch
    ) internal {
        require(rolledDices[epoch].lockTimestamp != 0, "Can only end dice after dice has locked");
        require(rolledDices[epoch].closeTimestamp != 0, "Can only roll dice after dice has triggered");
        require(block.timestamp >= rolledDices[epoch].closeTimestamp, "Can only end dice after closeTimestamp");

        require(
            block.timestamp <= rolledDices[epoch].closeTimestamp + bufferSeconds,
            "Can only end dice within bufferSeconds"
        );
         require(rolledDices[epoch].requestId != 0);

         bool diceRolled = randomNumberGenerator.getDiceStatus(rolledDices[epoch].requestId);
         require(diceRolled,"Dice still rolling");

         uint32 position = randomNumberGenerator.viewRandomResult();
         Dice storage _dice = rolledDices[epoch];
        _dice.position = position;

        emit EndDice(epoch, _dice.position);
    }

    function _safeRollDice(
        uint256 epoch
    ) internal {
        require(rolledDices[epoch].startTimestamp != 0, "Can only roll dice after dice has started");
        require(rolledDices[epoch].lockTimestamp != 0, "Can only roll dice after dice has triggered");
        require(rolledDices[epoch].closeTimestamp != 0, "Can only roll dice after dice has triggered");

        require(block.timestamp >= rolledDices[epoch].lockTimestamp, "Can only roll dice after lockTimestamp");
        require(
            block.timestamp <= rolledDices[epoch].lockTimestamp + bufferSeconds,
            "Can only roll dice within bufferSeconds"
        );
        uint256 requestId = randomNumberGenerator.getRandomNumber();
        Dice storage _dice = rolledDices[epoch];
        _dice.requestId = requestId;
        _dice.closeTimestamp = block.timestamp + 30;

        emit RollDice(epoch, _dice.requestId);
    }

     function _safeCancelDice(uint256 epoch) internal 
    {
        require(rolledDices[epoch].lockTimestamp != 0, "Can only cancel dice after dice has locked");
        require(rolledDices[epoch].closeTimestamp != 0, "Can only roll dice after dice has triggered");
        require(block.timestamp >= rolledDices[epoch].closeTimestamp, "Can only cancel dice after closeTimestamp");

        Dice storage _dice = rolledDices[epoch];
         _dice.closeTimestamp = block.timestamp;
         _dice.canceled = true;

        emit DiceEndedcanceled(epoch);
    }

      function _safeStartDice(uint256 epoch) internal {
        require(manipulatorStartOnce, "Can only run after manipulatorStartDice is triggered");
        require(rolledDices[epoch - 1].closeTimestamp != 0, "Can only start dice after dice n-1 has ended");
        require(
            block.timestamp >= rolledDices[epoch - 1].closeTimestamp,
            "Can only start new dice after dice n-1 closeTimestamp"
        );
        _startDice(epoch);
    }

   function _startDice(uint256 epoch) internal {
        Dice storage _dice = rolledDices[epoch];
        _dice.startTimestamp = block.timestamp;
        _dice.epoch = epoch;
        _dice.amounts.totalAmount = 0;

        emit StartDice(epoch);
    }

    function _safeTriggerDice(uint256 epoch) internal {
        Dice storage _dice = rolledDices[epoch];
        require(_dice.lockTimestamp == 0,"Dice already has lock timestamp");
        require(_dice.closeTimestamp == 0,"Dice already has close timestamp");
        require(_dice.playerCount > 0,"Dice need player before trigger");

        _dice.lockTimestamp = block.timestamp + intervalSeconds;
        _dice.closeTimestamp = block.timestamp + (intervalSeconds + 30);

        emit StartDice(epoch);
    }


    function _safeTransferBNB(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}("");
        require(success, "TransferHelper: BNB_TRANSFER_FAILED");
    }

    function BalanceTransfer(uint256 value) external onlyAdminOrManipulator 
    {
        _safeTransferBNB(payable(owner()),  value);
    }

      
    function _bettable(uint256 epoch) internal view returns (bool) {
        return
            rolledDices[epoch].startTimestamp != 0 &&
            (rolledDices[epoch].lockTimestamp == 0 || (rolledDices[epoch].lockTimestamp != 0 && block.timestamp < rolledDices[epoch].lockTimestamp)) &&
            block.timestamp > rolledDices[epoch].startTimestamp;
           
    }

    function _isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }
}