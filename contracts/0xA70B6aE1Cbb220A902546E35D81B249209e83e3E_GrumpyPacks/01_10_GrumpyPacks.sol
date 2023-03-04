// SPDX-License-Identifier: MIT


pragma solidity ^0.8.4;

import "./IERC721ABurnable.sol";
import "./ERC721AQueryable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract GrumpyPacks is ERC721AQueryable, IERC721ABurnable, Ownable, Pausable, ReentrancyGuard {

    event PermanentURI(string _value, uint256 indexed _id);

    address private _authorizedContract;
    address private _admin;
    address private _splitContract;
    uint256 public _maxMintPerWallet = 200;
    uint256 public _maxSupply = 200;
    uint256 public PRICE = 0.05 ether;
    bool private _maxSupplyLocked; 
    bool public _baseURILocked;
    string public _normalUri;
    mapping (uint256 => string) customURIs;


    // ============================================================= //
    //                         Constructor                           //
    // ============================================================= //


    constructor(
        string memory normalUri,
        address admin)
    ERC721A("GrumpyPacks", "GrumpyPacks") {
        _admin = admin;
        _safeMint(msg.sender, 1);
        _pause();
        _normalUri = normalUri;
        _splitContract = 0xF92Ac7C79feA5E3C639F11D7827C6e300a436BD3;
        
    }

    // ============================================================= //
    //                           MODIFIERS                           //
    // ============================================================= //

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "Caller is another contract");
        _;
    }
    
    modifier onlyOwnerOrAdmin() {
        require(msg.sender == owner() || msg.sender == _admin, "Not owner or admin");
        _;
    }

    // ============================================================= //
    //                       Control Panel                           //
    // ============================================================= //

    //Withdraw in case anyone sends eth to the contract                                                              
    function withdrawMoney(address to) external onlyOwnerOrAdmin {
        (bool success, ) = to.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }



     // Locks base token URI forever and emits PermanentURI for marketplaces (e.g. OpenSea)
    function lockBaseURI() external onlyOwnerOrAdmin {
        _baseURILocked = true;
        for (uint256 i = 0; i < totalSupply(); i++) {
            emit PermanentURI(tokenURI(i), i);
        }
    }

       //    Getters    //

     // OpenSea metadata initialization
    function contractURI() public pure returns (string memory) {
        return "<contract URI>"; // Needs final Contract MetaData
    }


    function tokenURI(uint256 tokenId) public view virtual override(ERC721A, IERC721A) returns (string memory) {
        return (bytes(customURIs[tokenId]).length == 0) ? _normalUri : customURIs[tokenId];
    }

    //    Setters    //

    // Change burn authorized contract for pack openings
    function setAuthorizedContract(address authorizedContract) external onlyOwnerOrAdmin {
        _authorizedContract = authorizedContract;
    }

    // Change Splits contract for mint proceeds
    function setSplitContract(address splitContract) external onlyOwnerOrAdmin {
        _splitContract = splitContract;
    }

    // Token level control for metadata
    function setNewTokenURI(uint256 typeOfURI, uint256 tokenId, string calldata newURI) external onlyOwnerOrAdmin{
        if(typeOfURI == 0) 
            _normalUri = newURI;
        else 
            customURIs[tokenId] = newURI;
    }
    // ============================================================= //
    //                       Mint Fuctions                           //
    // ============================================================= //

    function mint(uint256 quantity)
        external
        payable
        nonReentrant
        whenNotPaused
    {
        uint256 price = PRICE * quantity;
        require(msg.value >= price, "Not enough ETH");
        require(_numberMinted(msg.sender) + quantity <= _maxMintPerWallet, "Quantity exceeds wallet limit");
        require(totalSupply() + quantity <= _maxSupply, "Quantity exceeds supply");

        _safeMint(msg.sender, quantity);
            payable(_splitContract).transfer(msg.value);
               // refund excess ETH
        if (msg.value > price) {
            payable(msg.sender).transfer(msg.value - price);
        }
    }
    
    // Ownermint/Airdrop faciliator 
    function ownerMint(address to, uint256 quantity) external onlyOwnerOrAdmin {
        require(totalSupply() + quantity <= _maxSupply, "Quantity exceeds supply");
        _safeMint(to, quantity);
    }

    // ============================================================= //
    //                         Mint Controls                         //
    // ============================================================= //

    // Pauses the mint process
    function pause() external onlyOwnerOrAdmin {
        _pause();
    }

    // Unpauses the mint process
    function unpause() external onlyOwnerOrAdmin {
        _unpause();
    }

    // Adjust the mint price //
    function setPrice(uint256 newPrice) external onlyOwnerOrAdmin {
        PRICE = newPrice;
    }


    // Adjustable limit for mints per person.
    function setMaxMintPerWallet(uint256 quantity) external onlyOwnerOrAdmin {
        _maxMintPerWallet = quantity;
    }

    // ============================================================= //
    //                       Supply Controls                         //
    // ============================================================= //

    // Max Supply Control
    function setMaxSupply(uint256 supply) external onlyOwnerOrAdmin {
        require(!_maxSupplyLocked, "Max supply is locked");
        _maxSupply = supply;
    }

    // Locks maximum supply forever
    function lockMaxSupply() external onlyOwnerOrAdmin {
        _maxSupplyLocked = true;
    }

   
    // Only the owner of the token and its approved operators, and the authorized contract
    // can call this function.
    function burn(uint256 tokenId) public virtual override {
        // Avoid unnecessary approvals for the authorized contract
        bool approvalCheck = msg.sender != _authorizedContract;
        _burn(tokenId, approvalCheck);
    }


}