// SPDX-License-Identifier: MIT

// Developed By SuperNormal Atelier

pragma solidity ^0.8.17;

import "./ERC721A.sol";
import "@openzeppelin/[email protected]/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./DefaultOperatorFilterer.sol";
import "./OperatorFilterer.sol";


contract TreyRatcliff1k1k is ERC721A, Ownable, DefaultOperatorFilterer, ReentrancyGuard {
    using SafeMath for uint256;

    constructor() ERC721A("TREY RATCLIFF: 1K1K PROJECT", "ONEK") {
        
    }

    uint256 public immutable MAX_SUPPLY = 1000;
    uint256 public immutable TEAM_SUPPLY = 55;
    uint256 public immutable WL_SUPPLY = 945;

    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public override payable onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public override payable onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public override payable onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }
    

    
    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }



// Premint AllowList

// WL variables and functions
mapping(address => bool) public allowlist;
uint256 public WLedPrice = 0;
bool isWLedRunning = false;
uint256 public mintedInWLed = 0;
uint256 public wlStartTime;

mapping(address => uint256) public proofMints;
mapping(address => uint256) public moonbirdsMints;
mapping(address => uint256) public premintMints;

mapping(address => uint8) public allowlistGroups;

uint8 constant PROOF = 1;
uint8 constant MOONBIRDS = 2;
uint8 constant PREMINT = 3;

uint8 constant PROOF_LIMIT = 3;
uint8 constant MOONBIRDS_LIMIT = 2;
uint8 constant PREMINT_LIMIT = 1;

function set_WLedPrice(uint256 _price) public onlyOwner {
    WLedPrice = _price;
}

function runWLed() public onlyOwner {
    require(WLedPrice != 0, "Set the allowlist sale price!");
    isWLedRunning = true;
    wlStartTime = block.timestamp;
}

function safeMintWL(uint256 numTokens) external payable callerIsUser {
    require(WLedPrice != 0, "Allowlist sale has not begun yet!");
    require(isWLedRunning == true, "Allowlist sale is ended!");
    require(checkMintWindow(), "Not in allowed time window for minting!");

    uint8 group = allowlistGroups[msg.sender];
    uint256 mints;
    if (group == PROOF) {
        mints = proofMints[msg.sender];
    } else if (group == MOONBIRDS) {
        mints = moonbirdsMints[msg.sender];
    } else if (group == PREMINT) {
        mints = premintMints[msg.sender];
    } else {
        require(false, "Not eligible for allowlist mint!");
    }

    require(mints + numTokens <= groupLimit(group), "Maximum number of mints exceeded for group!");
    require(totalSupply() + numTokens <= MAX_SUPPLY, "Reached max supply!");
    require(mintedInWLed + numTokens <= WL_SUPPLY + TEAM_SUPPLY, "Reached max supply!");
    require(msg.value >= WLedPrice * numTokens, "Not enough ether sent!");

    if (group == PROOF) {
        proofMints[msg.sender] = proofMints[msg.sender].add(numTokens);
    } else if (group == MOONBIRDS) {
        moonbirdsMints[msg.sender] = moonbirdsMints[msg.sender].add(numTokens);
    } else if (group == PREMINT) {
        premintMints[msg.sender] = premintMints[msg.sender].add(numTokens);
    }
    mintedInWLed = mintedInWLed.add(numTokens);
    _safeMint(msg.sender, numTokens);
}


function addToAllowlist(address[] memory addresses, uint8 group) external onlyOwner {
    for (uint256 i = 0; i < addresses.length; i++) {
        allowlistGroups[addresses[i]] = group;
    }
}

function endWLed() public onlyOwner {
    isWLedRunning = false;
}

function checkMintWindow() private view returns (bool) {
    uint256 currentTime = block.timestamp;
    uint256 startTime = wlStartTime;
    if (currentTime < startTime + 1 hours) {
        return allowlistGroups[msg.sender] == PROOF;
    } else if (currentTime < startTime + 2 hours) {
        return allowlistGroups[msg.sender] == PROOF || allowlistGroups[msg.sender] == MOONBIRDS;
    } else {
        return true;
    }
}

function groupLimit(uint8 group) private pure returns (uint8) {
  if (group == PROOF) {
    return PROOF_LIMIT;
  } else if (group == MOONBIRDS) {
    return MOONBIRDS_LIMIT;
  } else if (group == PREMINT) {
    return PREMINT_LIMIT;
  } else {
    return 0;
  }
}


// Team Reserve Mint variables and functions
uint256 public teamReserveMintPrice = 0;
uint256 public teamReserveMintLimit = 0;
bool isTeamReserveMintRunning = false;

function isAuthorizedMinter(address _address) public pure returns (bool) {
    return _address == 0xd54B4Fde949570F18F1C13952a538a1525b6CaB2;
}

function set_teamReserveMintPrice (uint256 _price) public onlyOwner{
    teamReserveMintPrice = _price;
}

function set_teamReserveMintLimit (uint256 _limit) public onlyOwner{
    teamReserveMintLimit = _limit;
}

function runTeamReserveMint() public onlyOwner{
    require(teamReserveMintPrice != 0, "Set the team reserve mint price!");
    isTeamReserveMintRunning = true;
}

function safeMintTRM(uint256 amount) external payable nonReentrant callerIsUser {
    require(isAuthorizedMinter(msg.sender), "Unauthorized minter!");
    require(amount > 0, "Cannot mint zero or negative tokens!");
    require(teamReserveMintPrice != 0, "Team reserve mint has not begun yet!");
    require(isTeamReserveMintRunning==true,"Team reserve mint is ended!");
    require(totalSupply() + amount <= MAX_SUPPLY, "Not enough items left!");
    require(msg.value >= (amount * teamReserveMintPrice), "Not enough ether sent!");
    require(amount <= teamReserveMintLimit, "Cannot mint more than the limit!");
    _safeMint(msg.sender, amount);
}

function endTeamReserveMint () public onlyOwner{
    isTeamReserveMintRunning=false;
}



// Public sale variables and functions
    uint256 public publicSalePrice = 0;
    bool isPublicSaleRunning = false;
    function set_publicSalePrice (uint256 _price) public onlyOwner{
        publicSalePrice = _price;
    }
    function runPublicSale() public onlyOwner{
        require(publicSalePrice != 0, "Set the public sale price!");
        isPublicSaleRunning = true;
    }
    function safeMintPS(uint256 amount) external payable nonReentrant callerIsUser{
        require(publicSalePrice != 0, "Public sale has not begun yet!");
        require(isPublicSaleRunning==true,"Public sale is ended!");
        require(totalSupply() + amount <= MAX_SUPPLY, "Not enough items left!");
        require(msg.value >= (amount * publicSalePrice), "Not enough ether sent!");
        _safeMint(msg.sender, amount);
    }
    function endPublicSale () public onlyOwner{
        isPublicSaleRunning=false;
    }


// metadata URI

bool public revealed = false;

string private _baseTokenURI;

string private notRevealedUri;

function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
    notRevealedUri = _notRevealedURI;
}

function revealItems() external onlyOwner {
    revealed = true;
}

function _baseURI() internal view virtual override returns (string memory) {
    return _baseTokenURI;
}

function setBaseURI(string memory baseURI) external onlyOwner {
    _baseTokenURI = baseURI;
}

function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

    string memory baseURI = _baseURI();

    if (revealed == false) {
        return notRevealedUri;
    }

    return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, _toString(tokenId))) : '';
}

//withdrawal

function withdraw() external onlyOwner {
  uint256 balance = address(this).balance;
  uint256 TreyRatcliffAmount = balance.mul(925).div(1000); // 92.5% of the balance will go to TreyRatcliff's wallet
  uint256 SuperNormalTeamAmount = balance.mul(75).div(1000); // 7.5% of the balance will go to SuperNormalTeam's wallet

  address payable TreyRatcliffWallet = payable(0x8A2Cc795646F64C06eB4AB060F03271f13C080D1);
  address payable SuperNormalTeamWallet = payable(0xb2dC04AcC5342D14833fEbfc2C500eC3E3eC53Ba);
 

  TreyRatcliffWallet.transfer(TreyRatcliffAmount);
  SuperNormalTeamWallet.transfer(SuperNormalTeamAmount);
  
}




}