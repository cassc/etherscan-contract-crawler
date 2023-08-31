// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.19;

/*
                                                         ,--,                
                                                      ,---.'|  .--,-``-.     
           .---.    ,----..   ,-.----.       ,---,    |   | : /   /     '.   
          /. ./|   /   /   \  \    /  \    .'  .' `\  :   : |/ ../        ;  
      .--'.  ' ;  /   .     : ;   :    \ ,---.'     \ |   ' :\ ``\  .`-    ' 
     /__./ \ : | .   /   ;.  \|   | .\ : |   |  .`\  |;   ; ' \___\/   \   : 
 .--'.  '   \' ..   ;   /  ` ;.   : |: | :   : |  '  |'   | |__    \   :   | 
/___/ \ |    ' ';   |  ; \ ; ||   |  \ : |   ' '  ;  :|   | :.'|   /  /   /  
;   \  \;      :|   :  | ; | '|   : .  / '   | ;  .  |'   :    ;   \  \   \  
 \   ;  `      |.   |  ' ' ' :;   | |  \ |   | :  |  '|   |  ./___ /   :   | 
  .   \    .\  ;'   ;  \; /  ||   | ;\  \'   : | /  ; ;   : ; /   /\   /   : 
   \   \   ' \ | \   \  ',  / :   ' | \.'|   | '` ,/  |   ,/ / ,,/  ',-    . 
    :   '  |--"   ;   :    /  :   : :-'  ;   :  .'    '---'  \ ''\        ;  
     \   \ ;       \   \ .'   |   |.'    |   ,.'              \   \     .'   
      '---"         `---`     `---'      '---'                 `--`-,,-'     
                                                                             
*/

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";


contract W0rdl3 is ERC721A, Ownable, ReentrancyGuard{

    // ====================== 🇽 VARIABLES 🇾 =======================
    uint256 public maxSupply = 21250;
    uint256 public mintPrice = 0.00069 ether;
    uint256 public maxPerTxn = 26;
    string public baseExtension = ".json";
    string public baseURI;
    bool public mintEnabled = false;

    constructor (
    string memory _initBaseURI) 
    ERC721A("W0rdl3", "W0RDL3") {
        setBaseURI(_initBaseURI);
    }

    // ====================== 🖼️ MINT FUNCTIONS 🖼️ =======================
    function teamMint(address[] calldata _address, uint256 _amount) external onlyOwner nonReentrant {
        require(totalSupply() + _amount <= maxSupply, "W0rdl3Error: Max supply reached");
        for (uint i = 0; i < _address.length; i++) {
            _safeMint(_address[i], _amount);
        }
    }

    function mint(uint256 _quantity) external payable nonReentrant{

        require(mintEnabled, "W0rdl3Error: Mint is not live");
        require(_quantity <= maxPerTxn, "W0rdl3Error: Cannot mint more than max per txn");
        require(totalSupply() + _quantity <= maxSupply, "W0rdl3Error: Max supply reached");
        require(msg.value >= (_quantity * mintPrice), "W0rdl3Error: Not enough ether sent");
        
        _safeMint(msg.sender, _quantity);
    }

    
    // ====================== 🎨 BASE URI / TOKEN URI 🎨 =======================
   // returns the baseuri of collection, private
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    // override _statTokenId() from erc721a to start tokenId at 1
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    // return tokenUri given the tokenId
    function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
    {
    require(_exists(tokenId),"W0rdl3Error: ERC721Metadata: URI query for nonexistent token");
    
        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _toString(tokenId), baseExtension))
        : "";
        
    }

    // ====================== 🕹️ CONTROL FUNCTIONS 🕹️ =======================
    function toggleMint() external onlyOwner nonReentrant{
        mintEnabled = !mintEnabled;
    }

    function setPrice(uint256 _mintPrice) external onlyOwner nonReentrant{
        mintPrice = _mintPrice;
    }

    function setMaxPerTxn(uint256 _maxPerTxn) external onlyOwner nonReentrant{
        maxPerTxn = _maxPerTxn;
    }

    function setMaxSupply(uint256 _maxSupply) external onlyOwner nonReentrant {
        maxSupply = _maxSupply;
    }

    function setBaseURI(string memory _newURI) public onlyOwner nonReentrant{
        baseURI = _newURI;
    }


    // ====================== 💰 WITHDRAW CONTRACT FUNDS 💰 =======================
    function withdraw() external onlyOwner {
        (bool success, ) = owner().call{value: address(this).balance}("");
        require(success, "W0rdl3Error: Withdraw failed !");
    }
}