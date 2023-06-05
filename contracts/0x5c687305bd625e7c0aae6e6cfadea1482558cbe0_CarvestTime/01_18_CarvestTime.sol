//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
                                                                                                                                                                               
// MMMMMMMM               MMMMMMMM ZZZZZZZZZZZZZZZZZZZ KKKKKKKKK    KKKKKKK ZZZZZZZZZZZZZZZZZZZ
// M:::::::M             M:::::::M Z:::::::::::::::::Z K:::::::K    K:::::K Z:::::::::::::::::Z
// M::::::::M           M::::::::M Z:::::::::::::::::Z K:::::::K    K:::::K Z:::::::::::::::::Z
// M:::::::::M         M:::::::::M Z:::ZZZZZZZZ:::::Z  K:::::::K   K::::::K Z:::ZZZZZZZZ:::::Z 
// M::::::::::M       M::::::::::M ZZZZZ     Z:::::Z   KK::::::K  K:::::KKK ZZZZZ     Z:::::Z  
// M:::::::::::M     M:::::::::::M         Z:::::Z       K:::::K K:::::K            Z:::::Z    
// M:::::::M::::M   M::::M:::::::M        Z:::::Z        K::::::K:::::K            Z:::::Z     
// M::::::M M::::M M::::M M::::::M       Z:::::Z         K:::::::::::K            Z:::::Z      
// M::::::M  M::::M::::M  M::::::M      Z:::::Z          K:::::::::::K           Z:::::Z       
// M::::::M   M:::::::M   M::::::M     Z:::::Z           K::::::K:::::K         Z:::::Z        
// M::::::M    M:::::M    M::::::M    Z:::::Z            K:::::K K:::::K       Z:::::Z         
// M::::::M     MMMMM     M::::::M ZZZ:::::Z     ZZZZZ KK::::::K  K:::::KKK ZZZ:::::Z     ZZZZZ
// M::::::M               M::::::M Z::::::ZZZZZZZZ:::Z K:::::::K   K::::::K Z::::::ZZZZZZZZ:::Z
// M::::::M               M::::::M Z:::::::::::::::::Z K:::::::K    K:::::K Z:::::::::::::::::Z
// M::::::M               M::::::M Z:::::::::::::::::Z K:::::::K    K:::::K Z:::::::::::::::::Z
// MMMMMMMM               MMMMMMMM ZZZZZZZZZZZZZZZZZZZ KKKKKKKKK    KKKKKKK ZZZZZZZZZZZZZZZZZZZ
                                                                                                                                                                                
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import './ERC721WithRoyalties.sol';
import "./BaseOpenSea.sol";

interface ERC721MZKZ {
  function ownerOf(uint256 tokenId) external returns (address owner);
}

contract CarvestTime is ERC721Enumerable, ERC721Burnable, Ownable, BaseOpenSea, ERC721WithRoyalties {

    address public erc721MZKZContract;
    mapping(uint256 => uint256) public claimedTokens;
    string public baseURI;
    string public provenance = "";
    uint256 public minted;
    uint256 public reserveMinted;
    uint256 constant public maxSupply = 310;
    uint256 constant public startId = 1;
    uint256 constant public reservedSupply = 190;
    uint256 constant public price = 31000000000000000;
    uint256 constant public saleStartTime = 1635433200;
    uint256 constant public claimStartTime = 1635346800;
    uint256 constant public buyLimit = 5;
    uint256 constant public claimLimitPerQualifyingId = 1;

    constructor(
        string memory name_, 
        string memory symbol_,
        string memory contractURI_,
        string memory baseURI_,
        address erc721MZKZContract_,
        address openseaProxyRegistry_,
        address royaltyRecipient_,
        uint256 royaltyValue_
    ) ERC721(name_, symbol_) {
        // set BaseURI
        setBaseURI(baseURI_);
        
        // set the MZKZ contract
        erc721MZKZContract = erc721MZKZContract_;

        // set contract uri if present
        if (bytes(contractURI_).length > 0) {
            _setContractURI(contractURI_);
        }

        // set OpenSea proxyRegistry for gas-less trading if present
        if (address(0) != openseaProxyRegistry_) {
            _setOpenSeaRegistry(openseaProxyRegistry_);
        }

        // set Royalties on the contract
        if (address(0) != royaltyRecipient_) {
            _setRoyalties(royaltyRecipient_, royaltyValue_);
        }
    }

    function mintClaim(uint256 id) public {
            uint256[] memory ids = new uint256[](1);
            ids[0] = id;
            mintClaims(ids);
    }

    function mintClaims(uint256[] memory ids) public {
        require(minted + ids.length <= maxSupply, "Claims exceed max supply limit");
        require(reserveMinted + ids.length <= reservedSupply, "Claims exceed reserve supply limit");
        require(block.timestamp >= claimStartTime, "Claims have not started");
        
        ERC721MZKZ erc721MZKZ = ERC721MZKZ(erc721MZKZContract);
        for (uint256 i; i < ids.length; i++) {
            require(ids[i] >= 1 && ids[i] <= 200, "At least one submitted tokenId does not qualify for claim");

            address tokenOwner = erc721MZKZ.ownerOf(ids[i]);
            require(msg.sender == tokenOwner, "Sender does not own the qualifying token");

            claimedTokens[ids[i]] += 1;
            require(claimedTokens[ids[i]] <= claimLimitPerQualifyingId, "Too many requested");
        }

        uint256 tokenId = startId + minted; 
        minted += ids.length;
        reserveMinted += ids.length;
        for(uint256 i; i < ids.length; i++) {
            _mintTo(msg.sender, tokenId);
            tokenId++;
        }
    }

    function mint(uint256 amount) public payable {
        require(msg.value == amount * price, "Invalid payment amount");
        require(minted + amount <= maxSupply - (reservedSupply - reserveMinted), "Purchase exceeds supply limit");
        require(amount <= buyLimit, "Too many requested");
        require(msg.sender == tx.origin, "Purchase request must come directly from an EOA");
        require(block.timestamp >= saleStartTime, "Sale has not started");

        uint256 tokenId = startId + minted;
        minted += amount;
        for(uint256 i; i < amount; i++) {
            _mintTo(msg.sender, tokenId);
            tokenId++;
        }
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setProvenanceHash(string memory provenanceHash) public onlyOwner {
        provenance = provenanceHash;
    }

    /// @notice Allows the setting of royalties on the contract
    /// @param recipient the royalties recipient
    function setRoyaltiesRecipient(address recipient) public onlyOwner {
        _setRoyaltiesRecipient(recipient);
    }

    /// @notice Helper for the owner of the contract to set the new contract URI
    /// @dev needs to be owner
    /// @param contractURI_ new contract URI
    function setContractURI(string memory contractURI_) external onlyOwner {
        _setContractURI(contractURI_);
    }

    function withdraw() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    // internal functions
    function _mintTo(address recipient, uint256 tokenId) internal {
        _safeMint(recipient, tokenId);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    
    // The following functions are overrides
    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    /// @notice Allows gas-less trading on OpenSea by safelisting the ProxyRegistry of the user
    /// @dev Override isApprovedForAll to check first if current operator is owner's OpenSea proxy
    /// @inheritdoc	ERC721
    function isApprovedForAll(address owner, address operator)
        public
        view
        override
        returns (bool)
    {
        // allows gas less trading on OpenSea
        return super.isApprovedForAll(owner, operator) || isOwnersOpenSeaProxy(owner, operator);
    }

    /// @inheritdoc	ERC165
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721Enumerable, ERC721, ERC721WithRoyalties)
        returns (bool)
    {
        return
            // either ERC721Enumerable
            ERC721Enumerable.supportsInterface(interfaceId) ||
            // or Royalties
            ERC721WithRoyalties.supportsInterface(interfaceId);
    }
}