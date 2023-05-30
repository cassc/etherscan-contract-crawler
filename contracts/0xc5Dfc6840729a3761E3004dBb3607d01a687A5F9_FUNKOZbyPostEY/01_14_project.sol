// SPDX-License-Identifier: MIT

/*


 _____  ___    _______    ______    _______    _______  ___      ___   ________  
(\"   \|"  \  /"     "|  /    " \  /" _   "|  /"     "||"  \    /"  | /"       ) 
|.\\   \    |(: ______) // ____  \(: ( \___) (: ______) \   \  //   |(:   \___/  
|: \.   \\  | \/    |  /  /    ) :)\/ \       \/    |   /\\  \/.    | \___  \    
|.  \    \. | // ___)_(: (____/ // //  \ ___  // ___)_ |: \.        |  __/  \\   
|    \    \ |(:      "|\        / (:   _(  _|(:      "||.  \    /:  | /" \   :)  
 \___|\____\) \_______) \"_____/   \_______)  \_______)|___|\__/|___|(_______/   
                                                                                 
 _______  ___  ___                                                               
|   _  "\|"  \/"  |                                                              
(. |_)  :)\   \  /                                                               
|:     \/  \\  \/                                                                
(|  _  \\  /   /                                                                 
|: |_)  :)/   /                                                                  
(_______/|___/                                                                   
                                                                                 
  _______  ___  ___  _______    __     _______                                   
 /"     "||"  \/"  |/"      \  |" \   /"     "|                                  
(: ______) \   \  /|:        | ||  | (: ______)                                  
 \/    |    \\  \/ |_____/   ) |:  |  \/    |                                    
 // ___)    /   /   //      /  |.  |  // ___)_                                   
(:  (      /   /   |:  __   \  /\  |\(:      "|                                  
 \__/     |___/    |__|  \___)(__\_|_)\_______)                                  
                                                                                 

*/

pragma solidity ^0.6.6;

import "ERC721A.sol";
import "Ownable.sol";
import "ReentrancyGuard.sol";
import "MerkleProof.sol";

contract FUNKOZbyPostEY is Ownable, ERC721A, ReentrancyGuard {
    uint256 public maxSupply = 1111;
    uint256 public maxMintPerTx = 10;
    uint256 public price = 0.111 * 10 ** 18;
    bytes32 public whitelistMerkleRoot =
        0x3f082953ff4d8f2249036113c8ce6b2b8488b3c5d6ee54043e710002c6302558;
    bool public publicPaused = true;
    bool public revealed = false;
    string public baseURI;
    string public hiddenMetadataUri =
        "ipfs://QmZsqnS7gcme1FkLaxSMghViGJfCduSdycHiBww2MLsH8L";

    constructor() public ERC721A("FUNKOZ by PostEY", "FUNKOZ", 1111, 1111) {}

    function mint(uint256 amount) external payable {
        uint256 ts = totalSupply();
        require(publicPaused == false, "Mint not open for public");
        require(ts + amount <= maxSupply, "Purchase would exceed max tokens");
        require(
            amount <= maxMintPerTx,
            "Amount should not exceed max mint number"
        );

        require(msg.value >= price * amount, "Please send the exact amount.");

        _safeMint(msg.sender, amount);
    }

    function openPublicMint(bool paused) external onlyOwner {
        publicPaused = paused;
    }

    function setWhitelistMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        whitelistMerkleRoot = _merkleRoot;
    }

    function setPrice(uint256 _price) external onlyOwner {
        price = _price;
    }

    function whitelistStop(uint256 _maxSupply) external onlyOwner {
        maxSupply = _maxSupply;
    }

    function setMaxPerTx(uint256 _maxMintPerTx) external onlyOwner {
        maxMintPerTx = _maxMintPerTx;
    }

    function setRevealed(bool _state) public onlyOwner {
        revealed = _state;
    }

    function setBaseURI(string calldata newBaseURI) external onlyOwner {
        baseURI = newBaseURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function whitelistMint(
        uint256 amount,
        bytes32[] calldata _merkleProof
    ) public payable {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        uint256 ts = totalSupply();
        require(ts + amount <= maxSupply, "Purchase would exceed max tokens");

        require(
            MerkleProof.verify(_merkleProof, whitelistMerkleRoot, leaf),
            "Invalid proof!"
        );

        {
            _safeMint(msg.sender, amount);
        }
    }

    function setHiddenMetadataUri(
        string memory _hiddenMetadataUri
    ) public onlyOwner {
        hiddenMetadataUri = _hiddenMetadataUri;
    }

    function tokenURI(
        uint256 _tokenId
    ) public view virtual override returns (string memory) {
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        if (revealed == false) {
            return hiddenMetadataUri;
        }

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(abi.encodePacked(currentBaseURI, _tokenId.toString()))
                : "";
    }

    function withdraw() external onlyOwner nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    function stake(uint256 tokenId) external onlyOwner {
        _stake(tokenId);
    }
}