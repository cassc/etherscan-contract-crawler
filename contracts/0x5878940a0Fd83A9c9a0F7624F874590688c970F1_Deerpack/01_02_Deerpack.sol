// SPDX-License-Identifier: MIT
//
// DeerPack
/*
 *
 * ASTERIA LABS
 * @Danny_One
 *
 */

import "./ERC721_efficient.sol";

pragma solidity ^0.8.0;

contract Deerpack is ERC721Enumerable, Ownable, nonReentrant {
    uint256 public PRICE = 0.055 ether;
    uint256 public PRESALE_PRICE = 0.05 ether;

    uint256 public MAX_SUPPLY = 888;
    uint256 public MAX_TEAMRESERVE = 100;

    uint256 public maxSaleMint = 2;
    mapping(address => uint256) public mintedPerAddress;

    uint256 public teamMints = 0;
    bytes32 public MerkleRoot =
        0x3a685e002d570083c931265030a76d282bc9fa56e3e125c52ac27ad006af1893;

    address public proxyRegistryAddress;
    mapping(address => bool) public projectProxy;

    enum SaleState { paused, presale, publicSale }
    SaleState public saleState;

    string public revealedURI;
    string public unrevealedURI = "ipfs://QmYx8htxUmfZsVsixKD4yaUaXV53WW7LzjB2wLZde64Mwg";
    bool public isRevealed;

    constructor() ERC721("The Deerpack", "DPK") {}

    // PUBLIC FUNCTIONS

    function mint(uint256 _mintAmount) external payable {
        require(saleState == SaleState.publicSale, "public sale not active");
        require(msg.sender == tx.origin, "no proxy transactions");
        require(_mintAmount <= maxSaleMint, "max mint per session exceeded");
        require(msg.value >= _mintAmount * PRICE, "not enough ETH sent");

        uint256 supply = totalSupply();
        require(supply + _mintAmount <= MAX_SUPPLY, "max NFT limit exceeded");

        for (uint256 i = 0; i < _mintAmount; ) {
            _mint(msg.sender, supply + i);
            unchecked { ++i; }
        }
    }

    function mintPresale(bytes32[] memory _proof, uint256 _mintAmount)
        external
        payable
    {
        require(saleState == SaleState.presale, "presale not active");
        require(_mintAmount < 3, "max presale mint per session exceeded");
        require(
            mintedPerAddress[msg.sender] + _mintAmount < 3,
            "max per address exceeded"
        );
        require(
            MerkleProof.verify(
                _proof,
                MerkleRoot,
                keccak256(abi.encodePacked(msg.sender))
            ),
            "invalid sender proof"
        );
        require(
            msg.value >= _mintAmount * PRESALE_PRICE,
            "not enough ETH sent"
        );

        uint256 supply = totalSupply();
        require(
            supply + _mintAmount <= MAX_SUPPLY,
            "max collection limit exceeded"
        );

        mintedPerAddress[msg.sender] += _mintAmount;

        for (uint256 i = 0; i < _mintAmount; ) {
            _mint(msg.sender, supply + i);
            unchecked { ++i; }
        }
    }

    function checkProof(bytes32[] memory proof) external view returns (bool) {
        return
            MerkleProof.verify(
                proof,
                MerkleRoot,
                keccak256(abi.encodePacked(msg.sender))
            );
    }

    function tokensOfWalletOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 tokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](tokenCount);
        for (uint256 i; i < tokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokenIds;
    }

    function isApprovedForAll(address _owner, address operator)
        public
        view
        override(ERC721, IERC721)
        returns (bool)
    {
        MarketplaceProxyRegistry proxyRegistry = MarketplaceProxyRegistry(
            proxyRegistryAddress
        );
        if (
            address(proxyRegistry.proxies(_owner)) == operator ||
            projectProxy[operator]
        ) return true;
        return super.isApprovedForAll(_owner, operator);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        if (isRevealed) {
            return bytes(revealedURI).length > 0 ? string(abi.encodePacked(revealedURI, Strings.toString(tokenId))) : "";
        }
        return bytes(unrevealedURI).length > 0 ? string(abi.encodePacked(unrevealedURI)) : "";
    }

    // ONLY OWNER FUNCTIONS

    function setBaseURI(string memory unrevealedbaseURI_, string memory revealedbaseURI_) public onlyOwner {
        unrevealedURI = unrevealedbaseURI_;
        revealedURI = revealedbaseURI_;
    }

    function setIsRevealed() public onlyOwner {
        isRevealed = !isRevealed;
    }

    function setMerkleRoot(bytes32 _MerkleRoot) public onlyOwner {
        MerkleRoot = _MerkleRoot;
    }

    function setSaleState(SaleState _newState) public onlyOwner {
        saleState = _newState;
    }

    function setPrice(uint256 pub_price, uint256 pre_price) public onlyOwner {
        PRICE = pub_price;
        PRESALE_PRICE = pre_price;
    }

    function setProxyRegistry(address _proxyRegistryAddress) public onlyOwner {
        proxyRegistryAddress = _proxyRegistryAddress;
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        (bool success, ) = msg.sender.call{value: balance}("");
        require(success, "withdraw failed");
    }

    /** reserve function for team mints (giveaways & payments) */
    function teamMint(address _to, uint256 _reserveAmount) public onlyOwner {
        require(
            _reserveAmount > 0 &&
                _reserveAmount + teamMints < MAX_TEAMRESERVE + 1,
            "Not enough reserve left for team"
        );
        uint256 supply = totalSupply();
        teamMints = teamMints + _reserveAmount;

        for (uint256 i = 0; i < _reserveAmount; i++) {
            _safeMint(_to, supply + i);
        }
    }
}

contract OwnableDelegateProxy {}

contract MarketplaceProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}