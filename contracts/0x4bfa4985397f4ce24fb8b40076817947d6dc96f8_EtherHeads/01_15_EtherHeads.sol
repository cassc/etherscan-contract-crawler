// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC721/ERC721.sol"; 
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "contracts/recovery.sol";

contract EtherHeads is Ownable, ERC721Enumerable, recovery{

    uint256 public cost;  
    uint256 public cost50;
    uint256 public cost90;
    string private _baseTokenURI;    
    string public EH_PROVENANCE = "d9df370a6f4ce906e17dbf85e66df87ea9eb909ecefff9d4b7c172f7ac7609d5"; 
    uint256 public constant maxSupply = 10000;
    uint256 public maxMintAmount = 20;
    uint256 public maxReedemAmount = 10;
    bool public isSaleActive = false;  // can mint
    bool public earlyIsActive = true;  // can claim free EH for EC
    bool public canList = false;
    IERC721Enumerable public EtherCards;

    // EC Claim Records
    uint256                  public maxFree = 1000;
    uint256                  public freeAllocation; // Number of free cards taken so far
    mapping(address => uint) public freeCardsTaken; // EC holders who have claimed
    mapping(uint256 => bool) public freeClaimed;    // EC tokenIDS already used
    uint256                  public maxP50 = 1000;
    uint256                  public p50Allocation; // Number of 50% cards taken so far
    mapping(address => uint) public p50CardsTaken; // EC holders who have claimed
    address payable public wallet; 
    event NothingToRedeem();

    constructor(
        string memory _initBaseURI,
        IERC721Enumerable _ethercards,
        address payable _wallet
    ) ERC721("EtherHeads", "ETHEAD") {
        setBaseURI(_initBaseURI);
        EtherCards  = _ethercards;
        setWallet(_wallet);
        setCost(0.05 ether);
    }

    //SHA256(concat(for all images SHA256(images)) 
    function setProvenanceHash(string memory _provenanceHash) public onlyOwner {
        EH_PROVENANCE = _provenanceHash;
    }

    function _baseURI() internal view virtual override(ERC721) returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string memory _baseU) public onlyOwner {
        _baseTokenURI = _baseU;
    }

    function setCost(uint256 _newCost) public onlyOwner {
        cost   = _newCost;
        cost50 = _newCost / 2;
        cost90 = (_newCost * 9) / 10;
    }

    function setMaxMintAmount(uint256 _newmaxMintAmount) public onlyOwner {
        maxMintAmount = _newmaxMintAmount;
    }
    
    function setWallet(address payable _wallet) public onlyOwner {
        wallet = _wallet;
    }

    function setCanList(bool _state) public onlyOwner {
        canList = _state;
    }

    function setSaleActive(bool _state) public onlyOwner {
        isSaleActive = _state;
    }

    function setEarlyActive(bool _state) public onlyOwner {
        earlyIsActive = _state;
    }

    function isEligible(uint256 tokenId, mapping(uint256 => bool) storage claimed ) private view returns (bool) {
        return ((!claimed[tokenId]) && (EtherCards.ownerOf(tokenId)==msg.sender));
    }

    function setApprovalForAll(address operator, bool approved) public virtual override {    
        require(canList, "Cannot list at this time");
        super.setApprovalForAll(operator, approved);
    }

    function redeemableTokensByOwner(address _owner) external view returns(uint256[] memory ) {
        uint256 tokenCount = EtherCards.balanceOf(_owner);
        if (tokenCount == 0) {
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 index;
            uint256 idx;
            for (index = 0; index < tokenCount; index++) {
                uint256 tokenId = EtherCards.tokenOfOwnerByIndex(_owner, index);
                if(!freeClaimed[tokenId]) {
                   result[idx] = tokenId;
                   idx++;
                }
            }
            uint256[] memory result2 = new uint256[](idx);
            for (index = 0; index < idx; index++) {
                result2[index] = result[index];
            }
            return result2;
        }
    }

    function eligibleCards(uint256[] memory tokenIds, mapping(uint256 => bool) storage claimed) private view returns (uint256) {
        require(earlyIsActive, "Early Access is not active");
        uint256 count;
        for (uint j = 0; j < tokenIds.length; j++) {
            uint256 tid = tokenIds[j];
            if ( isEligible(tid,claimed)) {
                count++;
            }
        }
        require(count <= maxReedemAmount, "Exceeds maximum tokens you can claim in a single transaction");  // 10 per transaction
        return count;
    }

    function earlyFreeAccessByCard(uint256[] memory tokenIds) public {
        uint256 _redeemAmount = eligibleCards(tokenIds, freeClaimed);
        require(_redeemAmount > 0,"Nothing to redeem");
        require(freeCardsTaken[msg.sender] + _redeemAmount <= maxReedemAmount, "You can claim max 10 free EtherHeads");
        freeAllocation += _redeemAmount;
        require(freeAllocation <= maxFree,"This exceeds the number of free cards available");
        uint256 mintIndex = totalSupply();
        uint256 allocated;            
        for (uint i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            if (isEligible(tokenId,freeClaimed)) {
                freeClaimed[tokenId] = true;
                allocated += 1;             
                _safeMint(msg.sender, mintIndex + allocated);                
            }
        }
        assert(_redeemAmount == allocated);
        freeCardsTaken[msg.sender] += allocated;
    }

    function early50AccessByCard(uint256 _redeemAmount) public payable {
        require(EtherCards.balanceOf(msg.sender) > 0,"you do not hold any Ether Cards");
        require(earlyIsActive, "Early Access is not active");
        p50CardsTaken[msg.sender] += _redeemAmount;
        require(p50CardsTaken[msg.sender] <= maxReedemAmount, "You can buy max 10 EtherHeads at 50% discount");
        require(msg.value >= _redeemAmount * cost50,"Insufficient ETH received");
        p50Allocation += _redeemAmount;
        require(p50Allocation <= maxP50,"This exceeds the number of free cards available");
        uint256 mintIndex = totalSupply();           
        for (uint i = 0; i < _redeemAmount; i++) {        
            _safeMint(msg.sender, mintIndex + i + 1);                
        }
        wallet.transfer(address(this).balance);
    }

    function mint(address _to, uint256 _mintAmount) public payable {
        uint mintIndex = super.totalSupply();
        require(_mintAmount > 0, "You cannot by ZERO EthHeads");
        require(_mintAmount <= maxMintAmount, "Exceeds maximum tokens you can purchase in a single transaction");
        require(mintIndex + _mintAmount <= maxSupply, "Exceeds maximum tokens available for purchase");        
        if (msg.sender != owner()) {
            if(earlyIsActive) {
                require(EtherCards.balanceOf(msg.sender)> 0,"You do not hold an Ether Card");
                require(msg.value >= cost90 * _mintAmount, "Ether value sent is not correct"); 
            } else {
                require(isSaleActive, "Sale is not active" );       
                require(msg.value >= cost * _mintAmount, "Ether value sent is not correct"); 
            }
        }        
        for (uint256 i = 1; i <= _mintAmount; i++) {
            _safeMint(_to, mintIndex + i);
        }
        wallet.transfer(address(this).balance);        
    }

    function tokensByOwner(address _owner) external view returns(uint256[] memory ) {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 index;
            for (index = 0; index < tokenCount; index++) {
                result[index] = tokenOfOwnerByIndex(_owner, index);
            }
            return result;
        }
    }
}