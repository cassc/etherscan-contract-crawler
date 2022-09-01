// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
/*

            d$$//                                       d$$//
            $$$||                                       $$$||
           $$$$||                                      $$$$||
   d$$$$$$$$$$|/ d$$$$$$$$$$\\ d$$||    d$$$||d$$$$$$$$$$|/
  $$$$//    /$||$$$$//    /$||q$$$$$$$$$$$$p/$$$$$//   /$||
  $$$//    /$|| $$$//    /$$|| e$$$$$$$$$e/  $$$$//   /$$||
 /$$//    /$$|/$$$//    /$$||d$$$||    $$$$||$$$//   /$$$||
 `$$$$$$$$$$/  `$$$$$$$$$$$/.$$$$'     $$$/'`.$$$$$$$$$$/'

*/
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "./DoxdIndividualTokenCollection.sol";
import "./DoxdAssociatedTokenCollection.sol";

/// @custom:security-contact [email protected]
contract DoxdProjectTokenCollection is Initializable, ERC721Upgradeable, PausableUpgradeable, OwnableUpgradeable, UUPSUpgradeable, ERC721BurnableUpgradeable, ReentrancyGuardUpgradeable {
    using CountersUpgradeable for CountersUpgradeable.Counter;

    CountersUpgradeable.Counter private _tokenIdCounter;
    address payable public PAYMENT_ADDRESS;
    uint256 public MINT_PRICE;
    string public CONTRACT_METADATA_URI;
    string public COLLECTION_BASE_URI;
    uint public MAX_TOKENS_INDIVIDUAL;
    uint public MAX_TOKENS_ASSOCIATED;
    address public NFT_COLLECTION_INDIVIDUAL;
    address public NFT_COLLECTION_ASSOCIATED;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address _paymentAddress) public initializer {
        __ERC721_init("doxd: Project", "DOXD-P");
        __Pausable_init();
        __Ownable_init();
        __UUPSUpgradeable_init();
        PAYMENT_ADDRESS = payable(_paymentAddress);
        MAX_TOKENS_INDIVIDUAL = 5;
        MAX_TOKENS_ASSOCIATED = 5;
        MINT_PRICE = 0.5 ether;
        CONTRACT_METADATA_URI = "https://us-central1-doxd-thenftysetup.cloudfunctions.net/project-contract-metadata";
        COLLECTION_BASE_URI = "https://us-central1-doxd-thenftysetup.cloudfunctions.net/project-token-metadata/";
    }
    
    modifier notInProd {
        uint256 id;
        assembly {
            id := chainid()
        }
        require(id != 1, "You can't do this in production");
        _;
    }

    function updateConfig(
        address _individualCollectionAddress,
        address _associatedCollectionAddress,
        uint _maxTokensIndividual,
        uint _maxTokensAssociated,
        uint256 _mintPrice
    ) public onlyOwner {
        require(_individualCollectionAddress != address(0), "Invalid individual address");
        require(_associatedCollectionAddress != address(0), "Invalid associated address");
        NFT_COLLECTION_INDIVIDUAL = _individualCollectionAddress;
        NFT_COLLECTION_ASSOCIATED = _associatedCollectionAddress;
        MAX_TOKENS_INDIVIDUAL = _maxTokensIndividual;
        MAX_TOKENS_ASSOCIATED = _maxTokensAssociated;
        MINT_PRICE = _mintPrice;
    }

    function setURIs(string memory _contractUri, string memory _collectionUri) public onlyOwner {
        CONTRACT_METADATA_URI = _contractUri;
        COLLECTION_BASE_URI = _collectionUri;
    }

    function setPaymentAddress(address newPaymentAddress)
        external
        onlyOwner
    {
        PAYMENT_ADDRESS = payable(newPaymentAddress);
    }

    function contractURI() public view returns (string memory) {
        return CONTRACT_METADATA_URI;
    }

    function _baseURI() internal view override returns (string memory) {
        return COLLECTION_BASE_URI; // Token Id is appended: string(abi.encodePacked(baseURI, tokenId.toString()))
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function mint(address[] calldata _individualWallets, address[] calldata _associatedWallets)
        external
        payable
        whenNotPaused
        nonReentrant
    {
        require(msg.value == MINT_PRICE, "Incorrect funds submitted");
        require(_individualWallets.length <= MAX_TOKENS_INDIVIDUAL, "Max individual wallets exceeded");
        require(_associatedWallets.length <= MAX_TOKENS_ASSOCIATED, "Max associated wallets exceeded");
        DoxdIndividualTokenCollection iToken = DoxdIndividualTokenCollection(NFT_COLLECTION_INDIVIDUAL);
        DoxdAssociatedTokenCollection aToken = DoxdAssociatedTokenCollection(NFT_COLLECTION_ASSOCIATED);

        uint256 tokenId = _tokenIdCounter.current();
        PAYMENT_ADDRESS.transfer(msg.value);
        _safeMint(msg.sender, tokenId);
        iToken.mint(tokenId, _individualWallets);
        aToken.mint(tokenId, _associatedWallets);
        _tokenIdCounter.increment();
    }

    function adminMint(bool _issueNewProjectToken, uint256 _existingProjectTokenId, address[] calldata _individualWallets, address[] calldata _associatedWallets)
        external
        whenNotPaused
        nonReentrant
        onlyOwner
    {
        DoxdIndividualTokenCollection iToken = DoxdIndividualTokenCollection(NFT_COLLECTION_INDIVIDUAL);
        DoxdAssociatedTokenCollection aToken = DoxdAssociatedTokenCollection(NFT_COLLECTION_ASSOCIATED);

        uint256 tokenId;
        if (_issueNewProjectToken) {
            tokenId = _tokenIdCounter.current();
            _safeMint(msg.sender, tokenId);
        } else {
            tokenId = _existingProjectTokenId;
        }
        if (_individualWallets.length > 0)
            iToken.mint(tokenId, _individualWallets);
        if (_associatedWallets.length > 0)
            aToken.mint(tokenId, _associatedWallets);
        if (_issueNewProjectToken)
            _tokenIdCounter.increment();
    }

    function burnEverything()
        external
        onlyOwner
        notInProd
    {
        DoxdIndividualTokenCollection iToken = DoxdIndividualTokenCollection(NFT_COLLECTION_INDIVIDUAL);
        DoxdAssociatedTokenCollection aToken = DoxdAssociatedTokenCollection(NFT_COLLECTION_ASSOCIATED);

        uint256 currentTokenId = _tokenIdCounter.current();
        for (uint256 i = 0; i < currentTokenId; i++) {
            _burn(i);
        }
        iToken.burnEverything();
        aToken.burnEverything();
        _tokenIdCounter.reset();
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    )
        internal
        override
        whenNotPaused
    {
        require(from == address(0) || to == address(0), "doxd project tokens cannot be sold or transferred");
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function approve(address to, uint256 tokenId) public virtual override {
        revert("doxd project tokens cannot be sold or transferred");
    }
    
    function setApprovalForAll(address operator, bool approved) public virtual override {
        revert("doxd project tokens cannot be sold or transferred");
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyOwner
    {}

    // The following functions are overrides required by Solidity.

    function _burn(uint256 tokenId)
        internal
        override
    {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}

contract DoxdProjectTokenCollectionUpgradeTest is DoxdProjectTokenCollection {
    function test() public pure returns (bool isTestContract) {
        return true;
    }
}