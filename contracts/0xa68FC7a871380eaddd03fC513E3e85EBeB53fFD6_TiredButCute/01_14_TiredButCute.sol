/**
SPDX-License-Identifier: MIT
*/

pragma solidity ^0.8.13;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol"; 
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";

/// @title TiredButCute
/// @author [email protected] twitter.com/0xYuru
/// @dev aa0cdefd28cd450477ec80c28ecf3574 0x8fd31bb99658cb203b8c9034baf3f836c2bc2422fd30380fa30b8eade122618d3ca64095830cac2c0e84bc22910eef206eb43d54f71069f8d9e66cf8e4dcabec1c 
contract TiredButCute is ERC721A, ERC2981, EIP712, ReentrancyGuard, Ownable {
    using Strings for uint256;
    using ECDSA for bytes32;

    enum Stage {
        SaleNotStart,
        PresaleSale,
        PublicSale,
        Pause
    }
    uint256 public constant PUBLIC_LIMIT = 2;
    uint256 public constant MAX_SUPPLY = 3333;
    bytes32 public constant MINTER_TYPEHASH = 
        keccak256("Minter(address recipient,uint256 amount)"); 
    
    string public baseURI;
    Stage public stage;
    address public signer;


    modifier notContract() {
        require(!_isContract(_msgSender()), "NOT_ALLOWED_CONTRACT");
        require(_msgSender() == tx.origin, "NOT_ALLOWED_PROXY");
        _;
    }

    
    mapping(address => uint256) public PublicMinter;
    mapping(address => uint256) public PresaleMinter;

    constructor(
            string memory _previewURI,
            address _owner,
            address _signer
        )
        ERC721A("TiredButCute", "BLANKET")
        EIP712("TiredButCute", "1.0.0")
    {
        stage = Stage.SaleNotStart;
        signer = _signer;
        baseURI = _previewURI;
        _mint(_owner, 1);
        _setDefaultRoyalty(0x83739A8Ec78f74Ed2f1e6256fEa391DB01F1566F, 750);
        _transferOwnership(_owner);
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
    /// @param _amount amount of NFT to be minted
    /// @param _limit amount of limit  NFT to be minted
    /// @param _signature signature to mint NFT
    function presaleMint(uint256 _amount, uint256 _limit, bytes calldata _signature) 
        nonReentrant
        notContract
        external 
        payable 
    {
        require(stage == Stage.PresaleSale, "STAGE_NMATCH");
        require(_amount <= 3, "LIMIT_TX");
        require(PresaleMinter[msg.sender] + _amount <= _limit, "LIMIT_EXCEDEED");
        require(signer == _verify(_msgSender(), _limit, _signature), "INVALID_SIGNATURE");
        require(totalSupply() + _amount <= MAX_SUPPLY, "SUPPLY_EXCEDEED");

        PresaleMinter[msg.sender] += _amount;
        _mint(msg.sender, _amount);

    }

    /// @notice mint NFT for whitelisted user 
    /// @param _amount amount of NFT to be minted
    function mint(uint256 _amount) 
        nonReentrant
        notContract
        external 
        payable 
    {
        require(_amount <= 2, "LIMIT_TX");
        require(stage == Stage.PublicSale, "STAGE_NMATCH");
        require(PublicMinter[msg.sender] + _amount <= PUBLIC_LIMIT, "LIMIT_EXCEDEED");
        require(totalSupply() + _amount <= MAX_SUPPLY, "SUPPLY_EXCEDEED");

        PublicMinter[msg.sender] += _amount;
        _mint(msg.sender, _amount);

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

    function _verify(address _recipient, uint256 _amountLimit, bytes calldata _sign)
        internal
        view
        returns (address)
    {
        bytes32 digest = _hashTypedDataV4(
            keccak256(abi.encode(MINTER_TYPEHASH, _recipient, _amountLimit))
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
        sendValue(payable(msg.sender), address(this).balance);
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

        return string(abi.encodePacked(baseURI, _id.toString()));
    }
    
}