/**
 *Submitted for verification at Etherscan.io on 2023-06-30
*/

// SPDX-License-Identifier: MIT

//'########::'########:'########:::'######:::'#######::::'#####:::
//##.... ##: ##.....:: ##.... ##:'##... ##:'##.... ##::'##.. ##::
//##:::: ##: ##::::::: ##:::: ##: ##:::..::..::::: ##:'##:::: ##:
//########:: ######::: ########:: ##::::::::'#######:: ##:::: ##:
//##.... ##: ##...:::: ##.. ##::: ##:::::::'##:::::::: ##:::: ##:
//##:::: ##: ##::::::: ##::. ##:: ##::: ##: ##::::::::. ##:: ##::
//########:: ########: ##:::. ##:. ######:: #########::. #####:::
//........:::........::..:::::..:::......:::.........::::.....::::
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
        address depositContract;
        address airDropContract;
        string logo;
        string name;
        string symbol;
        uint256 totalSupply;
        uint256 airDropNums;
        uint256 depositeCycle;
        uint256 claimCycle; 
        uint256 depositStartTime;
        uint256 minDeposit;
        uint256 totalDeposits; 
    }

    address public bercContract;
    address public berc20StoreContract;

    uint256 public currentPage = 1;
    uint256 public pageSize = 10;
    
    AirdropData[] public airdropList;


    struct DepositAddress{
        address depoiter;
        uint256 amount;
        uint256 weight;
        uint256 cycleCounts;
    }

    // 映射用于存储用户的质押记录
    mapping(address =>mapping(uint256=>DepositAddress)) public userDeposits;
    mapping(uint256=>uint256) public totalWeights;
    mapping(uint256=>uint256) public totalCycles;
    mapping(uint256=>uint256) public claimedTotalWeights;

    event AirdropCreated(address indexed tokenContract, uint256 airDropNums, uint256 startTime, uint256 endTime, uint256 minDeposit);
    event Deposit(address indexed depositor, uint256 indexed airdropIndex, uint256 amount);
    event Claim(address indexed claimer, uint256 amount);

    modifier onlyAuthorized() {
        require(msg.sender == authorizedAddress, "Not authorized");
        _;
    }

    function createAirdrop(address depositContract,address airDropContract, uint256 _airDropNums, uint256 depositeCycle, uint256 claimCycle, uint256 _minDeposit) external onlyAuthorized {
        require(_airDropNums > 0, "Invalid airdrop");
        require(depositeCycle > 0, "Invalid time range");
        require(claimCycle > 0, "Invalid time range");
        require(_minDeposit > 0, "Invalid minimum deposit");
        Berc20Store berc20Store = Berc20Store(berc20StoreContract);
        (Berc20Store.TokenInfo memory tokenInfo, Berc20Store.TokenMsg memory tokenMsg) = berc20Store.getTokenBase(airDropContract);
        require(tokenInfo.tokenAddress!= address(0),"illegal address!");
        uint256 _startTime = block.timestamp;
        uint256 _endTime = block.timestamp + depositeCycle;
        uint256 _claimEndTime = _endTime + claimCycle;
        AirdropData memory airdrop = AirdropData({
            index: airdropList.length,
            depositContract:depositContract,
            airDropContract:airDropContract,
            logo: tokenMsg.logoUrl,
            name: tokenInfo.name,
            symbol: tokenInfo.symbol,
            totalSupply: tokenInfo.totalSupply,
            airDropNums: _airDropNums,
            depositeCycle: depositeCycle,
            claimCycle: claimCycle,
            depositStartTime: _startTime,
            minDeposit: _minDeposit,
            totalDeposits: 0
        });
        totalCycles[airdropList.length] = 1;
        airdropList.push(airdrop);

        emit AirdropCreated(airDropContract, _airDropNums, _startTime, _endTime, _minDeposit);
    }

    function deposit(uint256 _airdropIndex, uint256 _amount) external {
        require(_airdropIndex < airdropList.length, "Invalid airdrop index");

        AirdropData storage airdrop = airdropList[_airdropIndex];
        require(block.timestamp >= airdrop.depositStartTime, "Deposit not yet started");
        require(block.timestamp <= airdrop.depositStartTime+airdrop.depositeCycle, "Deposit has ended");
        require(_amount >= airdrop.minDeposit, "Amount below minimum deposit");

        address depositor = msg.sender;
        airdrop.totalDeposits += _amount;

        IERC20 token = IERC20(airdrop.depositContract);
        require(token.transferFrom(depositor, address(this), _amount), "Transfer failed");

        uint256 weight = calculateWeight(_amount,block.timestamp,airdrop.depositStartTime,airdrop.depositStartTime+airdrop.depositeCycle);

        if (userDeposits[depositor][_airdropIndex].depoiter == address(0)) {
            userDeposits[depositor][_airdropIndex] = DepositAddress({
                depoiter: depositor,
                amount: _amount,
                weight: weight,
                cycleCounts:0
            });
        } else {
            userDeposits[depositor][_airdropIndex].amount += _amount;
            userDeposits[depositor][_airdropIndex].weight += weight;
        }

        totalWeights[airdrop.index] += weight;
        emit Deposit(depositor, _airdropIndex, _amount);
    }

    //claimType 0:领取质押币和空投币 1:只领空投币，质押币继续质押
    function claim(uint256 _airdropIndex,uint256 claimType) external {
        require(_airdropIndex < airdropList.length, "Invalid airdrop index");
        AirdropData storage airdrop = airdropList[_airdropIndex];

        if(block.timestamp>airdrop.depositStartTime+airdrop.depositeCycle+airdrop.claimCycle){
            airdrop.depositStartTime = block.timestamp;
            totalWeights[_airdropIndex] -= claimedTotalWeights[_airdropIndex];
            totalWeights[_airdropIndex] += totalWeights[_airdropIndex];
            claimedTotalWeights[_airdropIndex]=0;
            totalCycles[_airdropIndex] += 1;
        }else {
            require(block.timestamp > airdrop.depositStartTime+airdrop.depositeCycle,"Claim not yet available");
            require(block.timestamp < airdrop.depositStartTime+airdrop.depositeCycle+airdrop.claimCycle, "Claim not yet available");
            address claimer = msg.sender;
            uint256 depositAmount = userDeposits[claimer][_airdropIndex].amount;
            require(depositAmount > 0, "No deposit to claim");
            IERC20 token1 = IERC20(airdrop.airDropContract);
            uint256 airDropNums = token1.balanceOf(address(this));

            uint256 totalWeight = totalWeights[_airdropIndex];
            uint256 userWeight = userDeposits[claimer][_airdropIndex].weight;

            uint256 claimAmount = (airDropNums * userWeight)*(totalCycles[_airdropIndex]-userDeposits[claimer][_airdropIndex].cycleCounts) / totalWeight;

            token1.transfer(claimer, claimAmount);

            if (claimType==1){
                IERC20 token2 = IERC20(airdrop.depositContract);
                token2.transfer(claimer, depositAmount);
                userDeposits[claimer][_airdropIndex].amount = 0;
                claimedTotalWeights[airdrop.index] += userDeposits[claimer][_airdropIndex].weight;
                userDeposits[claimer][_airdropIndex].weight = 0;
                airdrop.totalDeposits -= depositAmount;
            }else {
                userDeposits[claimer][_airdropIndex].weight += calculateWeight(
                    userDeposits[claimer][_airdropIndex].amount,
                    block.timestamp,
                    block.timestamp,
                    block.timestamp + airdrop.depositeCycle
                    );
            }
            userDeposits[claimer][_airdropIndex].cycleCounts += 1;
            emit Claim(claimer, claimAmount);
        }
    }

    function calculateWeight(
        uint256 depositCount, 
        uint256 depositTime, 
        uint256 startTime, 
        uint256 endTime) internal pure returns (uint256) {
        uint256 weight = (endTime - depositTime) * 1000 * depositCount / (endTime-startTime);
        return weight;
    }

    function getAirdropsPage(uint256 _pageNumber, uint256 _pageSize) external view  returns (AirdropData[] memory,uint256) {
        require(_pageNumber > 0, "Invalid page number");
        require(_pageSize > 0, "Invalid page size");

        uint256 startIndex = (_pageNumber - 1) * _pageSize;
        uint256 endIndex = startIndex + _pageSize;
        if (endIndex > airdropList.length) {
            endIndex = airdropList.length;
        }
        AirdropData[] memory result = new AirdropData[](endIndex - startIndex);
        for (uint256 i = startIndex; i < endIndex; i++) {
            Berc20Store berc20Store = Berc20Store(berc20StoreContract);
            (Berc20Store.TokenInfo memory tokenInfo, Berc20Store.TokenMsg memory tokenMsg) = berc20Store.getTokenBase(airdropList[i].airDropContract);
            IERC20 token2 = IERC20(airdropList[i].airDropContract);
            AirdropData memory airdrop = AirdropData({
                index:  airdropList[i].index,
                depositContract:airdropList[i].depositContract,
                airDropContract:airdropList[i].airDropContract,
                logo: tokenMsg.logoUrl,
                name: airdropList[i].name,
                symbol: airdropList[i].symbol,
                totalSupply: airdropList[i].totalSupply,
                airDropNums: token2.balanceOf(address(this)),
                depositeCycle:airdropList[i].depositeCycle,
                claimCycle:airdropList[i].claimCycle,
                depositStartTime: airdropList[i].depositStartTime,
                minDeposit: airdropList[i].minDeposit,
                totalDeposits: airdropList[i].totalDeposits
            });
            result[i - startIndex] = airdrop;
        }
        return  (result,airdropList.length);
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