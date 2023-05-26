// SPDX-License-Identifier: MIT

/*

 _____ ______   ________      ___       ________  ________   ________     
|\   _ \  _   \|\   ____\    |\  \     |\   __  \|\   ___  \|\   ___ \    
\ \  \\\__\ \  \ \  \___|    \ \  \    \ \  \|\  \ \  \\ \  \ \  \_|\ \   
 \ \  \\|__| \  \ \  \  ___   \ \  \    \ \   __  \ \  \\ \  \ \  \ \\ \  
  \ \  \    \ \  \ \  \|\  \   \ \  \____\ \  \ \  \ \  \\ \  \ \  \_\\ \ 
   \ \__\    \ \__\ \_______\   \ \_______\ \__\ \__\ \__\\ \__\ \_______\
    \|__|     \|__|\|_______\    \|_______|\|__|\|__|\|__| \|__|\|_______|

*/
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

contract MGLand is ERC721Enumerable, ReentrancyGuard, Ownable {

    bool private _isPaused;
    string private _baseTokenUri;
    uint8 constant MAX_LAND_TYPE = 4;
    uint256 constant MAX_PER_TX = 8;
    uint256 constant LARGE_LAND_START = 100;
    uint256 constant MEDIUM_LAND_START = 1000;
    uint256 constant SMALL_LAND_START = 4000;

    struct LandParam {
        uint256 price;
        uint256 currentId;
        uint256 maxId;
    }

    mapping(uint8 => LandParam) public landInfo;

    constructor(
        string memory _name, 
        string memory _symbol
    ) ERC721(_name, _symbol) {
        landInfo[0] = LandParam(1.2 ether, 0, 100);
        landInfo[1] = LandParam(0.6 ether, 100, 1000);
        landInfo[2] = LandParam(0.3 ether, 1000, 4000);
        landInfo[3] = LandParam(0.15 ether, 4000, 10000);
    }
    
    function batchMint(uint8 landType, uint256 quantity) external payable nonReentrant{
        require(msg.sender == tx.origin, "EOAOnly");
        require(!_isPaused, "Mint Paused");
        require(landType < MAX_LAND_TYPE, "Land type error");
        require(quantity <= MAX_PER_TX, "Upper limit");

        LandParam memory land = landInfo[landType];

        require(msg.value == quantity * land.price, "Mint fee error");
        require(land.currentId < land.maxId, "Mint over");

        if (land.currentId + quantity <= land.maxId) {
            _batchMint(landType, quantity);
        } else {
            uint256 actQuant = land.maxId - land.currentId;
            uint256 value = msg.value - land.price * actQuant;
            _batchMint(landType, actQuant);
            _refund(value);
        }
    }

    function _batchMint(uint8 landType, uint256 quantity) internal {
        LandParam storage land = landInfo[landType];
        for (uint i; i < quantity; i++) {
            _safeMint(msg.sender, land.currentId + 1 + i);
        }        
        land.currentId += quantity;

    }

    function _refund(uint256 refundValue) internal {
        payable(msg.sender).transfer(refundValue);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenUri;
    }

    // =================================== View ====================================
    function totalSupply() public view override returns(uint256) {
        return superLandSupply() + largeLandSupply() + mediumLandSupply() + smallLandSupply(); 
    }

    function getLandSupply() public view returns(uint256[] memory landSupply) {
        landSupply = new uint256[](4);
        landSupply[0] = superLandSupply();
        landSupply[1] = largeLandSupply();
        landSupply[2] = mediumLandSupply();
        landSupply[3] = smallLandSupply();
    }

    function superLandSupply() private view returns(uint256) {
        return landInfo[0].currentId;
    }

    function largeLandSupply() private view returns(uint256) {
        return landInfo[1].currentId - LARGE_LAND_START;
    }

    function mediumLandSupply() private view returns(uint256) {
        return landInfo[2].currentId - MEDIUM_LAND_START;
    }

    function smallLandSupply() private view returns(uint256) {
        return landInfo[3].currentId - SMALL_LAND_START;
    }

    // ================================== Owner Function ================================
    function setBaseURI(string memory newURI) external onlyOwner {
        _baseTokenUri = newURI;
    }

    function setMintPaused() external onlyOwner {
        _isPaused = !_isPaused;
    }

    function setPrice(uint8 landType, uint256 newPrice) external onlyOwner {
        landInfo[landType].price = newPrice;
    }

    function withdraw(address to) external onlyOwner {
        require(to != address(0), "Transfer to zero address");
        uint256 balance = address(this).balance;
        payable(to).transfer(balance);
    }

}