// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/IERC1155MetadataURI.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/structs/BitMaps.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

interface IStakingPool {
    function balanceOf(address _owner) external view returns (uint256 balance);
    function mint(address[] calldata _addresses, uint256[] calldata _points) external;
    function burn(address _owner, uint256 _amount) external;
}

interface IRainiCardPacksv2 is IERC721 {
    struct PackType {
        uint32 packClassId;
        uint128 costInEth;
        uint16 maxMintsPerAddress;
        uint32 tokenIdStart; // the first token id
        uint32 supply;
        uint32 mintTimeStart; // the timestamp from which the pack can be minted
    }

    function packTypes(uint256 _id) external view returns (PackType memory);

    function numberOfPackMinted(uint256 _packTypeId)
        external
        view
        returns (uint256);

    function numberMintedByAddress(address _address, uint256 _packTypeId)
        external
        view
        returns (uint256);

    function mint(
        address _to,
        uint256 _packTypeId,
        uint256 _amount
    ) external;

    function burn(uint256 _tokenId) external;

    function addToNumberMintedByAddress(
        address _address,
        uint256 _packTypeId,
        uint256 amount
    ) external;
}

interface IRainiCards is IERC1155 {
    function mint(
        address _to,
        uint256 _tokenId,
        uint256 _amount
    ) external;
}

contract RtlolPackFunctions is AccessControl, ReentrancyGuard {
    bytes32 public constant EDITOR_ROLE = keccak256("EDITOR_ROLE");
    
    using ECDSA for bytes32;
    using BitMaps for BitMaps.BitMap;

    struct LotteryResult {
        bytes32 lotteryHash;
        uint256 blockNumber;
    }

    uint256 public constant POINT_COST_DECIMALS = 1000000000000000000;

    mapping(address => bool) public rainbowPools;
    mapping(address => bool) public unicornPools;

    mapping(uint256 => LotteryResult) public lotteryResults;

    address public verifier;
    address payable public treasury;

    IRainiCardPacksv2 public packsContract;
    IRainiCards public cardsContract;
    
    BitMaps.BitMap private sigUsed;

    event PointsLocked(address owner, uint256 rainbows, uint256 unicorns);
    event PointsUnlocked(address owner, uint256 rainbows, uint256 unicorns, uint256 transactionId);
    event LotteryRun(uint256 id, bytes32 lotteryHash, uint256 blockNumber);
    event PacksClaimed(uint256 transactionId);
    event PackOpened(uint256 packTokenId);

    constructor(
        address _packsContract,
        address _contractOwner,
        address _verifier,
        address payable _treasury
    ) {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(DEFAULT_ADMIN_ROLE, _contractOwner);
        _setupRole(EDITOR_ROLE, _verifier);
        packsContract = IRainiCardPacksv2(_packsContract);
        verifier = _verifier;
        treasury = _treasury;
    }

    modifier onlyOwner() {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()));
        _;
    }

    modifier onlyEditor() {
        require(hasRole(EDITOR_ROLE, _msgSender()), "NFTSP: caller is not a editor");
        _;
    }

    function checkSigniture(bytes memory message, bytes memory sig) public view returns (bool _success) {
        bytes32 _hash = keccak256(abi.encode("RtlolPackFunctions|", block.chainid, message));
        address signer = ECDSA.recover(_hash.toEthSignedMessageHash(), sig);
        return signer == verifier;
    }

    function setPacksContract(address _packsContract) external onlyOwner {
        packsContract = IRainiCardPacksv2(_packsContract);
    }
    function setCardsContract(address _cardsContract) external onlyOwner {
        cardsContract = IRainiCards(_cardsContract);
    }

    function addRainbowPool(address _rainbowPool) external onlyOwner {
        rainbowPools[_rainbowPool] = true;
    }

    function removeRainbowPool(address _rainbowPool) external onlyOwner {
        rainbowPools[_rainbowPool] = false;
    }

    function addUnicornPool(address _unicornPool) external onlyOwner {
        unicornPools[_unicornPool] = true;
    }

    function removeUnicornPool(address _unicornPool) external onlyOwner {
        unicornPools[_unicornPool] = false;
    }

    function setVerifierAddress(address _verifier) external onlyOwner {
        verifier = _verifier;
    }

    function lockPoints(
        uint256 rainbows,
        uint256 unicorns,
        address[] memory _rainbowPools,
        address[] memory _unicornPools
        ) external {
        for (uint256 n = 0; n < 2; n++) {
            bool loopTypeUnicorns = n > 0;

            uint256 totalBalance = 0;
            uint256 totalPrice = loopTypeUnicorns
                ? unicorns
                : rainbows;
            uint256 remainingPrice = totalPrice;

            if (totalPrice > 0) {
                uint256 loopLength = loopTypeUnicorns
                    ? _unicornPools.length
                    : _rainbowPools.length;

                require(loopLength > 0, "invalid pools");

                for (uint256 i = 0; i < loopLength; i++) {
                    IStakingPool pool;
                    if (loopTypeUnicorns) {
                        require(
                            (unicornPools[_unicornPools[i]]),
                            "invalid unicorn pool"
                        );
                        pool = IStakingPool(_unicornPools[i]);
                    } else {
                        require(
                            (rainbowPools[_rainbowPools[i]]),
                            "invalid rainbow pool"
                        );
                        pool = IStakingPool(_rainbowPools[i]);
                    }
                    uint256 _balance = pool.balanceOf(_msgSender());
                    totalBalance += _balance;

                    if (totalBalance >= totalPrice) {
                        pool.burn(_msgSender(), remainingPrice);
                        remainingPrice = 0;
                        break;
                    } else {
                        pool.burn(_msgSender(), _balance);
                        remainingPrice -= _balance;
                    }
                }

                require (remainingPrice == 0, "not enough balance");
            }
        }
        emit PointsLocked(_msgSender(), rainbows, unicorns);
    }


    function unlockPoints(
        uint256 rainbows, 
        uint256 unicorns, 
        address _rainbowPool,
        address _unicornPool,
        bytes memory sig,
        uint256 transactionId,
        uint256 expiryTime
        ) external {
        
        require (expiryTime > block.timestamp, "expired");
        require (!sigUsed.get(transactionId), "sig used");
        sigUsed.set(transactionId);
        bytes memory _hashString = abi.encode(_msgSender(), rainbows, unicorns, transactionId, expiryTime, "|unlockPoints|");

        require(checkSigniture(_hashString, sig), "Invalid sig");
        require(rainbowPools[_rainbowPool], "invalid rainbow pool");
        require(unicornPools[_unicornPool], "invalid unicorn pool");

        IStakingPool rainbowPool = IStakingPool(_rainbowPool);
        IStakingPool unicornPool = IStakingPool(_unicornPool);

        address[] memory ownerArray = new address[](1);
        ownerArray[0] = _msgSender();

        if (rainbows > 0) {
            uint256[] memory rainbowArray = new uint256[](1);
            rainbowArray[0] = rainbows;
            rainbowPool.mint(ownerArray, rainbowArray);
        }
        
        if (unicorns > 0) {
            uint256[] memory unicornArray = new uint256[](1);
            unicornArray[0] = unicorns;
            unicornPool.mint(ownerArray, unicornArray);
        }

        emit PointsUnlocked(_msgSender(), rainbows, unicorns, transactionId);
    }

    // Lotteries use a number of measures to ensure results are fair
    // Firstly, all tickets for a lottery are combined into a merkel tree
    // The 'lotteryHash' is created by hashing the merkel tree, the total ticket count and the lottery rewards together
    // After the lotteryHash is created 'runLottery' uses transaction based randomness to determine the winner
    // The transaction based randomness is combined with a deterministic verifier based signiture that is only revealed after the lottery is run
    // This ensures that miners without the verifier private key can't meaningfully influence the results

    function runLottery(uint256 id, bytes32 lotteryHash) external onlyEditor {
        require(lotteryResults[id].blockNumber == 0, "already run");
        lotteryResults[id] = LotteryResult({
            lotteryHash: lotteryHash,
            blockNumber: block.number
        });
        emit LotteryRun(id, lotteryHash, block.number);
    }

    function _getWinningTicket(bytes memory randSig, bytes32 roll, uint256 ticketCount) internal pure returns (uint256) {
        // combine verifier randomness with transaction based randomness 
        // so neither the varifier or miner can influence it on their own
        uint256 random = uint256(keccak256(abi.encode(randSig, roll)));
        return random % ticketCount;
    }

    // a helper function which be used to prove a users tickets were included in the lottery
    function checkMerkleProof (
            address user,
            uint256 first,
            uint256 last,
            bytes32 merkleRoot,
            bytes32[] calldata merkleProof) public pure returns (bool) {

        bytes32 _hash = keccak256(abi.encode(user, first, last));
        bool isValidProof = MerkleProof.verify(
            merkleProof,
            merkleRoot,
            _hash
        );
        return isValidProof;
    }
    
    function getWinningTicketIndex(
            bytes memory randSig,
            uint256 lotteryId,
            uint256 ticketCount,
            uint256 prizePosition,
            bytes32 merkleRoot) public view returns (uint256) {
                
        LotteryResult memory _result = lotteryResults[lotteryId];

        // randSig is pseudorandomness supplied by verifier signiture so can't be influenced by miners
        bytes memory _hashString = abi.encode(lotteryId, merkleRoot, prizePosition, "|claimReward|");
        require(checkSigniture(_hashString, randSig), "Invalid sig");

        bytes32 _hash = blockhash(_result.blockNumber);
        require(_hash != 0, "lottery expired");

        uint256 winningTicketIndex = _getWinningTicket(randSig, _hash, ticketCount);

        return winningTicketIndex;
    }

    function claimPacks(
        bytes memory sig,
        uint256 transactionId,
        uint256[] memory _packType,
        uint256[] memory _amount) public {

        require (!sigUsed.get(transactionId), "packs claimed");
        sigUsed.set(transactionId);

        bytes memory _hashString = abi.encode(transactionId, _msgSender(), "|claimPacks|");       
        for (uint256 i = 0; i < _packType.length; i++) {
            _hashString = abi.encode(
                _hashString,
                _packType[i],
                _amount[i]
            );
        }
        require(checkSigniture(_hashString, sig), "Invalid sig");

        for (uint256 i = 0; i < _packType.length; i++) {
            packsContract.mint(_msgSender(), _packType[i], _amount[i]);
        }
        emit PacksClaimed(transactionId);
    }

    function bulkClaimPacks(
        bytes[] memory sig,
        uint256[] memory transactionId,
        uint256[][] memory _packType,
        uint256[][] memory _amount
    ) external {
        for (uint256 i = 0; i < sig.length; i++) {
            claimPacks(sig[i], transactionId[i], _packType[i], _amount[i]);
        }
    }

    function openPacks(
        uint256[][] memory _cardId,
        uint256[][] memory _amount,
        bytes[] memory sig,
        uint256[] memory _salt,
        uint256[] memory _packId
    ) external {
        for (uint256 i = 0; i < _cardId.length; i++) {
            require(
                packsContract.ownerOf(_packId[i]) == address(_msgSender()),
                "not the owner"
            );
            bytes memory _hashingString = abi.encode(_salt[i], _packId[i], "|openPacks|");
            for (uint256 j = 0; j < _cardId[i].length; j++) {
                _hashingString = abi.encode(
                    _hashingString,
                    _cardId[i][j],
                    _amount[i][j]
                );
            }
            
            require(checkSigniture(_hashingString, sig[i]), "Invalid sig");
        }

        for (uint256 i = 0; i < _cardId.length; i++) {
            packsContract.burn(_packId[i]);
            for (uint256 j = 0; j < _cardId[i].length; j++) {
                cardsContract.mint(
                    _msgSender(),
                    _cardId[i][j],
                    _amount[i][j]
                );
            }
            emit PackOpened(_packId[i]);
        }
    }

    struct BuyPacksData {
        uint256 amountEthToWithdraw;
        bool success;
    }

    function buyPacks(
        uint256[] memory _packType,
        uint256[] memory _amount
    ) external payable nonReentrant {
        BuyPacksData memory _locals = BuyPacksData({
            amountEthToWithdraw: 0,
            success: false
        });

        bool[] memory addToMaxMints = new bool[](_packType.length);

        for (uint256 i = 0; i < _packType.length; i++) {
            IRainiCardPacksv2.PackType memory packType = packsContract.packTypes(
                _packType[i]
            );

            require(packType.costInEth > 0, "bad packType");
            require(
                block.timestamp >= packType.mintTimeStart ||
                    hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
                "too early"
            );
            require(
                packType.maxMintsPerAddress == 0 ||
                    (packsContract.numberMintedByAddress(
                        _msgSender(),
                        _packType[i]
                    ) +
                        _amount[i] <=
                        packType.maxMintsPerAddress),
                "Max mints reached for address"
            );
            addToMaxMints[i] = packType.maxMintsPerAddress > 0;

            uint256 numberMinted = packsContract.numberOfPackMinted(
                _packType[i]
            );
            if (numberMinted + _amount[i] > packType.supply) {
                _amount[i] = packType.supply - numberMinted;
            }

            _locals.amountEthToWithdraw += packType.costInEth * _amount[i];
        }        

        require(_locals.amountEthToWithdraw <= msg.value, "eth too low");

        (_locals.success, ) = _msgSender().call{
            value: msg.value - _locals.amountEthToWithdraw
        }(""); // refund excess Eth
        require(_locals.success, "transfer failed");

        bool _tokenMinted = false;
        for (uint256 i = 0; i < _packType.length; i++) {
            if (_amount[i] > 0) {
                if (addToMaxMints[i]) {
                    packsContract.addToNumberMintedByAddress(
                        _msgSender(),
                        _packType[i],
                        _amount[i]
                    );
                }
                packsContract.mint(_msgSender(), _packType[i], _amount[i]);
                _tokenMinted = true;
            }
        }
        require(_tokenMinted, "Allocation exhausted");
    }




    // Allow the owner to withdraw Ether payed into the contract
    function withdrawEth(uint256 _amount) external {
        require(_amount <= address(this).balance, "not enough balance");
        require(_msgSender() == treasury, "not treasury");
        (bool success, ) = treasury.call{value: _amount}("");
        require(success, "transfer failed");
    }
}