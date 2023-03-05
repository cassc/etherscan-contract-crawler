// SPDX-License-Identifier: MIT

//████████ ██   ██ ███████     ███████  █████  ███    ███ ██ ██   ██    ██ 
//   ██    ██   ██ ██          ██      ██   ██ ████  ████ ██ ██    ██  ██  
//   ██    ███████ █████       █████   ███████ ██ ████ ██ ██ ██     ████   
//   ██    ██   ██ ██          ██      ██   ██ ██  ██  ██ ██ ██      ██    
//   ██    ██   ██ ███████     ██      ██   ██ ██      ██ ██ ███████ ██    
//                                                                         

pragma solidity 0.8.12;

// token
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";

// security
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

// utils
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract TheFamily is ERC721, AccessControl, ReentrancyGuard, ERC721Burnable  {

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    
    using Counters for Counters.Counter;
    using SafeMath for uint256;
    
    // mint
    bool public liveMint = false;
    uint256 public tokenPrice = 50000000000000000; //0.05 
    uint256 public maxSupply = 10000;
    uint256 public maxMintPerTx = 10;
    
    // public
    Counters.Counter private _tokenIdCounter;
    mapping (uint256 => string) private _tokenURIs;

    // private
    string private _metadata;

// =========== 

    event minted();

    modifier duringMint() {
        require(
            liveMint,
                "Mint is not live!"
                );
            _;
        }

    constructor() ERC721("The Family", "FAM") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
    }

// =========== mint

    function mint(uint256 quantity) 
        external 
        payable 
        duringMint 
        nonReentrant
    {
        require(
            msg.value == tokenPrice.mul(quantity),
            "Wrong amount of ether sent!"
        );

         require(
            quantity <= maxMintPerTx,
            "Max per tx!"
        );

        require(
            _tokenIdCounter.current().add(quantity) <= maxSupply,
            "Minting this many would exceed supply!"
        );

        _minter(payable(msg.sender), quantity);
    }

    function teamMint(address to, string calldata metadata_) 
        external 
        onlyRole(MINTER_ROLE) 
    {
        _safeMint(to, _tokenIdCounter.current() + 1);
        _tokenURIs[_tokenIdCounter.current() + 1] = metadata_;
        _tokenIdCounter.increment();
    }
    
// ========== internal

     function _minter(address payable sender, uint256 quantity) 
        internal 
    {
        for (uint256 i = 0; i < quantity; i++) {
            _safeMint(sender, _tokenIdCounter.current() + 1);
            _tokenURIs[_tokenIdCounter.current() + 1] = _metadata;
            _tokenIdCounter.increment();
        }
        emit minted();
    } 

    function _burn(uint256 tokenId) 
        internal 
        override 
        onlyRole(MINTER_ROLE)
    {
        super._burn(tokenId);
    }

// =========== utils

    function setMetadata(string calldata metadata_)
        external
        onlyRole(MINTER_ROLE) 
    {
       _metadata = metadata_;
    }

    function setTokenPrice(uint256 tokenPrice_)
        external
        onlyRole(MINTER_ROLE) 
    {
       tokenPrice = tokenPrice_;
    }

    function setMaxSupply(uint256 maxSupply_)
        external
        onlyRole(MINTER_ROLE) 
    {
       maxSupply = maxSupply_;
    }

    function setMaxMintTx(uint256 maxMintPerTx_)
        external
        onlyRole(MINTER_ROLE) 
    {
       maxMintPerTx = maxMintPerTx_;
    }

    function toggleMint() 
        external
        onlyRole(MINTER_ROLE) 
    {
        liveMint = !liveMint;
    }

// ========= view

function getSupply()
        external
        view
        returns (uint256)
    {
        return _tokenIdCounter.current();
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        return _tokenURIs[tokenId];
    }
    
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

// ========= 

     function withdraw()
        external 
        onlyRole(MINTER_ROLE) 
    {
        payable(payable(msg.sender)).transfer(address(this).balance);
    }

     receive () 
        external 
        payable 
        {}
}