// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";
import "./ZZPass.sol";

/*
 * Project: cryptowillprevail (https://www.cryptowillprevail.com/)
 * Powered by: zzcryptolabs (https://www.zzcryptolabs.com)
 */

contract CryptoWillPrevail is
    DefaultOperatorFilterer,
    ERC721Enumerable,
    Ownable
{
    enum NFTKind {
        None,
        Regular,
        Special,
        Leader
    }

    enum GroupID {
        None,
        Robot,
        Skeleton,
        Alien,
        Tentacle,
        Spider,
        Kitty,
        Ape,
        WhiteRebel,
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
        uint256 nftId;
    }

    struct Group {
        uint16 regularCount;
        uint16 specialCount;
        uint256[625] map;
        string ipfs;
    }

    struct NFTReturn {
        address owner;
        NFT nft;
    }

    mapping(uint256 => NFT) public nfts;

    Leader[] public leaders;

    uint256 public regularPrice;
    uint256 public specialPrice;

    address payable beneficiaryWallet1;
    address payable beneficiaryWallet2;

    mapping(uint256 => uint256) public passesUsed;
    mapping(address => bool) public whitelist;
    mapping(address => bool) public whitelistFree;

    uint256 public nftCounter = 1;

    Group[10] groups;

    bool public saleIsOpen;

    uint256 randomNonce;

    string public baseURI;

    bool public whitelistEnabled;
    bool public whitelistFreeEnabled;

    bool public claimWithPassEnabled;

    uint256 public maxClaimWithPass;

    uint256 public whitelistDiscount = 0; // 0% - 100%

    ZZPass passContract;

    constructor(
        address w1,
        address w2,
        string memory uri,
        uint256 nPrice,
        uint256 sPrice,
        address passContractAddress
    ) ERC721("CryptoWillPrevail", "CWP") {
        for (uint256 i = 0; i < groups.length; i++) {
            groups[i].regularCount = 600;
            groups[i].specialCount = 25;
        }

        beneficiaryWallet1 = payable(w1);
        beneficiaryWallet2 = payable(w2);
        baseURI = uri;

        regularPrice = nPrice;
        specialPrice = sPrice;

        maxClaimWithPass = 2;

        passContract = ZZPass(passContractAddress);
    }

    // internal
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function getToken(address addr) internal returns (uint256) {
        uint256 token = nftCounter;
        _safeMint(addr, token);
        nftCounter++;
        return token;
    }

    function mintNFT(
        address addr,
        GroupID groupID,
        NFTKind kind,
        string memory message
    ) internal returns (uint256) {
        require(bytes(message).length <= 32, "Message is too long");
        require(kind > NFTKind.None && kind <= NFTKind.Leader);
        if (kind == NFTKind.Leader)
            require(groupID == GroupID.Leader, "Invalid groupID");
        else
            require(
                groupID != GroupID.Leader && groupID != GroupID.None,
                "Invalid groupID"
            );

        uint256 gid = uint256(groupID) - 1;
        if (kind != NFTKind.Leader) {
            if (kind == NFTKind.Special) {
                require(groups[gid].specialCount > 0, "Sold out");
                groups[gid].specialCount--;
            } else if (kind == NFTKind.Regular) {
                require(groups[gid].regularCount > 0, "Sold out");
                groups[gid].regularCount--;
            }
        }

        uint256 tokenID = getToken(addr);
        nfts[tokenID].groupID = groupID;
        nfts[tokenID].kind = kind;

        if (kind != NFTKind.Leader) {
            uint256 pos = getRandomCoords(gid);
            groups[gid].map[pos] = tokenID;
            nfts[tokenID].y = uint8(pos / 25);
            nfts[tokenID].x = uint8(pos % 25);
        }

        nfts[tokenID].message = message;

        return tokenID;
    }

    function getLeaderFromCode(string memory code)
        internal
        view
        returns (int256)
    {
        bytes32 code_hash = keccak256(abi.encodePacked(code));
        for (uint256 i = 0; i < leaders.length; i++)
            if (
                code_hash ==
                keccak256(abi.encodePacked(leaders[i].affiliateCode))
            ) return int256(i);
        return -1;
    }

    function calculate(uint256 val, uint256 percent)
        internal
        pure
        returns (uint256)
    {
        return (val / 100) * percent;
    }

    function random(uint256 max) internal returns (uint256) {
        uint256 h = uint256(
            keccak256(
                abi.encodePacked(block.difficulty, block.timestamp, randomNonce)
            )
        );
        randomNonce++;
        return h % max;
    }

    function getRandomCoords(uint256 groupID) internal returns (uint256) {
        uint256 max = 25**2;
        uint256 n = random(max);
        while (groups[groupID].map[n] != 0) {
            n++;
            if (n >= max) n = 0;
        }
        return n;
    }

    // public
    function mint(
        GroupID groupID,
        bool special,
        string memory message,
        string memory code
    ) external payable returns (uint256) {
        require(saleIsOpen, "Sale is not open");
        int256 leaderIdx = getLeaderFromCode(code);

        uint256 price = (special ? specialPrice : regularPrice);
        if (leaderIdx >= 0) price -= price / 10;

        require(msg.value >= price, "Message value is not enough");

        uint256 nftID = mintNFT(
            msg.sender,
            groupID,
            special ? NFTKind.Special : NFTKind.Regular,
            message
        );

        if (leaderIdx >= 0) {
            uint256 idx = uint256(leaderIdx);
            uint256 transfer_price = msg.value / 10;
            payable(leaders[idx].addr).transfer(transfer_price);
        }

        return nftID;
    }

    function claimWhitelist(GroupID groupID, string memory message)
        external
        payable
        returns (uint256)
    {
        require(whitelistEnabled, "Claiming with whitelist is not enabled!");
        require(whitelist[msg.sender], "You are not whitelisted!");

        uint256 price = regularPrice;
        price -= ((price * whitelistDiscount) / 100);

        require(msg.value >= price, "Message value is not enough");

        uint256 nftID = mintNFT(msg.sender, groupID, NFTKind.Regular, message);
        whitelist[msg.sender] = false;

        return nftID;
    }

    function claimWhitelistFree(GroupID groupID, string memory message)
        external
        payable
        returns (uint256)
    {
        require(
            whitelistFreeEnabled,
            "Claiming with whitelist is not enabled!"
        );
        require(whitelistFree[msg.sender], "You are not whitelisted!");

        require(msg.value >= 0, "Message value is not enough");

        uint256 nftID = mintNFT(msg.sender, groupID, NFTKind.Regular, message);
        whitelistFree[msg.sender] = false;

        return nftID;
    }

    function claimWithPass(
        GroupID groupID,
        string memory message,
        uint256 passTokenID
    ) external returns (uint256) {
        require(claimWithPassEnabled, "Claiming with a pass is not enabled!");
        require(passContract.exists(passTokenID), "Pass NFT does not exist!");
        require(
            passContract.ownerOf(passTokenID) == msg.sender,
            "You are not the owner of the pass NFT!"
        );
        require(
            passesUsed[passTokenID] < maxClaimWithPass,
            "Pass has already been used!"
        );

        uint256 nftID = mintNFT(msg.sender, groupID, NFTKind.Regular, message);
        passesUsed[passTokenID]++;

        return nftID;
    }

    function changeMessage(uint256 token, string memory message) public {
        require(_exists(token), "Token does not exist");
        require(bytes(message).length <= 32, "Message is too long");
        require(
            msg.sender == ownerOf(token),
            "Only the owner of the token can change the message"
        );

        nfts[token].message = message;
    }

    function getLeaderAddressFromCode(string memory code)
        public
        view
        returns (address)
    {
        int256 id = getLeaderFromCode(code);
        require(id != -1, "Invalid Code");
        return leaders[uint256(id)].addr;
    }

    function isLeaderRegistered(address addr) public view returns (bool) {
        for (uint256 i = 0; i < leaders.length; i++)
            if (leaders[i].addr == addr) return true;

        return false;
    }

    function groupCounts() public view returns (uint16[] memory) {
        uint16[] memory counts = new uint16[](groups.length * 2);
        for (uint256 i = 0; i < groups.length; i++) {
            counts[i * 2] = groups[i].regularCount;
            counts[i * 2 + 1] = groups[i].specialCount;
        }
        return counts;
    }

    function groupMap(uint256 groupID)
        public
        view
        returns (uint256[625] memory)
    {
        require(groupID <= groups.length);
        require(groupID > 0);
        return groups[groupID - 1].map;
    }

    function batchGetNFT(uint256 startIdx, uint256 count)
        public
        view
        returns (NFTReturn[] memory)
    {
        NFTReturn[] memory batch = new NFTReturn[](count);
        for (uint256 i = 0; i < count; i++) {
            uint256 tokenIdx = startIdx + i;
            if (!_exists(tokenIdx)) break;
            batch[i].owner = ownerOf(tokenIdx);
            batch[i].nft = nfts[tokenIdx];
        }

        return batch;
    }

    function getGroupID(uint256 nft) public view returns (GroupID) {
        require(_exists(nft));
        return nfts[nft].groupID;
    }

    function getKind(uint256 nft) public view returns (NFTKind) {
        require(_exists(nft));
        return nfts[nft].kind;
    }

    function GetGroupIPFS(uint256 groupID) public view returns (string memory) {
        require(groupID >= 1 && groupID <= 10,"Not valid group ID");
        return groups[groupID-1].ipfs;
    }

    // admin
    function setBaseURI(string memory uri) external onlyOwner {
        baseURI = uri;
    }

    function setMaxClaimWithPass(uint256 max) external onlyOwner {
        maxClaimWithPass = max;
    }

    function setRegularPrice(uint256 price) external onlyOwner {
        regularPrice = price;
    }

    function setSpecialPrice(uint256 price) external onlyOwner {
        specialPrice = price;
    }

    function setWhitelistDiscount(uint256 discount) external onlyOwner {
        require(discount <= 100, "Invalid whitelist discount");
        whitelistDiscount = discount;
    }

    function addToWhitelist(address[] memory toAdd) external onlyOwner {
        for (uint256 i = 0; i < toAdd.length; i++) {
            whitelist[toAdd[i]] = true;
        }
    }

    function addToWhitelistFree(address[] memory toAdd) external onlyOwner {
        for (uint256 i = 0; i < toAdd.length; i++) {
            whitelistFree[toAdd[i]] = true;
        }
    }

    function switchSaleIsOpen() external onlyOwner {
        saleIsOpen = !saleIsOpen;
    }

    function switchWhitelistEnabled() external onlyOwner {
        whitelistEnabled = !whitelistEnabled;
    }

    function switchWhitelistFreeEnabled() external onlyOwner {
        whitelistFreeEnabled = !whitelistFreeEnabled;
    }

    function switchClaimWithPassEnabled() external onlyOwner {
        claimWithPassEnabled = !claimWithPassEnabled;
    }

    function setGroupIPFS(uint256 groupID, string memory ipfs)
        external
        onlyOwner
    {
        require(groupID > 0 || groupID <= 10, "Invalid group ID");
        groups[groupID - 1].ipfs = ipfs;
    }

    function registerLeader(
        address addr,
        string memory message,
        string memory affiliateCode
    ) external onlyOwner returns (uint256) {
        require(
            !isLeaderRegistered(addr),
            "A leader with this address has already been added"
        );
        for (uint256 i = 0; i < leaders.length; i++) {
            require(
                keccak256(abi.encodePacked(leaders[i].affiliateCode)) !=
                    keccak256(abi.encodePacked(affiliateCode)),
                "Affiliate code already in use"
            );
        }

        uint256 token = mintNFT(addr, GroupID.Leader, NFTKind.Leader, message);
        Leader memory leader = Leader(addr, affiliateCode, token);
        leaders.push(leader);
        return token;
    }

    function airdrop(
        address addr,
        GroupID groupID,
        bool special,
        string memory message
    ) external onlyOwner returns (uint256) {
        return
            mintNFT(
                addr,
                groupID,
                special ? NFTKind.Special : NFTKind.Regular,
                message
            );
    }

    function withdraw() external onlyOwner {
        uint256 amount = address(this).balance / 2;
        beneficiaryWallet1.transfer(amount);
        beneficiaryWallet2.transfer(amount);
    }

    // creator fee enforce
    function setApprovalForAll(address operator, bool approved)
        public
        override(ERC721, IERC721)
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId)
        public
        override(ERC721, IERC721)
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override(ERC721, IERC721) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override(ERC721, IERC721) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public override(ERC721, IERC721) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}