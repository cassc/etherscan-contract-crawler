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

import "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

import "../interfaces/IPoolKit.sol";
/**
 */

contract PandaVRFProducer is Ownable, ReentrancyGuard, VRFConsumerBaseV2 {
    using SafeERC20 for IERC20;
    struct RequestInfo {
        uint256 reqFunc;
        address sender;
        uint256 ownerTokenId;
        uint256 targetTokenId;
        uint256 amountFeeMax;
        uint256 deadline;
        uint256 reqState;
    }


    address immutable public pandaToken;
    address immutable public pandaNFT;
    IPoolKit public poolKit;
    bool public isVrfOpen = false;
    mapping(uint256 => RequestInfo) public reqInfos;
    mapping(address => uint256) public rebornMap;
    mapping(address => uint256) public buyMap;

    VRFCoordinatorV2Interface COORDINATOR;
    LinkTokenInterface LINKTOKEN;
    // Storage parameters
    // uint256 public requestId;
    uint64 public subscriptionId;
    // A reasonable default is 100000, but this value could be different
    // on other networks.
    uint32 callbackGasLimit = 250_000;
    uint256 public fixedGasPrice = 10 gwei;

    uint256 constant buyGas = 179_980;
    uint256 constant rebornGas = 179_980;
    uint256 public constant REBRON_FUNC_TYPE = 1;
    uint256 public constant BUY_FUNC_TYPE = 2;
    uint8 public constant GAS_LEVEL_CONTRACT = 1;
    uint8 public constant GAS_LEVEL_200 = 2;
    uint8 public constant GAS_LEVEL_500 = 3;
    uint8 public constant GAS_LEVEL_1000 = 4;

    uint8 public constant REQ_NOT_SEND = 0;
    uint8 public constant REQ_START = 1;
    uint8 public constant REQ_PENDING = 2;
    uint8 public constant REQ_FINISH = 3;

    address public constant ZERO_ADDRESS = address(0);
    uint256 public constant NFT_TOTAL_SUPPLY = 10000;

    uint256 public constant FEE_BASE = 10000;
    uint256 public poolFeeValue = 375;
    uint256 public treasuryFeeValue = 0;

    // The default is 3, but you can set this higher.
    uint16 constant requestConfirmations = 3;
    uint32 constant numWords =  1;
    // address constant vrfCoordinator = 0x6168499c0cFfCaCD319c818142124B7A15E857ab;
    //main net 
    address constant vrfCoordinator = 0x271682DEB8C4E0901D1a1550aD2e64D568E69909;
   
    // address constant link_token_contract = 0x01BE23585060835E02B77ef475b0Cc51aA1e0709;
    //main net 0x514910771AF9Ca656af840dff83E8264EcF986CA
    address constant link_token_contract = 0x514910771AF9Ca656af840dff83E8264EcF986CA;

    // bytes32 constant keyHash200 = 0xd89b2bf150e3b9e13446986e571fb9cab24b13cea0a43ea20a6049a85cc807cc;
    // bytes32 constant keyHash500 = 0xd89b2bf150e3b9e13446986e571fb9cab24b13cea0a43ea20a6049a85cc807cc;
    // bytes32 constant keyHash1000 = 0xd89b2bf150e3b9e13446986e571fb9cab24b13cea0a43ea20a6049a85cc807cc;

    //main net 
    bytes32 constant keyHash200 = 0x8af398995b04c28e9951adb9721ef74c74f93e6a478f39e7e0777be13527e7ef;
    bytes32 constant keyHash500 = 0xff8dedfbfa60af186cf3c830acbc32c05aae823045ae5ea7da1e45fbfaba4f92;
    bytes32 constant keyHash1000 = 0x9fe0eebf5e446e3c998ec9bb19951541aee00bb90ea201ae456421a2ded86805;


    event PreReborn(uint256 indexed requestId, address indexed recipient,uint256 ownerTokenId, uint256 fee);
    event PreBuy(uint256 indexed requestId, address indexed recipient, uint256 payAmount);
    event Reborn(address indexed recipient,uint256 ownerTokenId, uint256 targetTokenId);
    event Buy(address indexed recipient, uint256 targetTokenId);
    event WithdrawERC20(address recipient, address tokenAddress, uint256 tokenAmount);
    event WithdrawEther(address recipient, uint256 amount);
    event RandomOpened(address indexed sender, uint256 index, uint256 targetIndex, uint256 requestId, uint256 random);
    event NewSubscription(address consumer, uint256 subscriptionId);
    event TopUpSubscription(uint256 amount);
    event AddConsumer(address consumerAddress);
    event RemoveConsumer(address consumerAddress);
    event CancelSubscription(address receivingWallet, uint256 subscriptionId);
    event SwitchEvent(bool _vrfOpen);
    event FixedGasPrice(uint256 _gasPrice);
    event CallbackGasLimet(uint256 _limit);
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
    error MaxBuyNotMatch(uint256 maxUserPayFor, uint256 poolNeedPayFor);
    error PoolNotEnoughNFT(uint256 poolBalance, uint256 downLimit);
    error TransferEhterFail(address sender, address receiver, uint256 amount);
    error ConcurrentRebornError(address sender, uint256 requistId);
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

    modifier vrfOpen() {
        if(!isVrfOpen) {
            revert PoolCloseError();
        }
        _;
    }


    

     /**
     * @dev Constructor.
     */
    constructor(
        address _pandaCore,
        address _pandaToken,
        address _pandaNft
    ) VRFConsumerBaseV2(vrfCoordinator)
    {
        poolKit = IPoolKit(_pandaCore);
        pandaToken = _pandaToken;
        pandaNFT = _pandaNft;
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
        LINKTOKEN = LinkTokenInterface(link_token_contract);
        //Create a new subscription when you deploy the contract.
        createNewSubscription();
    }




//########################### Vrf Buy&Reborn Functions Start ####################
    

    /**
     * @dev  reborn NFT.
     * @param _ownerTokenId The NFT Id you want to reborn
     * @param _amountFeeMax max fee you want to pay for swapping
     * @param _deadline deadline
     * @param _gasLevel gas level you want pay for
     */
    function reborn(uint256 _ownerTokenId, uint256 _amountFeeMax, uint256 _deadline, uint8 _gasLevel) payable external ensure(_deadline)  nonReentrant vrfOpen {
        if (rebornMap[msg.sender] != 0) {
            revert ConcurrentRebornError(msg.sender, rebornMap[msg.sender]);
        }
        bytes32 keyHash = keyHash200;
        uint256 gasPrice = fixedGasPrice;
        if (_gasLevel == GAS_LEVEL_200) {
            gasPrice = 200 gwei;
        } else if (_gasLevel == GAS_LEVEL_500) {
            keyHash = keyHash500;
            gasPrice = 500 gwei;
        } else if (_gasLevel == GAS_LEVEL_1000) {
            keyHash = keyHash1000;
            gasPrice = 1000 gwei;
        }

        if(msg.value < gasPrice * rebornGas) {
            revert NoEnoughCallbackGas(msg.value, gasPrice * rebornGas);
        }
        if (msg.value > gasPrice * rebornGas) {
            payable(msg.sender).transfer(msg.value - gasPrice * rebornGas);
        }

        uint256 requestId = COORDINATOR.requestRandomWords(
          keyHash,
          subscriptionId,
          requestConfirmations,
          callbackGasLimit,
          numWords
        );
        RequestInfo storage reqInfo = reqInfos[requestId];
        reqInfo.reqFunc = REBRON_FUNC_TYPE;
        reqInfo.sender = msg.sender;
        reqInfo.ownerTokenId = _ownerTokenId;
        reqInfo.amountFeeMax = _amountFeeMax;
        reqInfo.deadline = _deadline;
        reqInfo.reqState = REQ_START;
        rebornMap[msg.sender] = requestId;

        uint256 _price = poolKit._currentPrice();
        uint256 feeValue = poolFeeValue + treasuryFeeValue;
        if (_amountFeeMax < _price * feeValue / FEE_BASE) {
            revert MaxFeeNotMatch(_amountFeeMax, _price * (FEE_BASE - feeValue) / FEE_BASE);
        }
        IERC20 _pandaToken = IERC20(pandaToken);
        if (_pandaToken.balanceOf(msg.sender) < _price *feeValue / FEE_BASE) {
            revert PandaNotEnough(msg.sender, _pandaToken.balanceOf(msg.sender), _price * feeValue / FEE_BASE);
        }
        if (poolFeeValue != 0) {
            poolKit._safeTransferFromPanda(msg.sender, address(poolKit), _price * poolFeeValue / FEE_BASE);
        }
        
        
        if(treasuryFeeValue != 0) {
            poolKit._safeTransferFromPanda(msg.sender, owner(), _price * treasuryFeeValue / FEE_BASE);
        }
        

        
        poolKit._safeTransferFromNFT(msg.sender, address(poolKit), _ownerTokenId, "");
        poolKit._poolPushNft(_ownerTokenId);

        emit PreReborn(requestId, msg.sender, _ownerTokenId, _price * feeValue / FEE_BASE);
    }


    /**
     * @dev buy NFT, you should pay $PANDA.
     * @param _amountBuyMax  Above this value you will not make a purchase
     * @param _deadline deadline
     * @param _gasLevel gas level you want pay for
     */
    function buy(uint256 _amountBuyMax, uint256 _deadline, uint8 _gasLevel) payable external ensure(_deadline)  nonReentrant vrfOpen {
        bytes32 keyHash = keyHash200;
        uint256 gasPrice = fixedGasPrice;
        if (_gasLevel == GAS_LEVEL_200) {
            gasPrice = 200 gwei;
        } else if (_gasLevel == GAS_LEVEL_500) {
            keyHash = keyHash500;
            gasPrice = 500 gwei;
        } else if (_gasLevel == GAS_LEVEL_1000) {
            keyHash = keyHash1000;
            gasPrice = 1000 gwei;
        }

        if(msg.value < gasPrice * buyGas) {
            revert NoEnoughCallbackGas(msg.value, gasPrice * buyGas);
        }
        if (msg.value > gasPrice * buyGas) {
            payable(msg.sender).transfer(msg.value - gasPrice * buyGas);
        } 

        uint256 requestId = COORDINATOR.requestRandomWords(
          keyHash,
          subscriptionId,
          requestConfirmations,
          callbackGasLimit,
          numWords
        );
        RequestInfo storage reqInfo = reqInfos[requestId];
        reqInfo.reqFunc = BUY_FUNC_TYPE;
        reqInfo.sender = msg.sender;
        reqInfo.amountFeeMax = _amountBuyMax;
        reqInfo.deadline = _deadline;
        reqInfo.reqState = REQ_START;
        buyMap[msg.sender] = requestId;

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
            poolKit._safeTransferFromPanda(msg.sender,  owner(), _price * treasuryFeeValue/ FEE_BASE);
        }

        IERC721 _pandaNFT = IERC721(pandaNFT);
        if(_pandaNFT.balanceOf(address(poolKit)) <= poolKit._minPoolNFTCount()) {
            revert PoolNotEnoughNFT(_pandaNFT.balanceOf(address(poolKit)), poolKit._minPoolNFTCount());
        }
        
        emit PreBuy(requestId, msg.sender, _price * (FEE_BASE + feeValue) / FEE_BASE);
    }

    function fulfillRandomWords(
        uint256 _requestId, /* requestId */
        uint256[] memory randomWords
    ) internal override {
        uint256 index = randomWords[0] % poolKit._poolSize();
        uint256 targetIndex = poolKit._getIdByIndex(index);
        poolKit._poolRemoveNft(index);
        RequestInfo storage reqInfo = reqInfos[_requestId];
        reqInfo.targetTokenId = targetIndex;
        reqInfo.reqState = REQ_PENDING;
        emit RandomOpened(reqInfo.sender, index, targetIndex, _requestId, randomWords[0]);
        // uint256 funcType = reqInfo.reqFunc;
        // if (funcType == REBRON_FUNC_TYPE) {
        //     _reborn(reqInfo.sender,reqInfo.ownerTokenId, targetIndex, reqInfo.amountFeeMax, reqInfo.deadline);  
        // } else {
        //     _buy(reqInfo.sender, targetIndex, reqInfo.amountFeeMax, reqInfo.deadline);
        // }
    }

    /**
     * @dev external reborn NFT.
     */
    function onReborn() external  {
        uint256 _requestId = rebornMap[msg.sender];
        uint256 targetId = reqInfos[_requestId].targetTokenId;
        uint256 reqState = reqInfos[_requestId].reqState;
        if (_requestId == 0 || targetId == 0 || reqState != REQ_PENDING) {
            revert RequestInvalid(msg.sender, _requestId, targetId);
        }
        
        IERC721 _pandaNFT = IERC721(pandaNFT);
        if (_pandaNFT.ownerOf(targetId) != address(poolKit)) {
            revert NFTOwnerNotMatch(targetId, address(poolKit), _pandaNFT.ownerOf(targetId));
        }
        poolKit._safeTransferFromNFT(address(poolKit), msg.sender, targetId, "");
        rebornMap[msg.sender] = 0;
        reqInfos[_requestId].reqState = REQ_FINISH;
        emit Reborn(msg.sender, reqInfos[_requestId].ownerTokenId, targetId);
    }

    /**
     * @dev external buy NFT, you will receive $PANDA.
     */
    function onBuy() external {
        uint256 _requestId = buyMap[msg.sender];
        uint256 _targetId = reqInfos[_requestId].targetTokenId;
        uint256 _reqState = reqInfos[_requestId].reqState;
        if (_requestId == 0 || _targetId == 0 || _reqState != REQ_PENDING) {
            revert RequestInvalid(msg.sender, _requestId, _targetId);
        }
        IERC721 _pandaNFT = IERC721(pandaNFT);
        if (_pandaNFT.ownerOf(_targetId) != address(poolKit)) {
            revert NFTOwnerNotMatch(_targetId,  address(poolKit), _pandaNFT.ownerOf(_targetId));
        }
        poolKit._safeTransferFromNFT(address(poolKit), msg.sender, _targetId, "");

        buyMap[msg.sender] = 0;
        reqInfos[_requestId].reqState = REQ_FINISH;
        emit Buy(msg.sender, _targetId);
    }

    /**
     * @dev redeem NFT, you will receive $PANDA.
     * @param _ownerTokenId The NFT Id you want to redeem
     * @param _amountRedeemMin  Less than this value you will not redeem
     * @param _deadline deadline
     */
    function redeem(uint256 _ownerTokenId, uint256 _amountRedeemMin, uint256 _deadline) external ensure(_deadline) nonReentrant vrfOpen {
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


//########################### Vrf Buy&Reborn Functions End ####################



//########################### VRF Base Functions Start ####################
    function createNewSubscription() public onlyOwner {
        address[] memory consumers = new address[](1);
        consumers[0] = address(this);
        subscriptionId = COORDINATOR.createSubscription();
        COORDINATOR.addConsumer(subscriptionId, consumers[0]);
        emit NewSubscription(consumers[0], subscriptionId);
    }

    function topUpSubscription(uint256 amount) external onlyOwner {
        LINKTOKEN.transferAndCall(address(COORDINATOR), amount, abi.encode(subscriptionId));
        emit TopUpSubscription(amount);
    }

    function addConsumer(address consumerAddress) external onlyOwner {
        COORDINATOR.addConsumer(subscriptionId, consumerAddress);
        emit AddConsumer(consumerAddress);
    }

    function removeConsumer(address consumerAddress) external onlyOwner {
        COORDINATOR.removeConsumer(subscriptionId, consumerAddress);
        emit RemoveConsumer(consumerAddress);
    }

    function cancelSubscription(address receivingWallet) external onlyOwner {
        COORDINATOR.cancelSubscription(subscriptionId, receivingWallet);
        subscriptionId = 0;
        emit CancelSubscription(receivingWallet, subscriptionId);
    }
//########################### VRF Base Functions End ####################



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


    /**
     * @dev setLiquidityClose close or open swap、redeem、buy.
     * @param _vrfOpen true or false        
     */
    function setSwitchs(bool _vrfOpen) external onlyOwner {
        isVrfOpen = _vrfOpen;
        emit SwitchEvent(_vrfOpen);
    }

    function seteFixedGasPrice(uint256 _gasPrice) external onlyOwner {
        fixedGasPrice = _gasPrice;
        emit FixedGasPrice(_gasPrice);
    }

    function setCallbackGasLimet(uint32 _limit) external onlyOwner {
        callbackGasLimit = _limit;
        emit CallbackGasLimet(_limit);
    }

    function setPoolFeeValue(uint256 _feeValue) external onlyOwner {
        poolFeeValue = _feeValue;
        emit SetPoolFeeValue(_feeValue);
    }

    function setTreasuryFeeValue(uint256 _feeValue) external onlyOwner {
        treasuryFeeValue = _feeValue;
        emit SetTreasuryFeeValue(_feeValue);
    }


    fallback () external payable {}

    receive () external payable {}

}