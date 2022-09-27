// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/*
* Project: cryptowillprevail (https://www.cryptowillprevail.com/)
* Powered by: zzcryptolabs (https://www.zzcryptolabs.com)
*/

contract CryptoWillPrevail is ERC721Enumerable, Ownable {
    enum NFTKind {
        None,
        Regular,
        Special,
        Leader
    }

    enum GroupID {
        Robot,
        Skeleton,
        Soldier,
        Alien,
        Mummy,
        Tentacle,
        Spider,
        Kitty,
        Fighter,
        Ape,
        Tattoo,
        Knight,
        Wizard,
        WhiteRebel,
        Doggy,
        BlackRebel,
        TRex,
        Hook,
        Pixel,
        Zombie,
        Leader
    }

    struct NFT {
        GroupID groupID;
        NFTKind kind;
        uint8 x;
        uint8 y;
        string message;
    }

    struct Leader {
        address addr;
        string affiliateCode;
        uint nftId;
    }

    struct Group {
        uint16 regularCount;
        uint16 specialCount;
        uint[625] map;
    }

    struct NFTReturn {
        address owner;
        NFT nft;
    }

    mapping(uint => NFT) public nfts;

    Leader[] public leaders;

    uint public regularPrice;
    uint public specialPrice;

    address payable wallet1;
    address payable wallet2;

    uint public nftCounter = 1;

    Group[21] groups;

    bool public saleIsOpen;

    uint randomNonce;

    string public baseURI;

    constructor(address w1, address w2, string memory uri, uint nPrice, uint sPrice) ERC721("CryptoWillPrevail NFT", "CWP NFT") {
        for(uint i = 0; i < groups.length; i++) {
            groups[i].regularCount = 600;
            groups[i].specialCount = 25;
        }

        wallet1 = payable(w1);
        wallet2 = payable(w2);
        baseURI = uri;

        regularPrice = nPrice;
        specialPrice = sPrice;
    }

    // internal
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function getToken(address addr, bool isLeader) internal returns(uint) {
        if(isLeader) {
            uint token = 12500 + 1 + leaders.length;
            _safeMint(addr, token);
            return token;
        } else {
            uint token = nftCounter;
            _safeMint(addr, token);
            nftCounter++;
            return token;
        }
    }

    function mintNFT(address addr, GroupID groupID, NFTKind kind, string memory message) internal returns(uint) {
        require(saleIsOpen, "Sale is not open");
        require(bytes(message).length <= 32, "Message is too long");
        require(kind > NFTKind.None && kind <= NFTKind.Leader);
        if(kind == NFTKind.Leader) require(groupID == GroupID.Leader, "Invalid groupID");
        else require(groupID < GroupID.Leader, "Invalid groupID");

        uint gid = uint(groupID);
        if(kind != NFTKind.Leader) {
            if(kind == NFTKind.Special) {
                require(groups[gid].specialCount > 0, "Sold out");
                groups[gid].specialCount--;
            } else if(kind == NFTKind.Regular) {
                require(groups[gid].regularCount > 0, "Sold out");
                groups[gid].regularCount--;
            }
        }

        uint tokenID = getToken(addr, kind == NFTKind.Leader);
        nfts[tokenID].groupID = groupID;
        nfts[tokenID].kind = kind;

        if(kind != NFTKind.Leader) {
            uint pos = getRandomCoords(gid);
            groups[gid].map[pos] = tokenID;
            nfts[tokenID].y = uint8(pos / 25 + 1);
            nfts[tokenID].x = uint8((pos - 1) % 25 + 1);
        }

        nfts[tokenID].message = message;

        return tokenID;
    }

    function getLeaderFromCode(string memory code) internal view returns(int) {
        bytes32 code_hash = keccak256(abi.encodePacked(code));
        for(uint i = 0; i < leaders.length; i++)
            if (code_hash == keccak256(abi.encodePacked(leaders[i].affiliateCode)))
                return int(i);
        return -1;
    }

    function calculate(uint val, uint percent) internal pure returns(uint) {
        return val / 100 * percent;
    }

    function random(uint max) internal returns (uint) {
        uint h = uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, randomNonce)));
        randomNonce++;
        return h % max;
    }

    function getRandomCoords(uint groupID) internal returns(uint) {
        uint max = 25**2;
        uint n = random(max) + 1;

        while(groups[groupID].map[n] != 0) {
            n++;
            if(n >= max) n = 1;
        }

        return n;
    }

    // public
    function mint(GroupID groupID, bool special, string memory message, string memory code) external payable returns(uint) {
        require(bytes(message).length <= 32, "Message is too long");
        int leaderIdx = getLeaderFromCode(code);

        uint price = (special ? specialPrice : regularPrice);
        if(leaderIdx >= 0) price -= price / 10;

        require(msg.value >= price, "Message value is not enough");

        if(leaderIdx >= 0) {
            uint idx = uint(leaderIdx);
            uint transfer_price = msg.value / 10;
            payable(leaders[idx].addr).transfer(transfer_price);
        }

        return mintNFT(msg.sender, groupID, special ? NFTKind.Special : NFTKind.Regular, message);
    }

    function changeMessage(uint token, string memory message) public {
        require(_exists(token), "Token does not exist");
        require(bytes(message).length <= 32, "Message is too long");
        require(msg.sender == ownerOf(token), "Only the owner of the token can change the message");

        nfts[token].message = message;
    }

    function getLeaderAddressFromCode(string memory code) public view returns(address) {
        int id = getLeaderFromCode(code);
        if(id == 0) return address(0);
        else return leaders[uint(id)].addr;
    }

    function isLeaderRegistered(address addr) public view returns(bool) {
        for(uint i = 0; i < leaders.length; i++)
            if(leaders[i].addr == addr) return true;

        return false;
    }

    function leadersCount() public view returns(uint) {
        return leaders.length;
    }

    function groupCounts() public view returns(uint16[] memory) {
        uint16[] memory counts = new uint16[](42);
        for(uint i = 0; i < 21; i++) {
            counts[i * 2] = groups[i].regularCount;
            counts[i * 2 + 1] = groups[i].specialCount;
        }
        return counts;
    }

    function groupMap(uint groupID) public view returns(uint[625] memory) {
        require(groupID >= 0 && groupID <= 21);
        return groups[groupID].map;
    }

    function batchGetNFT(uint startIdx, uint count) public view returns(NFTReturn[] memory) {
        NFTReturn[] memory batch = new NFTReturn[](count);
        for(uint i = 0; i < count; i++) {
            uint tokenIdx = startIdx + i;
            if(!_exists(tokenIdx)) break;
            batch[i].owner = ownerOf(tokenIdx);
            batch[i].nft = nfts[tokenIdx];
        }

        return batch;
    }

    function getGroupID(uint nft) public view returns(GroupID) {
        require(_exists(nft));
        return nfts[nft].groupID;
    }

    function getKind(uint nft) public view returns(NFTKind) {
        require(_exists(nft));
        return nfts[nft].kind;
    }

    // admin
    function setWallet1(address addr) external onlyOwner {
        wallet1 = payable(addr);
    }

    function setWallet2(address addr) external onlyOwner {
        wallet2 = payable(addr);
    }

    function setBaseURI(string memory uri) external onlyOwner {
        baseURI = uri;
    }

    function setSaleIsOpen(bool b) external onlyOwner {
        saleIsOpen = b;
    }

    function setRegularPrice(uint price) external onlyOwner {
        regularPrice = price;
    }

    function setSpecialPrice(uint price) external onlyOwner {
        specialPrice = price;
    }

    function registerLeader(address addr, string memory message, string memory affiliateCode) external onlyOwner returns(uint) {
        require(!isLeaderRegistered(addr), "A leader with this address has already been added");
        for(uint i = 0; i < leaders.length; i++) {
            require(keccak256(abi.encodePacked(leaders[i].affiliateCode)) 
                != keccak256(abi.encodePacked(affiliateCode)), 
                "Affiliate code already in use");
        }

        uint token = mintNFT(addr, GroupID.Leader, NFTKind.Leader, message);
        Leader memory leader = Leader(addr, affiliateCode, token);
        leaders.push(leader);
        return token;
    }

    function airdrop(address addr, GroupID groupID, NFTKind kind, string memory message) external onlyOwner returns(uint) {
        return mintNFT(addr, groupID, kind, message);
    }

    function withdraw() external onlyOwner {
        uint amount = address(this).balance / 2;
        wallet1.transfer(amount);
        wallet2.transfer(amount);
    }
}