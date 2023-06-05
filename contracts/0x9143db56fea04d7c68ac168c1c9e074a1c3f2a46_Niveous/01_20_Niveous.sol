// SPDX-License-Identifier: MIT
/*                                                                                                        
             ▄█▄▄
            ▄████             ▄      ▄█▄           ▄██▌                 ▄███▄▄▄▄
           ▄████▀     ▄▄████ ████   ▐████   ▄▀▄▄▄██████████████▌▄  ▄▄██████▀▀██████
          █████▀   ▄██████▀ ████▀  ▐████▀▀▀▀▀   ▀████▀   ▄████████▀▀█████       ████
         ▄█████▄▓█████▀▀   ▐████   █████       ▐█████▄▄█████████▀ ▄████▀       ████▀
        ▄██████████▀       ████   █████      ▄████████████▀▀     ▄███▀       █████
     ▄▄██████████         ▄███▌  ████▀       ██████████▄        ████      ▄████▀
      ██████▀█████████▄▄  ████▄▄████▀        ████   ▀█████▄    ▐███   ▄▄████▀
     ▄████               ▐████████▀         ███▀         ▀▀█▀   █████████▀▀
     ███▀                 █████▀           ▐██                     ▀▀
    ▀▀                                          ▄████            ▄▄      ▄▄
                                             ▄██▀ ▐▀  ██▀▄▄██▄██▐█ ▀████▀▀▌
                                            ▐██▄▄▄▄▀▀███▀██ ▀ █ █ ██▄▄▀▄█▀▀
     
     Presents
     
       ███▄    █  ██▓ ██▒   █▓▓█████  ▒█████   █    ██   ██████ 
       ██ ▀█   █ ▓██▒▓██░   █▒▓█   ▀ ▒██▒  ██▒ ██  ▓██▒▒██    ▒ 
      ▓██  ▀█ ██▒▒██▒ ▓██  █▒░▒███   ▒██░  ██▒▓██  ▒██░░ ▓██▄   
      ▓██▒  ▐▌██▒░██░  ▒██ █░░▒▓█  ▄ ▒██   ██░▓▓█  ░██░  ▒   ██▒
      ▒██░   ▓██░░██░   ▒▀█░  ░▒████▒░ ████▓▒░▒▒█████▓ ▒██████▒▒
      ░ ▒░   ▒ ▒ ░▓     ░ ▐░  ░░ ▒░ ░░ ▒░▒░▒░ ░▒▓▒ ▒ ▒ ▒ ▒▓▒ ▒ ░
      ░ ░░   ░ ▒░ ▒ ░   ░ ░░   ░ ░  ░  ░ ▒ ▒░ ░░▒░ ░ ░ ░ ░▒  ░ ░
         ░   ░ ░  ▒ ░     ░░     ░   ░ ░ ░ ▒   ░░░ ░ ░ ░  ░  ░  
               ░  ░        ░     ░  ░    ░ ░     ░           ░  
                          ░                                     
						  
Niveous ISSUE 1

Total Supply:11,111
Price: 0.03 eth
Public Supply:9800

20 max per tx

Reserved

1111 for KOMICPASS holders
100  for Cycrone
100  for Kuro Comics Dao

KDAO TOKEN CONTRACT ADDRESS: 0xE0703247AC5A9cBda3647713cA810Fb9c7025123
KOMICPASS:0xfd4c08F58DCFc22C54ceA240eB3Ad04320A08d99

https://kurocomics.com

all rights reserved KDAO

*/
pragma solidity ^0.8.13;


import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "./ERC721A.sol";
import "./IERC721ABurnable.sol";
import "./ERC721AQueryable.sol";

abstract contract BurnInterface {
    function burnToClaim(uint256 tokenId, address tokenOwner ) public virtual;
    function isClaimLive() public virtual returns(bool);
}
/**
  @title Niveous Issue 1 genesis
  @author kurofoundation.eth
  @notice Use this contract to mint and claim Niveous
*/
contract Niveous is ERC721A,IERC721ABurnable,ERC721AQueryable,Ownable,ERC2981 {

    // Base uri
    string private uri;
    // Provenance
    string public NIVEOUS_PROVENANCE = "";
    // Lock metadata
    bool public metadataLocked = false;
    bool public contractLocked = false;
    // Toggle Sale
    bool public publicSale = false;

    // Approved claim contract
    address claimContract;
    // Approved splitter contract
    address splitContract;

    // Approved KOMICPASS contract
    ERC721Enumerable public komicpass;
    address komicpassAddress;

    // KOMICPASS token mapping for claim
    mapping (address => mapping (uint256 => bool)) claimedToken;

    // Sale Price
    uint256 public immutable salePrice = 30000000000000000;
    
    // Total Issues
    uint256 public immutable issues = 11111;
    // Reserved 1,111 for komicpass holders , 100 for Ralph Del Mundo and 100 for Kuro Comics DAO
    uint256 public immutable reserved = 1311;

    uint256 public immutable maxMint = 20;

    constructor() ERC721A("Niveous: ISSUE 1", "Niveous1") {}
    /**
     * @notice Burn Niveous1 token `id` to claim kdao
     * @param id Token Id that will be burnt 
     */
    function burnDao(uint256 id) public {
        // Check claim contract is set 
        require(claimContract != address(0), "Contract has not been set");

        BurnInterface kdaoContract = BurnInterface(claimContract);
        // Check if claim is live
        require(kdaoContract.isClaimLive() == true,"Burn claim is not live yet");
        // Check if the user own one of the ERC-721 
        require(ownerOf(id) == msg.sender, "Doesn't own the token");
        // Burn one Niveous1 ERC-721 token
        burn(id); 
        // Receive kdao
        kdaoContract.burnToClaim(id,msg.sender); 
    }

    /**
     * @notice Redeem KOMICPASS's for Niveous1 , all ids must be valid
     * @param tokenIds An array of token ids to redeem
     */
    function claimNiveous(uint256[] calldata tokenIds) public {
        // Check claim contract is set 
        require(komicpassAddress != address(0), "KOMICPASS contract has not been set");

        //Check Claim has started
        require(publicSale, "claim has not started");

        uint256 amount = tokenIds.length;
    
        require(amount > 0, "You have to claim atleast 1 allocation");

        for(uint256 i = 0; i < tokenIds.length; i++) {
        
            komicpass = ERC721Enumerable(komicpassAddress);

            // Verify token ownership and if already redeemed
            require(komicpass.ownerOf(tokenIds[i]) == msg.sender, "You do not own komicpass");    
            require(checkIfRedeemed(komicpassAddress, tokenIds[i]) == false, "tokenId already redeemed");
          
            // Token is claimed
            claimedToken[komicpassAddress][tokenIds[i]] = true;
        }
        // Send tokens to pass holder
        _safeMint(msg.sender, amount);
    }
    /**
     * @notice Mint `quantity` Niveous1
     * @param quantity Amount of Niveous1 tokens to mint
     */    
    function mintNiveous(uint256 quantity) public payable {
        require(publicSale, "public sale is offline");
        require(contractLocked == false, "Contract has been locked");
        require(quantity <= maxMint,"can not mint this many");
        require(totalSupply() + reserved + quantity <= issues,"soldout");
        require(msg.value >= salePrice * quantity, "insufficient funds");

        _safeMint(msg.sender, quantity);
    }

    function foundationMint(uint256 quantity) public {
        require(publicSale, "public sale is offline");
        require(contractLocked == false, "Contract has been locked");
        require(msg.sender == 0xE51f79Cde0dA2561460A4Ca4DAE74daC990fbB99, "not authorized");
        require(quantity + _numberMinted(msg.sender) <= 101 , "cannot mint more than 100"); //KOMICPASS ID 0 will be claimed by the DAO so we need 101

         _safeMint(msg.sender, quantity); // Mint token
    }

    function artistMint(uint256 quantity) public {
        require(publicSale, "public sale is offline");
        require(contractLocked == false, "Contract has been locked");
        require(msg.sender == 0xb37728ddb6796BA53212361C2F9B8B20eBf20C0D, "not authorized");
        require(quantity <= maxMint,"can not mint this many");
        require(quantity + _numberMinted(msg.sender) <= 100 , "cannot mint more than 100");

         _safeMint(msg.sender, quantity); // Mint token
    }
    // Set provenance hash
    function setProvenanceHash(string memory provenanceHash) public onlyOwner {
        require(contractLocked == false, "Contract has been locked");
        NIVEOUS_PROVENANCE = provenanceHash;
    }
    // Change the claim contract
    function setClaimContract(address newAddress) public onlyOwner { 
        require(contractLocked == false, "Contract has been locked");
        claimContract = newAddress;
    }
    // Change the splitter contract
    function setSplitContract(address newAddress) public onlyOwner { 
        require(contractLocked == false, "Contract has been locked");
        splitContract = newAddress;
    }
    // Change the komicpass contract
    function setPassContract(address newAddress) public onlyOwner { 
        require(contractLocked == false, "Contract has been locked");
        komicpassAddress = newAddress;
    }
    function lockContract() public onlyOwner {
        contractLocked = true;   
    }
    function lockMetadata() public onlyOwner {
        metadataLocked = true;   
    }
    // Set base uri. OnlyOwner can call it.
    function setBaseURI(string calldata _value) public onlyOwner {
        require(metadataLocked == false, "Contract has been locked and URI can't be changed");
        uri = _value;
    }
    // Check if the mintpass has been used to claim
    function checkIfRedeemed(address _contractAddress, uint256 _tokenId) view public returns(bool) {
        return claimedToken[_contractAddress][_tokenId];
    }
    // Toggle public sales
    function togglePublicSales() public onlyOwner {
        publicSale = !publicSale;
    }
    // Check if public sale is live
    function isPublicSaleLive() view public returns(bool) {
        return publicSale;
    }
    // Set Royalties
    function setRoyalties(address recipient, uint96 value) public onlyOwner {
        _setDefaultRoyalty(recipient, value);
    }
    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }
    //backup withraw
    function withdraw() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
         require(success, "Transfer failed.");
    }
    function withdrawSplit() external onlyOwner {
        // Check split contract is set 
        require(splitContract != address(0), "Contract has not been set");
        (bool success, ) = splitContract.call{value: address(this).balance}("");
         require(success, "Transfer failed.");
    }
    // Overrides //

    // Returns base uri
    function _baseURI() internal view virtual override returns (string memory) {
        return uri;
    }
    // Start tokenid at 1
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }
    // Burn override
    function burn(uint256 tokenId) public virtual override {
        _burn(tokenId, true);
    }
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC721A,ERC721A, ERC2981) returns (bool) {
        return
        ERC721A.supportsInterface(interfaceId) || 
        ERC2981.supportsInterface(interfaceId);
    }
}