pragma solidity ^0.8.12;

import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "erc721a/contracts/interfaces/IERC721ABurnable.sol";

contract Savior is ERC721AQueryable, Ownable {
    using ECDSA for bytes32;
    using Strings for uint256;

    struct AuctionConfig {
        uint8 maxPerWallet;
        uint16 maxAuctionSupply;
        uint16 auctionMinted;
        uint16 curveLength; 
        uint16 intervalDrop; 
        uint32 startTime; 
        uint112 startPrice; 
        uint112 endPrice;  
        uint112 stepSize;
    }

    struct MintTimes {
        uint112 startTime;
        uint112 endTime;
    }

    IERC721ABurnable public vitriolToken;
    IERC20 public suckerToken;
    address private signer;

    AuctionConfig public auctionConfig;
    MintTimes public timeForMint;

    uint256 constant public maxSupply = 4444;
    uint256 constant public suckerNeeded = 5000000000 * 10 ** 18; 

    string private _baseTokenURI;
    bool revealed;

    bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;
    address private _royaltyAddress;
    uint256 private _royaltyPercentage;

    mapping (bytes => bool) public claimed;

    constructor(MintTimes memory _mintTimes, AuctionConfig memory _auctionConfig, IERC721ABurnable _vitriolToken, IERC20 _suckerToken, address _signer, address royaltyAddress, uint256 royaltyPercentage, string memory baseTokenURI) ERC721A("Saviors", "SAVIOR") {
        timeForMint = _mintTimes;
        auctionConfig = _auctionConfig;
        vitriolToken = _vitriolToken;
        suckerToken = _suckerToken;
        signer = _signer;
        _baseTokenURI = baseTokenURI;
    }
    
    function holderClaim(uint256[] memory tokenIds) external {
        require(block.timestamp >= timeForMint.startTime, "NOT_ACTIVE");
        require(tokenIds.length > 0 && totalSupply() + tokenIds.length <= maxSupply, "MAX_SUPPLY");
        uint256 i;
        for(i; i < tokenIds.length;) {
            uint256 vitriolId = tokenIds[i];
            require(vitriolToken.ownerOf(vitriolId) == msg.sender, "NOT_OWNER");
            vitriolToken.burn(vitriolId);
            unchecked { ++i; }
        }
        require(suckerToken.transferFrom(msg.sender, address(this), suckerNeeded * tokenIds.length), "FAILED_TRANSFER");
        _mint(msg.sender, tokenIds.length * 2);
    }

    function freeMint(bytes calldata signature) external {
        require(block.timestamp >= timeForMint.startTime && block.timestamp <= timeForMint.endTime, "NOT_ACTIVE");
        require(totalSupply() + 1 <= maxSupply);
        require(!claimed[signature], "ALREADY_CLAIMED");
        require(keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32",
            keccak256(abi.encodePacked(msg.sender))
        )).recover(signature) == signer);
        claimed[signature] = true;
        _mint(msg.sender, 1);
    }

    function auctionBuy(uint256 quantity) public payable {
        AuctionConfig memory _auctionConfig = auctionConfig;
        require(_auctionConfig.auctionMinted + quantity <= _auctionConfig.maxAuctionSupply, "MAX_SUPPLY");
        require(quantity <= _auctionConfig.maxPerWallet, "MAX_PER_WALLET");
        uint256 startTime = uint256(auctionConfig.startTime);
        require(startTime != 0 && block.timestamp >= startTime, "NOT_ACTIVE");
        uint256 cost = getPrice() * quantity;
        require(msg.value >= cost, "NOT_ENOUGH_ETHER");
        auctionConfig.auctionMinted += uint16(quantity);
        _mint(msg.sender, quantity);
    }


    function ownerMint(uint256 quantity) external onlyOwner {
        require(totalSupply() + quantity <= maxSupply, "MAX_SUPPLY");
        _mint(msg.sender, quantity);
    }

    function editMintTimes(MintTimes memory _mintTime) external onlyOwner {
        timeForMint = _mintTime;
    }

    function editAuctionSupply(uint16 _newSupply) external onlyOwner {
        auctionConfig.maxAuctionSupply = _newSupply;
    }

    function editAuctionConfig(AuctionConfig memory newConfig) external onlyOwner {
        auctionConfig = newConfig;
    }
    
    function editSigner(address _newSigner) external onlyOwner {
        signer = _newSigner;
    }

    function editBaseURI(string memory _base) external onlyOwner {
        _baseTokenURI = _base;
    }

    function reveal(string memory _newBase) external onlyOwner {
        revealed = true;
        _baseTokenURI = _newBase;
    }

    function editRoyaltyFee(address to, uint256 percent) external onlyOwner {
        _royaltyAddress = to;
        _royaltyPercentage = percent;
    }

    function withdraw() external onlyOwner {
        (bool sent, ) = payable(msg.sender).call{value: address(this).balance }("");
        require(sent, "FAILED");
    }

    function getPrice() public view returns (uint256) {
      if(block.timestamp < auctionConfig.startTime) {
        return auctionConfig.startPrice;
      }
      uint256 timeLeft = block.timestamp - auctionConfig.startTime;
      if(timeLeft >= auctionConfig.curveLength) {
        return auctionConfig.endPrice;
      } else {
        uint256 steps = timeLeft / auctionConfig.intervalDrop;
        return auctionConfig.startPrice - (steps * auctionConfig.stepSize);
      }
    }

    function _baseURI() internal view virtual override returns (string memory) {
      return _baseTokenURI;
    }

    function tokenURI(uint256 tokenId) public view override(ERC721A, IERC721A) returns (string memory) {
        require(_exists(tokenId),"ERC721Metadata: URI query for nonexistent token");
        string memory currentBaseURI = _baseURI();
        if(revealed) {
            return string(abi.encodePacked(currentBaseURI, tokenId.toString(), ".json"));
        } else {
            return currentBaseURI;
        }
    } 

    function royaltyInfo(uint256, uint256 value) external view returns (address, uint256) {
        return (_royaltyAddress, value * _royaltyPercentage / 10000);
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }
}