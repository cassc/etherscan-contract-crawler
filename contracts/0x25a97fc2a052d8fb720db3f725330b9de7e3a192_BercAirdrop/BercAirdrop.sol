/**
 *Submitted for verification at Etherscan.io on 2023-06-22
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(_msgSender());
    }

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface Berc20Store {
    struct TokenInfo {
        address tokenAddress;
        string logo;
        string name;
        string symbol;
        uint256 totalSupply;
        uint256 maxMintCount;
        uint256 maxMintPerAddress;
        uint256 mintPrice;
        address creator;
        uint256 progress;
        uint256[4] limits;  // 0 - erc20，1 - erc721，2 - erc1155，3 - white list
    }

    struct TokenMsg {
        string description;
        string logoUrl;
        string bannerUrl;
        string website;
        string twitter;
        string telegram;
        string discord;
        string detailUrl;
    }

    function getTokenBase(address tokenAddress) external view returns (TokenInfo memory tokenInfo, TokenMsg memory tokenMsg);
}

contract BercAirdrop is Ownable {

    address private authorizedAddress;

    struct AirdropData {
        uint256 index;
        string logo;
        string name;
        string symbol;
        uint256 totalSupply;
        address tokenContract;
        uint256 airDropNums;
        uint256 startTime;
        uint256 endTime;
        uint256 minDeposit;
        uint256 totalDeposits; 
    }

    address public bercContract;
    address public berc20StoreContract;
    uint256 public currentPage = 1;
    uint256 public pageSize = 10;
    AirdropData[] public airdropList;

    mapping(address => mapping(uint256 => uint256)) public deposits;

    event AirdropCreated(address indexed tokenContract, uint256 airDropNums, uint256 startTime, uint256 endTime, uint256 minDeposit);
    event Deposit(address indexed depositor, uint256 indexed airdropIndex, uint256 amount);
    event Claim(address indexed claimer, uint256 amount);

    modifier onlyAuthorized() {
        require(msg.sender == authorizedAddress, "Not authorized");
        _;
    }

    function createAirdrop(address _tokenContract, uint256 _airDropNums, uint256 _startTime, uint256 _endTime, uint256 _minDeposit) external onlyAuthorized {
        require(_airDropNums > 0, "Invalid airdrop");
        require(_endTime > _startTime, "Invalid time range");
        require(_minDeposit > 0, "Invalid minimum deposit");
        Berc20Store berc20Store = Berc20Store(berc20StoreContract);
        (Berc20Store.TokenInfo memory tokenInfo, Berc20Store.TokenMsg memory tokenMsg) = berc20Store.getTokenBase(_tokenContract);

        AirdropData memory airdrop = AirdropData({
            index: airdropList.length,
            logo: tokenMsg.logoUrl,
            name: tokenInfo.name,
            symbol: tokenInfo.symbol,
            totalSupply: tokenInfo.totalSupply,
            tokenContract: _tokenContract,
            airDropNums: _airDropNums,
            startTime: _startTime,
            endTime: _endTime,
            minDeposit: _minDeposit,
            totalDeposits: 0
        });

        airdropList.push(airdrop);

        emit AirdropCreated(_tokenContract, _airDropNums, _startTime, _endTime, _minDeposit);
    }

    function deposit(uint256 _airdropIndex, uint256 _amount) external {
        require(_airdropIndex < airdropList.length, "Invalid airdrop index");

        AirdropData storage airdrop = airdropList[_airdropIndex];
        require(block.timestamp >= airdrop.startTime, "Deposit not yet started");
        require(block.timestamp <= airdrop.endTime, "Deposit has ended");
        require(_amount >= airdrop.minDeposit, "Amount below minimum deposit");

        address depositor = msg.sender;
        deposits[depositor][_airdropIndex] += _amount;

        airdrop.totalDeposits += _amount;

        IERC20 token = IERC20(bercContract);
        require(token.transferFrom(depositor, address(this), _amount), "Transfer failed");

        emit Deposit(depositor, _airdropIndex, _amount);
    }

    function claim(uint256 _airdropIndex) external {
        require(_airdropIndex < airdropList.length, "Invalid airdrop index");

        AirdropData storage airdrop = airdropList[_airdropIndex];
        require(block.timestamp > airdrop.endTime, "Claim not yet available");

        address claimer = msg.sender;
        uint256 depositAmount = deposits[claimer][_airdropIndex];
        require(depositAmount > 0, "No deposit to claim");
        uint256 airDropNums = airdrop.airDropNums;
        uint256 totalDeposits = airdrop.totalDeposits;
        uint256 claimAmount = (airDropNums * depositAmount) / totalDeposits;

        IERC20 token1 = IERC20(airdrop.tokenContract);
        token1.transfer(claimer, claimAmount);

        IERC20 token2 = IERC20(bercContract);
        token2.transfer(claimer, depositAmount);
        
        deposits[claimer][_airdropIndex] = 0;

        emit Claim(claimer, claimAmount);
    }

    function getAirdropsPage(uint256 _pageNumber, uint256 _pageSize) public view returns (AirdropData[] memory,uint256) {
        require(_pageNumber > 0, "Invalid page number");
        require(_pageSize > 0, "Invalid page size");

        uint256 startIndex = (_pageNumber - 1) * _pageSize;
        uint256 endIndex = startIndex + _pageSize;
        if (endIndex > airdropList.length) {
            endIndex = airdropList.length;
        }

        AirdropData[] memory result = new AirdropData[](endIndex - startIndex);
        for (uint256 i = startIndex; i < endIndex; i++) {
            result[i - startIndex] = airdropList[i];
        }
        return (result,airdropList.length);
    }

    function setAuthorizedAddress(address _address) external onlyOwner {
        authorizedAddress = _address;
    }

    function setBercTokenContract(address _address) external onlyOwner {
        bercContract = _address;
    }

    function setBerc20StoreContract(address _address) external onlyOwner {
        berc20StoreContract = _address;
    }

}