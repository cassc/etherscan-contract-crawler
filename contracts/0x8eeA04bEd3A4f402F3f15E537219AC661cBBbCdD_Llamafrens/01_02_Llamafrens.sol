// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./ERC721_efficient.sol";

contract Llamafrens is ERC721Enumerable, Ownable {
    uint256 public PRE_PRICE = 0.04 ether;
    uint256 public PRICE = 0.04 ether;
    address immutable ASTERIA_ADDRESS =
        0x92768aC8daf1005d00C48Ba30A9925ef12d59f8A;
    address immutable AYDAN_ADDRESS =
        0x59cA02155ea6a106015B2d869814D4Ddd951889F;

    uint256 public immutable MAX_SUPPLY_PLUS1 = 556;
    uint256 public immutable MAX_PRESALE_PLUS1 = 556;
    uint256 public immutable MAX_PER_TXN_PLUS1 = 3;

    enum SaleState { pause, presale, publicsale }
    SaleState public saleState;

    bytes32 public MerkleRoot = 0x043187469c11d994528ce9cfc4d390f2e7c7b41a0cc2cbc52b96aabf046ad3b6;
    mapping(address => uint256) public mintedPresale;     

    bool public isTeamReserved;
    address public proxyRegistryAddress = 0xa5409ec958C83C3f309868babACA7c86DCB077c1;
    mapping(address => bool) public projectProxy;

    string public revealedURI;
    string public unrevealedURI = "ipfs://QmbXK2DMeZPMAmveRvKhxnCa2RkFfwsRMpCuWbhr87A4YD";
    bool public isRevealed;

    constructor() ERC721("Llamafrens", "LF") {}

    /**
     * USER FUNCTIONS
     */

    function mint(uint256 _amount) external payable {
        require(saleState == SaleState.publicsale, "public sale not active");
        require(msg.sender == tx.origin, "no proxy transactions");
        require(_amount < MAX_PER_TXN_PLUS1, "max per session exceeded");
        require(msg.value >= _amount * PRICE, "not enough ETH");

        uint256 _supply = totalSupply();
        require(_supply + _amount < MAX_SUPPLY_PLUS1, "max supply exceeded");

        for (uint256 i = 0; i < _amount; ) {
            _mint(msg.sender, _supply + i);
            unchecked { ++i; }
        }
    }

    function mintPresale(bytes32[] memory _proof) external payable {
        require(saleState == SaleState.presale, "presale not active");
        require(msg.sender == tx.origin, "no proxy transactions");
        require(msg.value >= PRE_PRICE, "not enough ETH");
        require(mintedPresale[msg.sender] < 1, "address already minted");

        require(
            MerkleProof.verify(
                _proof,
                MerkleRoot,
                keccak256(abi.encodePacked(msg.sender))
            ),
            "invalid sender proof"
        );

        uint256 _next_token = totalSupply();
        unchecked { _next_token++; }

        require(_next_token < MAX_PRESALE_PLUS1, "max presale supply exceeded");

        mintedPresale[msg.sender] = 1;
        _mint(msg.sender, _next_token); 
    }

    /**
     * VIEW FUNCTIONS
     */

    function checkProof(address a, bytes32[] memory proof) external view returns (bool) {
        return
            MerkleProof.verify(
                proof,
                MerkleRoot,
                keccak256(abi.encodePacked(a))
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

    /**
     * OVERRIDE FUNCTIONS
     */

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
            address(proxyRegistry) != address(0) &&
            (address(proxyRegistry.proxies(_owner)) == operator ||
                projectProxy[operator])
        ) return true;
        return super.isApprovedForAll(_owner, operator);
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

        if (isRevealed) {
            return
                bytes(revealedURI).length > 0
                    ? string(
                        abi.encodePacked(revealedURI, Strings.toString(tokenId))
                    )
                    : "";
        }
        return
            bytes(unrevealedURI).length > 0
                ? string(abi.encodePacked(unrevealedURI))
                : "";
    }

    /**
     * OWNER FUNCTIONS
     */
    function teamReserveMint() external onlyOwner {
        require(!isTeamReserved, "team reserves have already been minted");
        uint256 i = 0;
        for ( ; i < 26 ; ) {
            _mint(AYDAN_ADDRESS, i);
            unchecked { ++i; }
        }
        isTeamReserved = true;
    }

    function setBaseURI(
        string memory unrevealedbaseURI_,
        string memory revealedbaseURI_
    ) public onlyOwner {
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
        PRE_PRICE = pre_price;
    }

    function setProxyRegistry(address _proxyRegistryAddress) public onlyOwner {
        proxyRegistryAddress = _proxyRegistryAddress;
    }

    function withdraw() public onlyOwner {
        (bool asteria_success, ) = ASTERIA_ADDRESS.call{value: address(this).balance / 20}("");
        require(asteria_success, "asteria withdraw failed");

        (bool success, ) = AYDAN_ADDRESS.call{value: address(this).balance}("");
        require(success, "withdraw failed");
    }
}

contract OwnableDelegateProxy {}

contract MarketplaceProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}