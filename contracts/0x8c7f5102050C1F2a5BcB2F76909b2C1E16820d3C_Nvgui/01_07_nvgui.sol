// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "erc721a/contracts/ERC721A.sol";

contract Nvgui is Ownable, ERC721A, ReentrancyGuard {
    event Mint(address indexed account, uint256 indexed num);
    uint256 public maxCap;
    uint256 constant public MINT_PRICE = 0.1 ether;
    uint256 constant public MAX_MINT_ONE_PERSION = 1;
    uint256 public mintStartTime;
    uint256 public mintEndTime;
    string private _internalBaseURI;
    mapping(address => uint256) public nftMinted;

    constructor(string memory baseuri) ERC721A("Nvgui Genesis Producer Pass", "NvguiGenesis") {
        _internalBaseURI = baseuri;
        maxCap = 500;
        mintStartTime = 1677196800;
        mintEndTime = 1677290400;
    }

    function setBaseURI(string memory internalBaseURI_) external onlyOwner {
        _internalBaseURI = internalBaseURI_;
    }

    function mint() payable external callerIsUser nonReentrant {
        require(block.timestamp >= mintStartTime && block.timestamp <= mintEndTime, "not time");
        
        require(totalSupply() < maxCap, "over amount");
        require(msg.value >= MINT_PRICE, "insufficient funds");
        require(nftMinted[_msgSender()] < MAX_MINT_ONE_PERSION, "over limit amount");
        nftMinted[_msgSender()] += 1;
        super._safeMint(_msgSender(), 1);

        refundIfOver(MINT_PRICE);
        emit Mint(_msgSender(), 1);
    }

    function teamMint(address acount, uint256 amount) external onlyOwner {
        require(totalSupply() + amount <= maxCap, "over amount");
        super._safeMint(acount, amount);
    }

    function claim() external onlyOwner {
        payable(_msgSender()).transfer(address(this).balance);
    }

    function setMaxCap(uint256 cap) external onlyOwner {
        maxCap = cap;
    }

    function setMintTimes(uint256 mintStartTime_, uint256 mintEndTime_) external onlyOwner {
        require(mintStartTime_ < mintEndTime_);
        mintStartTime = mintStartTime_;
        mintEndTime = mintEndTime_;
    }

    function refundIfOver(uint256 price) private {
        if (msg.value > price) {
            payable(_msgSender()).transfer(msg.value - price);
        }
    }
    
    function _baseURI() internal view virtual override returns (string memory) {
        return _internalBaseURI;
    }

    modifier callerIsUser() {
        require(tx.origin == _msgSender(), "The caller is another contract");
        _;
    }

    function tokensOfOwner(address owner)
        external
        view
        returns (uint256[] memory)
    {
        uint256 tokenIdsIdx;
        address currOwnershipAddr;

        uint256 tokenIdsLength = balanceOf(owner);
        uint256[] memory tokenIds = new uint256[](tokenIdsLength);

        TokenOwnership memory ownership;
        for (uint256 i = _startTokenId(); tokenIdsIdx != tokenIdsLength; ++i) {
            ownership = _ownershipAt(i);

            if (ownership.burned) {
                continue;
            }

            if (ownership.addr != address(0)) {
                currOwnershipAddr = ownership.addr;
            }

            if (currOwnershipAddr == owner) {
                tokenIds[tokenIdsIdx++] = i;
            }
        }
        return tokenIds;
    }
}