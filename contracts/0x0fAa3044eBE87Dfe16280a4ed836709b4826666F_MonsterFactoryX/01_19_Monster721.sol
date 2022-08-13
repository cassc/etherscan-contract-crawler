// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.14;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "./ERC2981.sol";

contract MonsterFactoryX is
    Context,
    ERC721Enumerable,
    ERC721Burnable,
    ERC721URIStorage,
    ERC2981,
    AccessControl
{
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdTracker;

    string private baseTokenURI;

    address public owner;

    address public creator;
    
    address public signer;

    uint256 private MAX_SUPPLY;
    
    bool public isRevealed;

    uint256 private INITIAL_SUPPLY;

    uint256 public mintingFee = 0.03 ether;

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    //@notice Sign struct stores the sign bytes
    //@param v it holds(129-130) from sign value length always 27/28.
    //@param r it holds(0-66) from sign value length.
    //@param s it holds(67-128) from sign value length.
    //@param nonce unique value.

    struct Sign {
        uint8 v;
        bytes32 r;
        bytes32 s;
        uint256 nonce;
    }

    mapping(address => uint256) mintedCount;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    event MintingFeeUpdated(uint256 newMintingFee, uint256 mintingFee);

    event SignerChanged(address indexed signer, address indexed newSigner);

    event creatorChanged(address indexed newcreator, address indexed creator);

    constructor(
        string memory name,
        string memory symbol,
        string memory _baseTokenURI,
        address _creator
    ) ERC721(name, symbol) {
        baseTokenURI = _baseTokenURI;
        signer = _msgSender();
        owner = _msgSender();
        creator = _creator;
        MAX_SUPPLY = 3333;
        INITIAL_SUPPLY = 0;
        _setupRole(ADMIN_ROLE, msg.sender);
        _tokenIdTracker.increment();
    }

    function transferOwnership(address newOwner)
        external
        onlyRole(ADMIN_ROLE)
        returns (bool)
    {
        require(
            newOwner != address(0),
            "Ownable: Invalid address"
        );
        _revokeRole(ADMIN_ROLE, owner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        _setupRole(ADMIN_ROLE, newOwner);
        return true;
    }

    function setBaseURI(string memory _baseTokenURI) external onlyRole(ADMIN_ROLE) {
        baseTokenURI = _baseTokenURI;
    }

    function setCreator(address newcreator) external onlyRole(ADMIN_ROLE) {
        require(newcreator != address(0), "Invalid creator");
        creator = newcreator;
        emit creatorChanged(newcreator, creator);
    }
    
    function changeSigner(address newSigner) external onlyRole(ADMIN_ROLE) returns(bool) {
        require(newSigner != address(0), "Invalid Signer");
        address previousSigner = signer;
        signer = newSigner;
        emit SignerChanged(previousSigner, signer);
        return true;
    }

    function revealNFT() external onlyRole(ADMIN_ROLE) {
        isRevealed = true;
    }

    function setMintingFee(uint256 _mintingFee) external onlyRole(ADMIN_ROLE) {
        emit MintingFeeUpdated(_mintingFee, mintingFee);
        mintingFee = _mintingFee;
    }

    function batchMint(    
        string[] memory _tokenURI,
        uint96[] memory _royaltyFee,
        uint256 qty,
        Sign memory sign
        ) external virtual payable returns (uint256 _tokenId) {
        require(_tokenIdTracker.current() <= MAX_SUPPLY,"Minting limit reached");
        require(qty == _royaltyFee.length && qty == _tokenURI.length, "Invalid Quantity");
        require(mintedCount[msg.sender] + qty <= 3, "Minting limit exceeded");
        require((mintingFee * qty) == msg.value, "Insufficiet minting fee");
        verifySign(_tokenURI, qty, _msgSender(), sign); 
        for(uint256 i = 0; i < qty ; i++) {
            _tokenId = _tokenIdTracker.current();
            _mint(_msgSender(), _tokenId);
            _setTokenURI(_tokenId, _tokenURI[i]);
            _tokenIdTracker.increment();
            _setTokenRoyalty(_tokenId, _msgSender(), _royaltyFee[i]);
        }
        mintedCount[msg.sender] += qty;
        payable(owner).transfer(msg.value);
    }

    function addSupply(uint256 supply) external onlyRole(ADMIN_ROLE) {
        require(isRevealed != false,"Reveal NFTs") ;
        INITIAL_SUPPLY = MAX_SUPPLY;
        MAX_SUPPLY += supply;
        isRevealed = false;
    } 

    function baseURI() external view returns (string memory) {
        return _baseURI();
    }


    function _burn(uint256 tokenId)
        internal
        override(ERC721, ERC721URIStorage)
    {
        _resetTokenRoyalty(tokenId);
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        if(tokenId > INITIAL_SUPPLY && tokenId <= MAX_SUPPLY) {
            if(isRevealed) {
                return super.tokenURI(tokenId);
            }
            else {
                return "https://gateway.pinata.cloud/ipfs/QmYP1psMVSFedFxi6iXUiyRWfQNFyBUvjFmJgGSdtRUkah";
            }
        }

        else {
            return super.tokenURI(tokenId);
        }

    }

    function _baseURI() internal view override returns (string memory) {
        return baseTokenURI;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, ERC721Enumerable, ERC2981, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _encode(string[] memory tokenURI_, uint256 qty_) internal pure returns(bytes memory) {
        bytes memory hash;
        hash = abi.encode(tokenURI_, qty_);
        return hash;
    }

    function verifySign(string[] memory _tokenURI, uint256 _qty, address caller, Sign memory sign) internal view {
        bytes memory URI_hash = _encode(_tokenURI, _qty);
        bytes32 hash = keccak256(abi.encodePacked(this, caller, URI_hash, sign.nonce));
        require(signer == ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)), sign.v, sign.r, sign.s), "Owner sign verification failed");
    }

}