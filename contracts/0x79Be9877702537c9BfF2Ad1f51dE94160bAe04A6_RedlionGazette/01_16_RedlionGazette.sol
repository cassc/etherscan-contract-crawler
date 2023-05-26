pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/structs/BitMaps.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./ERC2981.sol";

interface IRedlionSubscriptions {
    function isExpired(uint) external view returns (bool);
    function balanceOf(address) external view returns (uint);
    function tokenOfOwnerByIndex(address, uint) external view returns (uint);
    function expirations(uint) external view returns (uint);
    function whichType(uint) external view returns (uint);
}

contract RedlionGazette is Context, Ownable, ERC2981, ERC721, ERC721Enumerable {

    using BitMaps for BitMaps.BitMap;

    event MintedIssue(address user, uint issue, uint tokenId);

    IRedlionSubscriptions public subs;

    struct Issue {
        uint circulating;
        uint onSale; // quantity of issues to sell
    }

    mapping (uint => string) public issueToIPFS;
    mapping (uint => Issue) public issues;
    mapping (uint => uint) public tokenIdToIssue;
    mapping (uint => uint) public issuingTimes;
    uint public mintingPrice = 0.05 ether;
    uint public limitPerBuy = 5;

    mapping (uint => bytes32) public issueToMerkleRoot;

    string private _baseTokenURI;
    uint private royaltyFee = 1000; // 10000 * percentage (ex : 0.5% -> 0.005)
    mapping (address => BitMaps.BitMap) private _claimedAirdrop;
    mapping (address => BitMaps.BitMap) private _claimedIssues;
    BitMaps.BitMap private _isIssuePaused;

    constructor(
        string memory name,
        string memory symbol, 
        string memory baseTokenURI,
        address deployedSubs
    ) ERC721(name, symbol) {
        _baseTokenURI = baseTokenURI;
        subs = IRedlionSubscriptions(deployedSubs);
    }

    function getCreationTimeOfSub(uint subId) public view returns (uint) {
        uint subType = subs.whichType(subId);
        uint expirationTime = subs.expirations(subId);
        if (subType == 0) {
            return expirationTime - 13 weeks;
        } else if (subType == 1) {
            return expirationTime - 26 weeks;
        } else {
            return expirationTime - 52 weeks;
        }
    }

    function getValidSubs(address user, uint issue) public view returns (uint) {
        uint balance = subs.balanceOf(user);
        uint validSubs = 0;
        for(uint i = 0; i < balance; i++) {
            uint subId = subs.tokenOfOwnerByIndex(user, i);
            if (withinAllowedWindow(subId, issue)) validSubs++;
        }
        return validSubs;
    }

    function withinAllowedWindow(uint subId, uint issue) public view returns (bool) {
        uint subExpirationTime = subs.expirations(subId);
        uint creationTime = getCreationTimeOfSub(subId);
        return (creationTime <= issuingTimes[issue]) && (block.timestamp <= issuingTimes[issue] + 8 weeks) && (issuingTimes[issue] <= subExpirationTime);                                                                                                                             
    }

    function withdraw() onlyOwner public {
        uint amount = address(this).balance;
        payable(owner()).transfer(amount);
    }

    function pause(uint issue, bool shouldPause) onlyOwner public {
        if (shouldPause) _isIssuePaused.set(issue);
        else _isIssuePaused.unset(issue);
    }

    modifier whenNotPaused(uint issue) {
        require(!_isIssuePaused.get(issue), "Issue paused");
        _;
    }
    
    function changeBaseURI(string memory baseTokenURI) onlyOwner public {
        _baseTokenURI = baseTokenURI;
    }

    function setMintingPrice(uint price) onlyOwner public {
        mintingPrice = price;
    }

    function setLimitPerBuy(uint limit) onlyOwner public {
        limitPerBuy = limit;
    }

    function setRoyaltyFee(uint fee) onlyOwner public {
        royaltyFee = fee;
    }

    function changeDeployedSubs(address deployedSubs) onlyOwner public {
        subs = IRedlionSubscriptions(deployedSubs);
    }

    function changeIPFS(uint issue, string memory ipfs) onlyOwner public {
        issueToIPFS[issue] = ipfs;
    }

    function launchNewIssue(uint issue, uint saleSize, string memory ipfs) onlyOwner public {
        issuingTimes[issue] = block.timestamp;
        issues[issue].onSale = saleSize;
        issueToIPFS[issue] = ipfs;
    }

    function addMerkleAirdrop(uint issue, bytes32 root) onlyOwner public {
        issueToMerkleRoot[issue] = root;
    }

    function ownerMint(uint issue, address[] calldata recipients) onlyOwner public {
        for(uint i = 0; i < recipients.length; i++) {
            uint256 tokenId = (issue * (10**6)) + (issues[issue].circulating++);
            tokenIdToIssue[tokenId] = issue;
            _safeMint(recipients[i], tokenId);
            emit MintedIssue(msg.sender, issue, tokenId);
        }
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) public override view returns (
        address receiver,
        uint256 royaltyAmount
    ) {
        return (owner(), (_salePrice*royaltyFee)/10000);
    }

    function claim(uint issue, bytes32[] calldata proof, uint amount) whenNotPaused(issue) public {
        require(!_claimedAirdrop[msg.sender].get(issue), "ALREADY CLAIMED FOR ISSUE");
        _claimedAirdrop[msg.sender].set(issue);
        require(MerkleProof.verify(proof, issueToMerkleRoot[issue], keccak256(abi.encodePacked(msg.sender, amount))), "INVALID PROOF");
        for(uint i = 0; i < amount; i++) {
            uint256 tokenId = (issue * (10**6)) + (issues[issue].circulating++);
            tokenIdToIssue[tokenId] = issue;
            _safeMint(msg.sender, tokenId);
            emit MintedIssue(msg.sender, issue, tokenId);
        }
    }
    
    function mint(uint issue, uint amount) whenNotPaused(issue) public payable {
        uint toMint = msg.value == 0 ? getValidSubs(msg.sender, issue) : amount;
        //sub claiming
        if (msg.value == 0) {
            require(!_claimedIssues[msg.sender].get(issue), "ALREADY CLAIMED");
            require(toMint > 0, "NO VALID SUBSCRIPTION");
            _claimedIssues[msg.sender].set(issue);
        } else { //regular buy
            require(msg.value == mintingPrice * amount, "INCORRECT PRICE");
            require(amount <= limitPerBuy, "OVER LIMIT");
            require(issuingTimes[issue] + 6 days >= block.timestamp, "SALE EXPIRED");
            issues[issue].onSale -= amount;
        }
        for(uint i = 0; i < toMint; i++) {
            uint256 tokenId = (issue * (10**6)) + (issues[issue].circulating++);
            tokenIdToIssue[tokenId] = issue;
            _safeMint(msg.sender, tokenId);
            emit MintedIssue(msg.sender, issue, tokenId);
        }
    }

    function isAirdropClaimed(address user, uint issue) public view returns (bool) {
        return _claimedAirdrop[user].get(issue);
    }

    function isClaimed(address user, uint issue) public view returns (bool) {
        return _claimedIssues[user].get(issue);
    }

    function isIssuePaused(uint issue) public view returns (bool) {
        return _isIssuePaused.get(issue);
    }

    function tokenURI(uint256 tokenId) public override(ERC721) view returns (string memory) {
        return string(abi.encodePacked(_baseURI(), issueToIPFS[tokenIdToIssue[tokenId]]));
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC2981, ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}