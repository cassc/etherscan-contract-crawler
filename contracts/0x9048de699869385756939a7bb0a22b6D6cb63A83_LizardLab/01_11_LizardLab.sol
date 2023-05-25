// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

 contract LizardLab is ERC721, Ownable {
    using Address for address;
    
    //some call it 'provenance'
    string public PROOF_OF_ANCESTRY;
    
    //where the wild things are (or will be)
    string public baseURI;

    //fives are good numbers... lets go with 5s
    uint256 public constant MAX_LIZARDS = 5000;
    uint256 public constant PRICE = 0.05 ether;
    uint256 public constant FOR_THE_WARCHEST = 100;
    uint256 public totalSupply;

    //do not get any ideas too soon
    bool public presaleActive = false;
    uint256 public presaleWave;
    bool public saleActive = false;

    //has [REDACTED] populated the war chest?
    bool public redactedClaimed = false;

    //who gets what
    address redLizard = 0xfb55e7ECbBA9715A9A9DD31DB3c777D8B98cB4Dc;
    address blueLizard = 0x87E9Ab2D6f4f744f36aad379f0157da30d3E2670;
    address greenLizard = 0x86bE508e686AB58ab9442c6A9800B1a941a6D60D;
    address warChest = 0x30471c24BDb0b9dDb75d9cA5D4E13049fc69FEfD;

    //some lizard keepers are...more privileged than others
    mapping (address => bool) public claimWhitelist;
    mapping (address => uint256) public presaleWhitelist;

    //there is a lot to unpack here
    constructor() ERC721("The Lizard Lab", "LIZRD") {   
    }
    
    //don't let them all escape!!  [REDACTED] needs them
    function recapture() public onlyOwner {
        require(bytes(PROOF_OF_ANCESTRY).length > 0,                "No distributing Lizards until provenance is established.");
        require(!redactedClaimed,                                   "Only once, even for you [REDACTED]");
        require(totalSupply + FOR_THE_WARCHEST <= MAX_LIZARDS,      "You have missed your chance, [REDACTED].");
        for (uint256 i = 0; i < FOR_THE_WARCHEST; i++) {
            _safeMint(warChest, totalSupply + i);
        }

        totalSupply += FOR_THE_WARCHEST;
        redactedClaimed = true;
    }

    //a freebie for you, thank you for your support
    function claim() public {
        require(presaleActive || saleActive,                        "A sale period must be active to claim");
        require(claimWhitelist[msg.sender],                         "No claim available for this address");
        require(totalSupply + 1 <= MAX_LIZARDS,                     "Claim would exceed max supply of tokens");

        _safeMint( msg.sender, totalSupply);
        totalSupply += 1;
        claimWhitelist[msg.sender] = false;
    }
    
    //thanks for hanging out..
    function mintPresale(uint256 numberOfMints) public payable {
        uint256 reserved = presaleWhitelist[msg.sender];
        require(presaleActive,                                      "Presale must be active to mint");
        require(reserved > 0,                                       "No tokens reserved for this address");
        require(numberOfMints <= reserved,                          "Can't mint more than reserved");
        require(totalSupply + numberOfMints <= MAX_LIZARDS,         "Purchase would exceed max supply of tokens");
        require(PRICE * numberOfMints == msg.value,                 "Ether value sent is not correct");
        presaleWhitelist[msg.sender] = reserved - numberOfMints;

        for(uint256 i; i < numberOfMints; i++){
            _safeMint( msg.sender, totalSupply + i );
        }

        totalSupply += numberOfMints;
    }
    
    //..and now for the rest of you
    function mint(uint256 numberOfMints) public payable {
        require(saleActive,                                         "Sale must be active to mint");
        require(numberOfMints > 0 && numberOfMints < 6,             "Invalid purchase amount");
        require(totalSupply + numberOfMints <= MAX_LIZARDS,         "Purchase would exceed max supply of tokens");
        require(PRICE * numberOfMints == msg.value,                 "Ether value sent is not correct");
        
        for(uint256 i; i < numberOfMints; i++) {
            _safeMint(msg.sender, totalSupply + i);
        }

        totalSupply += numberOfMints;
    }

    //these lizards are free
    function editClaimList(address[] calldata claimAddresses) public onlyOwner {
        for(uint256 i; i < claimAddresses.length; i++){
            claimWhitelist[claimAddresses[i]] = true;
        }
    }
    
    //somebody has to keep track of all of this
    function editPresaleList(address[] calldata presaleAddresses, uint256[] calldata amount) public onlyOwner {
        for(uint256 i; i < presaleAddresses.length; i++){
            presaleWhitelist[presaleAddresses[i]] = amount[i];
        }

        presaleWave = presaleWave + 1;
    }

    //[REDACTED] made me put this here..as to not..tinker with anything
    function setAncestry(string memory provenance) public onlyOwner {
        require(bytes(PROOF_OF_ANCESTRY).length == 0, "Now now, [REDACTED], do not go and try to play god...twice.");

        PROOF_OF_ANCESTRY = provenance;
    }

    //and a flip of the (small) switch
    function togglePresale() public onlyOwner {
        require(bytes(PROOF_OF_ANCESTRY).length > 0, "No distributing Lizards until provenance is established.");

        presaleActive = !presaleActive;
    }

    //the flip of a slightly larger switch
    function toggleSale() public onlyOwner {
        require(bytes(PROOF_OF_ANCESTRY).length > 0, "No distributing Lizards until provenance is established.");

        presaleActive = false;
        saleActive = !saleActive;
    }
    
    //for the grand reveal and where things are now.. where things will forever be.. lizards willing
    function setBaseURI(string memory uri) public onlyOwner {
        baseURI = uri;
    }
    
    //come have a looksy
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    //coins for the lizards
    function withdraw() public {
        uint256 balance = address(this).balance;
        payable(redLizard).transfer((balance * 400) / 1000);
        payable(greenLizard).transfer((balance * 400) / 1000);
        payable(blueLizard).transfer((balance * 200) / 1000);
    }    
}