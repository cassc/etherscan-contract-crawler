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
pragma solidity ^0.8.0;

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

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
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

interface IUniswapV2Pair {
    function sync() external;
}

interface IWETH {
    function deposit() external payable;
    function withdraw(uint256 amount) external;
    function transfer(address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

interface BlackErc20 {
    function getMintedCounts() external view returns (uint256);
    function getAllContractTypes() external view returns (uint256[] memory);
}

contract VotingContract  is Ownable {

    struct Candidate {
        address candidateAddress;
        uint256 votes;
        uint256 counts;
        uint256 top10EndTime;
    }

    enum VoteStatus {
        PayVote,
        BercVote
    }

    struct VoteData{
        address tokenAddress;
        string description;
        string logoUrl;
        string bannerUrl;
        string website;
        string twitter;
        string telegram;
        string discord;
        string detailUrl;       
        string name;
        string symbol;
        uint256 totalSupply;
        uint256 maxMintCount;
        uint256 maxMintPerAddress;
        uint256 mintPrice;    
        address creator;
        uint256 progress;
        uint256[4] limits;    
        uint256 votes;
        uint256 counts;
        uint256 top10EndTime;
    }


    address public devAddress;

    Candidate[] public payCandidates;
    Candidate[] public bercCandidates;

    mapping(address => uint256) public addressIndexs;
    uint256 public indexs=0;

    mapping(address=>uint256[]) public payVotesByAddress; 
    uint256[] public payTotalVotesByAddress; 

    mapping(address=>uint256[])  public bercVotesByAddress;
    uint256[] public bercTotalVotesByAddress;

    bool public votingActive;

    uint256 public currentPayStart;
    uint256 public currentBercStart;
    uint256 public votingPeriod;

    address public bercAddress;
    address public fundAddress = 0xc6Cec2dA269Bf0eE69c539407b227AF2cb13931e;
    address public bercLpAddress;
    address public bercStoreAddress;

    mapping(address => uint256) public oldTokenMintedNums;

    constructor() {
        votingActive = true;
        currentPayStart = block.timestamp;
        currentBercStart = block.timestamp;
        votingPeriod = 40000;
    }

   function payBercVote(address candidateAddress,uint256 _amount) public {
        require(votingActive, "Voting is not active.");
        require(candidateAddress != address(0), "Invalid candidate address.");
        Berc20Store berc20Store = Berc20Store(bercStoreAddress);
        (Berc20Store.TokenInfo memory tokenInfo, Berc20Store.TokenMsg memory tokenMsg) = berc20Store.getTokenBase(candidateAddress);
        require(tokenInfo.tokenAddress!= address(0),"illegal address!");
        require(_amount >0, "amount error");

        if (block.timestamp >= currentPayStart + votingPeriod) {
            currentPayStart = block.timestamp;
            resetVotes(candidateAddress,VoteStatus.PayVote);
        }

        IERC20 token = IERC20(bercAddress);
        require(token.transferFrom(msg.sender, fundAddress, _amount), "Transfer failed");

        bool candidateExists = false;
        for (uint256 i = 0; i < payCandidates.length; i++) {
            if (payCandidates[i].candidateAddress == candidateAddress) {
                payCandidates[i].votes += _amount;
                payCandidates[i].counts += 1;
                candidateExists = true;
                break;
            }
        }

        if (!candidateExists) {
            payCandidates.push(Candidate(candidateAddress, _amount,1,currentPayStart + votingPeriod));
        }

        if (payVotesByAddress[candidateAddress].length == 0) {
            payVotesByAddress[candidateAddress] = new uint256[](200);
            payTotalVotesByAddress = new uint256[](200);
        }
        if (addressIndexs[msg.sender]==0){
            addressIndexs[msg.sender] = indexs;
            indexs += 1;
        }
        payVotesByAddress[candidateAddress][addressIndexs[msg.sender]]+=_amount;
        payTotalVotesByAddress[addressIndexs[msg.sender]] += _amount;

        sortCandidates(VoteStatus.PayVote);
    }

    function bercVote(address candidateAddress, uint256 voteAmount) public {
        require(votingActive, "not active!");
        require(candidateAddress != address(0), "illegal address!");
        Berc20Store berc20Store = Berc20Store(bercStoreAddress);
        (Berc20Store.TokenInfo memory tokenInfo, Berc20Store.TokenMsg memory tokenMsg) = berc20Store.getTokenBase(candidateAddress);
        require(tokenInfo.tokenAddress!= address(0),"illegal address!");

        IERC20 token = IERC20(bercAddress);
        uint256 voterBalance = token.balanceOf(msg.sender);
        require(voteAmount > 0, "not illegal amount");
        require(voteAmount <= voterBalance, "Insufficient margin");
        if(bercVotesByAddress[candidateAddress].length>0){
            uint256 remainingVotes = voterBalance - bercVotesByAddress[candidateAddress][addressIndexs[msg.sender]];
            require(voteAmount <= remainingVotes, "over remain vote amounts");
        }
        if (block.timestamp >= currentBercStart + votingPeriod) {
            currentBercStart = block.timestamp;
            resetVotes(candidateAddress,VoteStatus.BercVote);
        }

        bool candidateExists = false;
        for (uint256 i = 0; i < bercCandidates.length; i++) {
            if (bercCandidates[i].candidateAddress == candidateAddress) {
                bercCandidates[i].votes += voteAmount;
                bercCandidates[i].counts += 1;
                candidateExists = true;
                break;
            }
        }

        if (!candidateExists) {
            bercCandidates.push(Candidate(candidateAddress, voteAmount,1,currentPayStart + votingPeriod));
        }

                
        if (bercVotesByAddress[candidateAddress].length == 0) {
            bercVotesByAddress[candidateAddress] = new uint256[](200);
            bercTotalVotesByAddress = new uint256[](200);
        }
        if (addressIndexs[msg.sender]==0){
            addressIndexs[msg.sender] = indexs;
            indexs += 1;
        }

        bercVotesByAddress[candidateAddress][addressIndexs[msg.sender]]+=voteAmount;
        bercTotalVotesByAddress[addressIndexs[msg.sender]] += voteAmount;

        sortCandidates(VoteStatus.BercVote);
    }

    function sortCandidates(VoteStatus voteStatus) internal {
        if (voteStatus == VoteStatus.PayVote) {
            uint256 count = payCandidates.length;
            for (uint256 i = 0; i < count - 1; i++) {
                uint256 maxVotesIndex = i;
                for (uint256 j = i + 1; j < count; j++) {
                    if (payCandidates[j].votes > payCandidates[maxVotesIndex].votes) {
                        maxVotesIndex = j;
                    }
                }
                if (maxVotesIndex != i) {
                    Candidate memory temp = payCandidates[i];
                    payCandidates[i] = payCandidates[maxVotesIndex];
                    payCandidates[maxVotesIndex] = temp;
                }
            }
        } else if (voteStatus == VoteStatus.BercVote) {
            uint256 count = bercCandidates.length;
            for (uint256 i = 0; i < count - 1; i++) {
                uint256 maxVotesIndex = i;
                for (uint256 j = i + 1; j < count; j++) {
                    if (bercCandidates[j].votes > bercCandidates[maxVotesIndex].votes) {
                        maxVotesIndex = j;
                    }
                }
                if (maxVotesIndex != i) {
                    Candidate memory temp = bercCandidates[i];
                    bercCandidates[i] = bercCandidates[maxVotesIndex];
                    bercCandidates[maxVotesIndex] = temp;
                }
            }
        }
    }


    function resetVotes(address candidateAddress,VoteStatus voteStatus) internal {
        if (voteStatus == VoteStatus.PayVote) {
            for (uint256 i = 0; i < payCandidates.length; i++) {
                payCandidates[i].votes = 0;
                payCandidates[i].counts = 0;
                payCandidates[i].top10EndTime = block.timestamp + votingPeriod;
            }
            delete payVotesByAddress[candidateAddress];
            delete payTotalVotesByAddress;
        } else if (voteStatus == VoteStatus.BercVote) {
            for (uint256 i = 0; i < bercCandidates.length; i++) {
                bercCandidates[i].votes = 0;
                bercCandidates[i].counts = 0;
                bercCandidates[i].top10EndTime = block.timestamp + votingPeriod;
            }
            delete bercVotesByAddress[candidateAddress];
            delete bercTotalVotesByAddress;
        }
    }

    function calculateTotalVotes(VoteStatus voteStatus,address contractAddress) public view returns (uint256) {
        uint256 totalVotes = 0;
        Candidate[] memory candidates;
        if (voteStatus == VoteStatus.PayVote) {
            candidates = payCandidates;
        } else if (voteStatus == VoteStatus.BercVote) {
            candidates = bercCandidates;   
        }    
        for (uint256 i = 0; i < candidates.length; i++) {
            if (candidates[i].candidateAddress == contractAddress) {
                totalVotes = candidates[i].votes;
                break;
            }
        }
        return totalVotes;
    }

    function getLastVotes(VoteStatus voteStatus) public view returns (uint256) {
        uint256 tenVotes = 0;
        Candidate[] memory candidates;
        if (voteStatus == VoteStatus.PayVote) {
            candidates = payCandidates;
        } else if (voteStatus == VoteStatus.BercVote) {
            candidates = bercCandidates;   
        }   
        if (candidates.length >= 10) {
            tenVotes = candidates[9].votes;
        }else if (candidates.length>0&&candidates.length<10) {
            tenVotes = candidates[candidates.length-1].votes;
        }
        return tenVotes;
    }

    function getTopCandidates(VoteStatus voteStatus) public view returns (VoteData[] memory) {
        Candidate[] memory candidates;
        if (voteStatus == VoteStatus.PayVote) {
            candidates = payCandidates;
        } else if (voteStatus == VoteStatus.BercVote) {
            candidates = bercCandidates;   
        }    
        uint256 count = candidates.length;
        uint256 topCount = count < 10 ? count : 10;

        VoteData[] memory topCandidates = new VoteData[](topCount);
        for (uint256 i = 0; i < topCount; i++) {
            Berc20Store berc20Store = Berc20Store(bercStoreAddress);
            (Berc20Store.TokenInfo memory tokenInfo, Berc20Store.TokenMsg memory tokenMsg) = berc20Store.getTokenBase(candidates[i].candidateAddress);
            uint256 progress = calculateTokenProgress(tokenInfo.tokenAddress,tokenInfo.maxMintCount);
            topCandidates[i].tokenAddress = tokenInfo.tokenAddress;
            topCandidates[i].description = tokenMsg.description;
            topCandidates[i].logoUrl = tokenMsg.logoUrl;
            topCandidates[i].bannerUrl = tokenMsg.bannerUrl;
            topCandidates[i].website = tokenMsg.website;
            topCandidates[i].twitter = tokenMsg.twitter;
            topCandidates[i].telegram = tokenMsg.telegram;
            topCandidates[i].discord = tokenMsg.discord;
            topCandidates[i].detailUrl = tokenMsg.detailUrl;
            topCandidates[i].name = tokenInfo.name;
            topCandidates[i].symbol = tokenInfo.symbol;
            topCandidates[i].totalSupply = tokenInfo.totalSupply;
            topCandidates[i].maxMintCount = tokenInfo.maxMintCount;
            topCandidates[i].maxMintPerAddress = tokenInfo.maxMintPerAddress;
            topCandidates[i].mintPrice = tokenInfo.mintPrice;
            topCandidates[i].creator = tokenInfo.creator;
            topCandidates[i].progress = progress;
            topCandidates[i].limits = tokenInfo.limits; 
            topCandidates[i].votes = candidates[i].votes;  
            topCandidates[i].counts = candidates[i].counts;  
            topCandidates[i].top10EndTime = candidates[i].top10EndTime;  
        }
        return topCandidates;
    }

    function getVoteData(address contractAddress,address user) public view returns (uint256[7] memory) {
        uint256 payVotes = payVotesByAddress[contractAddress][addressIndexs[user]];
        uint256 bercVotes = bercVotesByAddress[contractAddress][addressIndexs[user]];

        uint256 totalPayVotes = calculateTotalVotes(VoteStatus.PayVote,contractAddress);
        uint256 totalBercVotes = calculateTotalVotes(VoteStatus.BercVote,contractAddress);

        uint256 tenPayVotes = getLastVotes(VoteStatus.PayVote);
        uint256 tenBercVotes = getLastVotes(VoteStatus.BercVote);

        IERC20 berc = IERC20(bercAddress);
        uint256 voterBalance = berc.balanceOf(user);
        return [payVotes,totalPayVotes,tenPayVotes,bercVotes,totalBercVotes,tenBercVotes,voterBalance-bercVotes];
    }

    function getEndVoteTime()public view returns(uint256,uint256){
        return (currentPayStart+votingPeriod,currentBercStart+votingPeriod);
    } 

    function setVotingActive(bool _votingActive)external onlyOwner {
        votingActive = _votingActive;
    }

    function setBercStoreAddress(address _bercStoreAddress)external onlyOwner {
        bercStoreAddress = _bercStoreAddress;
    }

    function setBercAddress(address _bercAddress)external onlyOwner {
        bercAddress = _bercAddress;
    }


    function setVotingPeriod(uint256 _votingPeriod)external onlyOwner {
        votingPeriod = _votingPeriod;
    }
    
    function setDevAddress(address dev) external onlyOwner {
        devAddress = dev;
    }

    function setfundAddress(address fund) external onlyOwner {
        fundAddress = fund;
    }


    function setBercLpAddress(address _bercLpAddress) external onlyOwner {
        bercLpAddress = _bercLpAddress;
    }

    function calculateTokenProgress(address tokenAddress, uint256 maxMintCount) internal view returns (uint256) {
        uint256 tokenProgress = 0;
        if(oldTokenMintedNums[tokenAddress]==0){
            BlackErc20 blackErc20 = BlackErc20(tokenAddress);
            uint256 mintedCount = blackErc20.getMintedCounts();
            tokenProgress = (mintedCount * 10000) / maxMintCount;
        }else {
            tokenProgress = oldTokenMintedNums[tokenAddress] * 10000 / maxMintCount;
        }
        return tokenProgress;
    }

    function setOldTokenMintedNum(address tokenAddress, uint256 mintedNum) external  onlyOwner {
        oldTokenMintedNums[tokenAddress] = mintedNum;
    }

    function devAward() external onlyOwner{
        uint256 balance = address(this).balance;
        require(balance > 0, "Contract has no ETH balance.");
        address payable sender = payable(devAddress);
        sender.transfer(balance);
    }
}