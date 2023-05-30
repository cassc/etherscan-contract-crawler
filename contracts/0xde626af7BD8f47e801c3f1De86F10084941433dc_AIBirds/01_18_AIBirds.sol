// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/*

           _____   ____  _         _     
     /\   |_   _| |  _ \(_)       | |    
    /  \    | |   | |_) |_ _ __ __| |___ 
   / /\ \   | |   |  _ <| | '__/ _` / __|
  / ____ \ _| |_  | |_) | | | | (_| \__ \
 /_/    \_\_____| |____/|_|_|  \__,_|___/
               By Computer                                    

All 10,000 Moonbirds brought to life with AI

https://aibirds.art/
https://twitter.com/ComputerCrypto

kkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkxxxxxkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkk
kkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkxd:,,,:dxkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkk
kkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkxdc;;,;;,':dxkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkk
kkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkc.lOl,,,''..lkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkk
kkkkkkkkkkkkkkkkkkkkkkkkkkkkkxl;'oOdc:,','.;lxkkkkkkkkkkkkkkkkkkkkkkkkkkkkk
kkkkkkkkkkkkkkkkkkkkkkkkkkkkOo..:cc,.'',:;'..oOkkkkkkkkkkkkkkkkkkkkkkkkkkkk
kkkkkkkkkkkkkkkkkkkkkkkkkkkxlcl:,'....',::;'.,lxkkkkkkkkkkkkkkkkkkkkkkkkkkk
kkkkkkkkkkkkkkkkkkkkkkkkkkkd''oc.....'',,::;'.'dOkkkkkkkkkkkkkkkkkkkkkkkkkk
kkkkkkkkkkkkkkkkkkkkkkkkkxc,,,''..'coc;'';cdd;',cxkkkkkkkkkkkkkkkkkkkkkkkkk
kkkkkkkkkkkkkkkkkkkkkkkkkd,.;;'''..;:;,''cx0KOl.,dkkkkkkkkkkkkkkkkkkkkkkkkk
kkkkkkkkkkkkkkkkkkkkkkkkc',;;;clc;.'''''',:dOdc,.'ckkkkkkkkkkkkkkkkkkkkkkkk
kkkkkkkkkkkkkkkkkkkkkkxo;.,:ol,''..'''''''';cc:;'.;oxkkkkkkkkkkkkkkkkkkkkkk
kkkkkkkkkkkkkkkkkkkkkkl.':''cc:;;'.''''''''',:c:;'..lkkkkkkkkkkkkkkkkkkkkkk
kkkkkkkkkkkkkkkkkkkkxl;'','..,ccc;'''''''''',:cc:;;:clxkkkkkkkkkkkkkkkkkkkk
kkkkkkkkkkkkkkkkkkkOo..:,.........''''''':l:,,;:ldO0;.oOkkkkkkkkkkkkkkkkkkk
kkkkkkkkkkkkkkkkkkxl;,,,::,....,:;''''''':l:'',:ldO0c.,lxkkkkkkkkkkkkkkkkkk
kkkkkkkkkkkkkkkkkkd'.';coxo:'..';,............'''';:,..'dkkkkkkkkkkkkkkkkkk
kkkkkkkkkkkkkkkkxc'....',','............................'cxkkkkkkkkkkkkkkkk
kkkkkkkkkkxddddc,..........................',,,,,,,,,'....,cddddxkkkkkkkkkk
kkkkkkkkxl,....','................''.........''''........','....,lxkkkkkkkk
kkkkxoll,..............,:c:;;;;;;ldxxol:,',;lxxdl:;;;,............,looxkkkk
kkkko...............';ldolccccccccokKKX0dod0XKOoccccc::;;'............okkkk
kkkkd:;;;;........';lddlcldkkxxkOdccdkKNNNNNKdccoxxkxkOxl;.......;;;;:dkkkk
kkkkkkkkOkl::::'..,oxxl;lxkdclO0Okx:cd0NNNNNKc;dxxl:xK0Okl,;::::lkkkkkkkkkk
kkkkkkkkkkkkOd:'..,oxxl;lxko'.:oxkx::d00doool;:dkx:.,ldxxl;lkkkkkkkkkkkkkkk
kkkkkkkkkkkkkl..'',lxxl;oO0Oxddk00kc;:cc:cloo;:k00kddxO0Oo;lkkkkkkkkkkkkkkk
kkkkkkkkkkkkkl..''',:ddollOXXK000xldoc;;coxkd:;cxKXXK00ko;.ckkkkkkkkkkkkkkk
kkkkkkkkkkkkkl..'''';ldxddoooollokKXKOkl;cxdoclOOdooooldOl.:kkkkkkkkkkkkkkk
kkkkkkkkkkkkkl..'''''':ldxO000KXXXNNNXXk;:d::kXXXXXKK00Od;.:kkkkkkkkkkkkkkk
kkkkkkkkkkkkkl..''''''',:llodk0KKXNNNNN0occco0NNXKK0xllc,..:kkkkkkkkkkkkkkk
kkkkkkkkkkkkOl..'''''',;;,,;clcoxO0000000xlx000Kklcc;,,,'..:kkkkkkkkkkkkkkk
kkkkkkkkkkkxc,..'''''',;:::;;,,;cccccccccccccccc:,,,;::;'..:kkkkkkkkkkkkkkk
kkkkkkkkkkko..''''''''',;::::::;,,,,,,,,,,,,,,,,;;:::;:;;'.':dkkkkkkkkkkkkk
kkkkkkkkkkko..'''''''''',;::;:::::::::::::::::::::::::::;;'..lkkkkkkkkkkkkk
kkkkkkkkkkko..'''''''''',;::;;;;;;;;;;;;;;;;;;;;:::::::::,'..lkkkkkkkkkkkkk
kkkkkkkkkkko..'''''''''',;::;:::::::::::::::::::::::;;:::,'..lkkkkkkkkkkkkk
kkkkkkkkkkko..'''''''''',;::;::::::::::::::::::::::::::::;'..lkkkkkkkkkkkkk
kkkkkkkkkkOo..'''''''''',;:::::::::::::::::::::::::::::::;'..lkkkkkkkkkkkkk

*/

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./AIBirdFeed.sol";

contract AIBirds is ERC721A, Ownable, ReentrancyGuard {
    
    uint256 public presalePaidCounter = 0;
    mapping(address => uint256) public presaleWalletTracker;
    mapping(uint256 => bool) public birdFeedTracker;

    event UsedBirdFeed(uint256 tokenId, uint256 action);

    constructor() ERC721A("AI Birds by Computer", "AIBIRDS") {
        _mintTokens(msg.sender, 50);
    }

    function feedBird(uint256 tokenId, uint256 action) external nonReentrant {
        require(feedEnabled, "Your bird doesn't want to eat yet");
        require(birdFeedTracker[tokenId] == false, "Bird has already been fed");
        require(msg.sender == ownerOf(tokenId), "You don't own this bird");
        birdFeed.burn(msg.sender, 0, 1);
        birdFeedTracker[tokenId] = true;
        emit UsedBirdFeed(tokenId, action);
    }
    
    function mint(uint256 quantity) external payable nonReentrant {
        require(saleState == SaleState.PUBLIC, "Public sale is not active");
        require(publicPrice * quantity == msg.value, "Incorrect ETH amount");
        require(quantity < _publicTransactionLimit, "Over transaction limit");
        _mintTokens(msg.sender, quantity);
    }
    
    function presalePhase1(uint256 totalFree, uint256 totalPaid, bytes32[] memory proof) external payable nonReentrant {
        
        require(saleState != SaleState.OFF, "Presale phase 1 is not active");
        require(presalePrice * totalPaid == msg.value, "Incorrect ETH amount");
        require(totalFree != 0, "You are not eligible to mint during presale phase 1");
        require(MerkleProof.verify(proof, merkleRoot, keccak256(abi.encodePacked(msg.sender, totalFree))), "Invalid proof");
        
        uint256 presaleMints = presaleWalletTracker[msg.sender];
        require(((presaleMints == 0 ? totalPaid : presaleMints + totalPaid - totalFree) < _presalePaidLimit), "Exceeds presale limit");
        
        require(presalePaidCounter + totalPaid < _totalPresalePaidAvailable, "No more presale paid mints available");
        
        uint256 quantity = presaleMints == 0 ? totalFree + totalPaid : totalPaid;
        require(quantity != 0, "Free mint already claimed");
        
        presaleWalletTracker[msg.sender] += quantity;
        presalePaidCounter += totalPaid;

        _mintTokens(msg.sender, quantity);
    }

    function presalePhase2(uint256 quantity, bytes32[] memory proof) external payable nonReentrant {
        require(saleState > SaleState.PRESALE_1, "Presale phase 2 is not active");
        require(presalePrice * quantity == msg.value, "Incorrect ETH amount");
        require(MerkleProof.verify(proof, merkleRoot, keccak256(abi.encodePacked(msg.sender, uint256(0)))), "Invalid proof");
        require(presaleWalletTracker[msg.sender] + quantity < _presalePaidLimit, "Exceeds presale limit");
        require(presalePaidCounter + quantity < _totalPresalePaidAvailable, "No more presale paid mints available");

        presaleWalletTracker[msg.sender] += quantity;
        presalePaidCounter += quantity;

        _mintTokens(msg.sender, quantity);
    }

    function gift(address addr, uint256 quantity) external onlyOwner {
        _mintTokens(addr, quantity);
    }

    function _mintTokens(address addr, uint256 quantity) internal {
        require(quantity > 0, "Must be greater than 0");
        uint start = _totalMinted();
        uint end = start + quantity;
        require(end < _maxSupply, "Exceeds supply");

        if(address(birdFeed) != address(0)) {
            uint birdFeedQuantity = (end / 10) - (start / 10);
            if(birdFeedQuantity > 0) {
                birdFeed.mint(addr, birdFeedQuantity);
            }
        }

        _mint(msg.sender, quantity);
    }

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "Token does not exist.");
        return bytes(baseURI).length > 0 ? string(
            abi.encodePacked(
                baseURI,
                Strings.toString(_tokenId),
                ".json"
            )
        ) : "";
    }

    uint256 private _publicTransactionLimit = 11; // 10
    function publicTransactionLimit() external view returns (uint256) {
        return _publicTransactionLimit - 1;
    }
    function setPublicTransactionLimit(uint256 publicTransactionLimit_) external onlyOwner {
        _publicTransactionLimit = publicTransactionLimit_ + 1;
    }

    uint256 private _presalePaidLimit = 5; // 4 
    function presalePaidLimit() external view returns (uint256) {
        return _presalePaidLimit - 1;
    }
    function setPresalePaidLimit(uint256 presalePaidLimit_) external onlyOwner {
        _presalePaidLimit = presalePaidLimit_ + 1;
    }

    uint private constant _maxSupply = 10_001; // 10,000
    function maxSupply() external pure returns (uint256) {
        return _maxSupply - 1;
    }

    uint256 private _totalPresalePaidAvailable = 1; // 0
    function totalPresalePaidAvailable() external view returns (uint256) {
        return _totalPresalePaidAvailable - 1;
    }
    function setTotalPresalePaidAvailable(uint256 totalPresalePaidAvailable_) external onlyOwner {
        _totalPresalePaidAvailable = totalPresalePaidAvailable_ + 1;
    }

    uint256 public publicPrice = 0.025 ether;
    function setPublicPrice(uint256 price_) external onlyOwner {
        publicPrice = price_;
    }

    uint256 public constant presalePrice = 0.02 ether;

    bytes32 public merkleRoot;
    function setMerkleRoot(bytes32 merkleRoot_) external onlyOwner {
        merkleRoot = merkleRoot_;
    }

    string public baseURI = "";
    function setBaseUri(string memory uri_) external onlyOwner {
        baseURI = uri_;
    }

    enum SaleState { OFF, PRESALE_1, PRESALE_2, PUBLIC }
    SaleState public saleState = SaleState.OFF;
    function setSaleState(SaleState saleState_) external onlyOwner {
        saleState = saleState_;
    }

    bool public feedEnabled = false;
    function toggleFeedEnabled() external onlyOwner {
        feedEnabled = !feedEnabled;
    }

    AIBirdFeed public birdFeed;
    function setBirdFeed(address addr) external onlyOwner {
        birdFeed = AIBirdFeed(addr);
    }

    function presalePaidMintsRemaining() external view returns (uint256) {
       if(_totalPresalePaidAvailable > presalePaidCounter) {
            return _totalPresalePaidAvailable - presalePaidCounter - 1;
        } else {
            return 0;
        }
    }

    function releaseFunds() external onlyOwner {
        (bool sent, bytes memory data) = payable(0xBc3B2d37c5B32686b0804a7d6A317E15173d10A7).call{value: address(this).balance}("");
        require(sent, "Failed to release funds");
    }
}