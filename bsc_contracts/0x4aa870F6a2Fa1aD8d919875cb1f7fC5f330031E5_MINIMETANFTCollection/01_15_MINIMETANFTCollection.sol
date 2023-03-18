// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721SerialMint.sol";
import "./Signature.sol";
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';

contract MINIMETANFTCollection is ERC721SerialMint, Signature, ReentrancyGuard{
    using SafeERC20 for IERC20;
    
    event mintNFTsByToken(address indexed buyer, uint256 askPrice, address indexed token, uint256 times, uint256 totalAmount);

    struct BusinessPlan {
        address sellToken;
        uint256 pricePerSolt;
    }

    uint256 public totalCount;
    uint256 public startTimestamp;  // for public sale
    bool public paused = false;   // act as a mint pauser
    BusinessPlan[] public plans;

    uint256 public discount; // 80 for 80%
    uint256 public preSaleStartTimestamp; // for whitelist
    uint256 public preSaleLimit; // 0 for no limit
    uint256 public preSaleCount;
    bool public isFreeMint;


    constructor(
        string memory name_,
        string memory symbol_,
        string memory baseURI_,
        uint256 totalCount_,
        uint256 startTimestamp_,
        uint256 maxBatchMint_
    ) ERC721SerialMint(name_, symbol_, maxBatchMint_) {
        baseURI = baseURI_;
        totalCount = totalCount_;
        startTimestamp = startTimestamp_;
        maxBatchMint = maxBatchMint_;
    }

    function puase(bool _isPaused) public onlyOwner {
        paused = _isPaused;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);
        require(!paused, "ERC721Pausable: token transfer while paused");
    }

    function getPlans() public view returns (BusinessPlan[] memory) {
        return plans;
    }

    //init & edit pre-sale conditions
    function makePreSalePlan(uint256 _preSaleStartTimestamp, uint256 _discount, uint256 _preSaleLimit) public onlyOwner {
        require(block.timestamp < _preSaleStartTimestamp, "pre-sale already started");
        require(_preSaleStartTimestamp < startTimestamp, "time setting error 1");
        preSaleStartTimestamp = _preSaleStartTimestamp;
        require( 0 < _discount && _discount < 100, "discount error");
        discount = _discount;
        if(_preSaleLimit > 0){
            require(_preSaleLimit <= totalCount, "number error 1");
            preSaleLimit = _preSaleLimit;
        }
    }

    function changeStartTimestamp(uint256 _startTimestamp) public onlyOwner {
        require(block.timestamp < _startTimestamp, "public-sale already started");
        require(preSaleStartTimestamp < _startTimestamp, "time setting error 2");
        startTimestamp = _startTimestamp;
    }

    function addPlan(address _sellToken, uint256 _pricePerSlot) external onlyOwner {
        plans.push(BusinessPlan(_sellToken, _pricePerSlot));
    }

    function editPlan(uint256 _index, address _sellToken, uint256 _pricePerSlot) external onlyOwner {
        plans[_index].sellToken = _sellToken;
        plans[_index].pricePerSolt = _pricePerSlot;
    }

    function editPlans(uint256[] memory _indexes, BusinessPlan[] memory _plans) external onlyOwner {
        require(_indexes.length == _plans.length, "length dismatch");
        for(uint256 i=0; i < _indexes.length; i++){
            plans[_indexes[i]] = _plans[i];
        }
    }

    function setFreeMint(bool _isFreeMint) public onlyOwner {
        isFreeMint = _isFreeMint;
    }

    function setTotalCount(uint256 totalCount_) external onlyOwner() {
        require(totalCount_ > totalSupply, "can't decrease supply");
        totalCount = totalCount_;
    }

    function batchMintTo(address _to, uint256 _times) public onlyOwner {
        require(totalSupply + _times <= totalCount, "over mint");
        _batchMintR(_to, _times);
    }

    function mintNFTByToken(uint256 _planIndex, uint256, uint256 _times) payable public nonReentrant {
        require(block.timestamp > startTimestamp, "public-sale not start");
        _mintNFTByToken(_planIndex, _times, false);
    }

    function _mintNFTByToken(uint256 _planIndex, uint256 _times, bool _applyDiscount) internal{
        require(_times >0 && _times <= maxBatchMint, "wrong batch number");
        require(totalSupply + _times <= totalCount, "over mint");
        if(!isFreeMint) {
            address tokenUsed = plans[_planIndex].sellToken;
            uint256 price = plans[_planIndex].pricePerSolt;
            require(price > 0, "wrong price");
            uint256 totalPrice = price * _times;
            if(_applyDiscount){
                totalPrice = totalPrice * discount / 100;
            }
            if(tokenUsed != address(0)){
                IERC20(tokenUsed).safeTransferFrom(address(msg.sender), owner(), totalPrice);
            } else {
                require(uint256(msg.value) == totalPrice, "value error");
                payable(owner()).transfer(totalPrice);
            }
            emit mintNFTsByToken(msg.sender, price, tokenUsed, _times, totalPrice);
        }else {
            emit mintNFTsByToken(msg.sender, 0, address(0), _times, 0);
        }
        _batchMintR(msg.sender, _times);
    }

    modifier whitelistVerify(bytes memory _signature) {
        bytes32 message = prefixed(keccak256(abi.encodePacked(
            msg.sender, 
            address(this)
        )));
        require(verifySignature(message, _signature, owner()), "verification failed");
        _;
    }

    function mintByWhitelist(uint256 _planIndex, uint256 _times, bytes memory _signature) payable public whitelistVerify(_signature) nonReentrant{
        require(block.timestamp > preSaleStartTimestamp && block.timestamp < startTimestamp, "not in pre-sale window");
        if(preSaleLimit > 0){
            require(preSaleCount + _times <= preSaleLimit, "pre-sale over mint");
        }
        _mintNFTByToken(_planIndex, _times, true);
        preSaleCount += _times;
    }

    function burn(uint256 _tokenId) public {
        require(msg.sender == ownerOf(_tokenId), "not owner");
        _burn(_tokenId);
    }

    function batchBurn(uint256[] memory _tokenIds) public {
        for(uint256 i=0; i < _tokenIds.length; i++) {
            burn(_tokenIds[i]);
        }
    }
}