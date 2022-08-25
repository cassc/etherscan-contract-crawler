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

import "../interfaces/IPandaPool.sol";
import "../interfaces/IPoolKit.sol";

/**
 */

contract PandaPoolCore is Ownable, ReentrancyGuard, IERC721Receiver, IPoolKit, IPandaPool {
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
    uint256 public minPoolNFTCount = 1000;

    mapping(address => bool) public admins;

    bool public isPoolOpen = true;
    bool public isCrOpen = true;
    mapping(uint256 => uint256) public poolNftMap;
    mapping(address => BuyCommit) public buyCommits;
    mapping(address => RebornCommit) public rebornCommits;
    mapping(address => bool) public buyCompensates;
    mapping(address => bool) public rebornCompensates;
    uint256 public poolSize = 2000;
    uint256 public poolIndexBase = 1;

    address public constant ZERO_ADDRESS = address(0);
    uint256 public constant NFT_TOTAL_SUPPLY = 10000;
    uint256 public constant FEE_BASE = 10000;
    uint256 public poolFeeValue = 375;
    uint256 public treasuryFeeValue = 0;


    event Redeem(address indexed recipient, uint256 ownerTokenId, uint256 receiveAmount);
    event AddLiquidity(address indexed recipient, uint256[] supplyTokens, uint256 amountPayToken, uint256 updateMinPoolNftCount);
    event RemoveLiquidity(address indexed recipient, uint256[] targetTokens, uint256 amountReceiveToken, uint256 updateMinPoolNftCount);
    event RemovePoolForUpdate(address indexed recipient, uint256[] targetTokens);
    event AddPoolForSwap(address indexed recipient, uint256[] supplyTokens);
    event WithdrawERC20(address recipient, address tokenAddress, uint256 tokenAmount);
    event WithdrawEther(address recipient, uint256 amount);
    event CommitOwnerBuy(address indexed sender, bytes32 dataHash, uint64 block);    
    event CommitOwnerRebron(address indexed sender, bytes32 dataHash, uint64 block,uint256 ownerTokenId);    
    event OwnerRebornRevealHash(address indexed sender, bytes32 revealHash, uint256 ownerTokenId, uint256 index, uint256 targetIndex);
    event OwnerBuyRevealHash(address indexed sender, bytes32 revealHash, uint256 index, uint256 targetIndex);
    event ResetPandaPool(uint256 size, uint256 poolIndexBase);
    event SwitchEvent(bool poolOpne, bool crOpen);
    event SetPoolFeeValue(uint256 feeValue);
    event SetTreasuryFeeValue(uint256 feeValue);
    event UpdatePandaPool(uint256 updateMinPoolNftCount);

    error OnlyAdminError();
    error TimeOutError(uint256 deadline, uint256 timestamp);
    error ZeroAddrError();
    error PoolCloseError();
    error NFTOwnerNotMatch(uint tokenId, address expectOwner, address realOwner);
    error MaxFeeNotMatch(uint256 maxUserFee, uint256 poolNeedFee);
    error PandaNotEnough(address sender, uint256 balance, uint256 needBalance);
    error PoolNFTTooMany(uint256 poolNftNum, uint256 upLimit);
    error MinReceiveNotMatch(uint256 exceptMinReceive, uint256 poolPayFor);
    error MaxBuyNotMatch(uint256 maxUserPayFor, uint256 poolNeedPayFor);
    error PoolNotEnoughNFT(uint256 poolBalance, uint256 downLimit);
    error UserNotEnoughNFT(address user, uint256 userBalance, uint256 needBalance);
    error PoolIndexNotMatchNFTId(uint256 index, uint256 poolTokeId, uint256 exceptTokenId);
    error TransferEhterFail(address sender, address receiver, uint256 amount);
    error AlreadyRevealedError(address sender);
    error RevealedNotMatchError(bytes32 _hash, bytes32 commit);
    error RevealHappenEarly(uint256 revealTime, uint256 commitTime);
    error RevealTooLate(uint256 revealTime, uint256 lateTime);
    error NotCompensate(address user);
    error PoolArrayIndexOutOfRange(uint256 index, uint256 size);
    error CannotWithdrawPanda();


    modifier onlyAdmin() {
        if(!admins[msg.sender] && msg.sender != owner()) {
            revert OnlyAdminError();
        }
        _;
    }

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

     modifier poolOpen() {
        if(!isPoolOpen) {
            revert PoolCloseError();
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
        address _pandaToken,
        address _pandaNft
    )
    {
        pandaToken = _pandaToken;
        pandaNFT = _pandaNft;
    }

    function addAdmin(address _admin) external onlyOwner {
        admins[_admin] = true;
    }

    function removeAdmin(address _admin) external onlyOwner {
        admins[_admin] = false;
    }

    
//############################ Liquid Functions Start #####################

    /**
     * @dev redeem NFT, you will receive $PANDA.
     * @param _ownerTokenId The NFT Id you want to redeem
     * @param _amountRedeemMin  Less than this value you will not redeem
     * @param _deadline deadline
     */
    function redeem(uint256 _ownerTokenId, uint256 _amountRedeemMin, uint256 _deadline) external override ensure(_deadline) nonReentrant poolOpen {
        IERC721 _pandaNFT = IERC721(pandaNFT);
        if (_pandaNFT.ownerOf(_ownerTokenId) != msg.sender) {
            revert NFTOwnerNotMatch(_ownerTokenId,  msg.sender, _pandaNFT.ownerOf(_ownerTokenId));
        }
        
        uint256 _price = _currentPrice();
        uint256 feeValue = poolFeeValue + treasuryFeeValue;
        if (_amountRedeemMin > _price * (FEE_BASE - feeValue) / FEE_BASE) {
            revert MinReceiveNotMatch(_amountRedeemMin, _price * (FEE_BASE - feeValue) / FEE_BASE);
        }
        _pandaNFT.safeTransferFrom(msg.sender, address(this), _ownerTokenId, "");
        
        IERC20(pandaToken).safeTransfer(msg.sender,  _price * (FEE_BASE - feeValue) / FEE_BASE);
        _poolPushNft(_ownerTokenId);
        emit Redeem(msg.sender, _ownerTokenId, _price * (FEE_BASE - feeValue) / FEE_BASE);
    }


    /**
     * @dev owner addLiquidity.
     * @param _supplyTokens add these NFTs to pool
     * @param _amountTokenMax  Above this value owner will not add liquidity
     * @param _updateMinPoolNftCount update pool min nfts 
     * @param _deadline deadline
     */
    function addLiquidity(uint256[] calldata _supplyTokens, uint256 _amountTokenMax, uint256 _updateMinPoolNftCount, uint256 _deadline) external override ensure(_deadline) onlyOwner nonReentrant {

        uint256 _length = _supplyTokens.length;
        IERC721 _pandaNFT = IERC721(pandaNFT);
        if(_pandaNFT.balanceOf(msg.sender) < _length) {
            revert UserNotEnoughNFT(msg.sender, _pandaNFT.balanceOf(msg.sender), _length);
        }

        IERC20 _pandaToken = IERC20(pandaToken);
        if (_pandaToken.balanceOf(msg.sender) < _amountTokenMax) {
            revert PandaNotEnough(msg.sender, _pandaToken.balanceOf(msg.sender), _amountTokenMax);
        }

        uint256 _price = _currentPrice();
        uint256 tranTokens;
        
        
        uint256 _iTokenId;
        for (uint256 i = 0; i < _length; i++) {
            _iTokenId = _supplyTokens[i];
            _pandaNFT.safeTransferFrom(msg.sender, address(this), _iTokenId, "");
            tranTokens += _price;
            _poolPushNft(_iTokenId);
        }
        if (_amountTokenMax < tranTokens) {
            revert MaxBuyNotMatch(_amountTokenMax, tranTokens);
        }
        _pandaToken.safeTransferFrom(msg.sender, address(this), tranTokens);

        if (_pandaNFT.balanceOf(address(this)) < _updateMinPoolNftCount) {
            revert PoolNotEnoughNFT(_pandaNFT.balanceOf(address(this)), _updateMinPoolNftCount);
        }

        if(minPoolNFTCount != _updateMinPoolNftCount) {
            minPoolNFTCount = _updateMinPoolNftCount;
        }
        emit AddLiquidity(msg.sender, _supplyTokens, tranTokens, _updateMinPoolNftCount);
    }

    /**
     * @dev owner removeLiquidity.
     * @param _targetTokens remove these NFTs from pool
     * @param _amountTokenMin  Less than this value owner will not remove liquidity
     * @param _updateMinPoolNftCount update pool min nfts 
     */
    function removeLiquidity(uint256[] calldata _targetTokens, uint256[] calldata _targetPoolIndexs, uint256 _amountTokenMin, uint256 _updateMinPoolNftCount) external override onlyOwner nonReentrant {
        uint256 _length = _targetTokens.length;
        IERC721 _pandaNFT = IERC721(pandaNFT);
        if (_pandaNFT.balanceOf(address(this)) < _length) {
            revert PoolNotEnoughNFT(_pandaNFT.balanceOf(address(this)), _length);
        }

        IERC20 _pandaToken = IERC20(pandaToken);
        if (_pandaToken.balanceOf(address(this)) < _amountTokenMin) {
            revert PandaNotEnough(address(this), _pandaToken.balanceOf(address(this)), _amountTokenMin);
        }

        uint256 _price = _currentPrice();
        uint256 tranTokens;
        uint256 _iTargetTokenId;
        uint256 _iPoolIndex;
        for (uint256 i = 0; i < _length; i++) {
            _iTargetTokenId = _targetTokens[i];
            _iPoolIndex = _targetPoolIndexs[i];
            _pandaNFT.safeTransferFrom(address(this), msg.sender, _iTargetTokenId, "");
            {
                if(_getIdByIndex(_iPoolIndex) != _iTargetTokenId) {
                    revert PoolIndexNotMatchNFTId(_iPoolIndex, _getIdByIndex(_iPoolIndex), _iTargetTokenId);
                }
                _poolRemoveNft(_iPoolIndex);
            }
            
            tranTokens += _price;
        }

        if (_amountTokenMin > tranTokens) {
            revert MinReceiveNotMatch(_amountTokenMin, tranTokens);
        }
        _pandaToken.safeTransfer(msg.sender, tranTokens);

        if(_pandaNFT.balanceOf(address(this)) < _updateMinPoolNftCount) {
            revert PoolNotEnoughNFT(_pandaNFT.balanceOf(address(this)), _updateMinPoolNftCount);
        }
        if(minPoolNFTCount != _updateMinPoolNftCount) {
            minPoolNFTCount = _updateMinPoolNftCount;
        }

        emit RemoveLiquidity(msg.sender, _targetTokens, tranTokens, _updateMinPoolNftCount);
    }


    /**
     * @dev owner removePoolForUpdate.
     * @param _targetTokens remove these NFTs from pool
     */
    function removePoolForUpdate(uint256[] calldata _targetTokens, uint256[] calldata _targetPoolIndexs) external  onlyOwner nonReentrant {
        uint256 _length = _targetTokens.length;
        IERC721 _pandaNFT = IERC721(pandaNFT);
        if (_pandaNFT.balanceOf(address(this)) < _length) {
            revert PoolNotEnoughNFT(_pandaNFT.balanceOf(address(this)), _length);
        }

        uint256 _iTargetTokenId;
        uint256 _iPoolIndex;
        for (uint256 i = 0; i < _length; i++) {
            _iTargetTokenId = _targetTokens[i];
            _iPoolIndex = _targetPoolIndexs[i];
            _pandaNFT.safeTransferFrom(address(this), msg.sender, _iTargetTokenId, "");
            {
                if(_getIdByIndex(_iPoolIndex) != _iTargetTokenId) {
                    revert PoolIndexNotMatchNFTId(_iPoolIndex, _getIdByIndex(_iPoolIndex), _iTargetTokenId);
                }
                _poolRemoveNft(_iPoolIndex);
            }
        }

        emit RemovePoolForUpdate(msg.sender, _targetTokens);
    }


    /**
     * @dev owner addPoolforSwap.
     * @param _supplyTokens add these NFTs to pool
     */
    function addPoolForSwap(uint256[] calldata _supplyTokens) external  onlyOwner nonReentrant {

        uint256 _length = _supplyTokens.length;
        IERC721 _pandaNFT = IERC721(pandaNFT);
        if(_pandaNFT.balanceOf(msg.sender) < _length) {
            revert UserNotEnoughNFT(msg.sender, _pandaNFT.balanceOf(msg.sender), _length);
        }
      
        uint256 _iTokenId;
        for (uint256 i = 0; i < _length; i++) {
            _iTokenId = _supplyTokens[i];
            _pandaNFT.safeTransferFrom(msg.sender, address(this), _iTokenId, "");
            _poolPushNft(_iTokenId);
        }
       
        emit AddPoolForSwap(msg.sender, _supplyTokens);
    }

//########################### Liquid Functions End ####################



//########################### CR Buy&Reborn Functions Start ####################

    function addCompensate(address user) external onlyOwner {
        buyCompensates[user] = true;
    }
    function removeCompensate(address user) external onlyOwner {
        buyCompensates[user] = false;
    }

    function addRebornCompensate(address user) external onlyOwner {
        rebornCompensates[user] = true;
    }
    function removeRebornCompensate(address user) external onlyOwner {
        rebornCompensates[user] = false;
    }

    function ownerCBuy(bytes32 _dataHash) external  nonReentrant  {
        if (!buyCompensates[msg.sender]) {
            revert NotCompensate(msg.sender);
        }
        buyCommits[msg.sender].commit = _dataHash;
        buyCommits[msg.sender].block = uint64(block.number);
        buyCommits[msg.sender].revealed = false;
        emit CommitOwnerBuy(msg.sender, buyCommits[msg.sender].commit, buyCommits[msg.sender].block);
    }

    function ownerRBuy(bytes32 revealHash) external  nonReentrant crOpen {
        if (!buyCompensates[msg.sender]) {
            revert NotCompensate(msg.sender);
        }
        buyCompensates[msg.sender] = false;
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
        uint256 index = uint256(keccak256(abi.encodePacked(blockHash,revealHash))) % poolSize;
        uint256 targetIndex = _getIdByIndex(index);
        IERC721 _pandaNFT = IERC721(pandaNFT);
        if (_pandaNFT.ownerOf(targetIndex) != address(this)) {
            revert NFTOwnerNotMatch(targetIndex,  address(this), _pandaNFT.ownerOf(targetIndex));
        }

        if(_pandaNFT.balanceOf(address(this)) <= minPoolNFTCount) {
            revert PoolNotEnoughNFT(_pandaNFT.balanceOf(address(this)), minPoolNFTCount);
        }
        _pandaNFT.safeTransferFrom(address(this), msg.sender, targetIndex, "");
        _poolRemoveNft(index);
        emit OwnerBuyRevealHash(msg.sender, revealHash, index, targetIndex);
    }

    function ownerCReborn(uint256 _ownerTokenId, bytes32 _dataHash) external nonReentrant crOpen {
        if (!rebornCompensates[msg.sender]) {
            revert NotCompensate(msg.sender);
        }
        rebornCommits[msg.sender].commit = _dataHash;
        rebornCommits[msg.sender].block = uint64(block.number);
        rebornCommits[msg.sender].revealed = false;
        rebornCommits[msg.sender].ownerTokenId = _ownerTokenId;
        emit CommitOwnerRebron(msg.sender, buyCommits[msg.sender].commit, buyCommits[msg.sender].block, _ownerTokenId);
    }


    function ownerRReborn(bytes32 revealHash) external  nonReentrant crOpen {
        if (!rebornCompensates[msg.sender]) {
            revert NotCompensate(msg.sender);
        }
        rebornCompensates[msg.sender] = false;
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
        uint256 index = uint256(keccak256(abi.encodePacked(blockHash,revealHash))) % poolSize;

        uint256 targetIndex = _getIdByIndex(index);
        IERC721 _pandaNFT = IERC721(pandaNFT);
        if (_pandaNFT.ownerOf(targetIndex) != address(this)) {
            revert NFTOwnerNotMatch(targetIndex, address(this), _pandaNFT.ownerOf(targetIndex));
        }
        
        _pandaNFT.safeTransferFrom(msg.sender, address(this), rebornCommits[msg.sender].ownerTokenId, "");
        _pandaNFT.safeTransferFrom(address(this), msg.sender, targetIndex, "");
        _poolPushNft(rebornCommits[msg.sender].ownerTokenId);
        _poolRemoveNft(index);
        emit OwnerRebornRevealHash(msg.sender, revealHash, rebornCommits[msg.sender].ownerTokenId, index, targetIndex);
    } 

    function getHash(bytes32 data) public view returns(bytes32){
        return keccak256(abi.encodePacked(address(this), data));
    }           

//########################### CR Buy&Reborn Functions End ####################

//########################### Pool Utils Functions Start ####################

    function _safeTransferPanda(
        address to,
        uint256 value
    ) external override onlyAdmin {
        IERC20 _pandaToken = IERC20(pandaToken);
        _pandaToken.safeTransfer(to, value);
    }

    function _safeTransferFromPanda(
        address from,
        address to,
        uint256 value
    ) external override onlyAdmin {
        IERC20 _pandaToken = IERC20(pandaToken);
        _pandaToken.safeTransferFrom(from, to, value);
    }

    function _safeTransferToPanda(
        address to,
        uint256 value
    ) external override onlyAdmin {
        IERC20 _pandaToken = IERC20(pandaToken);
        _pandaToken.safeTransfer(to,  value);
    }

    function _safeTransferFromNFT(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external override onlyAdmin {
        IERC721 _pandaNFT = IERC721(pandaNFT);
        _pandaNFT.safeTransferFrom(from, to, tokenId, data);
    }

    function _poolSize() public override view returns(uint256) {
        return poolSize;
    }

    function _minPoolNFTCount() public override view returns(uint256) {
        return minPoolNFTCount;
    }

    function _poolRemoveNft(uint256 _index) public override onlyAdmin {
        if (_index >= poolSize) {
            revert PoolArrayIndexOutOfRange(_index, poolSize);
        }
        if (_index == poolSize - 1) {
            poolNftMap[_index] = 0;
        } else {
            poolNftMap[_index] = _getIdByIndex(poolSize - 1);//poolNftMap[poolSize - 1];
            poolNftMap[poolSize - 1] = 0;
        }
        poolSize--;
    }

    function _poolPushNft(uint256 _value) public override onlyAdmin {
        poolNftMap[poolSize] = _value;
        poolSize++;
    }

    function _getIdByIndex(uint256 _index) public override returns(uint256) {
        if (_index >= poolSize) {
            revert PoolArrayIndexOutOfRange(_index, poolSize);
        }
        if(poolNftMap[_index] == 0) {
            poolNftMap[_index] = _index + poolIndexBase;
            return poolNftMap[_index];
        } else {
            return poolNftMap[_index];
        }
    }

    /**
     * @dev calculate current price
     */
    function _currentPrice() public view override returns(uint256 _price) {
        if (IERC721(pandaNFT).balanceOf(address(this)) < NFT_TOTAL_SUPPLY) {
            _price = IERC20(pandaToken).balanceOf(address(this)) / (NFT_TOTAL_SUPPLY - poolSize);
        } else {
            _price = IERC20(pandaToken).balanceOf(address(this));
        }
        
    }   


    function _resetPandaPool(uint256 _size, uint256 _poolIndexBase) external onlyOwner {
        poolSize = _size;
        poolIndexBase = _poolIndexBase;
        emit ResetPandaPool(_size, _poolIndexBase);
    } 

    function _updatePandaPoolMin(uint256 _updateMinPoolNftCount) external onlyOwner {
        minPoolNFTCount = _updateMinPoolNftCount;
        emit UpdatePandaPool(_updateMinPoolNftCount);
    } 

//########################### Pool Utils Functions End ####################

    /**
     * @dev setLiquidityClose close or open swap、redeem、buy.
     * @param _poolOpne true or false
     * @param _crOpen true or false          
     */
    function setSwitchs(bool _poolOpne, bool _crOpen) external onlyOwner {
        isPoolOpen = _poolOpne;
        isCrOpen = _crOpen;
        emit SwitchEvent(_poolOpne, _crOpen);
    }

    function setPoolFeeValue(uint256 _feeValue) external onlyOwner {
        poolFeeValue = _feeValue;
        emit SetPoolFeeValue(_feeValue);
    }

    function setTreasuryFeeValue(uint256 _feeValue) external onlyOwner {
        treasuryFeeValue = _feeValue;
        emit SetTreasuryFeeValue(_feeValue);
    }


    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes calldata _data ) pure external override returns (bytes4) {
        return this.onERC721Received.selector;
    } 

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
     * @dev withdraw Ether.
     * @param recipient recipient
     * @param amount amount
     */
    function withdrawEther(address payable recipient, uint256 amount) external onlyOwner {
        (bool success,) = recipient.call{value:amount}("");
        if(!success) {
            revert TransferEhterFail(msg.sender, recipient, amount);
        }
        emit WithdrawEther(recipient, amount);
    }


    fallback () external payable {}

    receive () external payable {}

}