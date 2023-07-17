// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "solmate/tokens/ERC20.sol";
import "openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";
import "openzeppelin-contracts/contracts/utils/cryptography/MerkleProof.sol";
import "./ExclusivesYieldMap.sol";
import "./PccTierTwoItem.sol";
import "./PccLand.sol";
import "./MintUpdater.sol";
import "./PccTierTwo.sol";

struct TokenBucket {
    uint256 AvailableCurrently;
    uint256 DailyYield;
    uint256 MaxYield;
    uint256 CurrentYield;
    uint256 LastClaimTimestamp;
}


contract PccToken is ERC20, Ownable, ExclusivesYieldMap, ILandMintUpdater {
    uint256 public constant SECOND_RATE_FOR_ONE_PER_DAY = 11574074074074;
    uint256 public packedNumbers;

    PccTierTwoItem public TierTwoItem;
    IERC721 public TierTwo;

    bytes32 public MerkleRoot;

    event AddedClaimBucket(
        string indexed _name,
        uint256 _dailyYield,
        uint256 _maxYield
    );

    mapping(string => TokenBucket) public TokenClaimBuckets;
    mapping(address => bool) public ClaimedAirdrop;

    uint256[5] public EXCLUSIVES_DAILY_YIELD = [
        5 * SECOND_RATE_FOR_ONE_PER_DAY,
        10 * SECOND_RATE_FOR_ONE_PER_DAY,
        25 * SECOND_RATE_FOR_ONE_PER_DAY,
        50 * SECOND_RATE_FOR_ONE_PER_DAY,
        100 * SECOND_RATE_FOR_ONE_PER_DAY
    ];
    IERC721 immutable public EXCLUSIVES_CONTRACT;
    IERC721 immutable public landContract;

    uint256 public EXCLUSIVES_START_TIME;

    uint256 private constant MAX_VALUE_3_BIT_INT = 7;

    uint256 contractCount;

    mapping(uint256 => uint256) public test;

    mapping(IERC721 => uint256) public NftContracts;

    mapping(IERC721 => mapping(uint256 => uint256)) public LastClaimedTimes;

    mapping(IERC721 => uint256) public FirstClaimTime;

    constructor(PccLand _land, PccTierTwoItem _ticket, PccTierTwo _tierTwo, IERC721 _nft1, IERC721 _nft2, IERC721 _nft3) ERC20("YARN", "PCC Yarn", 18) {
        TierTwoItem = _ticket;

        EXCLUSIVES_CONTRACT = IERC721(0x9e8a92F833c0ae4842574cE9cC0ef4c7300Ddb12);

        landContract = IERC721(address(_land));
        TierTwo = IERC721(address(_tierTwo));

        EXCLUSIVES_START_TIME = block.timestamp;

        FirstClaimTime[
            _nft1
        ] = block.timestamp; //PCC
        FirstClaimTime[
            _nft2
        ] = block.timestamp; //kittens
        FirstClaimTime[
            _nft3
        ] = block.timestamp; //grandmas

        addNewContract(IERC721(address(_tierTwo)), 5);
        addNewContract(landContract, 5);

        addTokenBucket(
        "employee",
        7847312 ether, //start number
        12960 ether,    //daily yield
        78803313 ether); //max tokens

        addTokenBucket(
        "team",
        16176000 ether, //start number
        51840 ether,   //daily yield
        300000000 ether); //max tokens


            addNewContract(IERC721(address(_nft1)), 10);
            addNewContract(IERC721(address(_nft2)), 1);
            addNewContract(IERC721(address(_nft3)), 1);

    }

    function updateLandMintingTime(uint256 _id) external {
        require(address(landContract) == msg.sender, "not authorised");

        LastClaimedTimes[landContract][_id] = block.timestamp;
    }

    function updateTierTwoMintingTime(uint256 _id) external {
        require(address(TierTwo) == msg.sender, "not authorised");

        LastClaimedTimes[TierTwo][_id] = block.timestamp;
    }

    function payForTierTwoItem(address _sender, uint256 _amount) public {
        address tierTwoAddress = address(TierTwoItem);
        require(msg.sender == tierTwoAddress, "not authorised");
        require(balanceOf[_sender] >= _amount, "insufficient balance");

        balanceOf[_sender] -= _amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[tierTwoAddress] += _amount;
        }

        emit Transfer(_sender, tierTwoAddress, _amount);
    }

    function burn(address _from, uint256 _quantity) public onlyTicketContract {
        _burn(_from, _quantity);
    }

    function addTokenBucket(
        string memory _name,
        uint256 _startNumber,
        uint256 _dailyYield,
        uint256 _maxYield
    ) private {
        TokenBucket memory bucket = TokenBucket(
            _startNumber,
            _dailyYield,
            _maxYield,
            0,
            uint80(block.timestamp)
        );

        TokenClaimBuckets[_name] = bucket;
        emit AddedClaimBucket(_name, _dailyYield, _maxYield);
    }


    function addNewContract(IERC721 _contract, uint256 _yield)
        private

    {
        require(NftContracts[_contract] == 0, "duplicate contract");
        require(_yield < 11 && _yield > 0, "yield out of range");
        unchecked {
            ++contractCount;
        }

        NftContracts[_contract] = _yield * SECOND_RATE_FOR_ONE_PER_DAY;
    }

    function claimCommunitityAirdrop(
        bytes32[] calldata _merkleProof,
        uint256 _amount
    ) public {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, _amount));
        require(
            MerkleProof.verify(_merkleProof, MerkleRoot, leaf),
            "not authorised"
        );
        require(!ClaimedAirdrop[msg.sender], "already claimed airdrop");

        ClaimedAirdrop[msg.sender] = true;
        _mint(msg.sender, _amount * 1 ether);
    }

    function setMerkleRoot(bytes32 _root) public onlyOwner {
        MerkleRoot = _root;
    }

    function claimTokens(IERC721[] calldata _contracts, uint256[] calldata _ids)
        public
    {
        uint256 contractsLength = _contracts.length;
        require(contractsLength == _ids.length, "invalid array lengths");
        uint256 amountToMint;

        for (uint256 i; i < contractsLength; ) {
            amountToMint += getYield(_contracts[i], _ids[i], msg.sender);
            LastClaimedTimes[_contracts[i]][_ids[i]] = block.timestamp;
            unchecked {
                ++i;
            }
        }

        _mint(msg.sender, amountToMint);
        require(totalSupply < 2000000000 ether, "reached max cap");
    }

    function currentTokenToClaim(
        address _owner,
        IERC721[] calldata _contracts,
        uint256[] calldata _ids
    ) external view returns (uint256) {
        uint256 contractsLength = _contracts.length;
        require(contractsLength == _ids.length, "invalid array lengths");
        uint256 amountToClaim;

        for (uint256 i; i < contractsLength; ) {
            unchecked {
                amountToClaim += getYield(_contracts[i], _ids[i], _owner);
                ++i;
            }
        }

        return amountToClaim;
    }

    function availableFromBucket(string calldata _name)
        public
        view
        returns (uint256)
    {
        TokenBucket memory bucket = TokenClaimBuckets[_name];

        require(bucket.LastClaimTimestamp > 0, "bucket does not exist");

        uint256 amountToMint = bucket.AvailableCurrently;

        amountToMint +=

                (block.timestamp - bucket.LastClaimTimestamp) *
                    (bucket.DailyYield / 86400)
            ;

        if (bucket.CurrentYield + (amountToMint) > bucket.MaxYield) {
            return bucket.MaxYield - bucket.CurrentYield;
        }

        return amountToMint;
    }

    function bucketMint(string calldata _name, uint256 _amount)
        public
        onlyOwner
    {
        TokenBucket memory bucket = TokenClaimBuckets[_name];

        require(bucket.LastClaimTimestamp > 0, "bucket does not exist");

        uint256 amountToMint = bucket.AvailableCurrently;

        uint256 timeSinceLastClaim = (block.timestamp - bucket.LastClaimTimestamp);

        amountToMint += (timeSinceLastClaim * (bucket.DailyYield / 86400));

        bucket.CurrentYield += _amount;
        require(
            bucket.CurrentYield <= bucket.MaxYield && amountToMint >= _amount,
            "cannot mint this many from this bucket"
        );

        _mint(msg.sender, _amount);


        bucket.AvailableCurrently = amountToMint - _amount;
        bucket.LastClaimTimestamp = uint80(block.timestamp);

        TokenClaimBuckets[_name] = bucket;
    }

    function getYield(
        IERC721 _contract,
        uint256 _id,
        address _operator
    ) private view returns (uint256) {
        address owner = _contract.ownerOf(_id);
        require(
            owner == _operator || _contract.isApprovedForAll(owner, _operator),
            "not eligible"
        );
        if (_contract == EXCLUSIVES_CONTRACT) {
            return getExclusivesYield(_id);
        } else {
            return getNftYield(_contract, _id);
        }
    }

    function getExclusivesYield(uint256 _id) public view returns (uint256) {
        uint256 lastClaim = (
            LastClaimedTimes[EXCLUSIVES_CONTRACT][_id] == 0
                ? EXCLUSIVES_START_TIME
                : LastClaimedTimes[EXCLUSIVES_CONTRACT][_id]
        );
        return
            (block.timestamp - lastClaim) *
            EXCLUSIVES_DAILY_YIELD[getExclusivesDailyYield(_id)];
    }

    function getNftYield(IERC721 _nft, uint256 _id)
        public
        view
        returns (uint256)
    {
        uint256 lastClaim = (
            LastClaimedTimes[_nft][_id] == 0
                ? FirstClaimTime[_nft] == 0
                    ? block.timestamp - (5 days - 1)
                    : FirstClaimTime[_nft]
                : LastClaimedTimes[_nft][_id]
        );
        return (block.timestamp - lastClaim) * NftContracts[_nft];
    }

    function getExclusivesDailyYield(uint256 _id)
        public
        view
        returns (uint256)
    {
        return unpackNumber(YIELD_MAP[_id / 85], _id % 85);
    }

    function unpackNumber(uint256 _packedNumbers, uint256 _position)
        private
        pure
        returns (uint256)
    {
        unchecked {
            uint256 number = (_packedNumbers >> (_position * 3)) &
                MAX_VALUE_3_BIT_INT;
            return number;
        }
    }

    modifier onlyTicketContract() {
        require(address(TierTwoItem) == msg.sender, "only ticket contract");
        _;
    }
}