pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '@openzeppelin/contracts/token/ERC1155/IERC1155.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import "@openzeppelin/contracts/access/Ownable.sol";

//          _____                    _____                    _____                    _____
//         /\    \                  /\    \                  /\    \                  /\    \
//        /::\____\                /::\____\                /::\____\                /::\    \
//       /:::/    /               /:::/    /               /::::|   |               /::::\    \
//      /:::/    /               /:::/    /               /:::::|   |              /::::::\    \
//     /:::/    /               /:::/    /               /::::::|   |             /:::/\:::\    \
//    /:::/____/               /:::/    /               /:::/|::|   |            /:::/__\:::\    \
//   /::::\    \              /:::/    /               /:::/ |::|   |           /::::\   \:::\    \
//  /::::::\____\________    /:::/    /      _____    /:::/  |::|___|______    /::::::\   \:::\    \
// /:::/\:::::::::::\    \  /:::/____/      /\    \  /:::/   |::::::::\    \  /:::/\:::\   \:::\    \
///:::/  |:::::::::::\____\|:::|    /      /::\____\/:::/    |:::::::::\____\/:::/  \:::\   \:::\____\
//\::/   |::|~~~|~~~~~     |:::|____\     /:::/    /\::/    / ~~~~~/:::/    /\::/    \:::\  /:::/    /
// \/____|::|   |           \:::\    \   /:::/    /  \/____/      /:::/    /  \/____/ \:::\/:::/    /
//       |::|   |            \:::\    \ /:::/    /               /:::/    /            \::::::/    /
//       |::|   |             \:::\    /:::/    /               /:::/    /              \::::/    /
//       |::|   |              \:::\__/:::/    /               /:::/    /               /:::/    /
//       |::|   |               \::::::::/    /               /:::/    /               /:::/    /
//       |::|   |                \::::::/    /               /:::/    /               /:::/    /
//       \::|   |                 \::::/    /               /:::/    /               /:::/    /
//        \:|   |                  \::/____/                \::/    /                \::/    /
//         \|___|                   ~~                       \/____/                  \/____/
//
contract KumaRaffle is Ownable {

    struct Raffle {
        uint32 tracker;
        uint32 trackerMult;
        uint32 genesis;
        uint32 genesisMult;
        uint32 toy;
        uint32 toyMult;
        uint32 paw;
        uint32 pawMult;

        uint256 pawPrice;
        uint64 starts;
        uint64 ends;
    }

    struct Entry {
        uint256 total;
        uint64 genesisEntered;
        uint64 trackerEntered;
    }

    modifier onlyAdmin() {
        require(admin[msg.sender] , "not admin");
        _;
    }

    error NotForGenesis();
    error NotForTracker();
    error NotForToy();
    error NotForPaw();
    error NotStarted();
    error Ended();
    error AlreadyEntered();

    mapping(address => bool) admin;

    // address => raffle id => entries
    mapping(address => mapping(uint32 => Entry)) public entries;

    // id => raffle
    mapping(uint32 => Raffle) public raffles;

    IERC721 genesisContract;
    IERC721 toysContract;
    IERC1155 trackerContract;
    IERC20 pawContract;

    event RaffleEntered(uint indexed id, address indexed addr, uint entries);

    constructor(
        address _genesisContract,
        address _trackerContract,
        address _toyContract,
        address _pawContract
    ) {
        genesisContract = IERC721(_genesisContract);
        trackerContract = IERC1155(_trackerContract);
        toysContract = IERC721(_toyContract);
        pawContract = IERC20(_pawContract);
    }

    function enterGenesis(uint32 _raffleId) external  {
        Raffle memory raffle = raffles[_raffleId];
        if (raffle.genesis != 1) revert NotForGenesis();
        if (block.timestamp < raffle.starts) revert NotStarted();
        if (block.timestamp > raffle.ends) revert Ended();

        Entry memory entry = entries[msg.sender][_raffleId];
        if (entry.genesisEntered == 1) revert AlreadyEntered();

        uint256 balance = genesisContract.balanceOf(msg.sender);

        entry.total += balance * raffle.genesisMult;
        entry.genesisEntered = 1;

        entries[msg.sender][_raffleId] = entry;

        emit RaffleEntered(_raffleId, msg.sender, balance * raffle.genesisMult);
    }

    function enterTracker(uint32 _raffleId) external  {
        Raffle memory raffle = raffles[_raffleId];
        if (raffle.tracker != 1) revert NotForTracker();
        if (block.timestamp < raffle.starts) revert NotStarted();
        if (block.timestamp > raffle.ends) revert Ended();

        Entry memory entry = entries[msg.sender][_raffleId];
        if (entry.trackerEntered == 1) revert AlreadyEntered();

        uint256 balance = trackerContract.balanceOf(msg.sender, 1);

        entry.total += balance * raffle.trackerMult;
        entry.trackerEntered = 1;

        entries[msg.sender][_raffleId] = entry;
        emit RaffleEntered(_raffleId, msg.sender, balance * raffle.trackerMult);
    }

    function enterTrackerAndGenesis(uint32 _raffleId) external {
        Raffle memory raffle = raffles[_raffleId];
        if (raffle.genesis != 1) revert NotForGenesis();
        if (raffle.tracker != 1) revert NotForTracker();
        if (block.timestamp < raffle.starts) revert NotStarted();
        if (block.timestamp > raffle.ends) revert Ended();

        Entry memory entry = entries[msg.sender][_raffleId];
        if (entry.trackerEntered == 1) revert AlreadyEntered();
        if (entry.genesisEntered == 1) revert AlreadyEntered();

        uint256 balanceg = genesisContract.balanceOf(msg.sender);
        uint256 balancet = trackerContract.balanceOf(msg.sender, 1);

        entry.total += ((balanceg * raffle.genesisMult) + (balancet * raffle.trackerMult));
        entry.trackerEntered = 1;
        entry.genesisEntered = 1;
        entries[msg.sender][_raffleId] = entry;
        emit RaffleEntered(_raffleId, msg.sender, ((balanceg * raffle.genesisMult) + (balancet * raffle.trackerMult)));
    }

    function enterToy(uint32 _raffleId, uint256[] calldata _toysId) external {
        Raffle memory raffle = raffles[_raffleId];
        if (raffle.toy != 1) revert NotForToy();
        if (block.timestamp < raffle.starts) revert NotStarted();
        if (block.timestamp > raffle.ends) revert Ended();

        Entry memory entry = entries[msg.sender][_raffleId];

        for (uint256 i = 0; i < _toysId.length; i++) {
            toysContract.transferFrom(msg.sender, address(this), _toysId[i]);
        }
        entry.total += _toysId.length * raffle.toyMult;
        entries[msg.sender][_raffleId] = entry;
        emit RaffleEntered(_raffleId, msg.sender, _toysId.length * raffle.toyMult);
    }

    function enterPaw(uint32 _raffleId, uint32 _quantity) external {
        Raffle memory raffle = raffles[_raffleId];
        if (raffle.paw != 1) revert NotForPaw();
        if (block.timestamp < raffle.starts) revert NotStarted();
        if (block.timestamp > raffle.ends) revert Ended();

        Entry memory entry = entries[msg.sender][_raffleId];

        if (pawContract.transferFrom(msg.sender, address(this), raffle.pawPrice * _quantity)) {
            entry.total += _quantity * raffle.pawMult;
            entries[msg.sender][_raffleId] = entry;
        }
        emit RaffleEntered(_raffleId, msg.sender, _quantity * raffle.pawMult);
    }


    function createRaffle(uint32 _id, Raffle calldata _raffle) public  onlyAdmin {
        raffles[_id] = _raffle;
    }

    function entriesFor(uint32 _id, address _address) public view returns (Entry memory) {
        return entries[_address][_id];
    }

    function setAdmin(address _addr, bool _isAdmin) external onlyOwner {
        admin[_addr] = _isAdmin;
    }
}