//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.11;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";
import '@openzeppelin/contracts/utils/Strings.sol';

contract Voyager is ERC721A, Ownable, ReentrancyGuard, Pausable {
    using Strings for uint256;

    uint256 public supply = 5000;
    uint256 public price = 0.25 ether;
    string public placeholder = "https://ipfs.io/ipfs/QmRxT8xRjgYeKGf6uuryz7d8os12gp9M6Z4Sg1Yf3wm5fo/";
    string public uri;
    address public signer;
    address public treasury;
    string public provenance;

    bool public preSaleLive;
    bool public publicSaleLive;

    mapping(address => bool) public minted;
    mapping(address => bool) private admins;

    event PreSaleLive(bool live);
    event PublicSaleLive(bool live);

    constructor(string memory name, string memory symbol) ERC721A(name, symbol) {
        treasury = owner();
    }

    /**
        @dev adminMint used to mint prior the sale starts 
        - to create collection
        - gift to recipients
        - reimburse users
     */
    function adminMint(uint256 quantity, address to) external adminOrOwner {
        require(totalSupply() + quantity <= supply , "Exceeds supply");        
        _safeMint(to, quantity);
    }

    function presaleMint(
        uint256 quantity,
        bytes calldata signature
    ) 
    external 
    payable 
    nonReentrant 
    whenNotPaused 
    mintConditions(quantity, signature) {
        require(preSaleLive, "not live");
        _mint(quantity);
    }

    function publicMint(
        uint256 quantity,
        bytes calldata signature
    ) 
    external 
    payable 
    nonReentrant 
    whenNotPaused 
    mintConditions(quantity, signature) {
        require(publicSaleLive, "not live");
        _mint(quantity);
    }

    modifier mintConditions(uint256 quantity, bytes calldata signature) {
        require(_isValid(quantity, _msgSender(), signature), "Invalid signature");
        require(!minted[_msgSender()], "Already minted");
        require(msg.value >= price * quantity, "Insufficient amount");
        require(totalSupply() + quantity <= supply , "Exceeds supply");

        _;
    }

    function _mint(uint256 quantity) internal {        
        minted[msg.sender] = true;
        _safeMint(msg.sender, quantity);
    }

    function _isValid(uint256 quantity, address user, bytes calldata signature) internal view returns (bool) {
        return SignatureChecker.isValidSignatureNow(signer, keccak256(abi.encodePacked(user, quantity)), signature);
    }

    function burn(uint256 id) external {
        TokenOwnership memory prevOwnership = ownershipOf(id);

        bool isApprovedOrOwner = (_msgSender() == prevOwnership.addr ||
            isApprovedForAll(prevOwnership.addr, _msgSender()) ||
            getApproved(id) == _msgSender());
        require(isApprovedOrOwner, "unauthorised");
        _burn(id);
    }

    function withdraw() external adminOrOwner {
        (bool success,) = treasury.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    function setSupply(uint256 _supply) external adminOrOwner {
        supply = _supply;
    }

    function setPrice(uint256 _price) external adminOrOwner {
        price = _price;
    }

    function setTreasury(address _treasury) external adminOrOwner {
        treasury = _treasury;
    }

    function setSigner(address _signer) external adminOrOwner {
        signer = _signer;
    }

    function setProvenance(string memory _provenance) public onlyOwner {
        provenance = _provenance;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _baseURI();
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : placeholder;
    }
        
    function _baseURI() internal view override returns (string memory) {
        return uri;
    }

    function setPlaceholder(string memory _uri) external adminOrOwner {
        placeholder = _uri;
    }

    function setURI(string memory _uri) external adminOrOwner {
        uri = _uri;
    }

    function togglePublicSale() external adminOrOwner {
        bool isLive = !publicSaleLive;
        publicSaleLive = isLive;
        emit PublicSaleLive(isLive);
    }
    
    function togglePreSale() external adminOrOwner {
        bool isLive = !preSaleLive;
        preSaleLive = isLive;
        emit PreSaleLive(isLive);
    }

    function pause() external adminOrOwner {
        _pause();
    }

    function unpause() external adminOrOwner {
        _unpause();
    }

    function addAdmin(address _admin) external adminOrOwner {
        admins[_admin] = true;
    }

    function removeAdmin(address _admin) external adminOrOwner {
        admins[_admin] = false;
    } 

    modifier adminOrOwner() {
        require(admins[_msgSender()] || _msgSender() == owner(), "Unauthorized");
        _;
    }
}