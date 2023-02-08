//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import {CANONICAL_CORI_SUBSCRIPTION, CANONICAL_OPERATOR_FILTER_REGISTRY_ADDRESS} from "./Operator/Constants.sol";
import {IOperatorFilterRegistry} from "./Operator/IOperatorFilterRegistry.sol";

contract ValibotsTier1 is ERC721EnumerableUpgradeable, OwnableUpgradeable, ReentrancyGuardUpgradeable, ERC2981 {
    using SafeMathUpgradeable for uint256;

    event Mint(address minter, uint256 amount);

    string _baseTokenURI;

    uint256 public nftSupply;

    uint256 public nftPrice;

    bool public canMint;

    IERC20 public usdcToken;

    //Mapping with address and nft minted
    mapping(address => uint256) public nftMinted;
    
    function initialize(address _usdcToken) initializer public {
        __Ownable_init();
        __ReentrancyGuard_init();
        __ERC721_init("VALIBOTS Tier 1", "VBOTS");

        usdcToken = IERC20(_usdcToken);
        nftPrice = 400_000000;
    }


    //Others

    //

    function setUsdcToken(address _usdcToken) public onlyOwner {
        usdcToken = IERC20(_usdcToken);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setURI(string memory _URI) external onlyOwner {
        _baseTokenURI = _URI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        return string(abi.encodePacked(_baseTokenURI, Strings.toString(tokenId), ".json"));
    }

    

    //Blacklist

    mapping(address => bool) public blacklist;

    modifier noBlacklist(address _user) {
        require(blacklist[_user] == false, "NFT: You are blacklisted");
        _;
    }

    function setBlacklist(address user, bool isBlacklist) public onlyOwner {
        blacklist[user] = isBlacklist;
    }



    //Whitelist

    bytes32 private whitelist;
    bool public isWhitelistMint;

    function setWhitelist(bytes32 _whitelist) public onlyOwner {
        whitelist = _whitelist;
    }

    function setIsWhitelistMint(bool _isWhitelistMint) public onlyOwner {
        isWhitelistMint = _isWhitelistMint;
    }

    function isAddressWhitelisted(address account, bytes32[] calldata merkleProof) public view returns(bool) {
		bytes32 leaf = keccak256( abi.encodePacked(account) );
		bool whitelisted = MerkleProof.verify(merkleProof, whitelist, leaf);

		return whitelisted;
	}
    


    /* Mint Functions */

    function mintNft(address _to) internal noBlacklist(_to) {
        nftSupply += 1;
        _mint(_to, nftSupply);
        emit Mint(_to, 1);
    }

    address public mintReceiver;
    uint256 public mintBuyCounter;
    address public mintTeamReceiver;

    function mint(uint256 _amount, bytes32[] calldata merkleProof) public nonReentrant noBlacklist(_msgSender()) {
        address sender = _msgSender();
        mintBuyCounter += _amount;

        require(canMint == true, "NFT: Mint is disabled");
        if (isWhitelistMint) require(isAddressWhitelisted(sender, merkleProof), "NFT: You are not Whitelist");
        require(nftMinted[sender] + _amount <= 100, "NFT: Max mint hited");
        require(nftSupply + _amount <= 10_000, "NFT: Mint limit reached");

        usdcToken.transferFrom(sender, mintReceiver, nftPrice * _amount);

        nftMinted[sender] += _amount;

        for (uint256 i; i < _amount; i++) {
            mintNft(sender);
        }

        //Mint for team every 100 mint
        if (mintBuyCounter >= 100) {
            for (uint256 i; i < 15; i++) {
                mintNft(mintTeamReceiver);
            }

            mintBuyCounter = mintBuyCounter - 100;
        }
    }

    function mintTo(address[] calldata _to) public onlyOwner {
        for (uint256 i = 0; i < _to.length; i++) {
            mintNft(_to[i]);
        }
    }

    function setMintReceiver(address _mintReceiver) external onlyOwner {
        mintReceiver = _mintReceiver;
    }

    function setMintTeamReceiver(address _mintTeamReceiver) external onlyOwner {
        mintTeamReceiver = _mintTeamReceiver;
    }

    function setNftPrice(uint256 _nftPrice) external onlyOwner {
        nftPrice = _nftPrice;
    }
    
    function setCanMint(bool _canMint) external onlyOwner {
        canMint = _canMint;
    }

    function getSupply() external view returns (uint256) {
        return nftSupply - balanceOf(0x000000000000000000000000000000000000dEaD);
    }


    //OperatorFiler
    error OperatorNotAllowed(address operator);

    IOperatorFilterRegistry public constant OPERATOR_FILTER_REGISTRY =
        IOperatorFilterRegistry(CANONICAL_OPERATOR_FILTER_REGISTRY_ADDRESS);

    function setupOperatorFilter() external onlyOwner {
        if (address(OPERATOR_FILTER_REGISTRY).code.length > 0) {
            OPERATOR_FILTER_REGISTRY.registerAndSubscribe(address(this), CANONICAL_CORI_SUBSCRIPTION);
        }
    }


    //Utils

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721EnumerableUpgradeable, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function setRoyalities(address receiver, uint96 feeNumerator) external onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }
}