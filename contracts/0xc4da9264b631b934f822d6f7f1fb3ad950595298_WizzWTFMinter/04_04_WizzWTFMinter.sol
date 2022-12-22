//
//                 __                                        _        ____ 
//      _    _     LJ    _____     _____         _    _     FJ_      / ___J
//     FJ .. L]         [__   F   [__   F       FJ .. L]   J  _|    J |_--'
//    | |/  \| |   FJ   `-.'.'/   `-.'.'/      | |/  \| |  | |-'    |  _|  
//    F   /\   J  J  L  .' (_(_   .' (_(_      F   /\   J  F |__-.  F |_J  
//   J\__//\\__/L J__L J_______L J_______L    J\__//\\__/L \_____/ J__F    
//    \__/  \__/  |__| |_______| |_______|     \__/  \__/  J_____F |__|    
//     
//                                                                  
// Wizz WTF Minter
// https://wizz.wtf
pragma solidity ^0.8.9;

import "solmate/tokens/ERC1155.sol";
import "solmate/utils/ReentrancyGuard.sol";
import "solmate/auth/Owned.sol";

interface ArtworkContract {
    function tokenSupply(uint256 tokenId) external returns (uint256);

    function mint(
        address initialOwner,
        uint256 tokenId,
        uint256 amount,
        bytes calldata data
    ) external;
}

contract WizzWTFMinter is Owned, ReentrancyGuard {
    address public wizzWTFAddress;
    uint256 public numArtworkTypes;

    bool public mintEnabled = false;
    uint256 public mintPrice = (1 ether * 0.01);
    uint256 public freeMintsPerAddress = 1;
    mapping(address => uint) public minted;
    mapping(uint256 => bool) public tokenFrozen;

    event WizzWTFMinted(address minter, uint256 artworkType);
    event WizzWTFClaimed(address claimer, uint256 artworkType);

    constructor(address _artworkAddress, uint256 _numArtworkTypes, address _owner) Owned(_owner) {
        wizzWTFAddress = _artworkAddress;
        numArtworkTypes = _numArtworkTypes;
    }

    function canClaim(address claimer) public view returns (bool) {
        return minted[claimer] < freeMintsPerAddress;
    }

    function claim(uint256 artworkType) public nonReentrant {
        require(mintEnabled, "MINT_CLOSED");
        require(!tokenFrozen[artworkType], "TOKEN_FROZEN");
        require(canClaim(msg.sender), "FREE_CLAIMS_USED");
        ArtworkContract artwork = ArtworkContract(wizzWTFAddress);
        require(artworkType < numArtworkTypes, "INCORRECT_ARTWORK_TYPE");

        artwork.mint(msg.sender, artworkType, 1, "");

        minted[msg.sender] += 1;

        emit WizzWTFClaimed(msg.sender, artworkType);
    }

    function mint(uint256 artworkType) public payable nonReentrant {
        require(mintEnabled, "MINT_CLOSED");
        require(!tokenFrozen[artworkType], "TOKEN_FROZEN");
        require(msg.value == mintPrice, "INCORRECT_ETH_VALUE");
        ArtworkContract artwork = ArtworkContract(wizzWTFAddress);
        require(artworkType < numArtworkTypes, "INCORRECT_ARTWORK_TYPE");

        artwork.mint(msg.sender, artworkType, 1, "");

        minted[msg.sender] += 1;

        emit WizzWTFMinted(msg.sender, artworkType);
    }

    // Only contract owner shall pass
    function withdraw() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function setMintEnabled(bool _newMintEnabled) public onlyOwner {
        mintEnabled = _newMintEnabled;
    }

    function setMintPrice(uint256 _newMintPrice) public onlyOwner {
        mintPrice = _newMintPrice;
    }

    function setFreeMintsPerAddress(uint256 _numMints) public onlyOwner {
        freeMintsPerAddress = _numMints;
    }

    function setFreezeToken(uint256 _tokenId, bool freeze) public onlyOwner {
        tokenFrozen[_tokenId] = freeze;
    }

    function setNumArtworkTypes(uint256 _artworkTypeMax) public onlyOwner {
        numArtworkTypes = _artworkTypeMax;
    }
}