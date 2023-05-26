// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract TenLevels is ERC721, ERC721Enumerable, Ownable {
    // lib
    using Address for address payable;

    // struct
    struct LevelInfo {
        uint16 lastNeedNum;
        uint16 merkleProofAnswerNum;

        uint16 payCount;
        uint256[] payNumAndPrice;

        bytes32 answerMerkleProofRootHash;
        bytes32 answerHash;

        uint256 mintNum;
        mapping(uint256 => bool) indexMinted;
    }

    struct InvestInfo{
        uint256 maxAmount;
        uint256 sharePer;

        uint256 curAmount;
        mapping(address => uint256) userAmount;
    }

    // constant
    uint256 public constant MAX_INVEST_LEVEL = 3;
    uint256 public constant MAX_LEVEL = 10;
    uint256 public constant LEVEL_GAP = 100000000;
    uint256 public constant MAX_PER = 10000;
    uint256 public constant OWNER_SHARE_PER = 2000;
    uint256 public constant INVESTOR_SHARE_PER = 3000;

    // storage
    mapping(uint256 => LevelInfo) public levelInfos;
    mapping(uint256 => bool) public useFlag;
    mapping(uint256 => bool) public rewardFlag;

    uint256 public investorShare;
    mapping(uint256 => InvestInfo) public investInfos;
    mapping(address => bool) public investClaimFlag;
    bool public adminInvestClaimFlag;

    uint256 private _rewardShare;

    string private _basePath;

    // event
    event Mint(address indexed user, uint256 indexed costToken, uint256 indexed newToken);
    event ClaimRewards(address indexed user, uint256[] tokenIDs, uint256 amount);
    event Invest(address indexed user, uint256 indexed level, uint256 amount);
    event CancleInvest(address indexed user, uint256 indexed level, uint256 amount);
    event InvestClaimRewards(address indexed user, uint256 amount);
    event AdminClaimRemainInvestRewards(uint256 amount);
    event MetadataUpdate(uint256 _tokenId);

    // function
    constructor() ERC721("TenLevels", "TL") {
        investInfos[0].maxAmount = 20 ether;
        investInfos[0].sharePer = 3333;

        investInfos[1].maxAmount = 200 ether;
        investInfos[1].sharePer = 3334;

        investInfos[2].maxAmount = 500 ether;
        investInfos[2].sharePer = 3333;

        levelInfos[0].lastNeedNum = 0;
        levelInfos[0].merkleProofAnswerNum = 200;
        levelInfos[0].answerMerkleProofRootHash = 0x78f16dbcd6602e42a45821832f3b540e2712f7e9a66aae0a722ccf396241b78c;
        levelInfos[0].answerHash = 0x59c6f2975c10e62a1d4b219b16cd3abe2803ccdedab2a6de45642e3fe32e9aa8;
        levelInfos[0].payCount = 15;
        levelInfos[0].payNumAndPrice.push(0x00c8000001900014025800280320003c03e8005004b000640578007d06400096);
        levelInfos[0].payNumAndPrice.push(0x07d000c8096000fa0af0012c0c80015e0e1001900fa001c2ffff01f400000000);

        levelInfos[1].lastNeedNum = 1;
        levelInfos[1].merkleProofAnswerNum = 200;
        levelInfos[1].answerMerkleProofRootHash = 0x1c3a00fdfca86c31df9cfce93631d9bd269e581aac8f18ed81f86ce40920d5b3;
        levelInfos[1].answerHash = 0x5b729d5d0254371da8a738bb9a1e75c1816ab2e661ab6d24ac7c2c3f94f1c12b;
        levelInfos[1].payCount = 15;
        levelInfos[1].payNumAndPrice.push(0x00c8000001900014025800280320003c03e8005004b000640578007d06400096);
        levelInfos[1].payNumAndPrice.push(0x07d000c8096000fa0af0012c0c80015e0e1001900fa001c2ffff01f400000000);

        levelInfos[2].lastNeedNum = 100;
        levelInfos[2].merkleProofAnswerNum = 200;
        levelInfos[2].answerMerkleProofRootHash = 0xf06f9cd5d1873ca46a97548fcd4fb39a3afb70b17d5bffb899d9c0f1884ac98b;
        levelInfos[2].answerHash = 0x4ded7967f7842140ae7006c103ce73ea5256b0977acb1632e37060f0bafc4bd0;
        levelInfos[2].payCount = 15;
        levelInfos[2].payNumAndPrice.push(0x00c8000001900014025800280320003c03e8005004b000640578007d06400096);
        levelInfos[2].payNumAndPrice.push(0x07d000c8096000fa0af0012c0c80015e0e1001900fa001c2ffff01f400000000);

        levelInfos[3].lastNeedNum = 400;
        levelInfos[3].merkleProofAnswerNum = 200;
        levelInfos[3].answerMerkleProofRootHash = 0xe43e41e9003bd92e6e202d0fc3e3897c91d637d92644168959b56c4b99f54e87;
        levelInfos[3].answerHash = 0x3feab3fe18a2a8713785ec615e1caa545c789d8ced21faaf5d3f4e0e73b4ca99;
        levelInfos[3].payCount = 15;
        levelInfos[3].payNumAndPrice.push(0x00640000012c001401f4002802bc003c03840050044c00640514007d05dc0096);
        levelInfos[3].payNumAndPrice.push(0x076c00c808fc00fa0a8c012c0c1c015e0dac01900f3c01c2ffff01f400000000);

        levelInfos[4].lastNeedNum = 600;
        levelInfos[4].merkleProofAnswerNum = 200;
        levelInfos[4].answerMerkleProofRootHash = 0x6f607813810a3b48873bd28fbcc17c2b53fe006e5224aea89ea77602e873e41a;
        levelInfos[4].answerHash = 0x1a44d30ccc44edad6d888341a26a7932844b28b1df0555ca9aa29254cac53be5;
        levelInfos[4].payCount = 15;
        levelInfos[4].payNumAndPrice.push(0x00640000012c001401f4002802bc003c03840050044c00640514007d05dc0096);
        levelInfos[4].payNumAndPrice.push(0x076c00c808fc00fa0a8c012c0c1c015e0dac01900f3c01c2ffff01f400000000);

        levelInfos[5].lastNeedNum = 800;
        levelInfos[5].merkleProofAnswerNum = 200;
        levelInfos[5].answerMerkleProofRootHash = 0x35c007961ca7bad5c0c0943f1af071f2b154bba7a3944c41c1bccdcde1a90cd5;
        levelInfos[5].answerHash = 0x2e644071c81edbf8b51209eea9a251eaf70fb873d9223e93c007314f2e25c555;
        levelInfos[5].payCount = 15;
        levelInfos[5].payNumAndPrice.push(0x00640000012c001401f4002802bc003c03840050044c00640514007d05dc0096);
        levelInfos[5].payNumAndPrice.push(0x076c00c808fc00fa0a8c012c0c1c015e0dac01900f3c01c2ffff01f400000000);

        levelInfos[6].lastNeedNum = 1000;
        levelInfos[6].merkleProofAnswerNum = 200;
        levelInfos[6].answerMerkleProofRootHash = 0xd4ac862bcb86437e9e90153f99d77dc5a95d36723471e1ddb99db2999b4ae38e;
        levelInfos[6].answerHash = 0x7ff64423ecd407767ecdeaea2f8775ff9fa00a1d1ba362bfb34ffbd735d0100b;
        levelInfos[6].payCount = 15;
        levelInfos[6].payNumAndPrice.push(0x00640000012c001401f4002802bc003c03840050044c00640514007d05dc0096);
        levelInfos[6].payNumAndPrice.push(0x076c00c808fc00fa0a8c012c0c1c015e0dac01900f3c01c2ffff01f400000000);

        levelInfos[7].lastNeedNum = 1200;
        levelInfos[7].merkleProofAnswerNum = 200;
        levelInfos[7].answerMerkleProofRootHash = 0x38a5b793b291a360eb0737529bc504d86f60da7778b7169cfb027ab689506a13;
        levelInfos[7].answerHash = 0xd5b431763adc5e047f66fe04ee50b6dad32df2d6728743843de06c79f1d3796e;
        levelInfos[7].payCount = 15;
        levelInfos[7].payNumAndPrice.push(0x00640000012c001401f4002802bc003c03840050044c00640514007d05dc0096);
        levelInfos[7].payNumAndPrice.push(0x076c00c808fc00fa0a8c012c0c1c015e0dac01900f3c01c2ffff01f400000000);

        levelInfos[8].lastNeedNum = 1400;
        levelInfos[8].merkleProofAnswerNum = 0;
        levelInfos[8].answerMerkleProofRootHash = 0x87a60323373e695e2873a8eb5ede67246e1623b2a8495bf5442f6c0dad2bee7c;
        levelInfos[8].answerHash = 0x37cd3ef0fc43ab4c39271455958d6014e87e25a5f6fccfa2022f902fc658d141;
        levelInfos[8].payCount = 1;
        levelInfos[8].payNumAndPrice.push(0xffff01f400000000000000000000000000000000000000000000000000000000);

        levelInfos[9].lastNeedNum = 100;
        levelInfos[9].merkleProofAnswerNum = 0;
        levelInfos[9].answerMerkleProofRootHash = 0xeee7ac1014d23da9f803d288bfe00c449b5eb4c817957d3a19cfd160bfff1630;
        levelInfos[9].answerHash = 0x9496cef18af800073905704f8b18429f907a5d3f21b0a11c686692d2e9a9418f;
        levelInfos[9].payCount = 1;
        levelInfos[9].payNumAndPrice.push(0xffff000000000000000000000000000000000000000000000000000000000000);
    }

    function getMintedIndex(uint256 level, uint256[] memory index) public view returns(bool[] memory){
        bool[] memory rets = new bool[](index.length);
        for (uint256 i = 0; i < index.length; ++i){
            rets[i] = levelInfos[level].indexMinted[index[i]];
        }

        return rets;
    }

    function getMintPrice(uint256 level) public view returns (uint256){
        uint256 count = levelInfos[level].payCount;
        uint256 mintNum = levelInfos[level].mintNum;
        for (uint256 i = 0; i < count; ++i){
            uint256 pos = i / 8;
            uint256 moveBit = 240 - (i % 8) * 32;
            if (mintNum < ((levelInfos[level].payNumAndPrice[pos] & (0xffff << moveBit))>>moveBit)){
                return ((levelInfos[level].payNumAndPrice[pos] & (0xffff << (moveBit - 16)))>>(moveBit - 16)) * 1e15;
            }
        }

        revert("mint num overflow");
    }

    function getRewards() public view returns (uint256){
        if (levelInfos[MAX_LEVEL - 1].mintNum > 0){
            return _rewardShare;
        }
        else{
            return address(this).balance - investorShare;
        }
    }

    function _payEth(uint256 level) private {
        uint price = getMintPrice(level);
        if (price <=  0){
            return;
        }
        require(msg.value == price, "eth insufficient");
        payable(owner()).sendValue(price * OWNER_SHARE_PER / MAX_PER);
        investorShare += price * INVESTOR_SHARE_PER / MAX_PER;
    }

    function merkleProofMint(uint256 tokenID, uint256 level, bytes32 nodeHash, uint256 index, bytes32[] memory proofs) public payable{
        require(level >= 0 && level < MAX_LEVEL, "level error");
        if (level > 0){
            require(levelInfos[level-1].mintNum >= levelInfos[level].lastNeedNum, "level lock");

            require(tokenID / LEVEL_GAP == level - 1, "tokenID level error");
            require(ownerOf(tokenID) == msg.sender, "tokenID owner error");
            require(useFlag[tokenID] == false, "tokenID has been used");
            useFlag[tokenID] = true;
            emit MetadataUpdate(tokenID);
        }

        if (level < MAX_LEVEL - 1){
            require(levelInfos[MAX_LEVEL - 1].mintNum == 0, "mint locked");
        }

        uint256 curMintNum = levelInfos[level].mintNum;
        require(curMintNum < levelInfos[level].merkleProofAnswerNum, "mint approach error");
        require(levelInfos[level].indexMinted[index] == false, "cur index already minted");
        require(MerkleProof.verify(proofs, levelInfos[level].answerMerkleProofRootHash, keccak256(abi.encodePacked(nodeHash, index))), "answer error");
        _payEth(level);

        if (level == MAX_LEVEL - 1 && levelInfos[MAX_LEVEL - 1].mintNum == 0){
            _rewardShare = address(this).balance - investorShare;
        }

        levelInfos[level].mintNum = curMintNum + 1;
        levelInfos[level].indexMinted[index] = true;

        uint256 newTokenID = level * LEVEL_GAP + curMintNum;
        _safeMint(msg.sender, newTokenID);

        emit Mint(msg.sender, tokenID, newTokenID);
    }

    function mint(uint256 tokenID, uint256 level, bytes32 answerHash) public payable{
        require(level >= 0 && level < MAX_LEVEL, "level error");
        if (level > 0){
            require(levelInfos[level-1].mintNum >= levelInfos[level].lastNeedNum, "level lock");

            require(tokenID / LEVEL_GAP == level - 1, "tokenID level error");
            require(ownerOf(tokenID) == msg.sender, "tokenID owner error");
            require(useFlag[tokenID] == false, "tokenID has been used");
            useFlag[tokenID] = true;
            emit MetadataUpdate(tokenID);
        }
        if (level < MAX_LEVEL - 1){
            require(levelInfos[MAX_LEVEL - 1].mintNum == 0, "mint locked");
        }


        uint256 curMintNum = levelInfos[level].mintNum;
        require(curMintNum >= levelInfos[level].merkleProofAnswerNum, "mint approach error");
        require(keccak256(abi.encodePacked(answerHash)) == levelInfos[level].answerHash, "answer error");
        _payEth(level);

        if (level == MAX_LEVEL - 1 && levelInfos[MAX_LEVEL - 1].mintNum == 0){
            _rewardShare = address(this).balance - investorShare;
        }
        
        levelInfos[level].mintNum = curMintNum + 1;

        uint256 newTokenID = level * LEVEL_GAP + curMintNum;
        _safeMint(msg.sender, newTokenID);

        emit Mint(msg.sender, tokenID, newTokenID);
    }

    function claimRewards(uint256[] memory tokenIDs) public{
        require(levelInfos[MAX_LEVEL - 1].mintNum > 0, "not finish");
        uint256 id = 0;
        for (uint256 i = 0; i < tokenIDs.length; ++i){
            id = tokenIDs[i];
            require(id / LEVEL_GAP == MAX_LEVEL - 1, "token level error");
            require(ownerOf(id) == msg.sender, "token owner error");
            require(rewardFlag[id] == false, "token has been rewarded");
            rewardFlag[id] = true;
        }

        uint256 reward = getRewards() * tokenIDs.length / levelInfos[MAX_LEVEL - 2].mintNum;
        payable(msg.sender).sendValue(reward);

        emit ClaimRewards(msg.sender, tokenIDs, reward);
    }

    function adminClaimRemainRewards() public onlyOwner(){
        require(levelInfos[MAX_LEVEL - 1].mintNum > 0, "not finish");
        require(adminInvestClaimFlag == false, "already claim");

        uint256 rewardAmount = 0;
        for (uint256 i = 0; i < MAX_INVEST_LEVEL; ++i){
            rewardAmount += investorShare * investInfos[i].sharePer / MAX_PER * (investInfos[i].maxAmount - investInfos[i].curAmount) / investInfos[i].maxAmount;
        }

        adminInvestClaimFlag = true;
        payable(msg.sender).sendValue(rewardAmount);

        emit AdminClaimRemainInvestRewards(rewardAmount);
    }

    function invest(uint256 level) public payable{
        require(levelInfos[MAX_LEVEL - 1].mintNum == 0, "invest locked");
        require(level >= 0 && level < MAX_INVEST_LEVEL, "level error");

        require(msg.value > 0 && msg.value <= (investInfos[level].maxAmount - investInfos[level].curAmount), "share overflow");

        investInfos[level].curAmount += msg.value;
        investInfos[level].userAmount[msg.sender] += msg.value;
        
        emit Invest(msg.sender, level, msg.value);
    }

    function cancleInvest(uint256 level, uint256 amount) public{
        require(levelInfos[MAX_LEVEL - 1].mintNum == 0, "cancle invest locked");
        require(level >= 0 && level < MAX_INVEST_LEVEL, "level error");

        require(amount <= investInfos[level].userAmount[msg.sender], "share overflow");

        investInfos[level].curAmount -= amount;
        investInfos[level].userAmount[msg.sender] -= amount;

        payable(msg.sender).sendValue(amount);

        emit CancleInvest(msg.sender, level, amount);
    }

    function getUserInvestInfo(address user, uint256[] memory levels) public view returns(uint256[] memory){
        uint256[] memory rets = new uint256[](levels.length);
        for (uint256 i = 0; i < levels.length; ++i){
            rets[i] = investInfos[levels[i]].userAmount[user];
        }
        return rets;
    }

    function getInvestRewards(address user) public view returns(uint256){
        uint256 rewardAmount = 0;
        uint256 investAmount = 0;
        for (uint256 i = 0; i < MAX_INVEST_LEVEL; ++i){
            investAmount = investInfos[i].userAmount[user];
            if (investAmount > 0){
                rewardAmount += investorShare * investInfos[i].sharePer / MAX_PER * investAmount / investInfos[i].maxAmount;
            }
        }

        return rewardAmount;
    }
    
    function claimInvestRewards() public {
        require(levelInfos[MAX_LEVEL - 1].mintNum > 0, "not finish");
        require(investClaimFlag[msg.sender] == false, "already claim");
        uint256 rewardAmount = getInvestRewards(msg.sender);

        require(rewardAmount > 0, "no reward to claim");
        investClaimFlag[msg.sender] = true;
        payable(msg.sender).sendValue(rewardAmount);

        emit InvestClaimRewards(msg.sender, rewardAmount);
    }

    function _baseURI() internal view override returns (string memory) {
        return _basePath;
    }

    function setBaseURI(string calldata path) public onlyOwner(){
        _basePath = path;
    }

    // The following functions are overrides required by Solidity.
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);

        if (levelInfos[MAX_LEVEL - 1].mintNum == 0){
            require(useFlag[tokenId] == false, "token already use during gaming");
        }
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return interfaceId == bytes4(0x49064906) || super.supportsInterface(interfaceId);
    }
}