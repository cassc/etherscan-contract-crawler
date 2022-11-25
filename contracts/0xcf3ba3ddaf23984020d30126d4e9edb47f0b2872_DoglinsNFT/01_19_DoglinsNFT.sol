// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "./lib/Administration.sol";
import "./lib/IENERGY.sol";
import "./lib/IEnergySystem.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "./lib/operator_filter/OperatorFilterer.sol";


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


contract DoglinsNFT is ERC721, Administration, OperatorFilterer, ERC2981 { 

    uint public price = 0.009 ether;
    uint public maxSupply = 7000;
    uint public maxTx = 10;
    uint public totalSupply = 0;

    mapping(address => bool) public free;
    bool public mintOpen = false;

    bool public operatorFilteringEnabled = true;

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
        setRoyaltyInfo(payable(_msgSender()),500);
        _registerForOperatorFiltering(address(0), false);
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

    function buyWL(bytes calldata signature_, uint qty, bool boost_) external payable {
        require(mintOpen, "Mint is closed");
        require(isAllowed(signature_, "_wl"), "Not allowed");
        bool freeAvailable = !free[_msgSender()];
        uint finalPrice = (qty * price) - (freeAvailable ? price : 0);
        require(finalPrice <= msg.value, "wrong value");
        if(freeAvailable){
            free[_msgSender()] = true;
        }
        _mintTo(_msgSender(),qty,boost_);
    }

    function buy(uint qty, bool boost_) external payable {
        require(qty * price <= msg.value, "wrong value");
        require(mintOpen, "Mint is closed");
        _mintTo(_msgSender(),qty,boost_);
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

    function toggleMintOpen() external onlyOwner {
        mintOpen = !mintOpen;
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

    function setEnergyAndSystemAddresses(address energy_, address system_) external onlyOwner {
        energySystemAddress = system_;
        energyAddress = energy_;
    }

    function setSigner(address new_) public onlyOwner {
        _signer = new_;
    }

    // OPERATOR FILTER

    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function setOperatorFilteringEnabled(bool value) public onlyOwner {
        operatorFilteringEnabled = value;
    }

    function _operatorFilteringEnabled() internal view virtual override returns (bool) {
        return operatorFilteringEnabled;
    }

    // IERC2981

    function setRoyaltyInfo(address payable receiver, uint96 numerator) public onlyOwner {
        _setDefaultRoyalty(receiver, numerator);
    }

    // ERC165

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC2981) returns (bool) {
        return ERC721.supportsInterface(interfaceId) || ERC2981.supportsInterface(interfaceId);
    }
    
}