// SPDX-License-Identifier: Apache 2.0

pragma solidity ^0.8.12;

import "./ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract TheAsian is
    ERC721A,
    IERC2981,
    Ownable,
    Pausable,
    ReentrancyGuard
{
    using Strings for uint256;

    string public contractURIstr = "ipfs://QmZjngQRQkYT3nG48MFVpwHzpfcCh7xsNeDzfk4mcZCa8s/";
    string public baseExtension = ".json";
    string public notRevealedUri = "ipfs://QmZjngQRQkYT3nG48MFVpwHzpfcCh7xsNeDzfk4mcZCa8s/";
    string private baseURI;


    uint256 public constant PUBLIC_PRICE = 0.000 ether;  
    uint256 public royalty = 75; 

    uint256 public constant NUMBER_RESERVED_TOKENS = 500; // Team Reverse 

    bool public revealed = true;
    bool public publicListSaleisActive = true;

    uint256 public constant MAX_SUPPLY = 10000;
    uint256 public maxPerTransaction = 10;
    uint256 public maxPerWallet = 10;

    uint256 public currentId = 0;
    uint256 public publiclistMint = 0;
    uint256 public reservedTokensMinted = 0;

    bool public testWithDraw = false;
    bool public testReserved = false;

    mapping(address => uint256) private _publiclistMintTracker;

    constructor( string memory _name, string memory _symbol) ERC721A("The Asian", "TSN"){}
    
    function publicMint(
        uint256 numberOfTokens
    )
        external
        payable
        isSaleActive(publicListSaleisActive)
        canClaimTokenPublic(numberOfTokens)
        isCorrectPaymentPublic(PUBLIC_PRICE, numberOfTokens)
        isCorrectAmount(numberOfTokens)
        isSupplyRemaining(numberOfTokens)
        nonReentrant
        whenNotPaused
    {
        _safeMint(msg.sender, numberOfTokens);
        currentId = currentId + numberOfTokens;
        publiclistMint = publiclistMint + numberOfTokens;
        _publiclistMintTracker[msg.sender] =
            _publiclistMintTracker[msg.sender] +
            numberOfTokens;
    }

    function mintReservedToken(address to, uint256 numberOfTokens)
        external
        canReserveToken(numberOfTokens)
        isNonZero(numberOfTokens)
        nonReentrant
        onlyOwner
    {
        testReserved = true;
        _safeMint(to, numberOfTokens);
        reservedTokensMinted = reservedTokensMinted + numberOfTokens;
    }

    function withdraw() external onlyOwner {
        testWithDraw = true;
        payable(owner()).transfer(address(this).balance);
    }


    function _startTokenId() 
        internal 
        view 
        virtual 
        override 
        returns (uint256) 
    {
        return 1;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        if (revealed == false) {
            return notRevealedUri;
        }

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        tokenId.toString(),
                        baseExtension
                    )
                )
                : "";
    }

    function contractURI() 
        external 
        view 
        returns 
        (string memory) 
    {
        return contractURIstr;
    }

    function numberMinted(address owner) 
        public 
        view 
        returns 
        (uint256) 
    {
        return _numberMinted(owner);
    }

    function getOwnershipData(uint256 tokenId)
        external
        view
        returns (TokenOwnership memory)
    {
        return _ownershipOf(tokenId);
    }

    function _baseURI() 
        internal 
        view 
        virtual 
        override 
        returns (string memory) 
    {
        return baseURI;
    }

    function setReveal(bool _reveal) 
        public 
        onlyOwner 
    {
        revealed = _reveal;
    }

    function setBaseURI(string memory _newBaseURI) 
        public 
        onlyOwner 
    {
        baseURI = _newBaseURI;
    }

    function setNotRevealedURI(string memory _notRevealedURI) 
        public 
        onlyOwner 
    {
        notRevealedUri = _notRevealedURI;
    }

    function setBaseExtension(string memory _newBaseExtension)
        public
        onlyOwner
    {
        baseExtension = _newBaseExtension;
    }

    function setContractURI(string calldata newuri) 
        external 
        onlyOwner
    {
        contractURIstr = newuri;
    }

    function pause() 
        external 
        onlyOwner 
    {
        _pause();
    }

    function unpause() 
        external 
        onlyOwner 
    {
        _unpause();
    }

    function flipPubliclistSaleState() 
        external 
        onlyOwner 
    {
        publicListSaleisActive = !publicListSaleisActive;
    }

    function updateSaleDetails(
        uint256 _royalty
    )
        external
        isNonZero(_royalty)
        onlyOwner
    {
        royalty = _royalty;
    }

    function isApprovedForAll(
        address _owner,
        address _operator
    ) 
        public 
        override 
        view 
        returns 
        (bool isOperator) 
    {
        if (_operator == address(0x58807baD0B376efc12F5AD86aAc70E78ed67deaE)) {
            return true;
        }
        
        return ERC721A.isApprovedForAll(_owner, _operator);
    }

    function royaltyInfo(
        uint256, /*_tokenId*/
        uint256 _salePrice
    )
        external
        view
        override(IERC2981)
        returns (address Receiver, uint256 royaltyAmount)
    {
        return (owner(), (_salePrice * royalty) / 1000); //100*10 = 1000
    }

    modifier canClaimTokenPublic(uint256 numberOfTokens) {
        require(
            _publiclistMintTracker[msg.sender] + numberOfTokens <= maxPerWallet,
            "Cannot claim more than allowed limit per address"
        );
        _;
    }

    modifier canReserveToken(uint256 numberOfTokens) {
        require(
            reservedTokensMinted + numberOfTokens <= NUMBER_RESERVED_TOKENS,
            "Cannot reserve more than 10 tokens"
        );
        _;
    }

    modifier isCorrectPaymentPublic(
        uint256 price, 
        uint256 numberOfTokens
    ) {
            require(
                0  == msg.value,
                "Incorrect ETH value sent"
                );
            _;  
    }

    modifier isCorrectAmount(uint256 numberOfTokens) {
        require(
            numberOfTokens > 0 && numberOfTokens <= maxPerTransaction,
            "Max per transaction reached, sale not allowed"
        );
        _;
    }

    modifier isSupplyRemaining(uint256 numberOfTokens) {
        require(
            totalSupply() + numberOfTokens <=
                MAX_SUPPLY - (NUMBER_RESERVED_TOKENS - reservedTokensMinted),
            "Purchase would exceed max supply"
        );
        _;
    }

    modifier isSaleActive(bool active) {
        require(active, "Sale must be active to mint");
        _;
    }

    modifier isNonZero(uint256 num) {
        require(num > 0, "Parameter value cannot be zero");
        _;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721A, IERC165)
        returns (bool)
    {
        return (interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId));
    }
}