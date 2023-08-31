// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./Peach.sol";

 contract OneGokuClub is ERC721, Ownable {
    using Address for address;
    using Strings for uint256;
    
    string public baseURI;

    Peach public peach;

    uint256 public constant EMISSION_RATE = uint256(40 * 1e18) / 86400;
    // 40 PEACH / Goku / 86400 / 24 hrs

    uint256 public constant MAX_GOKU = 1111;
    uint256 public constant TEAM_SUPPLY = 4;
    uint256 public constant MAX_WHITELIST = 2;
    uint256 public constant MAX_PUBLIC = 3;
    uint256 public totalSupply;
    uint256 public freeMintCount;

    string public constant BASE_EXTENSION = ".json";

    uint256 public PRICE = 0.06 ether;

    bool public presaleActive = false;
    bool public saleActive = false;
    bool public teamClaimed = false;

    mapping (address => uint256) public freeWhitelist;
    mapping (address => uint256) public presaleWhitelist;
    mapping (uint256 => uint256) public claimTime;

    constructor() ERC721("One Goku Club", "GOKU") { 
    }
    
    /*
        Goku minting contract requirements
        1. Free mints for certain members (Could be 1 or 2, max 55 only)
        2. Admin mint
        3. Whitelist mint (All max 2)
        4. Public sale (All max 3)
     */

    function adminMint() public onlyOwner {
        require(totalSupply + TEAM_SUPPLY <= MAX_GOKU,      "You have missed your chance");
        require(!teamClaimed,                               "Only once, even for you");
        for (uint256 i = 0; i < TEAM_SUPPLY; i++) {
            _safeMint(msg.sender, totalSupply + i);
        }

        totalSupply += TEAM_SUPPLY;
        teamClaimed = true;
    }

    function freeMint(uint256 numberOfMints) public {
        uint256 reserved = freeWhitelist[msg.sender];
        require(presaleActive || saleActive,                        "A sale period must be active to mint");
        require(numberOfMints <= reserved,                          "Can't mint more than reserved");
        require(totalSupply + numberOfMints <= MAX_GOKU,            "Claim would exceed max supply of tokens");
        freeWhitelist[msg.sender] = reserved - numberOfMints;

        for(uint256 i; i < numberOfMints; i++){
            _safeMint( msg.sender, totalSupply + i );
        }

        freeMintCount -= numberOfMints;
        totalSupply += numberOfMints;
    }
    
    function presaleMint(uint256 numberOfMints) public payable {
        uint256 reserved = presaleWhitelist[msg.sender];
        require(presaleActive || saleActive,                                    "A sale period must be active to mint");
        require(numberOfMints <= reserved,                                      "Can't mint more than reserved");
        require(totalSupply + numberOfMints + freeMintCount <= MAX_GOKU,        "Purchase would exceed max supply of tokens");
        require(PRICE * numberOfMints == msg.value,                             "Ether value sent is not correct");
        presaleWhitelist[msg.sender] = reserved - numberOfMints;

        for(uint256 i; i < numberOfMints; i++){
            _safeMint( msg.sender, totalSupply + i );
        }

        totalSupply += numberOfMints;
    }
    
    function mint(uint256 numberOfMints) public payable {
        require(saleActive,                                                     "Sale must be active to mint");
        require(numberOfMints > 0 && numberOfMints <= MAX_PUBLIC,               "Invalid purchase amount");
        require(totalSupply + numberOfMints + freeMintCount <= MAX_GOKU,        "Purchase would exceed max supply of tokens");
        require(PRICE * numberOfMints == msg.value,                             "Ether value sent is not correct");
        
        for(uint256 i; i < numberOfMints; i++) {
            _safeMint(msg.sender, totalSupply + i);
        }

        totalSupply += numberOfMints;
    }

    function editPeach(Peach _peach) public onlyOwner {
        peach = _peach;
    }

    function editFreeList(address[] calldata freeAddresses, uint256[] calldata amount) public onlyOwner {
        for(uint256 i; i < freeAddresses.length; i++){
            freeWhitelist[freeAddresses[i]] = amount[i];
            freeMintCount += amount[i];
        }
    }
    
    function editPresaleList(address[] calldata presaleAddresses) public onlyOwner {
        for(uint256 i; i < presaleAddresses.length; i++){
            presaleWhitelist[presaleAddresses[i]] = MAX_WHITELIST;
        }
    }

    function togglePresale() public onlyOwner {
        presaleActive = !presaleActive;
    }

    function toggleSale() public onlyOwner {
        presaleActive = false;
        saleActive = !saleActive;
        PRICE = 0.07 ether;
    }
    
    function setBaseURI(string memory uri) public onlyOwner {
        baseURI = uri;
    }
    
    function _safeMint(address to, uint256 tokenId) internal override {
        claimTime[tokenId] = block.timestamp;
        _safeMint(to, tokenId, "");
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function tokenURI(uint256 _id) public view virtual override returns (string memory) {
         require(
            _exists(_id),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0
            ? string(abi.encodePacked(currentBaseURI, _id.toString(), BASE_EXTENSION))
            : "";
    }

    function resetFreeMintCount() public onlyOwner {
        freeMintCount = 0;
    }

    function claim(uint256[] calldata tokenIds) public {
        require(tx.origin == msg.sender, "What you doing?");
        uint256 total = 0;
        for(uint256 i; i < tokenIds.length; i++){
            require(ownerOf(tokenIds[i]) == msg.sender, "Not owner");
            total += (block.timestamp - claimTime[tokenIds[i]]) * EMISSION_RATE;
            claimTime[tokenIds[i]] = block.timestamp;
        }
        peach.mintToken(msg.sender, total);
    }    

    function withdraw(address _address) public onlyOwner {
        uint256 balance = address(this).balance;
        payable(_address).transfer(balance);
    }    
}