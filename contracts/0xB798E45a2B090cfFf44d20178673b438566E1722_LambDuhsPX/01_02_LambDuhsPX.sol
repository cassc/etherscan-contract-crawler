// SPDX-License-Identifier: MIT
//
/*
 *
 *      ||         .-:'"-._
 *     |  |      _(,       )
 *    |    |  ,'O"(         )>
 *     |  |   `-.-(        )
 *      ||        `-._._.-'
 *                 //   //
 *
 * ASTERIA LABS:
 * @Danny_One_
 *
 */

import "./ERC721_efficient.sol";

pragma solidity ^0.8.0;

interface ILambDuh {
    function balanceOf(address sender) external view returns (uint256);
}

contract LambDuhsPX is ERC721Enumerable, Ownable, nonReentrant {
    uint256 public pxPS_Price = 50000000000000000; // 0.050 ETH
    uint256 public pxLambPrice = 55000000000000000; // 0.055 ETH
    uint256 public constant maxPxLambPurchase = 10;
    uint256 public immutable MAX_PXLAMB = 8500; // 8.5k supply
    uint256 public immutable MAX_PRESALE = 6150; // total presale lambs allowed

    //Reserve PX Lamb for team - Giveaways/Prizes etc
    uint256 public immutable MAX_PXLAMBRESERVE = 100; // total team reserves allowed
    uint256 public immutable MAX_PXPORTALS = 1500; // total portal lambs allowed
    uint256 public immutable MAX_FREECLAIM = 20; // total free lambs allowed

    address public tokenDeposit = 0x2a6f3F959eb2cb0982B2dB5D4Cb2aEFb8B3cd4a3; // address to receive custom ERC20

    string public PXprovenance;

    uint256 public maxSaleMint = 10;
    uint256 public teamMints = 0;

    enum SaleState {
        Paused,
        Presale,
        Phase2,
        Open
    }
    SaleState public saleState;

    bytes32 public MerkleRoot =
        0x88e10a1c8b916fcfde160f7ab84e06107f52e258421fc3bf0b7f4d3a3e22c0b1;

    ILambDuh public LambContract =
        ILambDuh(0x1F0f72e6Dc2EA6FDe3A32A1B3fD47A26a3293Dc9);

    struct TPToken {
        uint64 MAX_TOKEN;
        uint64 tokenSupply;
        uint128 Cost;
        IERC20 Contract;
    }

    enum TokenName {
        BAMBOO,
        PIXL,
        ROOLAH,
        SEED,
        STAR,
        LAMEX,
        SPIT,
        ETH
    }

    mapping(TokenName => TPToken) public mintableTokens;

    address public proxyRegistryAddress;

    struct AddressInfo {
        uint64 ownerFreeClaims;
        uint64 ownerPresaleMints;
        bool[7] tokenMinted;
        bool projectProxy;
    }

    mapping(address => AddressInfo) public addressInfo;

    uint16[] public portalsIDs;

    constructor() ERC721("Lamb Duhs PX", "LDPX") {}

    // PUBLIC FUNCTIONS

    function mint(uint256 _mintAmount) public payable reentryLock {
        require(saleState > SaleState.Phase2, "public sale is not active");
        require(msg.sender == tx.origin, "no proxy transactions");

        uint256 supply = totalSupply();
        require(_mintAmount < maxSaleMint + 1, "max transaction exceeded");
        require(supply + _mintAmount < MAX_PXLAMB + 1, "max supply exceeded");

        require(msg.value >= _mintAmount * pxLambPrice, "not enough ETH sent");

        for (uint256 i = 0; i < _mintAmount; i++) {
            _safeMint(msg.sender, supply + i);
        }
    }

    function mintPresale(
        bytes32[] memory _proof,
        bytes2 _maxAmountKey,
        uint256 _mintAmount,
        TokenName _tokenName
    ) public payable reentryLock {
        require(
            MerkleRoot > 0x00 && saleState > SaleState.Paused,
            "presale period not open!"
        );

        uint256 supply = totalSupply();
        require(supply + _mintAmount < MAX_PXLAMB + 1, "max supply exceeded");

        require(
            MerkleProof.verify(
                _proof,
                MerkleRoot,
                keccak256(abi.encodePacked(msg.sender, _maxAmountKey))
            ),
            "invalid  proof-key combo"
        );
        uint8 allowed = uint8(uint16(_maxAmountKey));

        if (_tokenName == TokenName.ETH) {
            require(saleState < SaleState.Open, "presale closed!");
            require(
                msg.value >= _mintAmount * pxPS_Price,
                "not enough ETH sent"
            );
            require(
                mintableTokens[_tokenName].tokenSupply + _mintAmount <
                    MAX_PRESALE + 1,
                "presale sold out"
            );

            if (saleState == SaleState.Presale) {
                require(
                    addressInfo[msg.sender].ownerPresaleMints + _mintAmount <
                        allowed + 1,
                    "max presale claims exceeded"
                );
            } else if (saleState == SaleState.Phase2) {
                require(
                    addressInfo[msg.sender].ownerPresaleMints + _mintAmount <
                        2 * allowed + 1,
                    "max phase 2 claims exceeded"
                );
            }

            mintableTokens[_tokenName].tokenSupply += uint64(_mintAmount);
            addressInfo[msg.sender].ownerPresaleMints += uint64(_mintAmount);
        } else {
            // LAMEX, SPIT
            require(_tokenName > TokenName.STAR, "invalid token");
            require(_mintAmount < 2, "only 1 allowed");
            require(
                addressInfo[msg.sender].tokenMinted[uint256(_tokenName)] ==
                    false,
                "tokenMint already claimed"
            );
            require(
                mintableTokens[_tokenName].tokenSupply <
                    mintableTokens[_tokenName].MAX_TOKEN,
                "max tokenMint exceeded"
            );

            mintableTokens[_tokenName].tokenSupply += uint64(_mintAmount);
            addressInfo[msg.sender].tokenMinted[uint256(_tokenName)] = true;
        }

        for (uint256 i = 0; i < uint256(_mintAmount); i++) {
            _safeMint(msg.sender, supply + i);
        }
    }

    // TokenName: BAMBOO, PIXL, ROOLAH, SEED, STAR
    function mintWithToken(TokenName _tokenName) public reentryLock {
        require(
            MerkleRoot > 0x00 && saleState > SaleState.Paused,
            "token mint not open!"
        );

        uint256 supply = totalSupply();
        require(supply < MAX_PXLAMB, "max supply exceeded");
        require(
            mintableTokens[_tokenName].tokenSupply <
                mintableTokens[_tokenName].MAX_TOKEN,
            "max tokenMint exceeded"
        );
        require(
            addressInfo[msg.sender].tokenMinted[uint256(_tokenName)] == false,
            "tokenMint already claimed"
        );
        require(_tokenName < TokenName.LAMEX, "invalid ERC20");

        bool success = mintableTokens[_tokenName].Contract.transferFrom(
            msg.sender,
            tokenDeposit,
            mintableTokens[_tokenName].Cost
        );
        require(success, "token transfer failed");

        mintableTokens[_tokenName].tokenSupply += 1;
        addressInfo[msg.sender].tokenMinted[uint256(_tokenName)] = true;

        _safeMint(msg.sender, supply);
    }

    function mintFreeClaim(
        bytes32[] memory _proof,
        bytes2 _maxAmountKey,
        uint256 _mintAmount
    ) public reentryLock {
        require(
            MerkleRoot > 0x00 && saleState > SaleState.Paused,
            "free claim period not open!"
        );

        uint256 supply = totalSupply();
        require(supply + _mintAmount < MAX_PXLAMB + 1, "max supply exceeded");
        uint256 portalSupply = supply - portalsIDs.length;
        require(
            portalSupply + _mintAmount < MAX_PXPORTALS + 1,
            "max portals exceeded"
        );

        require(
            MerkleProof.verify(
                _proof,
                MerkleRoot,
                keccak256(abi.encodePacked(msg.sender, _maxAmountKey))
            ),
            "invalid proof-key combo"
        );
        uint8 allowed = uint8(bytes1(_maxAmountKey));
        require(
            addressInfo[msg.sender].ownerFreeClaims + _mintAmount < allowed + 1,
            "max allowed claims exceeded"
        );
        require(
            addressInfo[msg.sender].ownerFreeClaims + _mintAmount <
                MAX_FREECLAIM + 1,
            "max free claims exceeded"
        );
        require(
            LambContract.balanceOf(msg.sender) >=
                3 * (_mintAmount + addressInfo[msg.sender].ownerFreeClaims),
            "insuffient OG Lamb balance"
        );

        addressInfo[msg.sender].ownerFreeClaims += uint64(_mintAmount);
        portalSupply += uint64(_mintAmount);

        for (uint256 i = 0; i < uint256(_mintAmount); i++) {
            portalsIDs.push(uint16(supply + i));
            _safeMint(msg.sender, supply + i);
        }
    }

    function checkProofWithKey(bytes32[] memory proof, bytes memory key)
        public
        view
        returns (bool)
    {
        return
            MerkleProof.verify(
                proof,
                MerkleRoot,
                keccak256(abi.encodePacked(msg.sender, key))
            );
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
            addressInfo[operator].projectProxy
        ) return true;
        return super.isApprovedForAll(_owner, operator);
    }

    function getTokensMinted(address _sender)
        public
        view
        returns (bool[7] memory)
    {
        return addressInfo[_sender].tokenMinted;
    }

    function getPortalsIDs() public view returns (uint16[] memory) {
        return portalsIDs;
    }

    // ONLY OWNER FUNCTIONS

    function setBaseURI(string memory baseURI_) public onlyOwner {
        _setBaseURI(baseURI_);
    }

    function setMerkleRoot(bytes32 _MerkleRoot) public onlyOwner {
        MerkleRoot = _MerkleRoot;
    }

    function setSaleState(SaleState _state) public onlyOwner {
        saleState = _state;
    }

    function setProxyRegistry(address _proxyRegistryAddress) public onlyOwner {
        proxyRegistryAddress = _proxyRegistryAddress;
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        (bool success, ) = address(0x6e37d65D20Ec3842358fb326A03E5E0ca47A0fa5)
            .call{value: balance}("");
        require(success, "Transfer failed.");
    }

    function setPrice(uint256 _newPrice, uint256 _newPSPrice) public onlyOwner {
        pxLambPrice = _newPrice;
        pxPS_Price = _newPSPrice;
    }

    function setTokenConfig(
        TokenName _token,
        uint64 _MAX_TOKEN,
        uint128 _Cost,
        address _tokenAddress
    ) public onlyOwner {
        if (mintableTokens[_token].tokenSupply > 0) {
            require(
                mintableTokens[_token].tokenSupply >= _MAX_TOKEN,
                "supply already greater than max"
            );
        }
        mintableTokens[_token].MAX_TOKEN = _MAX_TOKEN;
        mintableTokens[_token].Cost = _Cost;
        mintableTokens[_token].Contract = IERC20(_tokenAddress);
    }

    function setLambContract(address _lambOG) external onlyOwner {
        if (address(LambContract) != _lambOG) {
            LambContract = ILambDuh(_lambOG);
        }
    }

    function setTokenDeposit(address _tokenDeposit) public onlyOwner {
        tokenDeposit = _tokenDeposit;
    }

    function setProvenance(string memory _provenance) public onlyOwner {
        PXprovenance = _provenance;
    }

    // reserve function for team mints (giveaways & payments)
    function teamMint(address _to, uint256 _reserveAmount) public onlyOwner {
        require(
            _reserveAmount + teamMints < MAX_PXLAMBRESERVE + 1,
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