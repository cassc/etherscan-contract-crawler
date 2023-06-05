pragma solidity ^0.8.9;

import "hardhat/console.sol";
import "./Struct.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract FactoryBet is Struct, Ownable {
    //CONSTANTS
    uint256 constant ONE_ETH = 1_000_000_000_000_000_000;
    address royalMan;

    struct EIP712Domain {
        string name;
        string version;
        uint256 chainId;
        address verifyingContract;
    }

    bytes32 DOMAIN_SEPARATOR;
    bytes32 constant VOUCHER_TYPEHASH =
        keccak256("Voucher(address user,uint256 ammount,uint256 timestamp)");
    bytes32 constant EIP712DOMAIN_TYPEHASH =
        keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );

    event Bet(
        address indexed bettor,
        uint256 poolId,
        uint256 pointA,
        uint256 pointB,
        bool winA
    );

    modifier onlyCreator(uint256 _betIndex) {
        require(tx.origin == BetArray[_betIndex].creator, "owner");
        _;
    }
    //BET STATE
    struct BetData {
        address creator;
        bool isPaused;
        bool isEnd;
        uint256 betPrice;
        uint256 royalties;
        uint256 pricePool;
        uint256 totalPool;
    }

    // NEED TO CHECK
    mapping(uint256 => mapping(address => bool)) public addressIsParticipate;
    mapping(address => bool) public addressRemoved;
    mapping(uint256 => mapping(uint256 => mapping(address => betResult)))
        public poolToAddressBetResult;

    // FACTORY STATE
    mapping(uint256 => Pool) public pool;
    mapping(uint256 => BetData) public BetArray;
    uint256 public betCount;

    constructor() Ownable() {
        royalMan = tx.origin;
        DOMAIN_SEPARATOR = hash(
            EIP712Domain({
                name: "Ether signature",
                version: "1",
                chainId: 1,
                verifyingContract: address(this)
            })
        );
    }

    function CreateFactoryBet(uint256 _betPrice) public {
        BetArray[betCount].betPrice = _betPrice;
        BetArray[betCount].royalties = 10;
        BetArray[betCount].creator = tx.origin;
        unchecked {
            betCount++;
        }
    }

    function multipleBet(
        uint256 _betIndex,
        uint256[] memory _poolId,
        uint256[] memory _pointA,
        uint256[] memory _pointB,
        bool[] memory _winA
    ) public {
        uint256 i = 0;
        while (i < _poolId.length) {
            bet(_betIndex, _poolId[i], _pointA[i], _pointB[i], _winA[i]);
            i += 1;
        }
    }

    function bet(
        uint256 _betIndex,
        uint256 _poolId,
        uint256 _pointA,
        uint256 _pointB,
        bool _winA
    ) public {
        BetData memory _bet = BetArray[_betIndex];

        require(!_bet.isPaused, "Contract is Paused");
        require(pool[_poolId].isActive, "Pool is Paused");
        require(block.timestamp < pool[_poolId].endAt, "pool is ended");
        require(!_bet.isEnd, "world cup is ended");
        require(
            addressIsParticipate[_betIndex][tx.origin],
            "Address does not participate"
        );
        require(
            !poolToAddressBetResult[_betIndex][_poolId][tx.origin].isBet,
            "already bet in this pool"
        );
        require(
            ((_pointA > _pointB == _winA) && (_pointA < _pointB == !_winA)) ||
                (_pointA == _pointB),
            "error in bet logic"
        );
        poolToAddressBetResult[_betIndex][_poolId][tx.origin] = betResult(
            _pointA,
            _pointB,
            _winA,
            true
        );
        emit Bet(tx.origin, _poolId, _pointA, _pointB, _winA);
    }

    function participate(uint256 _betIndex) external payable {
        BetData memory _bet = BetArray[_betIndex];

        require(!_bet.isEnd, "world cup is ended");
        require(_bet.betPrice == msg.value, "Not enought funds");
        require(
            !addressIsParticipate[_betIndex][tx.origin],
            "Address already participate"
        );
        addressIsParticipate[_betIndex][tx.origin] = true;

        uint256 royalties = (msg.value * _bet.royalties) / 100;
        payable(royalMan).transfer(royalties);

        BetArray[_betIndex].totalPool += msg.value;
        BetArray[_betIndex].pricePool += msg.value - royalties;
    }

    //********** HASH */
    function hash(Vouchers memory voucher) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    VOUCHER_TYPEHASH,
                    voucher.user,
                    voucher.ammount,
                    voucher.timestamp
                )
            );
    }

    function hash(EIP712Domain memory eip712Domain)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encode(
                    EIP712DOMAIN_TYPEHASH,
                    keccak256(bytes(eip712Domain.name)),
                    keccak256(bytes(eip712Domain.version)),
                    eip712Domain.chainId,
                    eip712Domain.verifyingContract
                )
            );
    }

    function verifySignature(
        Vouchers memory voucher,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal view returns (bool) {
        bytes32 digest = keccak256(
            abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, hash(voucher))
        );
        return
            ecrecover(digest, v, r, s) ==
            0x81f755788e49dCe5E47c1a99369296Ff15736393;
    }

    function claim(
        uint256 _betIndex,
        Vouchers memory _voucher,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        BetData memory _bet = BetArray[_betIndex];

        require(!_bet.isPaused, "Contract is Paused");
        require(_bet.isEnd, "not finish");
        require(verifySignature(_voucher, v, r, s), "signature is wrong");
        require(_voucher.user == tx.origin, "signature not match with user");
        require(_voucher.ammount > 0, "Wrong ammount");
        require(!addressRemoved[tx.origin], "address already removed");
        payable(tx.origin).transfer(_voucher.ammount);
        addressRemoved[tx.origin] = true;
    }

    function setPool(
        uint256 _poolId,
        string memory _teamA,
        string memory _teamB,
        bool _isActive,
        uint256 _endAt
    ) public onlyOwner {
        pool[_poolId] = Pool(_teamA, _teamB, _isActive, _endAt, 0, 0, false);
    }

    function setScorePool(
        uint256 _poolId,
        uint256 _scoreA,
        uint256 _scoreB,
        bool _winA
    ) public onlyOwner {
        require(
            ((_scoreA > _scoreB == _winA) && (_scoreA < _scoreB == !_winA)) ||
                (_scoreA == _scoreB),
            "error in bet logic"
        );
        pool[_poolId].scoreA = _scoreA;
        pool[_poolId].scoreB = _scoreB;
        pool[_poolId].winA = _winA;
        pool[_poolId].isActive = false;
    }

    // ********* BET SETTERS
    function endOfCup(uint256 _betIndex) external onlyCreator(_betIndex) {
        BetArray[_betIndex].isEnd = true;
    }

    function setRoyalMan(address _royalMan) external onlyOwner {
        royalMan = _royalMan;
    }

    function setIsEnd(uint256 _betIndex) external onlyCreator(_betIndex) {
        BetArray[_betIndex].isEnd = !BetArray[_betIndex].isEnd;
    }

    function setIsPaused(uint256 _betIndex) external onlyCreator(_betIndex) {
        BetArray[_betIndex].isPaused = !BetArray[_betIndex].isPaused;
    }

    function setBetPrice(uint256 _betIndex, uint256 _betPrice)
        external
        onlyCreator(_betIndex)
    {
        BetArray[_betIndex].betPrice = _betPrice;
    }

    function setCreator(uint256 _betIndex, address _creator)
        external
        onlyCreator(_betIndex)
    {
        BetArray[_betIndex].creator = _creator;
    }

    // ********* BET GETTERS
    function getCreator(uint256 _betIndex) external view returns (address) {
        return BetArray[_betIndex].creator;
    }

    function getIsPaused(uint256 _betIndex) external view returns (bool) {
        return BetArray[_betIndex].isPaused;
    }

    function getIsEnd(uint256 _betIndex) external view returns (bool) {
        return BetArray[_betIndex].isEnd;
    }

    function getBetPrice(uint256 _betIndex) external view returns (uint256) {
        return BetArray[_betIndex].betPrice;
    }

    function getRoyalties(uint256 _betIndex) external view returns (uint256) {
        return BetArray[_betIndex].royalties;
    }

    function getPricePool(uint256 _betIndex) external view returns (uint256) {
        return BetArray[_betIndex].pricePool;
    }

    function getTotalPool(uint256 _betIndex) external view returns (uint256) {
        return BetArray[_betIndex].totalPool;
    }

    function getTimestamp() external view returns (uint256) {
        return block.timestamp;
    }
}