// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';

import "./libraries/ERC721A.sol";


contract FuckFiat is Ownable, ERC721A, ReentrancyGuard {
    using SafeMath for uint256;
    using Strings for uint256;
    using SafeERC20 for IERC20;
   
    bool private _isActive = false;
    bytes32 public merkleRoot;

    uint256 public constant MAX_SUPPLY = 10000;
    uint256 public mintPrice = 0.02 ether;

    uint256 public totalMinted = 0;
    string private _tokenBaseURI = "";

    event FreeClaimed(address indexed account, uint256 amount);

    mapping (address => bool) freeClaimedMap;

    modifier onlyActive() {
        require(_isActive && totalMinted < MAX_SUPPLY, 'not active');
        _;
    }

    constructor(bytes32 _merkleRoot) ERC721A("FuckFiat", "FuckFiat") {
        merkleRoot = _merkleRoot;
    }

    function claim(uint256 index, uint256 baseAmount, bytes32[] calldata merkleProof) external onlyActive nonReentrant() {
        require(!freeClaimedMap[msg.sender], "already claimed!");
        uint256 freeAmount = freeClaimable(index, msg.sender, baseAmount, merkleProof);
        require(freeAmount <= MAX_SUPPLY.sub(totalMinted), "not enough nfts");
        require(freeAmount > 0, "no nfts to claim");
        _safeMint(msg.sender, freeAmount);
        
        totalMinted += freeAmount;
        freeClaimedMap[msg.sender] = true;
        emit FreeClaimed(msg.sender, freeAmount);
    }

    function mint(uint256 amount) external payable onlyActive nonReentrant() {
        require(amount > 0, "zero count");
        require(amount <= MAX_SUPPLY.sub(totalMinted), "not enough nfts");

        uint256 costForMinting = costForMint(amount);
        if (costForMinting > 0) {
            require(msg.value >= costForMinting, "insufficient ETH amount");
        }

        _transferETH(msg.sender, msg.value.sub(costForMinting));
        _safeMint(msg.sender, amount);

        totalMinted += amount;
    }

    function costForMint(uint256 amount) public view returns(uint256) {
        return amount.mul(mintPrice);
    }


    function freeClaimable(uint256 index, address account, uint256 baseAmount, bytes32[] calldata merkleProof) public view returns(uint256) {
        if (freeClaimedMap[account]) return 0;
        bytes32 node = keccak256(abi.encodePacked(index, account, baseAmount));
        bool isVerified = MerkleProof.verify(merkleProof, merkleRoot, node);
        uint256 claimable = 0;
        if (isVerified) {
            if (baseAmount <= 8) {
                claimable = 1;
            } else if (baseAmount <= 19) {
                claimable = 2;
            } else {
                claimable = 3;
            }
        }
        return claimable;
    }

    function _baseURI() internal view override returns (string memory) {
        return _tokenBaseURI;
    }

    
    function _transferETH (address to, uint256 value) internal {
        Address.sendValue(payable(to), value);
    }

    function tokenURI(uint256 tokenId) public view override(ERC721A) returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    //=======================   Admin Functions =======================//
    function startSale() external onlyOwner {
        _isActive = true;
    }

    function endSale() external onlyOwner {
        _isActive = false;
    }

    function withdraw() external onlyOwner nonReentrant {
        uint256 balance = address(this).balance;
        Address.sendValue(payable(owner()), balance);
    }

    function setTokenBaseURI(string memory URI) external onlyOwner {
        _tokenBaseURI = URI;
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    receive() external payable {}


}