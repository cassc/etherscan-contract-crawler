// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


error NotOwner();
error IvalidAmount();
error MaxSupplyExceeded();
error NftMintLimitExceeded();
error FailedToSendEther();
error InvalidPercentage();
error InvalidAddress();
error InvalidPrice();
error InvalidLimit();


contract TMKNFTCollection is ERC721, ERC721Enumerable {
    using Counters for Counters.Counter;
    using Strings for uint256;
    Counters.Counter private _tokenIds;

    IERC20 public immutable token = IERC20(0xb6d54DbAc2cB10Dd97200aa4fdf9B49ae858EEEc);
    address payable public owner = payable(0x7b25845A8d16ffF240cdB0CF8cB27fCE681B25E5);
    mapping(address => bool) public whitelist;
    mapping(address => uint256) public commissionEarnedToken;
    mapping(address => uint256) public commissionEarnedEth;

    uint8 public immutable userLimit = 5;
    uint16 public immutable maxSupply = 500;
    uint8 public immutable discountPercentage = 50;
    uint256 public tokenPrice = 250000 ether;
    uint256 public ethPrice = 0.15 ether;
    uint256 public refferalPercentage = 5;

    modifier onlyOwner() {
        if(msg.sender != owner) {
            revert NotOwner();
        }
        _;
    }

    constructor() ERC721("Tomokachi", "TMK") {}

    function createNftToken(
        uint256 totalNfts,
        uint256 _amount,
        address refferal
    ) public {
        uint256 _tokenPrice = tokenPrice;
        if (whitelist[msg.sender]) {
            uint discountAmount = (totalNfts *
                _tokenPrice *
                discountPercentage) / 100;
            if(_amount != ((totalNfts * _tokenPrice) - discountAmount)) {
                revert IvalidAmount();
            }
            
        } else {
            if(_amount != totalNfts * _tokenPrice) {
                revert IvalidAmount();
            }
        }
        if(totalSupply() + totalNfts > maxSupply) {
            revert MaxSupplyExceeded();
        }
        uint256 _balance = balanceOf(msg.sender);
        if(_balance + totalNfts > userLimit) {
            revert NftMintLimitExceeded();
        }
        if (refferal != address(0)) {
            uint256 refferalAmount = (_amount * refferalPercentage) / 100;
            commissionEarnedToken[refferal] += refferalAmount;
            token.transferFrom(msg.sender, refferal, refferalAmount);
            token.transferFrom(msg.sender, owner, _amount - refferalAmount);
        } else {
            token.transferFrom(msg.sender, owner, _amount);
        }
        for (uint256 i = 0; i < totalNfts; i++) {
            _tokenIds.increment();
            uint256 newItemId = _tokenIds.current();
            _safeMint(msg.sender, newItemId);
        }
    }

    function createNftEth(
        uint256 totalNfts,
        address payable refferal
    ) public payable {
        uint256 _ethPrice = ethPrice;
        if (whitelist[msg.sender]) {
            uint discountAmount = (totalNfts * _ethPrice * discountPercentage) /
                100;
            if(msg.value != ((totalNfts * _ethPrice) - discountAmount)) {
                revert IvalidAmount();
            }
        } else {
            if(msg.value != totalNfts * _ethPrice) {
                revert IvalidAmount();
            }
        }
        if(totalSupply() + totalNfts > maxSupply) {
            revert MaxSupplyExceeded();
        }
        uint256 _balance = balanceOf(msg.sender);
        if(_balance + totalNfts > userLimit) {
            revert NftMintLimitExceeded();
        }
        if (refferal != address(0)) {
            uint256 refferalAmount = (msg.value * refferalPercentage) / 100;
            commissionEarnedEth[refferal] += refferalAmount;
            (bool success, ) = refferal.call{value: refferalAmount}("");
            if(!success) {
                revert FailedToSendEther();
            }

            (bool successOwner, ) = owner.call{
                value: msg.value - refferalAmount
            }("");
            if(!successOwner) {
                revert FailedToSendEther();
            }
        } else {
            (bool success, ) = owner.call{value: msg.value}("");
            if(!success) {
                revert FailedToSendEther();
            }
        }
        for (uint256 i = 0; i < totalNfts; i++) {
            _tokenIds.increment();
            uint256 newItemId = _tokenIds.current();
            _safeMint(msg.sender, newItemId);
        }
    }

    function addWhitelist(address[] calldata _users) public onlyOwner {
        for (uint256 i = 0; i < _users.length; i++) {
            whitelist[_users[i]] = true;
        }
    }

    function removeWhitelist(address[] calldata _users) public onlyOwner {
        for (uint256 i = 0; i < _users.length; i++) {
            whitelist[_users[i]] = false;
        }
    }

    function setTokenPrice(uint256 _tokenPrice) public onlyOwner {
        if(_tokenPrice == 0) {
            revert InvalidPrice();
        }
        tokenPrice = _tokenPrice;
    }

    function setEthPrice(uint256 _ethPrice) public onlyOwner {
        if(_ethPrice == 0) {
            revert InvalidPrice();
        }
        ethPrice = _ethPrice;
    }

    function setRefferalPercentage(
        uint256 _refferalPercentage
    ) public onlyOwner {
        if(_refferalPercentage > 100) {
            revert InvalidPercentage();
        }
        refferalPercentage = _refferalPercentage;
    }

    function setOwner(address payable _owner) public onlyOwner {
        if(_owner == address(0) || _owner == address(this)) {
            revert InvalidAddress();
        }
        owner = _owner;
    }

    function AllTokenIds() public view returns (uint256[] memory arr) {
        uint256 tokenCount = totalSupply();
        uint256[] memory tokenIds = new uint256[](tokenCount);
        for (uint256 i = 0; i < tokenCount; i++) {
            tokenIds[i] = tokenByIndex(i);
        }
        return tokenIds;
    }

    function getAllTokensbyAddress(
        address adr
    ) public view returns (uint256[] memory arr) {
        uint256 tokenCount = balanceOf(adr);

        uint256[] memory tokenIds = new uint256[](tokenCount);

        for (uint256 i = 0; i < tokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(adr, i);
        }
        return tokenIds;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return "https://ipfs.io/ipfs/QmTdviyZFGx6kUBT7prSqjb9BHTVtQALw2bUXTXiyhQYJt/";
    }

    function tokenURI(
        uint256 tokenId
    ) public view virtual override returns (string memory) {
        super._requireMinted(tokenId);

        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length > 0
                ? string(
                    abi.encodePacked(baseURI, tokenId.toString(), ".json")
                )
                : "";
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}