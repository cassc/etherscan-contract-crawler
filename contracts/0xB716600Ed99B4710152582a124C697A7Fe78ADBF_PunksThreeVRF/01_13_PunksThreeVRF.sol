// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

import "./ERC721Enumerable.sol";

contract PunksThreeVRF is VRFConsumerBaseV2, ERC721Enumerable {
    using ECDSA for bytes32;

    struct Window {
        uint128 startWindow;
        uint128 endWindow;
    }

    struct Prize {
        bool tokenType; //1155 is 0, 721 is 1
        bool mint;
        address tokenAddress;
    }
    
    address constant FOUNDERS_DAO = 0x580A96BC816C2324Bdff5eb2a7E159AE7ee63022;
    address signer;
    address immutable tokenHolder;

    uint256 public immutable PRICE;

    VRFCoordinatorV2Interface immutable COORDINATOR;
    bytes32 keyHash;
    uint32 callbackGasLimit = 2500000;
    uint16 requestConfirmations = 3;
    uint64 subscriptionId;
    
    uint256 public maxSale;
    uint8[] public remainingTokens;
    uint256 public amountSold;
    uint256 prizeCounter; 
    uint256 stageCounter; 

    mapping(uint256 => address) public requestToAddress;
    mapping(address => uint256) public amountMinted;
    mapping(uint256 => Window) public stages;
    mapping(uint256 => Prize) public prizes;

    Window publicWindow;

    error windowClosed();
    error signatureInvalid();
    error amountInvalid();
    error allPrizesDistributed();
    error insufficientPayment();
    error soldOut();
    error withdrawFailed();
    error addStagesFailed();
    error callerNotOwnerNorApproved();
    error notSameLength();
    error maxSupplyExceeded();

    constructor(
        address _vrfCoordinator,
        bytes32 _keyHash,
        uint64 _subscriptionId,
        address _signer,
        address _tokenHolder,
        string memory _name,
        string memory _symbol,
        string memory _uri,
        uint256 _price
    ) PVERC721(_name, _symbol, _uri, 15000) VRFConsumerBaseV2(_vrfCoordinator) {        
        COORDINATOR = VRFCoordinatorV2Interface(_vrfCoordinator);
        subscriptionId = _subscriptionId;
        keyHash = _keyHash;

        signer = _signer;
        tokenHolder = _tokenHolder;

        PRICE = _price;

        _internalMint(FOUNDERS_DAO);
    }   

    function fillRemainingTokens(uint8 _prizeId, uint256 _amount) public onlyOwner {
        for(uint256 i; i < _amount;) {

            remainingTokens.push(_prizeId);
            
            unchecked {
                ++i;
            }
        }

        maxSale += _amount;
    }

    function clearRemainingTokens(uint256 _newMaxSale) external onlyOwner {
        remainingTokens = new uint8[](0);
        maxSale = _newMaxSale;
    }

    function setPublicWindow(Window calldata window) external onlyOwner {
        publicWindow.startWindow = window.startWindow;
        publicWindow.endWindow = window.endWindow;
    }

    function setSigner(address _signer) external onlyOwner {
        signer = _signer;
    }

    function addStages(Window[] memory windows) external onlyOwner {
        for (uint256 i; i < windows.length; i++) {
            
            if(windows[i].startWindow >= windows[i].endWindow) {
                revert addStagesFailed();
            }

            Window storage p = stages[stageCounter];
            p.startWindow = windows[i].startWindow;
            p.endWindow = windows[i].endWindow;
            
            ++stageCounter;
        }
    }

    function editStage(uint256 _id, uint128 _startWindow, uint128 _endWindow) external onlyOwner {
        stages[_id].startWindow = _startWindow;
        stages[_id].endWindow = _endWindow;       
    }

    function addTieredPrizes(address _tokenAddress, bool _tokenType, bool _mint, uint256 _amount) external onlyOwner {
        Prize storage p = prizes[prizeCounter];
        p.tokenType = _tokenType;
        p.tokenAddress = _tokenAddress;
        p.mint = _mint;

        fillRemainingTokens(uint8(prizeCounter), _amount);

        ++prizeCounter;
    }

    function editTieredPrize(uint256 _id, address _tokenAddress, bool _tokenType, bool _mint) external onlyOwner {
        prizes[_id].tokenType = _tokenType;
        prizes[_id].tokenAddress = _tokenAddress;
        prizes[_id].mint = _mint;        
    }

    function burn(uint256 tokenId) external {        
        if(!isApprovedForAll[ownerOf(tokenId)][msg.sender] && getApproved[tokenId] != msg.sender && ownerOf(tokenId) != msg.sender ) {
            revert callerNotOwnerNorApproved();
        }

        _burn(tokenId);
    }

    function ownerMint (
        address[] calldata _to, 
        uint256[] calldata _amount
    ) external onlyOwner {

        if(_to.length != _amount.length) {
            revert notSameLength();
        }

        for(uint256 i; i < _to.length; i++) {
            
            if(tokenCounter + _amount[i] > MAX_SUPPLY) {
                revert maxSupplyExceeded();
            }

            _mintMany(_to[i], _amount[i]);
        }
    }  

    function setKeyHash(bytes32 _keyHash) external onlyOwner {
        keyHash = _keyHash;
    }

    function setCallbackGasLimit(uint32 _callbackGasLimit) external onlyOwner {
        callbackGasLimit = _callbackGasLimit;
    }

    function setRequestConfirmations(uint16 _requestConfirmations) external onlyOwner {
        requestConfirmations = _requestConfirmations;
    }

    function setSubscriptionId(uint64 _subscriptionId) external onlyOwner {
        subscriptionId = _subscriptionId;
    }    

    function withdraw(address payable _to, uint256 _amount) external onlyOwner {
        (bool sent, bytes memory data) = _to.call{value: _amount}("");

        if(!sent)  {
            revert withdrawFailed();
        }
    } 

    function mint(        
        bytes calldata _signature,
        uint256 _stage,
        uint256 _maxAtCurrentStage,
        uint32 _amount
    ) external payable {

        if(_amount + amountSold > maxSale) {
            revert soldOut();
        }

        if(_amount * PRICE != msg.value) {
            revert insufficientPayment();
        }
        
        if(block.timestamp < stages[_stage].startWindow || block.timestamp > stages[_stage].endWindow) {
            revert windowClosed();
        }

        bytes32 hash = keccak256(abi.encodePacked(msg.sender, _stage, _maxAtCurrentStage));
        if (hash.toEthSignedMessageHash().recover(_signature) != signer) {
            revert signatureInvalid();
        }

        if(_amount + amountMinted[msg.sender] > _maxAtCurrentStage){
            revert amountInvalid();
        }

        amountMinted[msg.sender] += _amount;
        amountSold += _amount;

        sendVRFRequests(_amount);
    }                       

    function publicMint(        
        uint32 _amount
    ) external payable {

        if(_amount + amountSold > maxSale) {
            revert soldOut();
        }
        if(_amount * PRICE != msg.value) {
            revert insufficientPayment();
        }
        if(block.timestamp < publicWindow.startWindow || block.timestamp > publicWindow.endWindow) {
            revert windowClosed();
        }
        if(_amount > 20){
            revert amountInvalid();
        }

        amountSold += _amount;

        sendVRFRequests(_amount);
    }

    function sendPrize(
        uint256 prizeId,
        address receiver
    ) external onlyOwner {
        Prize memory prize = prizes[prizeId];

        address tokenAddress = prize.tokenAddress;

        if (tokenAddress == address(this)) {
            _internalMint(receiver);
        } else {
            if(prize.mint) {
                IComicThreeSE(tokenAddress).mint(receiver);
            } else if (prize.tokenType) {
                IERC721Enumerable token = IERC721Enumerable(tokenAddress);
                token.transferFrom(tokenHolder, receiver, token.tokenOfOwnerByIndex(tokenHolder,0));
            } else {
                IERC1155(prize.tokenAddress).safeTransferFrom(tokenHolder, receiver, 0, 1, "");
            }
        }
    }

    function sendVRFRequests (
        uint32 _tokenAmount
    ) internal {

        while (_tokenAmount > 0) {

            uint32 _amountTemp = _tokenAmount > 10 ? 10 : _tokenAmount;
            _tokenAmount -= _amountTemp;

            uint256 s_requestId = COORDINATOR.requestRandomWords(
              keyHash,
              subscriptionId,
              requestConfirmations,
              callbackGasLimit,
              _amountTemp
            );

            requestToAddress[s_requestId] = msg.sender;
        }

    }

    function fulfillRandomWords(
        uint256 requestId,
        uint256[] memory randomWords
    ) internal override {

        for(uint256 i; i < randomWords.length;) {
            
            uint256 amountRemaining = remainingTokens.length;
            uint256 pickedIndex = randomWords[i] % amountRemaining;

            Prize memory prize = prizes[remainingTokens[pickedIndex]];

            remainingTokens[pickedIndex] = remainingTokens[amountRemaining - 1];
            remainingTokens.pop();

            address receiver = requestToAddress[requestId];
            address tokenAddress = prize.tokenAddress;

            if (tokenAddress == address(this)) {
                _internalMint(receiver);
            } else {
                if(prize.mint) {
                    IComicThreeSE(tokenAddress).mint(receiver);
                } else if (prize.tokenType) {
                    IERC721Enumerable token = IERC721Enumerable(tokenAddress);
                    token.transferFrom(tokenHolder, receiver, token.tokenOfOwnerByIndex(tokenHolder,0));
                } else {
                    IERC1155(prize.tokenAddress).safeTransferFrom(tokenHolder, receiver, 0, 1, "");
                }
            }

            unchecked {
                ++i;
            }
        }
    } 
}

interface IComicThreeSE {
    function mint(address to) external;
}