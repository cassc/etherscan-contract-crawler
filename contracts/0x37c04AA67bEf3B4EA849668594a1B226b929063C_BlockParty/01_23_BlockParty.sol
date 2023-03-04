// SPDX-License-Identifier: MIT

//  /$$$$$$$  /$$                     /$$             /$$$$$$$                        /$$              
// | $$__  $$| $$                    | $$            | $$__  $$                      | $$              
// | $$  \ $$| $$  /$$$$$$   /$$$$$$$| $$   /$$      | $$  \ $$  /$$$$$$   /$$$$$$  /$$$$$$   /$$   /$$
// | $$$$$$$ | $$ /$$__  $$ /$$_____/| $$  /$$/      | $$$$$$$/ |____  $$ /$$__  $$|_  $$_/  | $$  | $$
// | $$__  $$| $$| $$  \ $$| $$      | $$$$$$/       | $$____/   /$$$$$$$| $$  \__/  | $$    | $$  | $$
// | $$  \ $$| $$| $$  | $$| $$      | $$_  $$       | $$       /$$__  $$| $$        | $$ /$$| $$  | $$
// | $$$$$$$/| $$|  $$$$$$/|  $$$$$$$| $$ \  $$      | $$      |  $$$$$$$| $$        |  $$$$/|  $$$$$$$
// |_______/ |__/ \______/  \_______/|__/  \__/      |__/       \_______/|__/         \___/   \____  $$
//                                                                                            /$$  | $$
//                                                                                           |  $$$$$$/
//                                                                                            \______/ 

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./DefaultOperatorFilterer.sol";

contract BlockParty is ERC721Enumerable, Ownable, DefaultOperatorFilterer {
    using Strings for uint256;
    string public baseURI;
    string public baseExtension = ".json";
    string public notRevealedUri;

    uint256 public WLMaxMint = 2;
    mapping(address => uint256) public WLMinted;

    uint256 public PublicMaxMint = 5;
    mapping(address => uint256) public PublicMinted;

    bool public RevealedActive = false;

    bool public FreeSaleMode = false;
    bool public WLSaleMode = false;
    bool public WLHSaleMode = false;
    bool public PublicSaleMode = false;

    address private Proof;
    address public admin;


    uint256 public WLPrice = 0.04 ether;
    uint256 public PublicPrice = 0.1 ether;
    uint256 public MaxSupply = 800;
    
    ERC1155Burnable public MintPass;

    constructor(address _erc1155Address, address _admin) ERC721("Block Party by Andrew McWhae", "BPARTY") {
        MintPass = ERC1155Burnable(_erc1155Address);
        admin = _admin;
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    function FreeMint(uint256 _Amount) public payable callerIsUser {
        uint256 supply = totalSupply();
        require(_Amount > 0, "Incorrect Amount");
        require(FreeSaleMode == true, "Free Sale not started");
        require(supply + _Amount <= MaxSupply, "Sold Out");
        
        require(
            MintPass.balanceOf(msg.sender, 0) >= _Amount,
            "You don't own enough Mint Pass"
        );

       
        MintPass.burn(msg.sender, 0, _Amount);

        for (uint256 i = 1; i <= _Amount; i++) {
            _safeMint(msg.sender, supply + i);
        }
    }

    function WLMint(uint256 _Amount) public payable callerIsUser {
        uint256 supply = totalSupply();
        require(_Amount > 0, "Incorrect Amount");
        require(WLSaleMode == true, "WL Sale not started");
        require(totalSupply() + _Amount <= MaxSupply, "Sold Out");

        uint256 ownerWLMintedCount = WLMinted[msg.sender];
        require(
            ownerWLMintedCount + _Amount <= WLMaxMint,
            "Max NFT per Wallet Reached"
        );

        require(supply + _Amount <= MaxSupply, "Sold Out");
        require(msg.value >= WLPrice * _Amount, "Balance Insufficient");

        for (uint256 i = 1; i <= _Amount; i++) {
            WLMinted[msg.sender]++;
            _safeMint(msg.sender, supply + i);
        }
    }

    function PublicMint(uint256 _Amount) public payable callerIsUser {
        uint256 supply = totalSupply();
        require(_Amount > 0, "Incorrect Amount");
        require(PublicSaleMode == true, "WL Sale not started");
        require(totalSupply() + _Amount <= MaxSupply, "Sold Out");

        uint256 ownerPublicMintedCount = PublicMinted[msg.sender];
        require(
            ownerPublicMintedCount + _Amount <= PublicMaxMint,
            "Max NFT per Wallet Reached"
        );

        require(supply + _Amount <= MaxSupply, "Sold Out");
        require(msg.value >= PublicPrice * _Amount, "Balance Insufficient");

        for (uint256 i = 1; i <= _Amount; i++) {
            WLMinted[msg.sender]++;
            _safeMint(msg.sender, supply + i);
        }
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function walletOfOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i; i < ownerTokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokenIds;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId), "");
        if (RevealedActive == false) {
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


    function OwnerMint(uint256 _mintAmount) external onlyOwner {
        uint256 supply = totalSupply();
        require(supply + _mintAmount <= MaxSupply, "Sold Out");
        for (uint256 i = 1; i <= _mintAmount; i++) {
            _safeMint(msg.sender, supply + i);
        }
    }

    function WLHMint(uint256 _Amount, address _proof) public payable callerIsUser {
        uint256 supply = totalSupply();
        require(_Amount > 0, "Incorrect Amount");
        require(WLHSaleMode == true, "WL Sale not started");
        require(_proof == Proof);
        require(totalSupply() + _Amount <= MaxSupply, "Sold Out");

        uint256 ownerWLMintedCount = WLMinted[msg.sender];
        require(
            ownerWLMintedCount + _Amount <= WLMaxMint,
            "Max NFT per Wallet Reached"
        );

        require(supply + _Amount <= MaxSupply, "Sold Out");
        require(msg.value >= WLPrice * _Amount, "Balance Insufficient");

        for (uint256 i = 1; i <= _Amount; i++) {
            WLMinted[msg.sender]++;
            _safeMint(msg.sender, supply + i);
        }
    }

    function AirdropMint(address _to, uint256 _mintAmount) external onlyOwner {
        uint256 supply = totalSupply();
        require(supply + _mintAmount <= MaxSupply, "Sold Out");
        for (uint256 i = 1; i <= _mintAmount; i++) {
            _safeMint(_to, supply + i);
        }
    }

    // Set phases
    function TurnFreeMode(bool _state) public onlyOwner {
        FreeSaleMode = _state;
    }

    function TurnWLHMode(bool _state) public onlyOwner {
        WLHSaleMode = _state;
    }

    function TurnWLMode(bool _state) public onlyOwner {
        WLSaleMode = _state;
    }

    function TurnPublicMode(bool _state) public onlyOwner {
        PublicSaleMode = _state;
    }

    // Set Public Price & Presale Price
    function setPublicPrice(uint256 _newPublicPrice) public onlyOwner {
        PublicPrice = _newPublicPrice;
    }

    // Set MaxMint
    function setPublicMaxMint(uint256 _newPublicMaxMint) public onlyOwner {
        PublicMaxMint = _newPublicMaxMint;
    }

    function setWLMaxMint(uint256 _newWLMaxMint) public onlyOwner {
        WLMaxMint = _newWLMaxMint;
    }

    function setProof(address _newProof) public onlyOwner {
        Proof = _newProof;
    }


    // Set NFTs CID and Place Holder CID
    function setURIBase(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

    // Reveal the NFTs
    function Reveal() public onlyOwner {
        RevealedActive = true;
    }

    // Withdraw smart contract funds
    function withdraw(address payable recipient, uint amount) public {
        require(msg.sender == admin, "Only admin can withdraw funds.");
        recipient.transfer(amount);
    }

    // Opensea royalties
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override(ERC721, IERC721) onlyAllowedOperator {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override(ERC721, IERC721) onlyAllowedOperator {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public override(ERC721, IERC721) onlyAllowedOperator {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}