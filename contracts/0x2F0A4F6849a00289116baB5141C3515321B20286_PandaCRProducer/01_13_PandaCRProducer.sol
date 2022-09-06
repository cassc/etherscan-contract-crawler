/*
 **                                                                                                                                                              
 **                                                                   dddddddd                                                                                   
 **  PPPPPPPPPPPPPPPPP                                                d::::::d                  DDDDDDDDDDDDD                  AAA                 OOOOOOOOO     
 **  P::::::::::::::::P                                               d::::::d                  D::::::::::::DDD              A:::A              OO:::::::::OO   
 **  P::::::PPPPPP:::::P                                              d::::::d                  D:::::::::::::::DD           A:::::A           OO:::::::::::::OO 
 **  PP:::::P     P:::::P                                             d:::::d                   DDD:::::DDDDD:::::D         A:::::::A         O:::::::OOO:::::::O
 **    P::::P     P:::::Paaaaaaaaaaaaa  nnnn  nnnnnnnn        ddddddddd:::::d   aaaaaaaaaaaaa     D:::::D    D:::::D       A:::::::::A        O::::::O   O::::::O
 **    P::::P     P:::::Pa::::::::::::a n:::nn::::::::nn    dd::::::::::::::d   a::::::::::::a    D:::::D     D:::::D     A:::::A:::::A       O:::::O     O:::::O
 **    P::::PPPPPP:::::P aaaaaaaaa:::::an::::::::::::::nn  d::::::::::::::::d   aaaaaaaaa:::::a   D:::::D     D:::::D    A:::::A A:::::A      O:::::O     O:::::O
 **    P:::::::::::::PP           a::::ann:::::::::::::::nd:::::::ddddd:::::d            a::::a   D:::::D     D:::::D   A:::::A   A:::::A     O:::::O     O:::::O
 **    P::::PPPPPPPPP      aaaaaaa:::::a  n:::::nnnn:::::nd::::::d    d:::::d     aaaaaaa:::::a   D:::::D     D:::::D  A:::::A     A:::::A    O:::::O     O:::::O
 **    P::::P            aa::::::::::::a  n::::n    n::::nd:::::d     d:::::d   aa::::::::::::a   D:::::D     D:::::D A:::::AAAAAAAAA:::::A   O:::::O     O:::::O
 **    P::::P           a::::aaaa::::::a  n::::n    n::::nd:::::d     d:::::d  a::::aaaa::::::a   D:::::D     D:::::DA:::::::::::::::::::::A  O:::::O     O:::::O
 **    P::::P          a::::a    a:::::a  n::::n    n::::nd:::::d     d:::::d a::::a    a:::::a   D:::::D    D:::::DA:::::AAAAAAAAAAAAA:::::A O::::::O   O::::::O
 **  PP::::::PP        a::::a    a:::::a  n::::n    n::::nd::::::ddddd::::::dda::::a    a:::::a DDD:::::DDDDD:::::DA:::::A             A:::::AO:::::::OOO:::::::O
 **  P::::::::P        a:::::aaaa::::::a  n::::n    n::::n d:::::::::::::::::da:::::aaaa::::::a D:::::::::::::::DDA:::::A               A:::::AOO:::::::::::::OO 
 **  P::::::::P         a::::::::::aa:::a n::::n    n::::n  d:::::::::ddd::::d a::::::::::aa:::aD::::::::::::DDD A:::::A                 A:::::A OO:::::::::OO   
 **  PPPPPPPPPP          aaaaaaaaaa  aaaa nnnnnn    nnnnnn   ddddddddd   ddddd  aaaaaaaaaa  aaaaDDDDDDDDDDDDD   AAAAAAA                   AAAAAAA  OOOOOOOOO     
 **  
*/
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../interfaces/IPoolKit.sol";
/**
 */

contract PandaCRProducer is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    struct BuyCommit {
        bytes32 commit;
        uint64 block;
        bool revealed;
        uint256 amountBuyMax;
        uint256 deadline;
    }

    struct RebornCommit {
        bytes32 commit;
        uint64 block;
        bool revealed;
        uint256 ownerTokenId;
        uint256 amountFeeMax;
        uint256 deadline;
    }

    address immutable public pandaToken;
    address immutable public pandaNFT;
    IPoolKit public poolKit;
    bool public isCrOpen = false;
    mapping(uint256 => uint256) public poolNftMap;
    mapping(address => uint256) public rebornMap;
    mapping(address => uint256) public buyMap;
    mapping(address => BuyCommit) public buyCommits;
    mapping(address => RebornCommit) public rebornCommits;
    mapping(address => bool) public buyCompensates;
    mapping(address => bool) public rebornCompensates;
    uint256 public constant FEE_BASE = 10000;
    uint256 public poolFeeValue = 375;
    uint256 public treasuryFeeValue = 0;

    address public constant ZERO_ADDRESS = address(0);
    uint256 public constant NFT_TOTAL_SUPPLY = 10000;


    event WithdrawERC20(address recipient, address tokenAddress, uint256 tokenAmount);
    event WithdrawEther(address recipient, uint256 amount);
    event CommitRebron(address indexed sender, bytes32 dataHash, uint64 block,uint256 ownerTokenId, uint256 amountBuyMax, uint256 deadline);
    event CommitBuy(address indexed sender, bytes32 dataHash, uint64 block, uint256 amountBuyMax, uint256 deadline);
    event BuyRevealHash(address indexed sender, bytes32 revealHash, uint256 index, uint256 targetIndex);
    event RebornRevealHash(address indexed sender, bytes32 revealHash, uint256 ownerTokenId, uint256 index, uint256 targetIndex);
    event SwitchEvent(bool crOpen);
    event SetPoolFeeValue(uint256 feeValue);
    event SetTreasuryFeeValue(uint256 feeValue);
    event Redeem(address indexed recipient, uint256 ownerTokenId, uint256 receiveAmount);


    error TimeOutError(uint256 deadline, uint256 timestamp);
    error ZeroAddrError();
    error NoEnoughCallbackGas(uint256 value, uint256 needGas);
    error PoolCloseError();
    error NFTOwnerNotMatch(uint tokenId, address expectOwner, address realOwner);
    error MaxFeeNotMatch(uint256 maxUserFee, uint256 poolNeedFee);
    error PandaNotEnough(address sender, uint256 balance, uint256 needBalance);
    error PoolNFTTooMany(uint256 poolNftNum, uint256 upLimit);
    error MaxBuyNotMatch(uint256 maxUserPayFor, uint256 poolNeedPayFor);
    error PoolNotEnoughNFT(uint256 poolBalance, uint256 downLimit);
    error TransferEhterFail(address sender, address receiver, uint256 amount);
    error AlreadyRevealedError(address sender);
    error RevealedNotMatchError(bytes32 _hash, bytes32 commit);
    error RevealHappenEarly(uint256 revealTime, uint256 commitTime);
    error RevealTooLate(uint256 revealTime, uint256 lateTime);
    error RequestInvalid(address sender, uint256 requestId, uint256 targetTokenId);
    error MinReceiveNotMatch(uint256 exceptMinReceive, uint256 poolPayFor);


    
    modifier ensure(uint deadline) {
        if(deadline < block.timestamp) {
            revert TimeOutError(deadline, block.timestamp);
        }
        _;
    }

    modifier notZeroAddr(address addr_) {
        if(addr_ == ZERO_ADDRESS) {
            revert ZeroAddrError();
        }
        _;
    }

    modifier crOpen() {
        if(!isCrOpen) {
            revert PoolCloseError();
        }
        _;
    }


    

     /**
     * @dev Constructor.
     */
    constructor(
        address _poolCore,
        address _pandaToken,
        address _pandaNft   
    ) 
    {
        pandaToken = _pandaToken;
        pandaNFT = _pandaNft;
        poolKit = IPoolKit(_poolCore);
    }




//########################### CR Buy&Reborn Functions Start ####################

    function C_buy(uint256 _amountBuyMax, uint256 _deadline, bytes32 _dataHash) external ensure(_deadline)  nonReentrant crOpen {
        uint256 _requestId = buyMap[msg.sender];
        if (_requestId != 0) {
            revert RequestInvalid(msg.sender, _requestId, 0);
        }
        buyCommits[msg.sender].commit = _dataHash;
        buyCommits[msg.sender].block = uint64(block.number);
        buyCommits[msg.sender].revealed = false;
        buyCommits[msg.sender].amountBuyMax = _amountBuyMax;
        buyCommits[msg.sender].deadline = _deadline;

        uint256 feeValue = poolFeeValue + treasuryFeeValue;
        uint256 _price = poolKit._currentPrice();
        if (_amountBuyMax < _price * (FEE_BASE + feeValue) / FEE_BASE) {
            revert MaxBuyNotMatch(_amountBuyMax, _price * (FEE_BASE + feeValue) / FEE_BASE);
        }
        IERC20 _pandaToken = IERC20(pandaToken);
        if (_pandaToken.balanceOf(msg.sender) < _price * (FEE_BASE + feeValue) / FEE_BASE) {
            revert PandaNotEnough(msg.sender, _pandaToken.balanceOf(msg.sender), _price * (FEE_BASE + feeValue) / FEE_BASE);
        }

        if (poolFeeValue != 0) {
            poolKit._safeTransferFromPanda(msg.sender, address(poolKit), _price * (FEE_BASE + poolFeeValue) / FEE_BASE);
        }
        
        if (treasuryFeeValue != 0) {
            poolKit._safeTransferFromPanda(msg.sender,  owner(), _price * treasuryFeeValue / FEE_BASE);
        }

        IERC721 _pandaNFT = IERC721(pandaNFT);
        if(_pandaNFT.balanceOf(address(poolKit)) <= poolKit._minPoolNFTCount()) {
            revert PoolNotEnoughNFT(_pandaNFT.balanceOf(address(poolKit)), poolKit._minPoolNFTCount());
        }

        buyMap[msg.sender] = 1;
        emit CommitBuy(msg.sender, buyCommits[msg.sender].commit, buyCommits[msg.sender].block, _amountBuyMax, _deadline);
    }

    function R_buy(bytes32 revealHash) external  nonReentrant crOpen {
        uint256 _requestId = buyMap[msg.sender];
        if (_requestId == 0) {
            revert RequestInvalid(msg.sender, _requestId, 0);
        }
        if (buyCommits[msg.sender].revealed) {
            revert AlreadyRevealedError(msg.sender);
        }
        buyCommits[msg.sender].revealed=true;

        if (getHash(revealHash) != buyCommits[msg.sender].commit) {
            revert RevealedNotMatchError(getHash(revealHash), buyCommits[msg.sender].commit);
        }

        if (block.number <= buyCommits[msg.sender].block) {
            revert RevealHappenEarly(uint64(block.number), buyCommits[msg.sender].block);
        }
        
        if (block.number > buyCommits[msg.sender].block+250) {
            revert RevealTooLate(block.number, buyCommits[msg.sender].block+250);
        }
        //get the hash of the block that happened after they committed
        bytes32 blockHash = blockhash(buyCommits[msg.sender].block);
        //hash that with their reveal that so miner shouldn't know and mod it with some max number you want
        uint256 index = uint256(keccak256(abi.encodePacked(blockHash,revealHash))) % poolKit._poolSize();

        uint256 targetIndex = poolKit._getIdByIndex(index);
        IERC721 _pandaNFT = IERC721(pandaNFT);
        if (_pandaNFT.ownerOf(targetIndex) != address(poolKit)) {
            revert NFTOwnerNotMatch(targetIndex,  address(poolKit), _pandaNFT.ownerOf(targetIndex));
        }
        poolKit._safeTransferFromNFT(address(poolKit), msg.sender, targetIndex, "");
        poolKit._poolRemoveNft(index);
        buyMap[msg.sender] = 0;
        emit BuyRevealHash(msg.sender, revealHash, index, targetIndex);
    }

    function C_reborn(uint256 _ownerTokenId, uint256 _amountFeeMax, uint256 _deadline, bytes32 _dataHash) external ensure(_deadline)  nonReentrant crOpen {
        uint256 _requestId = rebornMap[msg.sender];
        if (_requestId != 0) {
            revert RequestInvalid(msg.sender, _requestId, 0);
        }
        IERC20 _pandaToken = IERC20(pandaToken); 
        uint256 _price = poolKit._currentPrice();
        uint256 feeValue = poolFeeValue + treasuryFeeValue;
        if (_amountFeeMax < _price * feeValue / FEE_BASE) {
            revert MaxFeeNotMatch(_amountFeeMax, _price * feeValue / FEE_BASE);
        }
        if (_pandaToken.balanceOf(msg.sender) < _price * feeValue / FEE_BASE) {
            revert PandaNotEnough(msg.sender, _pandaToken.balanceOf(msg.sender), _price * feeValue / FEE_BASE);
        }

        if (poolFeeValue != 0) {
            poolKit._safeTransferFromPanda(msg.sender, address(poolKit), _price * poolFeeValue / FEE_BASE);
        }

        if (treasuryFeeValue  != 0) {
            poolKit._safeTransferFromPanda(msg.sender, owner(), _price * treasuryFeeValue / FEE_BASE);
        }

        IERC721 _pandaNFT = IERC721(pandaNFT);
        if (_pandaNFT.ownerOf(_ownerTokenId) != msg.sender) {
            revert NFTOwnerNotMatch(_ownerTokenId, msg.sender, _pandaNFT.ownerOf(_ownerTokenId));
        }

        poolKit._safeTransferFromNFT(msg.sender, address(poolKit), _ownerTokenId, "");
        poolKit._poolPushNft(_ownerTokenId);

        rebornCommits[msg.sender].commit = _dataHash;
        rebornCommits[msg.sender].block = uint64(block.number);
        rebornCommits[msg.sender].revealed = false;
        rebornCommits[msg.sender].ownerTokenId = _ownerTokenId;
        rebornCommits[msg.sender].amountFeeMax = _amountFeeMax;
        rebornCommits[msg.sender].deadline = _deadline;
        rebornMap[msg.sender] = 1;
        emit CommitRebron(msg.sender, buyCommits[msg.sender].commit, buyCommits[msg.sender].block, _ownerTokenId, _price * 750 / 10000, _deadline);
    }

    function R_reborn(bytes32 revealHash) external  nonReentrant crOpen {
        uint256 _requestId = rebornMap[msg.sender];
        if (_requestId == 0) {
            revert RequestInvalid(msg.sender, _requestId, 0);
        }
        if (rebornCommits[msg.sender].revealed) {
            revert AlreadyRevealedError(msg.sender);
        }

        rebornCommits[msg.sender].revealed=true;

        if (getHash(revealHash) != rebornCommits[msg.sender].commit) {
            revert RevealedNotMatchError(getHash(revealHash), rebornCommits[msg.sender].commit);
        }

        if (block.number <= rebornCommits[msg.sender].block) {
            revert RevealHappenEarly(block.number, buyCommits[msg.sender].block);
        }
        
        if (block.number > rebornCommits[msg.sender].block+250) {
            revert RevealTooLate(block.number, buyCommits[msg.sender].block+250);
        }
        //get the hash of the block that happened after they committed
        bytes32 blockHash = blockhash(rebornCommits[msg.sender].block);
        //hash that with their reveal that so miner shouldn't know and mod it with some max number you want
        uint256 index = uint256(keccak256(abi.encodePacked(blockHash,revealHash))) % poolKit._poolSize();

        uint256 targetIndex = poolKit._getIdByIndex(index);
        IERC721 _pandaNFT = IERC721(pandaNFT);
        if (_pandaNFT.ownerOf(targetIndex) != address(poolKit)) {
            revert NFTOwnerNotMatch(targetIndex, address(poolKit), _pandaNFT.ownerOf(targetIndex));
        }
        poolKit._safeTransferFromNFT(address(poolKit), msg.sender, targetIndex, "");
        poolKit._poolRemoveNft(index);
        rebornMap[msg.sender] = 0;
        emit RebornRevealHash(msg.sender, revealHash, rebornCommits[msg.sender].ownerTokenId, index, targetIndex);
    }

    function getHash(bytes32 data) public view returns(bytes32){
        return keccak256(abi.encodePacked(address(this), data));
    }   


       /**
     * @dev redeem NFT, you will receive $PANDA.
     * @param _ownerTokenId The NFT Id you want to redeem
     * @param _amountRedeemMin  Less than this value you will not redeem
     * @param _deadline deadline
     */
    function redeem(uint256 _ownerTokenId, uint256 _amountRedeemMin, uint256 _deadline) external ensure(_deadline) nonReentrant crOpen {
        IERC721 _pandaNFT = IERC721(pandaNFT);
        if (_pandaNFT.ownerOf(_ownerTokenId) != msg.sender) {
            revert NFTOwnerNotMatch(_ownerTokenId,  msg.sender, _pandaNFT.ownerOf(_ownerTokenId));
        }
        
        uint256 _price = poolKit._currentPrice();
        uint256 feeValue = poolFeeValue + treasuryFeeValue;
        if (_amountRedeemMin > _price * (FEE_BASE - feeValue) / FEE_BASE) {
            revert MinReceiveNotMatch(_amountRedeemMin, _price * (FEE_BASE - feeValue) / FEE_BASE);
        }

        poolKit._safeTransferFromNFT(msg.sender, address(poolKit), _ownerTokenId, "");
        poolKit._poolPushNft(_ownerTokenId);
        poolKit._safeTransferToPanda(msg.sender, _price * (FEE_BASE - feeValue) / FEE_BASE);
        emit Redeem(msg.sender, _ownerTokenId, _price * (FEE_BASE - feeValue) / FEE_BASE);
    }        

//########################### CR Buy&Reborn Functions End ####################

    /**
     * @dev withdrawERC20  tokens.
     * @param _recipient recipient
     * @param _tokenAddress  token
     * @param _tokenAmount amount
     */
    function withdrawERC20(address _recipient, address _tokenAddress, uint256 _tokenAmount) external onlyOwner notZeroAddr(_tokenAddress) {
        IERC20(_tokenAddress).safeTransfer(_recipient, _tokenAmount);
        emit WithdrawERC20(_recipient, _tokenAddress, _tokenAmount);
    }
    

    /**
     * @dev setLiquidityClose close or open swap、redeem、buy.
     * @param _crOpen true or false          
     */
    function setSwitchs(bool _crOpen) external onlyOwner {
        isCrOpen = _crOpen;
        emit SwitchEvent(_crOpen);
    }

    function setPoolFeeValue(uint256 _feeValue) external onlyOwner {
        poolFeeValue = _feeValue;
        emit SetPoolFeeValue(_feeValue);
    }

    function setTreasuryFeeValue(uint256 _feeValue) external onlyOwner {
        treasuryFeeValue = _feeValue;
        emit SetTreasuryFeeValue(_feeValue);
    }

}