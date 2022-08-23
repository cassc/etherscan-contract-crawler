// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import '@openzeppelin/contracts/finance/PaymentSplitter.sol';
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";


contract DMPASS is ERC721A, Ownable, ReentrancyGuard, PaymentSplitter {
    string private _currentBaseURI;

    uint32 public MAX_SUPPLY = 3_333;
    uint32 public constant MAX_WL_SUPPLY = 700;
    uint32 public constant MAX_PER_TX = 5;
    uint32 public constant MAX_WL_PER_WALLET = 1;
    uint256 public MINT_PRICE = 0.035 ether;
    bytes32 public root;
    address proxyRegistryAddress;
    bool public revealed = true;
    bool public isLive = false;
    bool public isPublic = false;
    bool public isWhitelistSale = true;
    bool public paused = false;
    string public baseURI; 
    string public baseExtension = ".json";
    mapping(address => uint256) private _mintedWLAmount;
    uint256[] private _teamShares = [75, 25]; // 2 PEOPLE IN THE TEAM
    address[] private _team = [
        0x1BaBF19B6210236217235cE95D09e40202ab6416, // wallet #1 
        0x9a0D66111733CA6046e095Bd79fDfD9634887906 //  wallet #2
    ];
    constructor(string memory uri, bytes32 merkleroot, address _proxyRegistryAddress) ERC721A("DMPASS", "DMPASS") 
        PaymentSplitter(_team, _teamShares) // Split the payment based on the teamshares percentages
        ReentrancyGuard() // A modifier that can prevent reentrancy during certain functions
    {
        root = merkleroot;
        proxyRegistryAddress = _proxyRegistryAddress;
        setBaseURI(uri);
    }
    function mint(uint256 count) external payable nonReentrant {
        require(!paused, "DMPASS: Contract is paused");
        require(isPublic, "Public sale is not live yet.");
        require(isLive, "Minting is not live yet.");
        require(totalSupply() + count <= MAX_SUPPLY, "Sold Out!");
        require(count <= MAX_PER_TX, "Max per TX reached.");
        require(
            msg.value >= count * MINT_PRICE,
            "Please send the exact amount."
        );

        _safeMint(msg.sender, count);
    }
 
    function WhitelistMint(uint32 count, bytes32[] calldata _proof)
      external
      payable
      nonReentrant
      isValidMerkleProof(_proof)
      onlyAccounts{
        require(isLive);
        require(!paused, "DMPASS: Contract is paused");
        require(isWhitelistSale, "Whitelist minting is not live yet.");
        require(totalSupply() + count <= MAX_SUPPLY, "Sold Out!");
        require(
            totalSupply() + count <= MAX_WL_SUPPLY,
            "Whitelist Mint Sold Out!"
        );
        require(
            _mintedWLAmount[msg.sender] + count <= MAX_WL_PER_WALLET,
            "You can only mint one piece for free."
        );

        _mintedWLAmount[msg.sender] += count;
        _safeMint(msg.sender, count);
    }

    function setMerkleRoot(bytes32 merkleroot) 
      onlyOwner 
      public 
      {
        root = merkleroot;
      }

    modifier onlyAccounts () {
        require(msg.sender == tx.origin, "Not allowed origin");
        _;
    }

    modifier isValidMerkleProof(bytes32[] calldata _proof) {
         require(MerkleProof.verify(
            _proof,
            root,
            keccak256(abi.encodePacked(msg.sender))
            ) == true, "Not allowed origin");
        _;
   }


    function togglePresale() public onlyOwner {
        isWhitelistSale = !isWhitelistSale;
    }

    function setStateMint(bool _state) public onlyOwner {
        isLive = _state;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _currentBaseURI;
    }

    function togglePause() public onlyOwner {
        paused = !paused;
    }

    function togglePublicSale() public onlyOwner {
        isPublic = !isPublic;
    }

    function setBaseURI(string memory baseUri) public onlyOwner {
        _currentBaseURI = baseUri;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function setFreeForAll() external onlyOwner {
        MINT_PRICE = 0;
    }

    function giveawayWithAmounts(
        address[] memory receivers,
        uint256[] memory amounts
    ) external onlyOwner {
        require(receivers.length >= 1, "at least 1 receiver");
        require(
            receivers.length == amounts.length,
            "receivers.length must equal amounts.length"
        );
        // uint256 total = 0;
        // for (uint256 i; i < amounts.length; i++) {
        //     uint256 amount = amounts[i];
        //     require(amount >= 1, "each receiver should receive at least 1");
        //     total += amount;
        // }
        // require(totalSupply() + total <= MAX_SUPPLY, "would exceed MAX_SUPPLY");
        for (uint256 i; i < receivers.length; i++) {
            address receiver = receivers[i];
            _safeMint(receiver, amounts[i]);
        }
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

            string memory currentBaseURI = _baseURI();
        
            return
                bytes(currentBaseURI).length > 0
                    ? string(
                        abi.encodePacked(
                            currentBaseURI,
                            _toString(tokenId),
                            baseExtension
                        )
                    )
                    : "";
        }

    function isApprovedForAll(address owner, address operator)
            override
            public
            view
            returns (bool)
        {
            // Whitelist OpenSea proxy contract for easy trading.
            ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
            if (address(proxyRegistry.proxies(owner)) == operator) {
                return true;
            }

            return super.isApprovedForAll(owner, operator);
        }
    }

    contract OwnableDelegateProxy {}

    contract ProxyRegistry {
        mapping(address => OwnableDelegateProxy) public proxies;
    }