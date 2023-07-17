// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&&&&&&&&&&&&&&&&&&&&&&&&&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@&&%&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@&&%&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@&&&&%&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@&&&&&&&%&&&&&&&&&&&&&&&&&&&&&..&&&&&&&&&&&&&&&&&&&&&&&&&&@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@&&&&&&&%&&&&&&&&&..&&&&&&&&&&.....&&&&&&&&&&&&&&&&&&&&&&&@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@&&&&&&&%&&&&&&&....&&&&&&&#.........&&&&&&&&&&&&&&&&&&&&&&&&@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@&&&&&&&%&&&&&&&..&&&&&&&..............&&&&&&&&&&&&&&&&&&&&&&@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@&&&&&&&%&&&&.....&&&&&.....................&&&&&&&&&&&&&&&&&@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@&&&&&&&%&&......................................&&&&&&&&&&&&@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@&&&&&&&#.......&&&&......................&&&&(....&&&&&&&&&&@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@&&&&&&&#....&&&............................../&&.....&&&&&&&@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@&&&&&&&#.......%%%%......................%%%%/.......&&&&@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@&/*,,&&([email protected]@@@@@@@@@................&@@@@@@&@@.....&&,,@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@..&&#[email protected]@@@@@@[email protected]@@@@@@(.......&&[email protected]@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@//*.............................................//@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@(//.....****.....,,,,,,,,,,,,.....****,....///@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@//............,,/#######,,............//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@/////.........*##..###........./////@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@/////////(#######/////////@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@//..........................//,@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@///..............................*//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@///....///..************..///....*//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@//.......///****/##**###****///.......//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@//.......///**##########****///.......//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@//..........//##(*******##//..........//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@(////..........//##########**//........../////@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@//*....///.......//##(*******##//.......*//.....//@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@///////.....///////**##########****///////*....///////@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@///.......//.....//@@@****/##**###****[email protected]@//.....//.......///@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@///................///@@************@@///................///@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@///..............//@@@//@@@@@@@@@@@@//#@@//..............///@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@////*.........//@@@@@////////////@@@@@//..........////@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@(/////////@@@@@@@@@@@@@@@@@@@@@@@@@@//////////@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@


// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";

// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

/**
 * @dev CyberBabies NFT Token, with some nifty features included in the contract directly !
 *  - instant reveal after minting
 *  - key babies that will give you access to something very special...
 */
contract CyberBabies is
    ERC721,
    ERC721Enumerable,
    Ownable
{
    using SafeMath for uint256;

    uint256 public constant maxSupply = 500;

    // dev address, if anyone wants to donate to get on my good side
    address public dev = 0x41C8fE8A8e7A6A695890449BC7b153b067fB0986;
    // manager address, no need to donate
    address private _manager;

    // only 10 mints allowed per txn. If you are a parent, you'll understand that this is way too high already
    uint256 public maxMintCountPerTxn = 20;

    //starting off with a nice friendly price
    uint256 public mintPrice = 0.25 ether;

    // some of these babies hold the key to a bright future...
    mapping(uint256 => bool) private keyBabies;

    string public baseUri = "https://cyberbabies.io/api/token/";
    string public contractURI = "https://cyberbabies.io/api/contract";
    string public metadataProvenanceHash = '';
    bool public saleIsActive = false;

    event ItsYourBirthday(uint256 tokenId, address minter);
    event SpecialStatusChanged(uint256 tokenId, bool specialStatus);
    
    constructor () ERC721("Cyber Babies", "CYBB") {

    }

    receive() external payable {}

    modifier saleIsLive {
        require(saleIsActive == true, "Sale not live");
        _;
    }

    modifier onlyOwnerOrManager() {
        require(owner() == _msgSender() || _manager == _msgSender(), "Caller not the owner or manager");
        _;
    }

    function flipSaleState() public onlyOwnerOrManager {
        saleIsActive = !saleIsActive;
    }

    function setManager(address manager) external onlyOwnerOrManager {
        _manager = manager;
    }

    // we're going to raise mint price for series 2 and 3.
    function setMintPrice(uint256 newPrice) external onlyOwnerOrManager {
        mintPrice = newPrice;
    }

    // we don't intent on changing the max mint per txn, but better be safe than sorry
    function setMaxMintCountPerTxn(uint256 newMaxMintCount) external onlyOwnerOrManager {
        maxMintCountPerTxn = newMaxMintCount;
    }

    // here so we can update the ipfs link if/when it expires
    function setBaseURI(string memory _URI) external onlyOwnerOrManager {
        baseUri = _URI;
    }

    function setContractURI(string memory _URI) external onlyOwnerOrManager {
        contractURI = _URI;
    }
    
    function setProvenanceHash(string memory _hash) public onlyOwnerOrManager {
        metadataProvenanceHash = _hash;
    }

    function setSpecialBabies(uint256[] calldata specialBabies, bool specialStatus ) external onlyOwnerOrManager {
        for (uint i; i < specialBabies.length; i++) {
            keyBabies[specialBabies[i]] = specialStatus;
            emit SpecialStatusChanged(specialBabies[i],specialStatus);
        }
    }

    function setSpecialBaby(uint256 specialBabyToken, bool specialStatus) external onlyOwnerOrManager {
        keyBabies[specialBabyToken] = specialStatus;
        emit SpecialStatusChanged(specialBabyToken,specialStatus);
    }

    function withdraw(uint256 amount) public onlyOwnerOrManager {
        require(address(this).balance >= amount, "Insufficient balance");
        Address.sendValue(payable(msg.sender), amount);
    }

    // reserving some babies to keep for giveaway, airdrops, prizes, etc
    function reserveBaby(address receiverAddress) external onlyOwnerOrManager {
        uint256 tokenId = totalSupply() + 1;
        _safeMint(receiverAddress, tokenId);
        emit ItsYourBirthday(tokenId, receiverAddress);
    }

    function reserveBaby(address receiverAddress, uint256 reservedAmount) external onlyOwnerOrManager {
        for (uint256 i =1; i<= reservedAmount; i++) {
            uint256 tokenId = totalSupply() + 1;
            _safeMint(receiverAddress, tokenId);
            emit ItsYourBirthday(tokenId, receiverAddress);
        }
    }

    // no protection needed, you just have to be ready to take care of these kids !
    function makeBabies(uint256 familySize) external payable saleIsLive {
        require(familySize <= maxMintCountPerTxn, "You're gonna need more than a school bus !");
        require(totalSupply() + familySize <= maxSupply, "All babies have been adopted !");
        require(mintPrice * familySize <= msg.value, "This isn't a charity !");

        for (uint256 i =0; i < familySize; i++) {
            uint256 tokenId = totalSupply() + 1;
            _safeMint(msg.sender, tokenId);
            emit ItsYourBirthday(tokenId, msg.sender);
        }
        
    }

    // some babies are special...
    function amISpecial(uint256 tokenId) external view returns (bool){
        return keyBabies[tokenId];
    }
    
    function whichBabyIsMine(address parent) public view returns (uint256[] memory)
    {
        uint256 tokenCount = balanceOf(parent);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(parent, i);
        }
        return tokensId;
    }

    // Housekeeping the ERC721 functions
    function _baseURI() internal view override(ERC721) returns (string memory) {
        return baseUri;
    }
    function renounceOwnership() public override onlyOwner {}

    // Storing info on the chain
    function uploadBabiesImage(bytes calldata s) external onlyOwnerOrManager {}

    function uploadBabiesAttributes(bytes calldata s) external onlyOwnerOrManager {}
    
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
        
    }
    
    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}