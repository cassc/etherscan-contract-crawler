// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.8.9;

import "Pausable.sol";
import "ERC721ABurnable.sol";

abstract contract ContractGlossary {
    function getAddress(string memory name)
        public
        view
        virtual
        returns (address);
}

abstract contract Farmer {
    function minFarmSizeByType(string memory name)
        public
        view
        virtual
        returns (uint256);

    function minStableTerm() public view virtual returns (uint256);

    function maxStableTerm() public view virtual returns (uint256);

    function maxFarmSize() public view virtual returns (uint256);

    function minDestablingFee() public view virtual returns (uint256);

    function maxOwnerFee() public view virtual returns (uint256);
}

abstract contract Stabler {
    function ownerOf(uint256 tokenId) public view virtual returns (address);
}

contract Land is ERC721ABurnable, Pausable {
    uint256 public _tokenIdCounter;
    address public skyFallsPyramidAddress;
    address private extMintAddress;
    address public FarmAddress;
    Farmer FarmContract;

    string public _baseTokenURI;
    uint256 private _maxSupply;

    mapping(uint256 => string) public landTypes;
    mapping(uint256 => bool) public FreeStable;

    ContractGlossary Index;

    event LandMinted(
        uint256 amount_req,
        uint256 indexed _tokenIdCounter,
        string landType,
        bool freeStable
    );

    event NContigLandMinted(
        uint256 amount_req,
        uint256 indexed _tokenIdCounter,
        string landType,
        bool freeStable
    );

    constructor(
        string memory name,
        string memory symbol,
        string memory baseTokenURI,
        uint256 maxSupply,
        address indexContract
    ) ERC721A(name, symbol) {
        _maxSupply = maxSupply;
        _baseTokenURI = baseTokenURI;
        _tokenIdCounter = 0;
        Index = ContractGlossary(indexContract);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function mintTransfer(address to, uint256 amount_req)
        external
        whenNotPaused
    {
        require(
            msg.sender == Index.getAddress("SkyFalls"),
            "Must be called from Pyramid Contract"
        );
        ensureMintConditions(amount_req);
        emit LandMinted(amount_req, _tokenIdCounter, "SkyFalls", true);
        //Mint number of tokens
        for (uint256 i = 1; i <= amount_req; i++) {
            landTypes[_tokenIdCounter + i] = "SkyFalls";
            FreeStable[_tokenIdCounter + i] = true;
        }
        _safeMint(to, amount_req);
        _tokenIdCounter += amount_req;
    }

    function setBaseUri(string memory baseUri) external onlyOwner {
        _baseTokenURI = baseUri;
    }

    function mint(
        address to,
        uint256 amount_req,
        string memory landType,
        bool freeStable
    ) external onlyOwner {
        ensureMintConditions(amount_req);
        emit NContigLandMinted(
            amount_req,
            _tokenIdCounter,
            landType,
            freeStable
        );
        //Mint number of tokens
        for (uint256 i = 1; i <= amount_req; i++) {
            landTypes[_tokenIdCounter + i] = landType;
            FreeStable[_tokenIdCounter + i] = freeStable;
        }
        _safeMint(to, amount_req);
        _tokenIdCounter += amount_req;
    }

    function eMint(
        address to,
        uint256 amount_req,
        string memory landType,
        bool freeStable
    ) external whenNotPaused {
        require(
            msg.sender == extMintAddress,
            "MUST BE CALLED BY SPECIFIED EXTERNAL MINT ADDRESS"
        );
        emit NContigLandMinted(
            amount_req,
            _tokenIdCounter,
            landType,
            freeStable
        );
        //Mint number of tokens
        for (uint256 i = 1; i <= amount_req; i++) {
            landTypes[_tokenIdCounter + i] = landType;
            FreeStable[_tokenIdCounter + i] = freeStable;
        }
        ensureMintConditions(amount_req);
        _safeMint(to, amount_req);
        _tokenIdCounter += amount_req;
    }

    function eBurn(uint256 tokenID) public {
        require(
            msg.sender == extMintAddress,
            "MUST BE CALLED BY SPECIFIED EXTERNAL MINT ADDRESS"
        );
        burn(tokenID);
    }

    function setExtMintAddress(address contractAddress) public onlyOwner {
        require(contractAddress != address(0), "CANNOT BE 0x0 ADDRESS");
        extMintAddress = contractAddress;
    }

    function MAX_TOTAL_MINT() public view returns (uint256) {
        return _maxSupply;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return string(abi.encodePacked(_baseTokenURI));
    }

    function ensureMintConditions(uint256 count) internal view {
        require(totalSupply() + count <= _maxSupply, "EXCEEDS_MAX_SUPPLY");
    }
}