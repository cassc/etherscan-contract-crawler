/**
SPDX-License-Identifier: MIT
*/

pragma solidity ^0.8.13;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";

interface IJPGPeople {
    function ownerOf(uint256 tokenId) external view returns (address owner);
}
/// @title JPG People Date
/// @notice JPG People 2: In the Market for Love
/// @author [email protected] twitter.com/0xYuru
/// @dev aa0cdefd28cd450477ec80c28ecf3574 0x8fd31bb99658cb203b8c9034baf3f836c2bc2422fd30380fa30b8eade122618d3ca64095830cac2c0e84bc22910eef206eb43d54f71069f8d9e66cf8e4dcabec1c 
contract JPGPeopleDate is ERC721A, ERC2981, EIP712, ReentrancyGuard, Ownable {
    using ECDSA for bytes32;

    enum Stage {
        Pause,
        Sale
    }
    uint256 public constant PRICE = 0.04 ether;
    uint256 public constant MAX_SUPPLY = 8888;
    bytes32 public constant PUBLIC_MINTER_TYPEHASH = 
        keccak256("Minter(uint256 tokenId)"); 
    bytes32 public constant HOLDER_MINTER_TYPEHASH = 
        keccak256("Minter(address recipient,uint256 tokenId)");        
    address private constant WALLET_A = 0x83739A8Ec78f74Ed2f1e6256fEa391DB01F1566F;
    address private constant WALLET_B = 0x6969B743f0E3BFde2F97DAE01670979bE554d817;
    
    event Claimed(uint256 claimedTokenId, uint256 mintedTokenId, address minter);
    string public baseURI;
    Stage public stage;
    address public signer;


    modifier notContract() {
        require(!_isContract(_msgSender()), "NOT_ALLOWED_CONTRACT");
        require(_msgSender() == tx.origin, "NOT_ALLOWED_PROXY");
        _;
    }

    mapping(uint256 => bool) public tokenOwner;
    IJPGPeople public JPGContract;
    constructor(
            address _jpegContract,
            string memory _previewURI,
            address _signer,
            address _royaltyAddress
        )
        ERC721A("JPG People Date", "JPG2")
        EIP712("JPGPeopleDate", "1.0.0")
    {
        stage = Stage.Pause;
        signer = _signer;
        baseURI = _previewURI;
        _setDefaultRoyalty(_royaltyAddress, 800);
        JPGContract = IJPGPeople(_jpegContract);
    }

    /// @dev override tokenId to start from 1
    function _startTokenId() internal pure override returns (uint256){
        return 1;
    }

    function _isContract(address _addr) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(_addr)
        }
        return size > 0;
    }
    /// @notice mint NFT for whitelisted user 
    /// @param _signature signature to mint NFT
    function holderMint(uint256 _tokenId, bytes calldata _signature) 
        nonReentrant
        notContract
        external 
        payable 
    {
        require(stage == Stage.Sale, "STAGE_NMATCH");
        require(signer == _verifyHolderSale(_msgSender(), _tokenId, _signature), "INVALID_SIGNATURE");
        require(!tokenOwner[_tokenId], "ALREADY_CLAIMED");
        require(totalSupply() + 1 <= MAX_SUPPLY, "SUPPLY_EXCEDEED");

        tokenOwner[_tokenId] = true;
        _mint(msg.sender, 1);

        emit Claimed(_tokenId, _nextTokenId()-1,  msg.sender);
    }
    /// @notice Mint NFT for public user 
    function mint(uint256 _tokenId, bytes calldata _signature) 
        nonReentrant
        notContract
        external 
        payable 
    {
        require(stage == Stage.Sale, "STAGE_NMATCH");
        require(JPGContract.ownerOf(_tokenId) == msg.sender, "NOT_ELIGIBLE");
        require(signer == _verifyPublicSale(_tokenId, _signature), "INVALID_SIGNATURE");
        require(!tokenOwner[_tokenId], "ALREADY_CLAIMED");
        require(totalSupply() + 1 <= MAX_SUPPLY, "SUPPLY_EXCEDEED");
        require(msg.value >= PRICE, "INSUFFICIENT_FUND");
        
        tokenOwner[_tokenId] = true;
        _mint(msg.sender, 1);

        emit Claimed(_tokenId, _nextTokenId()-1,  msg.sender);

    }

    /// @notice Sent NFT Airdrop to an address
    /// @param _to list of address NFT recipient 
    /// @param _amount list of total amount for the recipient
    function gift(address[] calldata _to, uint256[] calldata _amount) 
        external 
        onlyOwner
    {
        for (uint256 i = 0; i < _to.length; i++) {
            require(totalSupply() + _amount[i] <= MAX_SUPPLY, "MAX_SUPPLY_EXCEEDED");
            _mint(_to[i], _amount[i]);

        }
    }

    function _verifyPublicSale(uint256 _tokenId, bytes calldata _sign)
        internal
        view
        returns (address)
    {
        bytes32 digest = _hashTypedDataV4(
            keccak256(abi.encode(PUBLIC_MINTER_TYPEHASH, _tokenId))
        );
        return ECDSA.recover(digest, _sign);
    }

    function _verifyHolderSale(address _recipient, uint256 _tokenId, bytes calldata _sign)
        internal
        view
        returns (address)
    {
        bytes32 digest = _hashTypedDataV4(
            keccak256(abi.encode(HOLDER_MINTER_TYPEHASH, _recipient, _tokenId))
        );
        return ECDSA.recover(digest, _sign);
    }
    function sendValue(address payable recipient, uint256 amount) 
        internal
    {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /// @notice Set base URI for the NFT.  
    /// @param _uri base URI (can be ipfs/https)
    function setBaseURI(string calldata _uri) 
        external 
        onlyOwner 
    {
        baseURI = _uri;
    }

    /// @notice Set Stage of NFT Contract.  
    /// @param _stage stage of nft contract
    function setStage(Stage _stage) 
        external 
        onlyOwner 
    {
        stage = _stage;
    }

    /// @notice Set signer for whitelist/redeem NFT.  
    /// @param _signer address of signer 
    function setSigner(address _signer) 
        external 
        onlyOwner 
    {
        signer = _signer;
    }
    /// @notice Set royalties for EIP 2981.  
    /// @param _recipient the recipient of royalty
    /// @param _amount the amount of royalty (use bps)
    function setRoyalties(address _recipient, uint96 _amount) 
        external 
        onlyOwner 
    {
        _setDefaultRoyalty(_recipient, _amount);
    }

    function withdrawAll() 
        external 
        onlyOwner 
    {
        require(address(this).balance > 0, "BALANCE_ZERO");
        uint256 walletABalance = address(this).balance * 40 / 100;
        uint256 walletBBalance = address(this).balance * 60 / 100;

        sendValue(payable(WALLET_A), walletABalance);
        sendValue(payable(WALLET_B), walletBBalance);
    }


    function supportsInterface(bytes4 interfaceId) 
        public 
        view 
        virtual 
        override(ERC721A, ERC2981) 
        returns (bool) 
    {
        // IERC165: 0x01ffc9a7, IERC721: 0x80ac58cd, IERC721Metadata: 0x5b5e139f, IERC29081: 0x2a55205a
        return ERC721A.supportsInterface(interfaceId) || ERC2981.supportsInterface(interfaceId);
    }


    function tokenURI(uint256 _id)
        public
        view
        override
        returns (string memory)
    {
        require(_exists(_id), "Token does not exist");

        return string(abi.encodePacked(baseURI, _toString(_id)));
    }
    
}