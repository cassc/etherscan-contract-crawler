// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./ERC20.sol";
import "./Pausable.sol";
import "./Ownable.sol";
import "./VRFCoordinatorV2Interface.sol";
import "./ConfirmedOwner.sol";
import "./VRFConsumerBaseV2.sol";
import "./Address.sol";

import "./RandomNumbers.sol";
import "./RaffleGov.sol";

contract RaffleRush is RaffleGov, VRFConsumerBaseV2, ERC20, Pausable {
    using SafeERC20 for IERC20;
    using Address for address;
    using Address for address payable;
    using SafeMath for uint256;
    //ChainLink
    VRFCoordinatorV2Interface immutable COORDINATOR;
    uint64 immutable subscriptionId;
    bytes32 immutable keyHash;
    uint32 constant CALLBACK_GAS_LIMIT = 100000;
    uint16 constant REQUEST_CONFIRMATIONS = 3;
    uint32 constant NUM_WORDS = 1;
    uint256 public lastRequestId;
    event ReturnedRandomness(uint256 requestId, uint256[] randomWords);
    event RequestRandom(uint256 requestId, address who);

    uint256 constant FEE_CAP = 88000 gwei;
    uint256 public feePerWinner = 0 gwei;
    struct Raffle {
        address owner;
        uint256 sum;
        uint256 min;
        address bonus;
        uint256 winners;
        uint256 picked;
        uint256 pickedIndex;
        uint256 rType;
        uint256 startAt;
        uint256 deadline1;
        uint256 deadline2;
        uint256 seed;
        string ipfsHash;
    }
    uint256 public maxWinners = 200;
    uint256 public maxWithdrawDelay = 604800;//7 days
    uint256 public maxDrawDelay = 604800;//7 days
    mapping(address => Raffle[]) public raffles;
    //ChainLink callback
    struct Caller{
        address who;
        uint256 index;
    }
    mapping(uint256 => Caller) public callers;

    mapping(address => uint256) public assetAvailable;
    mapping(address => uint256) public assetLocked;

    event CreateRaffle(address sponsor, uint256 rid, uint256 sum, uint256 winners, uint256 rType);
    event CleanRaffle(address executor, address sponsor, uint256 index);
    event UserClaim(address who, address bonus, uint256 amount);
    event SetFee(uint256 fee);
    event SetMaxWithdrawDelay(uint256 delay);
    event SetMaxDrawDelay(uint256 delay);
    event Draw(address sponsor, uint256 rid, address who, uint256 amount);
    constructor(
        uint64 _subscriptionId,
        address _vrfCoordinator,
        bytes32 _keyHash,
        address _gov
    ) RaffleGov(_gov) ERC20("RealDrawToken", "RDT") VRFConsumerBaseV2(_vrfCoordinator){
        COORDINATOR = VRFCoordinatorV2Interface(_vrfCoordinator);
        keyHash = _keyHash;
        subscriptionId = _subscriptionId;
    }

    function createRaffle(
        address _bonus,
        uint256 _sum,
        uint256 _winners,
        uint256 _rType,
        uint256 _min,
        uint256 _deadline1
    ) public payable{

        if(_winners > maxWinners){
            revert('!winners');
        }

        if(msg.sender.isContract()){
            revert('!EOA');
        }
        //Approve Check
        if(IERC20(_bonus).allowance(msg.sender, address(this)) < _sum){
            revert('!approve');
        }

        if(IERC20(_bonus).balanceOf(msg.sender) < _sum){
            revert('Insufficient amount!');
        }
        if(msg.value < feePerWinner * _winners){
            revert('!fee');
        }
        require(_rType == 1 || _rType == 2, "!rType");
        require(_deadline1 > block.timestamp && _deadline1 - block.timestamp <= maxDrawDelay, "!delay");
        if(feePerWinner > 0){
            payable(govAddress).sendValue(msg.value);
        }

        IERC20(_bonus).safeIncreaseAllowance(address(this), _sum);
        IERC20(_bonus).safeTransferFrom(msg.sender, address(this), _sum);

        raffles[msg.sender].push(Raffle({
            owner: msg.sender,
            bonus: _bonus,
            sum: _sum,
            picked: 0,
            pickedIndex: 0,
            winners: _winners,
            rType: _rType,
            min: _min,
            startAt: block.timestamp,
            deadline1: _deadline1,
            deadline2: _deadline1 + maxWithdrawDelay,
            seed: 0,
            ipfsHash: ''
        }));
        require(raffles[msg.sender].length > 0, "raffles can't be empty!!");
        if(_rType == 1){
            lastRequestId = COORDINATOR.requestRandomWords(
                keyHash,
                subscriptionId,
                REQUEST_CONFIRMATIONS,
                CALLBACK_GAS_LIMIT,
                NUM_WORDS
            );
            callers[lastRequestId] = Caller({
            who:msg.sender,
            index:raffles[msg.sender].length - 1
            });
        }
        _mint(msg.sender, 1 ether);//mint RDT
        availableIncrease(_bonus, _sum);
        emit CreateRaffle(msg.sender, raffles[msg.sender].length - 1, _sum, _winners, _rType);
    }

    function fillWinnerList(address sponsor, uint256 rid, string calldata ipfs) public {
        require(sponsor != address (0), "Invalid sponsor address");
        require(raffles[sponsor].length > rid, "No such raffle");
        require(raffles[sponsor][rid].owner != address (0), "Raffle owner invalid");
        require(raffles[sponsor][rid].deadline1 >= block.timestamp, "Draw date overdue");
        raffles[sponsor][rid].ipfsHash = ipfs;
    }
    //Chainlink Callback
    function fulfillRandomWords(
        uint256 requestId,
        uint256[] memory randomWords
    ) internal override {
        if(callers[requestId].who != address(0)){
            if(raffles[callers[requestId].who].length > callers[requestId].index){
                raffles[callers[requestId].who][callers[requestId].index].seed = randomWords[0];
            }
            delete callers[requestId];
        }
        emit ReturnedRandomness(requestId, randomWords);
    }

    function getRaffleResult(address sponsor, uint256 rid) public view returns (uint256[] memory){
        if(raffles[sponsor].length > rid){
            if(raffles[sponsor][rid].rType == 1){
                uint256[] memory randoms = RandomNumbers.generateNumbers(
                    raffles[sponsor][rid].seed,
                    raffles[sponsor][rid].sum,
                    raffles[sponsor][rid].min,
                    raffles[sponsor][rid].winners
                );
                return randoms;
            }else if(raffles[sponsor][rid].rType == 2){
                uint256[] memory randoms = new uint256[](raffles[sponsor][rid].winners);
                for (uint256 i = 0; i < raffles[sponsor][rid].winners; i++) {
                    randoms[i] = raffles[sponsor][rid].sum.div(raffles[sponsor][rid].winners);
                }
                return randoms;
            }else{
                return new uint256[](0);
            }

        }else{
            return new uint256[](0);
        }
    }

    function getRaffleResults(address sponsor) public view returns (uint256[][] memory){
        if(raffles[sponsor].length > 0){
            uint256 [][] memory randoms = new uint256[][](raffles[sponsor].length);
            for(uint256 i = 0 ; i < raffles[sponsor].length; i++){
                uint256[] memory random = getRaffleResult(sponsor, i);
                randoms[i] = random;
            }
            return randoms;
        }else{
            return new uint256[][](0);
        }
    }

    function getRaffles(address sponsor) public view returns (Raffle[] memory){
        if(raffles[sponsor].length > 0){
            return raffles[sponsor];
        }else{
            return new Raffle[](0);
        }
    }

    function draw(address sponsor, uint256 rid, address[] calldata users) public onlyOwner{
        require(sponsor != address (0), "Invalid sponsor address");
        require(raffles[sponsor].length > rid, "No such raffle");
        require(raffles[sponsor][rid].owner != address (0), "Raffle owner invalid");
        require(raffles[sponsor][rid].deadline1 >= block.timestamp, "Draw date overdue");
        require(users.length > 0, "users can't be empty");
        require(raffles[sponsor][rid].pickedIndex < raffles[sponsor][rid].winners, "Draw amount exceeded");

        Raffle memory raffle = raffles[sponsor][rid];
        uint256[] memory randoms = getRaffleResult(sponsor, rid);
        uint256 start = raffle.pickedIndex;
        uint256 max = start + users.length > raffle.winners ? raffle.winners : start + users.length;
        for(uint256 i = start; i < max; i++){
            if(address(users[i - start]).isContract()){
                continue;
            }
            IERC20(raffle.bonus).safeTransfer(address(users[i - start]), randoms[i]);
            raffles[sponsor][rid].picked = raffles[sponsor][rid].picked + randoms[i];
            raffles[sponsor][rid].pickedIndex = raffles[sponsor][rid].pickedIndex + 1;
            availableDecrease(raffle.bonus, randoms[i]);
            emit Draw(sponsor, rid, address(users[i - start]), randoms[i]);
        }
    }

    function drawSingle(address sponsor, uint256 rid, address user) public onlyOwner{
        require(sponsor != address (0), "Invalid sponsor address");
        require(raffles[sponsor].length > rid, "No such raffle");
        require(raffles[sponsor][rid].owner != address (0), "Raffle owner invalid");
        require(raffles[sponsor][rid].deadline1 >= block.timestamp, "Draw date overdue");
        require(user != address (0), "users can't be empty");
        require(raffles[sponsor][rid].pickedIndex < raffles[sponsor][rid].winners, "Draw amount exceeded");
        Raffle memory raffle = raffles[sponsor][rid];
        uint256[] memory randoms = getRaffleResult(sponsor, rid);

        IERC20(raffle.bonus).safeTransfer(address(user), randoms[raffle.pickedIndex]);
        emit Draw(sponsor, rid, address(user), randoms[raffle.pickedIndex]);
        raffles[sponsor][rid].picked = raffles[sponsor][rid].picked + randoms[raffle.pickedIndex];
        raffles[sponsor][rid].pickedIndex = raffles[sponsor][rid].pickedIndex + 1;
        availableDecrease(raffle.bonus, randoms[raffle.pickedIndex]);

    }

    function cleanRaffles(address sponsor, uint256 rid) public {
        require(raffles[sponsor].length > 0, "!sponsor");
        require(raffles[sponsor][rid].owner != address(0), "!rid");
        if(raffles[sponsor][rid].deadline2 < block.timestamp){
            if(raffles[sponsor][rid].sum > raffles[sponsor][rid].picked){
                lockIncrease(raffles[sponsor][rid].bonus, raffles[sponsor][rid].sum - raffles[sponsor][rid].picked);
            }
            if(raffles[sponsor].length > 1){
                raffles[sponsor][rid] = raffles[sponsor][raffles[sponsor].length - 1];
            }
            raffles[sponsor].pop();

            emit CleanRaffle(msg.sender, sponsor, rid);
        }
    }

    function availableIncrease(address _token, uint256 _amount) internal {
        assetAvailable[_token] = assetAvailable[_token] + _amount;
    }

    function availableDecrease(address _token, uint256 _amount) internal {
        require(assetAvailable[_token] >= _amount, "Bad decrease amount");
        if(assetAvailable[_token] < _amount){
            _amount = assetAvailable[_token];
        }
        assetAvailable[_token] = assetAvailable[_token] - _amount;
    }

    function lockIncrease(address _token, uint256 _amount) internal {
        availableDecrease(_token, _amount);
        assetLocked[_token] = assetLocked[_token] + _amount;
    }

    function lockDecrease(address _token, uint256 _amount) internal {
        require(assetLocked[_token] >= _amount, "Bad unlock amount");
        assetLocked[_token] = assetLocked[_token] - _amount;
    }
    function govClaim(address _token) public onlyGov {
        require(address(_token) != address(0) && assetLocked[_token] > 0, "Insufficient balance");
        IERC20(_token).safeTransfer(govAddress, assetLocked[_token]);
        assetLocked[_token] = 0;
    }
    function govClaimExact(address _token, uint256 _amount) public onlyGov {
        require(address(_token) != address(0) && assetLocked[_token] >= _amount, "Insufficient balance");
        IERC20(_token).safeTransfer(govAddress, _amount);
        assetLocked[_token] = 0;
    }

    function govMultiClaim(address[] calldata _tokens) public onlyGov {
        for(uint256 i = 0; i < _tokens.length; i++){
            address token = _tokens[i];
            if(assetLocked[token] > 0){
                govClaim(token);
            }
        }
    }

    function userClaim(uint256 rid) public {
        require(raffles[msg.sender].length > 0, "Invalid user");
        require(raffles[msg.sender][rid].owner == msg.sender, "Invalid rid");
        require(raffles[msg.sender][rid].deadline2 >= block.timestamp, "Claim expired");
        require(raffles[msg.sender][rid].deadline1 <= block.timestamp, "Claim disabled");
        uint256 claimable = raffles[msg.sender][rid].sum - raffles[msg.sender][rid].picked;
        require(assetAvailable[raffles[msg.sender][rid].bonus] >= claimable, 'Insufficient bonus');
        IERC20(raffles[msg.sender][rid].bonus).safeTransfer(msg.sender, claimable);
        availableDecrease(raffles[msg.sender][rid].bonus, claimable);
        raffles[msg.sender][rid].picked = raffles[msg.sender][rid].sum;
        emit UserClaim(msg.sender, raffles[msg.sender][rid].bonus, claimable);
    }

    function setFee(uint256 _fee) public onlyGov {
        require(_fee <= FEE_CAP, "!cap");
        feePerWinner = _fee;
        emit SetFee(_fee);
    }

    function setMaxWithdrawDelay(uint256 _delay) public onlyGov {
        require(_delay <= 7 days, "!cap");
        maxWithdrawDelay = _delay;
        emit SetMaxWithdrawDelay(_delay);
    }

    function setMaxDrawDelay(uint256 _delay) public onlyGov {
        require(_delay <= 7 days, "!cap");
        maxDrawDelay = _delay;
        emit SetMaxDrawDelay(_delay);
    }
    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }
    function _beforeTokenTransfer(address from, address to, uint256 amount)
    internal
    whenNotPaused
    override
    {
        super._beforeTokenTransfer(from, to, amount);
    }
}