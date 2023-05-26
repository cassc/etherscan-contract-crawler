/**
SPDX-License-Identifier: MIT

YYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYY
YYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYY
YYYYYYYYYYYYYYYYYYYYYPPPP5555PP5YYY5YYYYYYYYYYYYYY
YYYYYYYYYYYYYYYY55PPPGB&&&##BB###BPBB5YYYYYYYYYYYY
YYYYYYYYYYYYY5PGB#&&&&&&&&&&&&&&&&&#&BPPPGPYYYYYYY
YYYYYYYYYYYYY5PGB#&&&&&&&&&&&&&&&&&&&&#&&BPYYYYYYY
YYYYYYYYYYYPGBB&&&&&&&&&&##&&&&&&&#&&&&&&##G5YYYYY
YYYYYYYYYYY55GB#&&&#BBBP5PBB5JYY5YJP#&&&#55P5YYYYY
YYYYYYYYYYYYPPGBBJ~7YJ^~7J?:   .77?7&&&&GYYYYYYYYY
YYYYYYYYYYYYY5557~ .^?!.:?. :^^~J7Y5&GPB5YYYYYYYYY
YYYYYYYYYYYYYYY5::..^7J^:!!7!^^~7J?5J?7~PYYYYYYYYY
YYYYYYYYYYYYYYY5J7~!?Y77^.^!~~777!~7777J5YYYYYYYYY
YYYYYYYYYYYYYYPP5?^^^~~~:^^~~7?~~~!P#P55YYYYYYYYYY
YYYYYYYYYYYYYY555J!7J7!7J!!J!~^~!J5P55YYYYYYYYYYYY
YYYYYYYYYYYYYYYYY5YY!~~^^~~^~!?5PP555YYYYYYYYYYYYY
YYYYYYYYYYYYYYYYY55GGPPYJ77!~!5#GGGBBGP5YYYYYYYYYY
YYYYYYYYYYYYYYYY5BPGGPG7!~^~~JPGGGGGGGGGGP5YYYYYYY
YYYYYYYYYYYYYYYYGPPPPPPJ~~JPPGGGPPPGGGGGBBGYYYYYYY
YYYYYYYYYYYYYYYP555P5PPP!YGGG55555555PPPGBPYYYYYYY
YYYYYYYYYYYYYY55YPY555BG!JP5GPY5555555PPPGBYYYYYYY
YYYYYYYYYYYYYYPYPGY5YPGP!?PYPB5PPPGPY55PPPBPYYYYYY
YYYYYYYYYYYYY5PYPGJ55BPP!?GPGBGPPPPBYY5PPPBBYYYYYY
YYYYYYYYYYYYY5PYPGJ55PPP??GPPPPPPPPPGJ55PPGB5YYYYY
YYYYYYYYYYYYYP55PB5PPPGP??PGPPPPPPPPGYY5PPGBPYYYYY

     ██╗██╗   ██╗██╗  ██╗██╗██╗   ██╗███████╗██████╗ ███████╗███████╗
     ██║██║   ██║██║ ██╔╝██║██║   ██║██╔════╝██╔══██╗██╔════╝██╔════╝
     ██║██║   ██║█████╔╝ ██║██║   ██║█████╗  ██████╔╝███████╗█████╗  
██   ██║██║   ██║██╔═██╗ ██║╚██╗ ██╔╝██╔══╝  ██╔══██╗╚════██║██╔══╝  
╚█████╔╝╚██████╔╝██║  ██╗██║ ╚████╔╝ ███████╗██║  ██║███████║███████╗
 ╚════╝  ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═══╝  ╚══════╝╚═╝  ╚═╝╚══════╝╚══════╝                                                                 
*/

pragma solidity ^0.8.13;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol"; 
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";

/// @title Lost in Jukiverse
/// @author iqbal (github.com/2pai)
/// @notice Jukiverse is 3456 Jukis based on Indonesia comic character, Si Juki.
contract Jukiverse is ERC721A, ERC2981, EIP712, ReentrancyGuard, Ownable {
    using Strings for uint256;
    using ECDSA for bytes32;

    enum Stage {
        PublicSalePause,
        PublicSale,
        PresalePause,
        Presale,
        FinalPublicSalePause,
        FinalPublicSale,
        Pause
    }
    uint256 public constant PRICE = 0.12 ether;
    uint256 public constant WL_PRICE = 0.09 ether;
    uint256 public constant PUBLIC_LIMIT = 6;
    uint256 public constant WL_SUPPLY = 2251;
    uint256 public constant PUBLIC_SUPPLY = 1205;
    uint256 public constant MAX_SUPPLY = 3456;
    bytes32 public constant MINTER_TYPEHASH = 
        keccak256("Minter(address recipient,uint256 amount)"); 
    address private constant WALLET_A = 0xB33876BCD5aDB5570CA75e68162bF56A7F221B98;
    address private constant WALLET_B = 0x9a69B8134C7676Db6B84a868d6bDE5B989Bb32CB;
    address private constant WALLET_C = 0x2cad0E5841F859715ea43E2409295991BCE74928;
    
    string public baseURI;
    Stage public stage;
    address public signer;


    modifier notContract() {
        require(!_isContract(_msgSender()), "NOT_ALLOWED_CONTRACT");
        require(_msgSender() == tx.origin, "NOT_ALLOWED_PROXY");
        _;
    }

    
    mapping(address => uint256) public WhitelistMinter;
    mapping(address => uint256) public PublicMinter;

    constructor(
            string memory _previewURI,
            address _signer
        )
        ERC721A("Lost in Jukiverse", "JUKI")
        EIP712("Jukiverse", "1.0.0")
    {
        stage = Stage.PublicSalePause;
        signer = _signer;
        baseURI = _previewURI;
        _setDefaultRoyalty(0xefDD4c0ef4e9031cE80B7Aea3ab1e888C4712C29, 500);
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
    function JukilistMint(uint256 _amount, uint256 _limit, bytes calldata _signature) 
        nonReentrant
        notContract
        external 
        payable 
    {
        require(stage == Stage.Presale, "STAGE_NMATCH");
        require(WhitelistMinter[msg.sender] + _amount <= _limit, "LIMIT_EXCEDEED");
        require(signer == _verify(_msgSender(), _limit, _signature), "INVALID_SIGNATURE");
        require(totalSupply() + _amount <= MAX_SUPPLY, "SUPPLY_EXCEDEED");
        require(msg.value >= (WL_PRICE * _amount), "INSUFFICIENT_FUND");

        WhitelistMinter[msg.sender] += _amount;
        _mint(msg.sender, _amount);

    }
    /// @notice Mint NFT for public user 
    /// @param _amount amount of NFT to be minted
    function publicMint(uint256 _amount) 
        nonReentrant
        notContract
        external 
        payable 
    {
        require(stage == Stage.PublicSale, "STAGE_NMATCH");
        require(_amount <= 3, "LIMIT_TX");
        require(PublicMinter[msg.sender] + _amount <= PUBLIC_LIMIT, "LIMIT_EXCEDEED");
        require(totalSupply() + _amount <= PUBLIC_SUPPLY, "SUPPLY_EXCEDEED");
        require(msg.value >= (PRICE * _amount), "INSUFFICIENT_FUND");

        PublicMinter[msg.sender] += _amount;
        _mint(msg.sender, _amount);


    }
    
    /// @notice Mint NFT for public user 
    /// @param _amount amount of NFT to be minted
    function finalMint(uint256 _amount) 
        nonReentrant
        notContract
        external 
        payable 
    {
        require(stage == Stage.FinalPublicSale, "STAGE_NMATCH");
        require(_amount <= 3, "LIMIT_TX");
        require(PublicMinter[msg.sender] + _amount <= PUBLIC_LIMIT, "LIMIT_EXCEDEED");
        require(totalSupply() + _amount <= MAX_SUPPLY, "SUPPLY_EXCEDEED");
        require(msg.value >= (PRICE * _amount), "INSUFFICIENT_FUND");

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
        uint256 walletABalance = address(this).balance * 50 / 100;
        uint256 walletBBalance = address(this).balance * 15 / 100;
        uint256 walletCBalance = address(this).balance * 35 / 100;

        sendValue(payable(WALLET_A), walletABalance);
        sendValue(payable(WALLET_B), walletBBalance);
        sendValue(payable(WALLET_C), walletCBalance);
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