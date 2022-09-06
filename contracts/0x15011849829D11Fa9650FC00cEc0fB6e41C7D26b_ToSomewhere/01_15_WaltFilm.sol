// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract ToSomewhere is ERC721Enumerable, Ownable, ReentrancyGuard {
    event Mint(address indexed account, uint256 indexed tokenid);

    uint256 constant public MAX_TOKEN = 1000;
    uint256 constant public MAX_TOKENS_PER_ACCOUNT_FOR_FREE = 2;

    mapping(address => uint256) public mintNum;

    uint256 constant public MAX_TEAM_KEEP = 50;
    uint256 public teamKeep = MAX_TEAM_KEEP;
    string private _internalbaseURI;
    uint256 private _lastTokenId;
    address public teamAccount;
    uint256 public whitelistMintTime;
    uint256 public publicMintTime;
    bytes32 public merkleRoot;

    constructor(string memory baseURI_, string memory name_, string memory symbol_, uint256 whitelistMintTime_, uint256 publicMintTime_, address teamAccount_) ERC721(name_, symbol_) {
        _internalbaseURI = baseURI_;
        whitelistMintTime = whitelistMintTime_;
        publicMintTime = publicMintTime_;
        teamAccount = teamAccount_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _internalbaseURI;
    }

    function whitelistMint(uint256 num, bytes32[] calldata proof_) external callerIsUser nonReentrant {
        require(block.timestamp >= whitelistMintTime && block.timestamp < publicMintTime, "white list mint time error");
        require(isWhiteListed(proof_, merkleRoot, msg.sender), "not whitelisted");
        require(totalSupply() + num + teamKeep <= MAX_TOKEN, "over free supply");
        require(mintNum[msg.sender] + num <= MAX_TOKENS_PER_ACCOUNT_FOR_FREE, "over per account amount");
        mintNum[msg.sender] += num;
        _batchMint(msg.sender, num);
    }

    function publicMint(uint256 num) external callerIsUser nonReentrant {
        require(block.timestamp >= publicMintTime, "public mint not start");
        require(totalSupply() + num + teamKeep <= MAX_TOKEN, "over free supply");
        require(mintNum[msg.sender] + num <= MAX_TOKENS_PER_ACCOUNT_FOR_FREE, "over per account amount");
        mintNum[msg.sender] += num;
        _batchMint(msg.sender, num);
    }

    function batchClaim(address[] calldata _accounts, uint256[] calldata _quantity) external onlyOwner nonReentrant {
        uint256 total = 0;
        for (uint i = 0; i < _quantity.length; i++) {
            total += _quantity[i];
        }
        require(totalSupply() + total + teamKeep <= MAX_TOKEN, "over free supply");

        for (uint i = 0; i < _accounts.length; i++) {
            _batchMint(_accounts[i], _quantity[i]);
        }
    }

    function teamMint(uint256 num) external onlyOwner {
        require(num <= teamKeep, "over team amount");
        _batchMint(teamAccount, num);
        teamKeep-= num;
    }

    function _batchMint(address to, uint256 num) internal {
        for (uint i = 0; i < num; i++) {
            uint256 tokenid = _lastTokenId;
            super._safeMint(to, tokenid);
            emit Mint(to, tokenid);
            unchecked {
                _lastTokenId++;
            }
        }
    }

    function claim() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function setBaseURI(string memory uri) external onlyOwner {
        _internalbaseURI = uri;
    }

    function setMerkleRoot(bytes32 merkleRoot_) external onlyOwner {
        merkleRoot = merkleRoot_;
    }

    function setTeamAccount(address teamAccount_) external onlyOwner {
        require(teamAccount_ != address(0), "team account cant be zero");
        teamAccount = teamAccount_;
    }
    
    function setMintTime(uint256 whitelistMintTime_, uint256 publicMintTime_) external onlyOwner {
        whitelistMintTime = whitelistMintTime_;
        publicMintTime = publicMintTime_;
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    function isWhiteListed(
        bytes32[] calldata proof_,
        bytes32 merkleRoot_,
        address account_
    ) private pure returns (bool) {
        return MerkleProof.verify(proof_, merkleRoot_, leaf(account_));
    }

    function leaf(address account_) private pure returns (bytes32) {
        return keccak256(abi.encodePacked(account_));
    }

    function arrayTokenIds(address account, uint256 _from, uint256 _to) public view returns(uint256[] memory) {
        require(_to < balanceOf(account), "Wrong max array value");
        require((_to - _from) <= balanceOf(account), "Wrong array range");
        uint256[] memory ids = new uint256[](_to - _from + 1);
        uint index = 0;
        for (uint i = _from; i <= _to; i++) {
            uint id = tokenOfOwnerByIndex(account, i);
            ids[index] = id;
            index++;
        }
        return (ids);
    }
}