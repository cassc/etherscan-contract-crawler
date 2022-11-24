// SPDX-License-Identifier: MIT
pragma solidity >=0.8.12;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "./lib/Administration.sol";
import "./lib/IENERGY.sol";
import "./lib/IEnergySystem.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";


// ▓█████▄  ▒█████    ▄████  ██▓     ██▓ ███▄    █   ██████ 
// ▒██▀ ██▌▒██▒  ██▒ ██▒ ▀█▒▓██▒    ▓██▒ ██ ▀█   █ ▒██    ▒ 
// ░██   █▌▒██░  ██▒▒██░▄▄▄░▒██░    ▒██▒▓██  ▀█ ██▒░ ▓██▄   
// ░▓█▄   ▌▒██   ██░░▓█  ██▓▒██░    ░██░▓██▒  ▐▌██▒  ▒   ██▒
// ░▒████▓ ░ ████▓▒░░▒▓███▀▒░██████▒░██░▒██░   ▓██░▒██████▒▒
//  ▒▒▓  ▒ ░ ▒░▒░▒░  ░▒   ▒ ░ ▒░▓  ░░▓  ░ ▒░   ▒ ▒ ▒ ▒▓▒ ▒ ░
//  ░ ▒  ▒   ░ ▒ ▒░   ░   ░ ░ ░ ▒  ░ ▒ ░░ ░░   ░ ▒░░ ░▒  ░ ░
//  ░ ░  ░ ░ ░ ░ ▒  ░ ░   ░   ░ ░    ▒ ░   ░   ░ ░ ░  ░  ░  
//    ░        ░ ░        ░     ░  ░ ░           ░       ░  
//  ░                                                       


contract DoglinsNFT is ERC721, Administration { 

    uint public price = 0.035 ether;
    uint public maxSupply = 7000;
    uint public maxTx = 10;
    uint public totalSupply = 0;

    mapping(address => bool) public free;
    uint public maxFree = 2000;
    uint public freeCount = 0;

    bool public firstWave = false;
    bool public secondWave = false;
    bool public thirdWave = false;

    address private _signer;
    address public energySystemAddress;
    address public energyAddress;
    
    mapping(uint => uint) public rerollCooldown;
    mapping(uint => uint) public energyTime;

    string internal baseTokenURI;

    modifier onlyOwnerOf(uint tokenId){
        require(ownerOf(tokenId) == _msgSender(), "Ownership: caller is not the owner");
        _;
    }
    
    constructor(string memory tokenURI_, address signer_) ERC721("Doglins", "DGLNS") {
        setSigner(signer_);
        setBaseTokenURI(tokenURI_);
    }

    function isAllowed(bytes calldata signature_, string memory data_) private view returns (bool) {
        return ECDSA.recover(
                ECDSA.toEthSignedMessageHash(
                    keccak256(abi.encodePacked(msg.sender,data_))), signature_
                ) == _signer;
    }

    function _baseURI() internal override view returns (string memory) {
        return baseTokenURI;
    }

    function buyTo(address to, uint qty) external onlyAdmin {
        _mintTo(to, qty, false);
    }

    function mintWaveOne(bytes calldata signature_, uint qty_, bool boost_) external payable {
        require(firstWave, "This wave is closed");
        require(isAllowed(signature_,"_wave1"), "Wave 1: Not allowed");
        require(maxTx >= qty_, "Max tx");
        require(price * qty_ <= msg.value, "wrong value");
         _mintTo(_msgSender(),qty_,boost_);
    }

    function mintWaveTwo(uint qty_, bool boost_) external payable {
        require(secondWave, "This wave is closed");
        require(maxTx >= qty_, "Max tx");
        require(price * qty_ <= msg.value, "wrong value");
         _mintTo(_msgSender(),qty_,boost_);
    }

    function mintWaveThree(bytes calldata signature_, bool boost_) external {
        require(thirdWave, "This wave is closed");
        require(isAllowed(signature_, "_wave3"), "Wave 3: Not allowed");
        require(!free[_msgSender()],"Wave 3: You can only mint once");
        require(maxFree > freeCount,"Max free reached");
        free[_msgSender()] = true;
        freeCount++;
        _mintTo(_msgSender(),1,boost_);
    }

    function _mintTo(address to, uint qty, bool boost_) internal {
        require(qty + totalSupply <= maxSupply, "SUPPLY: Value exceeds totalSupply");
        uint[] memory tokenIds = new uint[](qty);
        for(uint i = 0; i < qty; i++){
            totalSupply++;
            _mint(to, totalSupply);
            tokenIds[i] = totalSupply;
        }
        if(boost_){
            IEnergySystem(energySystemAddress).boostBatch(tokenIds);
        }
    }

    function tokensByOwner(address addr) external view returns (uint256[] memory)
    {
        uint256 count;
        uint256 walletBalance = balanceOf(addr);
        uint256[] memory tokens = new uint256[](walletBalance);

        uint256 i;
        for (; i < maxSupply; ) {
            // early break if all tokens found
            if (count == walletBalance) {
                return tokens;
            }

            // exists will prevent throw if burned token
            if (_exists(i) && ownerOf(i) == addr) {
                tokens[count] = i;
                count++;
            }

            ++i;
        }
        return tokens;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override {
        if(IEnergySystem(energySystemAddress).boosted(tokenId)){
            revert("ERROR: this NFT is boosted. Unboost it before transfer.");
        }
        if (from != address(0)) {
            IENERGY(energyAddress).stopDripping(from, 1);
        }

        if (to != address(0)) {
            IENERGY(energyAddress).startDripping(to, 1);
        }
        super._beforeTokenTransfer(from, to, tokenId);      
    }
    
    function withdraw() external onlyOwner {
        payable(_msgSender()).transfer(address(this).balance);
    }

    function toggleFirstWave() external onlyOwner {
        firstWave = !firstWave;
    }

    function toggleSecondWave() external onlyOwner {
        secondWave = !secondWave;
    }

    function toggleThirdWave() external onlyOwner {
        thirdWave = !thirdWave;
    }
   
    function setPrice(uint newPrice) external onlyOwner {
        price = newPrice;
    }
    
    function setBaseTokenURI(string memory uri_) public onlyOwner {
        baseTokenURI = uri_;
    }
    
    function setMaxSupply(uint newSupply) external onlyOwner {
        maxSupply = newSupply;
    }
    
    function setMaxTx(uint newMax) external onlyOwner {
        maxTx = newMax;
    }

    function setEnergySystemAddress(address newAddress) external onlyOwner {
        energySystemAddress = newAddress;
    }

    function setEnergyAddress(address newAddress) external onlyOwner {
        energyAddress = newAddress;
    }

    function setSigner(address new_) public onlyOwner {
        _signer = new_;
    }
    
}