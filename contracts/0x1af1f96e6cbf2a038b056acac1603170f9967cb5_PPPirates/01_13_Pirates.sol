// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

interface IBooty {
    function updateReward(address _from, address _to) external;
}

interface IKeys {
    function ownerOf(uint256 tokenId) external view returns(address);
}

contract PPPirates is ERC721A, Ownable {
    using SafeMath for uint256;
    
    //Sale States
    bool public isKeyMintActive = false;
    bool public isAllowListActive = false;
    bool public isPublicSaleActive = false;
    mapping (address => uint8) public allowList;
    
    //Contracts
    IKeys public Keys;
    mapping(uint256 => bool) public keyUsed;    
    IBooty public Booty;
    
    //Privates
    string private _baseURIextended;
    
    //Constants
    uint256 public constant MAX_SUPPLY = 10000;
    uint256 public constant PRICE_PER_TOKEN = 0.05 ether;
    uint256 public constant RESERVE_COUNT = 33;
    uint256 public constant CAPTAIN_CUTOFF = 1000;
    uint256 public constant FIRSTMATE_CUTOFF = 2500;
    
    //Special Pirates
    mapping (address => uint256) public captainBalance;
    mapping (address => uint256) public firstmateBalance;
    
    constructor() ERC721A("PixelPiracyPirates", "PPPIRATES", 5) {
    }

    //Key Minting
    function setKeys(address keysAddress) external onlyOwner {
        Keys = IKeys(keysAddress);
    }
    
    function setKeyMintActive(bool _isKeyMintActive) external onlyOwner {
        isKeyMintActive = _isKeyMintActive;
    }

    function mintWithKey(uint256[] calldata keyIds) external {
        uint256 ts = totalSupply();
        require(isKeyMintActive, "Key minting is not active");
        require(ts + keyIds.length <= MAX_SUPPLY, "Minting would exceed max tokens");

        Booty.updateReward(address(0), msg.sender);
        for (uint256 i = 0; i < keyIds.length; i++) {
            require(Keys.ownerOf(keyIds[i]) == msg.sender, "Cannot redeem key you don't own");
            require(keyUsed[keyIds[i]] == false, "Key has been used");
            require(keyIds[i] < 500, "Key Invalid");
            keyUsed[keyIds[i]] = true;
            if (ts + i < CAPTAIN_CUTOFF) {
                captainBalance[msg.sender]++;
            }
            else if (ts + i < FIRSTMATE_CUTOFF) {
                firstmateBalance[msg.sender]++;
            }
        }
        uint256 toMint = keyIds.length;
        while(toMint > 0){
            if(toMint > maxBatchSize) {
                _safeMint(msg.sender, maxBatchSize);
                toMint -= maxBatchSize;
            }
            else {
                _safeMint(msg.sender, toMint);
                toMint = 0;
            }
        }
    }
    //

    //Allowed Minting
    function setIsAllowListActive(bool _isAllowListActive) external onlyOwner {
        isAllowListActive = _isAllowListActive;
    }

    function setAllowList(address[] calldata addresses, uint8 numAllowedToMint) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            allowList[addresses[i]] = numAllowedToMint;
        }
    }

    function mintAllowList(uint8 numberOfTokens) external {
        uint256 ts = totalSupply();
        require(isAllowListActive, "Allow list is not active");
        require(ts + numberOfTokens <= MAX_SUPPLY, "Purchase would exceed max tokens");
        require(numberOfTokens <= allowList[msg.sender], "Exceeded max available to purchase");

        allowList[msg.sender] -= numberOfTokens;
        Booty.updateReward(address(0), msg.sender);
        for (uint256 i = 0; i < numberOfTokens; i++) {
            if (ts + i < CAPTAIN_CUTOFF) {
                captainBalance[msg.sender]++;
            }
            else if (ts + i < FIRSTMATE_CUTOFF) {
                firstmateBalance[msg.sender]++;
            }
        }
        _safeMint(msg.sender, numberOfTokens);
    }
    //
    
    //Public Minting
    function setPublicSaleState(bool newState) public onlyOwner {
        isPublicSaleActive = newState;
    }

    function mintNFT(uint numberOfTokens) public payable {
        uint256 ts = totalSupply();
        require(isPublicSaleActive, "Sale must be active to mint tokens");
        require(numberOfTokens <= maxBatchSize, "Exceeded max token purchase");
        require(ts + numberOfTokens <= MAX_SUPPLY, "Purchase would exceed max tokens");
        require(PRICE_PER_TOKEN * numberOfTokens <= msg.value, "Ether value sent is not correct");

        Booty.updateReward(address(0), msg.sender);
        for (uint256 i = 0; i < numberOfTokens; i++) {
            if (ts + i < CAPTAIN_CUTOFF) {
                captainBalance[msg.sender]++;
            }
            else if (ts + i < FIRSTMATE_CUTOFF) {
                firstmateBalance[msg.sender]++;
            }
        }
        _safeMint(msg.sender, numberOfTokens);
    }
    //
    
    //Booty
    function setBooty(address bootyAddress) external onlyOwner {
        Booty = IBooty(bootyAddress);
    }
    
    function transferFrom(address from, address to, uint256 tokenId) public override {
        Booty.updateReward(from, to);
        if (tokenId < CAPTAIN_CUTOFF) {
            captainBalance[from]--;
            captainBalance[to]++;
        }
        else if (tokenId < FIRSTMATE_CUTOFF) {
            firstmateBalance[from]--;
            firstmateBalance[to]++;
        }        
        ERC721A.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public override {
        Booty.updateReward(from, to);
        if (tokenId < CAPTAIN_CUTOFF) {
            captainBalance[from]--;
            captainBalance[to]++;
        }
        else if (tokenId < FIRSTMATE_CUTOFF) {
            firstmateBalance[from]--;
            firstmateBalance[to]++;
        }
        ERC721A.safeTransferFrom(from, to, tokenId, data);
    }
    //

    //Overrides
    function setBaseURI(string memory baseURI_) external onlyOwner() {
        _baseURIextended = baseURI_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }
    //

    function reserve() public onlyOwner {
        require(totalSupply() == 0, "Tokens already reserved");
        uint256 toReserve = RESERVE_COUNT;
        while(toReserve > 0){
            if(toReserve > maxBatchSize) {
                _safeMint(msg.sender, maxBatchSize);
                toReserve -= maxBatchSize;
            }
            else {
                _safeMint(msg.sender, toReserve);
                toReserve = 0;
            }
        }
    }
    
    //Withdraw balance
    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
    //
}