// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

contract TheSecretSociety is Ownable, ERC721Enumerable {
    using Strings for uint256;    
    uint256 public MAXSUPPLY = 6666;
    uint256 public MAX_NFT_PRESALE_1 = 999;
    uint256 public MAX_NFT_PRESALE_2 = 3001;
    uint256 public PRESALE_COST_1 = 0.08 ether;
    uint256 public PRESALE_COST_2 = 0.13 ether;
    uint256 public MINT_PRICE = 0.13 ether;
    uint256 public mintTxLimit_presale_1 = 1;
    uint256 public mintTxLimit_presale_2 = 5;
    uint256 public mintTxLimit_sale = 5;

    string public notRevealedUri;
    string private baseURI;
    string public baseExtension = ".json";     

    mapping(address => bool) public preSaleMapping;

    bool public isPresale_1;
    bool public isPresale_2;
    bool public isLaunched;
    bool public revealed = false; 

    bytes32 private Whitelist1_Root;  

    //init function called on deploy
    function init(bytes32 wlroot1) public {
        isPresale_1 = false;
        isPresale_2 = false;
        isLaunched = false;
        Whitelist1_Root = wlroot1; 
    }

    constructor(string memory _initBaseURI, string memory _initNotRevealedUri) ERC721("THE SECRET SOCIETY XX", "T$$ XX") 
    {
        setBaseURI(_initBaseURI); 
        setNotRevealedURI(_initNotRevealedUri);        
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
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

    function reveal() public onlyOwner {
        revealed = true;
    }

    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

    function launchPresale1Toggle() public onlyOwner {
        isPresale_1 = !isPresale_1;
    }

    function launchPresale2Toggle() public onlyOwner {
        isPresale_2 = !isPresale_2;
    }

    function saleToggle() public onlyOwner {
        isLaunched = !isLaunched;
    }

    function setPresale1Price(uint256 newPrice) public onlyOwner {
        PRESALE_COST_1 = newPrice;
    }

    function setPresale2Price(uint256 newPrice) public onlyOwner {
        PRESALE_COST_2 = newPrice;
    }

    function setPrice(uint256 newPrice) public onlyOwner {
        MINT_PRICE = newPrice;
    }

    function setPresale1Amount(uint256 presale1Amount) public onlyOwner {
        MAX_NFT_PRESALE_1 = presale1Amount;
    }

    function setPresale2Amount(uint256 presale2Amount) public onlyOwner {
        MAX_NFT_PRESALE_2 = presale2Amount;
    }

    function _leaf(address account) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(account));
    }

    function withdraw() public payable onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    function updatePresaleRoot(string memory presaleType, bytes32 root)
        external
        onlyOwner
    {
        if (
            keccak256(abi.encodePacked(presaleType)) ==
            keccak256(abi.encodePacked("presale1Root"))
        ) {
            Whitelist1_Root = root;
        } else {
            revert("Incorrect presaleType");
        }
    }

    //presale
    function preSaleWhitelist1(
        address account,
        bytes32[] calldata proof,
        uint256 _mintAmount
    ) external payable {
        uint256 counter = totalSupply();

        require(isPresale_1, "presale is not active");
        require(
            MerkleProof.verify(proof, Whitelist1_Root, _leaf(account)),
            "account not part of whitelist"
        );
        require(!preSaleMapping[account], "already minted"); 
        require(
            _mintAmount <= mintTxLimit_presale_1,
            "Amount exceeds mintable limit per transaction" 
        );
        require(
            counter + _mintAmount <= MAX_NFT_PRESALE_1,
            "exceeds contract limit" //checks if presale left
        );
        require(
            msg.value >= PRESALE_COST_1 * _mintAmount,
            "Not enough eth sent: check price"
        );

        for (uint256 i = 1; i <= _mintAmount; i++) {
            _safeMint(account, counter + i);
        }
        preSaleMapping[account] = true;
    }

    function preSaleWhitelist2(
        address account,
        bytes32[] calldata proof,
        uint256 _mintAmount
    ) external payable {
        uint256 counter = totalSupply();
        require(isPresale_2, "presale is not active");
        require(
            MerkleProof.verify(proof, Whitelist1_Root, _leaf(account)),
            "account not part of whitelist"
        );
        require(
            _mintAmount <= mintTxLimit_presale_2,
            "Amount exceeds mintable limit per transaction"
        );
        require(
            counter + _mintAmount <= MAX_NFT_PRESALE_2,
            "exceeds contract limit"
        );
        require(
            msg.value >= PRESALE_COST_2 * _mintAmount,
            "Not enough eth sent: check price"
        );
        for (uint256 i = 1; i <= _mintAmount; i++) {
            _safeMint(account, counter + i);
        }
    }

    function mint(address account, uint256 _mintAmount) external payable {
        uint256 counter = totalSupply();
        require(isLaunched, "general mint has not started");
        require(counter + _mintAmount <= MAXSUPPLY, "exceeds contract limit");
        require(
            msg.value >= MINT_PRICE * _mintAmount,
            "Not enough eth sent: check price"
        );

        for (uint256 i = 1; i <= _mintAmount; i++) {
            _safeMint(account, counter + i);
        }
    }
}