//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
  
import "erc721a/contracts/ERC721A.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "hardhat/console.sol";
import "./ERC721Woodable.sol";

contract VMountainInterface {
    function balanceOf(address) public returns (uint) {}
    function tokenOfOwnerByIndex(address, uint) public returns (uint) {}
}

contract HexMountain is ERC721A, ERC721AQueryable, ERC721Woodable {  
    address private immutable contractAddress;
    address public owner;

    VMountainInterface private immutable _vMountainContract;
    mapping (uint => bool) _vMountainUsedForMint;

    uint constant public cap = 1200;
    uint public mintPrice = 7 ether / 100;
    uint public lasercuttingVoucherPrice = 10 ether / 100;

    bool public freeSaleActive = false;
    bool public saleActive = false;
    bool public lasercuttingVoucherSaleActive = false;

    // Donations going to Ethereum protocol contributors via the Protocol guild
    // https://twitter.com/StatefulWorks/status/1477006979704967169
    // https://stateful.mirror.xyz/mEDvFXGCKdDhR-N320KRtsq60Y2OPk8rHcHBCFVryXY
    // https://protocol-guild.readthedocs.io/en/latest/
    address public donationAddress = 0xF29Ff96aaEa6C9A1fBa851f74737f3c069d4f1a9;

    string private __baseURI;
    string private __woodBaseURI;


    constructor(address vMountainContractAddress) ERC721A("HexMountain", "HEXM") {
        contractAddress = address(this);
        owner = msg.sender;
        _vMountainContract = VMountainInterface(vMountainContractAddress);
        __baseURI = "https://nand.fr/assets/hmountain/metadata/";
        __woodBaseURI = "https://nand.fr/assets/hmountain/wnft/metadata/";
    }
  
    function mint(uint64 quantity) external payable noDelegateCall {
        require(tx.origin == msg.sender, "ser plz");
        require(_totalMinted() + quantity <= cap, "Cap reached");
        require(saleActive || freeSaleActive, "Sale not active yet");
        require(quantity <= 20, "Max 20 per tx");

        uint64 quantityToPay = quantity;

        // Free mints for VMountain owners
        for(uint i = 0; i < _vMountainContract.balanceOf(msg.sender); i++) {
            uint tokenId = _vMountainContract.tokenOfOwnerByIndex(msg.sender, i);
            if(_vMountainUsedForMint[tokenId] == false) {
                quantityToPay--;
                _vMountainUsedForMint[tokenId] = true;
                if(quantityToPay == 0) {
                    break;
                }
            }
        }

        // Free mint for whitelisted ppl
        uint32 freeWLMints = _getWLCount(msg.sender);
        if(freeWLMints > 0 && quantityToPay > 0) {
            uint32 freeWLMintsToConsume = uint64(freeWLMints) >= quantityToPay ? uint32(quantityToPay) : freeWLMints;
            quantityToPay -= freeWLMintsToConsume;
            _setWLCount(msg.sender, freeWLMints - freeWLMintsToConsume);
        }

        // If there are things to pay, ensure the main sale is active
        require(saleActive || quantityToPay == 0, "Sale active for free mint only");

        // Check price
        require(msg.value == quantityToPay * mintPrice, "Incorrect price");

        // Mint all
        _safeMint(msg.sender, quantity);
    }

    function _afterTokenTransfers(address from, address to, uint256 startTokenId, uint256 quantity) internal override {

        // If you minted a token ending with a "5", you get the free woodification of your NFT!
        if(from == address(0)) {
            for(uint tokenId = startTokenId; tokenId < startTokenId + quantity; tokenId++) {
                if(tokenId % 10 == 5) {
                    _setLasercuttingVouchers(to, _getLasercuttingVouchers(to) + 1);
                }
            }
        }
    }

    function buyLasercuttingVouchers(uint32 ticketCount) external payable {
        require(msg.value == lasercuttingVoucherPrice * ticketCount, "Incorrect price");
        require(lasercuttingVoucherSaleActive, "Lasercutting voucher sale not active yet");

        _setLasercuttingVouchers(msg.sender, _getLasercuttingVouchers(msg.sender) + ticketCount);
    } 

    function mintByOwner(uint64 quantity) public onlyOwner {
        _safeMint(msg.sender, quantity);
    }

    /**
     * The owner register a wood NFT he is doing for a given NFT.
     */
    function woodMintByOwner(uint256 tokenId, address initialOwner) public onlyOwner {
        require(_exists(tokenId), "Token does not exist");

        _safeWoodMint(tokenId, initialOwner);
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function hasVMountainBeenUsedForFreeMint(uint tokenId) public view returns (bool) {
        return _vMountainUsedForMint[tokenId];
    }

    function setBaseURI(string memory newBaseURI) public onlyOwner {
        __baseURI = newBaseURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return __baseURI;
    }

    function setWoodBaseURI(string memory newBaseURI) public onlyOwner {
        __woodBaseURI = newBaseURI;
    }

    function _woodBaseURI() internal view override returns (string memory) {
        return __woodBaseURI;
    }

    function gibWhitelist(address whitelistedAddress, uint32 whitelistedAmount) public onlyOwner {
        _setWLCount(whitelistedAddress, whitelistedAmount);
    }

    function hasWhitelistAmount(address addr) public view returns (uint32) {
        return _getWLCount(addr);
    }

    function gibLasercuttingVouchers(address whitelistedAddress, uint32 whitelistedAmount) public onlyOwner {
        _setLasercuttingVouchers(whitelistedAddress, whitelistedAmount);
    }

    function hasLasercuttingVoucherAmount(address addr) public view returns (uint32) {
        return _getLasercuttingVouchers(addr);
    }

    function setFreeSaleActive(bool active) public onlyOwner {
        freeSaleActive = active;
    }

    function setSaleActive(bool active) public onlyOwner {
        saleActive = active;
    }

    function setLasercuttingVoucherSaleActive(bool active) public onlyOwner {
        lasercuttingVoucherSaleActive = active;
    }

    function setLasercuttingVoucherPrice(uint price) public onlyOwner {
        lasercuttingVoucherPrice = price;
    }

    function setMintPrice(uint price) public onlyOwner {
        mintPrice = price;
    }

    function fetchSaleFunds() public onlyOwner {
        uint balance = address(this).balance;

        // Donation is 20% of all sales
        uint donation = balance / 5;
        uint remainingBalance = balance - donation;

        payable(donationAddress).transfer(donation);
        payable(msg.sender).transfer(remainingBalance);
    }

    // WL Count in left 32 bits of aux 64 bits
    function _getWLCount(address addr) internal view returns (uint32) {
        return uint32(_getAux(addr) / 2 ** 32);
    }
    function _setWLCount(address addr, uint32 wlCount) internal {
        _setAux(addr, uint64(_getLasercuttingVouchers(addr)) | (uint64(wlCount) * 2 ** 32));
    }

    // Lasercutting vouchers in right 32 bits of aux 64 bits
    function _getLasercuttingVouchers(address addr) internal view returns (uint32) {
        return uint32(_getAux(addr) % 2 ** 32);
    }
    function _setLasercuttingVouchers(address addr, uint32 voucherCount) internal {
        _setAux(addr, uint64(voucherCount) | (uint64(_getWLCount(addr)) * 2 ** 32));
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        owner = newOwner;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Caller is not the owner");
        _;
    }

    function isNotDelegated() private view {
        require(address(this) == contractAddress, "ser plz");
    }

    modifier noDelegateCall() {
        isNotDelegated();
        _;
    }
}