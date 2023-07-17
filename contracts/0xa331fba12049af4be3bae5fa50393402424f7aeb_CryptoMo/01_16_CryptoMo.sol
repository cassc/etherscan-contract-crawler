// SPDX-License-Identifier: MIT
/*
 _______ .-. .-.,---.    
|__   __|| | | || .-'      The Crypto Mos (MOS)
  )| |   | `-' || `-.       by The Crypto Art
  _) |   | .-. || .-'        Appreciation Society
   | |   | | |)||  `--.       https://cryptomo.art
   `-'   /(  (_)/( __.'        MINTING FEBRUARY 2022
        (__)   (__)                         
  ,--,  ,---.  .-.   .-.,---.  _______  .---. 
.' .')  | .-.\  \ \_/ )/| .-.\|__   __|/ .-. )
|  |(_) | `-'/   \   (_)| |-' ) )| |   | | |(_)
\  \    |   (     ) (   | |--' (_) |   | | | | 
 \  `-. | |\ \    | |   | |      | |   \ `-' / 
  \____\|_| \)\  /(_|   /(       `-'    )---' 
            (__)(__)   (__)            (_)  
         .---.    .---.                          
|\    /|/ .-. )  ( .-._)   JOIN A SOCIETY OF
|(\  / || | |(_)(_) \       ART LOVERS
(_)\/  || | | | _  \ \       THAT INVESTS IN
| \  / |\ `-' /( `-'  )       EMERGING ARTISTS.
| |\/| | )---'  `----'         BE REWARDED
'-'  '-'(_)                     WITH THEIR ART.

The Crypto Art Appreciation Society is offering 14 up-and-coming
artists from around the globe a residency and supporting 
them with 6 ETH each to create limited edition NFT art.
Enjoy your MO; Copyright transfers to the NFT holder!
*/

pragma solidity 0.8.2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";

contract CryptoMo is Ownable, ERC721Enumerable, PaymentSplitter {

    uint public publicSale = 1643644800; 

    uint public MAX_MO = 10000; 
    // The MOs reserve the right to *reduce* the supply shown, if needed.
    // But we hard-coded it below to *never* raise it above 10,000.

    uint public PUBLIC_MO_PRICE = 0.08 ether;
    uint public PRESALE_MO_PRICE = 0.05 ether;
    uint public walletLimit = 50;

    string public PROVENANCE_HASH;
    // Once we sellout and are sure of no errors requiring any image changes,
    // we will lock the provenance hash. This hash is a proof that the
    // images have not been tampered with in terms of order or content.

    string private _baseURIExtended;
    string private _contractURI;
    bool public _isSaleLive = false;
    bool public _isPreSaleLive = false;
    bool private locked;
    bool private PROVENANCE_LOCK = false;
    uint public _reserved;
    uint id = totalSupply();

    struct Account {
        uint nftsReserved;
        uint mintedNFTs;
        bool isAdmin ;
    }

    mapping(address => Account) public accounts;

    event Mint(address indexed sender, uint totalSupply);
    event PermanentURI(string _value, uint256 indexed _id);
    event Burn(address indexed sender, uint indexed _id);

    address[] private _distro;
    uint[] private _distro_shares;

    constructor(address[] memory distro, uint[] memory distro_shares, address[] memory teamclaim)
        ERC721("The Crypto Mos", "MOS")
        PaymentSplitter(distro, distro_shares)
    {
        _baseURIExtended = "ipfs://QmbHjsvFJT8uP64xRRSKoXuoq4VYXeRaao1VKzK3JFyEvE/";

        accounts[msg.sender] = Account( 0, 0, true);

        // teamclaim (7 wallets) 
        accounts[teamclaim[0]] = Account( 100, 0, true); // CMAAS 100 NFTs
        accounts[teamclaim[1]] = Account( 100, 0, true); // CMAAS 100 NFTs
        accounts[teamclaim[2]] = Account( 100, 0, true); // CMAAS 100 NFTs
        accounts[teamclaim[3]] = Account( 20, 0, true); // Dev 20 NFT
        accounts[teamclaim[4]] = Account( 20, 0, true); // Dev 20 NFT
        accounts[teamclaim[5]] = Account( 20, 0, true); // Dev 20 NFT
        accounts[teamclaim[6]] = Account( 15, 0, true); // Dev 15 NFT 

        _reserved = 375;

        _distro = distro;
        _distro_shares = distro_shares;
    }

    // (^_^) MODIFIERS (^_^) 

    modifier onlyAdmin() {
        require(accounts[msg.sender].isAdmin == true, "Error: You must be an admin.");
        _;
    }

    modifier noReentrant() {
        require(!locked, "Error: No re-entrancy.");
        locked = true;
        _;
        locked = false;
    }

    // (^_^) SETTERS (^_^) 

    function setAdmin(address _addr) external onlyOwner {
        accounts[_addr].isAdmin = !accounts[_addr].isAdmin;
    }

    function setProvenanceHash(string memory _provenanceHash) external onlyOwner {
        require(PROVENANCE_LOCK == false);
        PROVENANCE_HASH = _provenanceHash;
    }

    function lockProvenance() external onlyOwner {
        PROVENANCE_LOCK = true;
    }

    function setBaseURI(string memory _newURI) external onlyOwner {
        _baseURIExtended = _newURI;
    }

    function setContractURI(string memory _newURI) external onlyOwner {
        _contractURI = _newURI;
    }

    function activatePreSale() external onlyOwner {
        _isPreSaleLive = true;
    }

    function deactivatePreSale() external onlyOwner {
        _isPreSaleLive = false;
    }

    function activateSale() external onlyOwner {
        _isSaleLive = true;
        _isPreSaleLive = false;
    }

    function deactivateSale() external onlyOwner {
        _isSaleLive = false;
    }

    function setNewSaleTime(uint _newTime) external onlyOwner {
        publicSale = _newTime;
    }
    
    function setNewPublicPrice(uint _newPrice) external onlyOwner {
        PUBLIC_MO_PRICE = _newPrice;
    }

    function setNewPreSalePrice(uint _newPrice) external onlyOwner {
        PRESALE_MO_PRICE = _newPrice;
    }

    function setMaxMO(uint _maxMo) external onlyOwner {
        require(_maxMo <= MAX_MO, 'Error: New max supply cannot exceed original max.'); 
        MAX_MO = _maxMo;
    }

    function setWalletLimit(uint _newLimit) external onlyOwner {
       walletLimit = _newLimit;
    }

    function increaseReserved(uint _increaseReservedBy, address _addr) external onlyOwner {
        require(_reserved + totalSupply() + _increaseReservedBy <= MAX_MO, "Error: This would exceed the max supply.");

        _reserved += _increaseReservedBy;
        accounts[_addr].nftsReserved += _increaseReservedBy;
        accounts[_addr].isAdmin = true;
    }

    function decreaseReserved(uint _decreaseReservedBy, address _addr) external onlyOwner {
        require(_reserved - _decreaseReservedBy >= 0, "Error: This would make reserved less than 0.");
        require(accounts[_addr].nftsReserved - _decreaseReservedBy >= 0, "Error: User does not have this many reserved NFTs.");
        
        _reserved -= _decreaseReservedBy;
        accounts[_addr].nftsReserved -= _decreaseReservedBy;
        accounts[_addr].isAdmin = true;
    }
    

    // (^_^) GETTERS (^_^)

    // -- For OpenSea
    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    // -- For Metadata
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIExtended;
    }

    // -- For Convenience
    function getMintPrice() public view returns (uint){
        return PUBLIC_MO_PRICE;
    }


    // (^_^) BUSINESS LOGIC (^_^) 

    function claimReserved(uint _amount) external onlyAdmin {

        require(_amount > 0, "Error: Need to have reserved supply.");
        require(accounts[msg.sender].isAdmin == true,"Error: Only an admin can claim.");
        require(accounts[msg.sender].nftsReserved >= _amount, "Error: You are trying to claim more NFTs than you have reserved.");
        require(totalSupply() + _amount <= MAX_MO, "Error: You would exceed the max supply limit.");

        accounts[msg.sender].nftsReserved -= _amount;
        _reserved = _reserved - _amount;

       for (uint i = 0; i < _amount; i++) {
           id++;
           _safeMint(msg.sender, id);
           emit Mint(msg.sender, totalSupply());
        }

    }

    function airDropNFT(address[] memory _addr) external onlyOwner {

        require(totalSupply() + _addr.length <= (MAX_MO - _reserved), "Error: You would exceed the airdrop limit.");
        for (uint i = 0; i < _addr.length; i++) {
            id++;
            _safeMint(_addr[i], id);
            emit Mint(msg.sender, totalSupply());
        }

    }

    function mint(uint _amount) external payable noReentrant {

        require(_isSaleLive || _isPreSaleLive, "Error: Sale is not active.");
        require(totalSupply() + _amount <= (MAX_MO - _reserved), "Error: Purchase would exceed max supply.");
        require((_amount + accounts[msg.sender].mintedNFTs) <= walletLimit, "Error: You would exceed the wallet limit.");
        require(!isContract(msg.sender), "Error: Contracts cannot mint.");

        if(_isPreSaleLive) {

            require(msg.value >= (PRESALE_MO_PRICE * _amount), "Error: Not enough ether sent.");

        } else if (_isSaleLive) {

            require(msg.value >= (PUBLIC_MO_PRICE * _amount), "Error: Not enough ether sent.");
            require(block.timestamp >= publicSale, "Error: Public sale has not started.");

        }

        for (uint i = 0; i < _amount; i++) {
            id++;
            accounts[msg.sender].mintedNFTs++;
            _safeMint(msg.sender, id);
            emit Mint(msg.sender, totalSupply());
        }

    }

    function burn(uint _id) external returns (bool, uint) {
        require(msg.sender == ownerOf(_id) || msg.sender == getApproved(_id) || isApprovedForAll(ownerOf(_id), msg.sender), "Error: You must own this token to burn it.");
        _burn(_id);
        emit Burn(msg.sender, _id);
        return (true, _id);
    }

    function distributeShares() external onlyAdmin {
        for (uint i = 0; i < _distro.length; i++) {
            release(payable(_distro[i]));
        }
    }

    // (^_^) HELPER. (^_^)
    function isContract(address account) internal view returns (bool) {
  
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    } 

    // (^_^) THE END. (^_^)
    // .--- .. -- .--.-. --. . -. . .-. .- - .. ...- . -. ..-. - ... .-.-.- .. ---

}