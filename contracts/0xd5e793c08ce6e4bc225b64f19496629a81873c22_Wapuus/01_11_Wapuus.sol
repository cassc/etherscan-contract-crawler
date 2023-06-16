// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

library LibPart {
    bytes32 public constant TYPE_HASH = keccak256("Part(address account,uint96 value)");

    struct Part {
        address payable account;
        uint96 value;
    }

    function hash(Part memory part) internal pure returns (bytes32) {
        return keccak256(abi.encode(TYPE_HASH, part.account, part.value));
    }
}

contract OwnableDelegateProxy { }

contract ProxyRegistry {
  mapping(address => OwnableDelegateProxy) public proxies;
}

contract Wapuus is ERC1155, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    //New Marketplace royalty standard
    bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;

    /*
     * bytes4(keccak256('getRoyalties(LibAsset.AssetType)')) == 0x44c74bcc
     */
    bytes4 constant _INTERFACE_ID_ROYALTIES = 0x44c74bcc;

    string public WAPUU_PROVENANCE = ""; // IPFS URL WILL BE ADDED WHEN WAPUUS ARE ALL SOLD OUT

    string public LICENSE_TEXT = "GPLv2"; // IT IS WHAT IT SAYS

    bool licenseLocked = false; // TEAM CAN'T EDIT THE LICENSE AFTER THIS GETS TRUE

    uint256 public wapuuPrice = 20000000000000000; // 0.02 ETH

    uint256 public wapuuRenamePrice = 10000000000000000; // 0.01 ETH
    
    uint96 public royaltyBPS = 600; // 6% royalty for Rarible/Mintable

    uint public constant maxWapuuPurchase = 40;

    uint256 public constant MAX_WAPUUS = 2222;

    bool public saleIsActive = false;

    mapping(uint => string) public wapuuNames;
    
    // Reserve 50 Wapuus for team - Giveaways/Prizes etc
    uint public wapuuReserve = 50;

    //for OpenSea gas free sale listing
    //address proxyRegistryAddress = 0xF57B2c51dED3A29e6891aba85459d600256Cf317; //rinkeby
    address proxyRegistryAddress = 0xa5409ec958C83C3f309868babACA7c86DCB077c1; //mainnet
    
    event wapuuNameChange(address _by, uint _tokenId, string _name);
    
    event licenseisLocked(string _licenseText);

    constructor() ERC1155("https://api.web3wp.com/wapuus/{id}") { }

    /**
     * @dev Sets a new URI for all token types, by relying on the token type ID
     * substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * By this mechanism, any occurrence of the `\{id\}` substring in either the
     * URI or any of the amounts in the JSON file at said URI will be replaced by
     * clients with the token type ID.
     *
     * For example, the `https://token-cdn-domain/\{id\}.json` URI would be
     * interpreted by clients as
     * `https://token-cdn-domain/000000000000000000000000000000000000000000000000000000000004cce0.json`
     * for token type ID 0x4cce0.
     *
     * See {uri}.
     *
     * Because these URIs cannot be meaningfully represented by the {URI} event,
     * this function emits no events.
     */
    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }

    /**
    * Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-free listings.
    */
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        // Whitelist OpenSea proxy contract for easy trading.
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(account)) == operator) {
            return true;
        }

        return ERC1155.isApprovedForAll(account, operator);
    }
  
    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function totalSupply() public view virtual returns (uint256) {
        return _tokenIds.current();
    }

    /**
     * Returns balance of all tokens owned by address.
     * Equivalent to balanceOf(address) in an ERC721 (different in ERC1155)
     */
    function balanceOfWapuu(address account) public view virtual returns (uint256) {
        require(account != address(0), "No zero");

        uint256 balance = 0;
        for (uint256 i = 0; i < totalSupply(); ++i) {
            balance += balanceOf(account, i);
        }
        
        return balance;
    }

    function tokensOfOwner(address owner) public view returns (uint256[] memory) {
        require(owner != address(0), "No zero");

        uint256 tokenCount = 0;
        for (uint256 i = 0; i < totalSupply(); ++i) {
            tokenCount += balanceOf(owner, i);
        }

        uint256[] memory ids = new uint256[](tokenCount);
        for (uint256 i = 0; i < totalSupply(); ++i) {
            if (1 == balanceOf(owner, i)) {
                ids[i] = i;
            }
        }

        return ids;
    }
    
    /**
     * Only way to mint, and locked to only mint Non-fungibles (1 supply for all tokens)
     */
    function _mintNFTs(address account, uint256 numberOfTokens) internal virtual {
        if (numberOfTokens == 1) {
            _mint(account, totalSupply(), 1, "");
            _tokenIds.increment();
        } else {
            uint256[] memory ids = new uint256[](numberOfTokens);
            uint256[] memory amounts = new uint256[](numberOfTokens);
            for (uint256 i = 0; i < numberOfTokens; ++i) {
                ids[i] = totalSupply() + i;
                amounts[i] = 1; //only 1 per token, an NFT
            }
            _mintBatch(account, ids, amounts, "");

            //update counters
            for (uint256 i = 0; i < numberOfTokens; ++i) {
                _tokenIds.increment();
            }
        }
    }

    function reserveWapuus(address _to, uint256 _reserveAmount) public onlyOwner {        
        require(_reserveAmount > 0 && _reserveAmount <= wapuuReserve, "No rsrv");
        _mintNFTs(_to, _reserveAmount);
        wapuuReserve = wapuuReserve - _reserveAmount;
    }

    function setProvenanceHash(string memory provenanceHash) public onlyOwner {
        WAPUU_PROVENANCE = provenanceHash;
    }

    function flipSaleState() public onlyOwner {
        saleIsActive = !saleIsActive;
    }
    
    // Returns the license for tokens
    function tokenLicense(uint _id) public view returns(string memory) {
        require(_id < totalSupply(), "Invld Tkn");
        return LICENSE_TEXT;
    }
    
    // Locks the license to prevent further changes 
    function lockLicense() public onlyOwner {
        licenseLocked =  true;
        emit licenseisLocked(LICENSE_TEXT);
    }
    
    // Change the license
    function changeLicense(string memory _license) public onlyOwner {
        require(licenseLocked == false, "Alrdy lckd");
        LICENSE_TEXT = _license;
    }
    
    // Change the mintPrice
    function setMintPrice(uint256 newPrice) public onlyOwner {
        require(newPrice != wapuuPrice, "Not new");
        wapuuPrice = newPrice;
    }
    
    // Change the wapuuRenamePrice
    function setRenamePrice(uint256 newPrice) public onlyOwner {
        require(newPrice != wapuuRenamePrice, "Not new");
        wapuuRenamePrice = newPrice;
    }
    
    // Change the royaltyBPS
    function setRoyaltyBPS(uint96 newRoyaltyBPS) public onlyOwner {
        require(newRoyaltyBPS != royaltyBPS, "Not new");
        royaltyBPS = newRoyaltyBPS;
    }

    function mintWapuus(uint numberOfTokens) public payable {
        require(saleIsActive, "Sale Inactv");
        require(numberOfTokens > 0 && numberOfTokens <= maxWapuuPurchase, "Max 20");
        require(totalSupply() + numberOfTokens <= MAX_WAPUUS, "Excds max sply");
        require(msg.value == wapuuPrice * numberOfTokens, "Chk prce");
        
        _mintNFTs(msg.sender, numberOfTokens);
    }

    function changeWapuuName(uint _tokenId, string memory _name) public payable {
        require(balanceOf(msg.sender, _tokenId) == 1, "Prmsns Err");
        require(sha256(bytes(_name)) != sha256(bytes(wapuuNames[_tokenId])), "Not new");
        require(msg.value == wapuuRenamePrice, "Chk prce");
        wapuuNames[_tokenId] = _name;
        
        emit wapuuNameChange(msg.sender, _tokenId, _name);
    }
    
    function viewWapuuName(uint _tokenId) public view returns( string memory ){
        require( _tokenId < totalSupply(), "Invld Tkn" );
        return wapuuNames[_tokenId];
    }

    //Rarible royalty interface new
    function getRaribleV2Royalties(uint256 /*id*/) external view returns (LibPart.Part[] memory) {
         LibPart.Part[] memory _royalties = new LibPart.Part[](1);
        _royalties[0].value = royaltyBPS;
        _royalties[0].account = payable(owner());
        return _royalties;
    }

    //Mintable/ERC2981 royalty handler
    function royaltyInfo(uint256 /*_tokenId*/, uint256 _salePrice) external view returns (address receiver, uint256 royaltyAmount) {
       return (owner(), (_salePrice * royaltyBPS)/10000);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155) returns (bool) {
        if(interfaceId == _INTERFACE_ID_ROYALTIES) {
            return true;
        }
        if(interfaceId == _INTERFACE_ID_ERC2981) {
            return true;
        }
        return super.supportsInterface(interfaceId);
    }
}