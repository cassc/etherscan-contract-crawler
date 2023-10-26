// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./ICryptoflatsNFTGen.sol";
import "./ERC721R.sol";

contract CryptoflatsNFT_2 is 
    ICryptoflatsNFTGen,
    ERC721r,
    Ownable,
    ERC2981 
{
    using Strings for uint256;

    IERC721 public WL_BOX;
    uint96 public constant DEFAULT_ROYALTY = 500; // 5%
    uint256 public constant EARLY_ACCESS_PRICE = 0.04 ether;
    uint256 public constant PUBLIC_SALE_PRICE = 0.07 ether;
    uint256 public constant MAX_SUPPLY = 4_444;
    uint256 public immutable gen;
    address payable public teamWallet;
    bytes32 public whitelistFreePurchaseRoot;
    bytes32 public whitelistEarlyAccessRoot;
    mapping(address => bool) public isWhitelistFreePurchaseUserMintedOnce;
    mapping(address => uint256) public getMintCountForEarlyAccessUser;
    mapping(uint256 => bool) public isWlBoxIdUsed;
    
    bool public isPublicSaleActive;

    constructor(
        address payable teamWallet_,
        uint256 gen_
    ) ERC721r("Cryptoflats-Gen2", "CNRS-2", MAX_SUPPLY) {
        gen = gen_;
        teamWallet = teamWallet_;
        _setDefaultRoyalty(msg.sender, DEFAULT_ROYALTY);
        isPublicSaleActive = false;
    }



    function supportsInterface(bytes4 interfaceId) 
        public 
        view 
        virtual 
        override(ERC2981, ERC721r) 
        returns (bool) {
        return super.supportsInterface(interfaceId);
    }


    function getNFTType(uint256 _id) external view returns (Type) {
        require(_exists(_id), "CNRS-2: Token doesn't exsits");
        return _idToType[_id];
    }


    function setNewTeamWallet(address payable newTeamWallet) 
        external
        onlyOwner {
        emit TeamWalletTransferred(msg.sender, teamWallet, newTeamWallet);
        teamWallet = newTeamWallet;
    }

    function setNewFreePurchaseWhitelistRoot(bytes32 newFreePurchaseWhitelistRoot) 
        external
        onlyOwner {
        emit WhitelistRootChanged(
            msg.sender,
            whitelistFreePurchaseRoot,
            newFreePurchaseWhitelistRoot,
            "Free Purchase"
        );
        whitelistFreePurchaseRoot = newFreePurchaseWhitelistRoot;
        
    }


    function setNewWlBox(IERC721 newWlBox)
        external
        onlyOwner 
    {
        WL_BOX = newWlBox;
    }

    function setNewEarlyAccessWhitelistRoot(bytes32 newEarlyAccessWhitelistRoot) external onlyOwner {
        emit WhitelistRootChanged(
            msg.sender,
            whitelistFreePurchaseRoot,
            newEarlyAccessWhitelistRoot,
            "Early Access"
        );
        whitelistEarlyAccessRoot = newEarlyAccessWhitelistRoot;
    }


    function baseURI() 
        public
        pure
        returns (string memory) {
        return "ipfs://Qmf2QnooHvhYvwGGvnMzg9uFXvDUZgXySW1gdFk9Gbi1pk/";
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory) {
        require(_exists(_tokenId), "CNRS-2: URI query for nonexistent token");
        string memory baseUri = baseURI();
        return bytes(baseUri).length > 0 ? string(abi.encodePacked(baseUri, _tokenId.toString(), ".json")) : "";
    }

    function mint(
        bytes32[] calldata whitelistFreePurchaseProof,
        bytes32[] calldata whitelistEarlyAccessProof,
        uint256 wlBoxId
    ) external payable {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));

        if (isUserFreePurchaseWhitelist(whitelistFreePurchaseProof, msg.sender, wlBoxId) == true) {
            if(wlBoxId < MAX_SUPPLY) {
                require(WL_BOX.ownerOf(wlBoxId) == msg.sender, "CNRS-2: not wl box owner");
                isWlBoxIdUsed[wlBoxId] = true;
            }

            isWhitelistFreePurchaseUserMintedOnce[msg.sender] = true;
        } else if (isUserEarlyAccessWhitelist(whitelistEarlyAccessProof, msg.sender) == true) {
            require(msg.value >= EARLY_ACCESS_PRICE, "CNRS-2: Insufficient funds");
            getMintCountForEarlyAccessUser[msg.sender]++;
        } else {
            require(isPublicSaleActive == true, "CNRS-2: Public sale is inactive!");
            require(msg.value >= PUBLIC_SALE_PRICE, "CNRS-2: Insufficient funds");
        }

        _mintRandom(msg.sender, 1);
    }


    function isUserFreePurchaseWhitelist(
        bytes32[] calldata whitelistMerkleProof,
        address account,
        uint256 wlBoxId
    ) public view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(account));
        
        if(isWhitelistFreePurchaseUserMintedOnce[account] == true) {
            return false;
        }

        if(address(WL_BOX) != address(0))
        {
            if(isWlBoxIdUsed[wlBoxId] == true)
            {
                return false;
            }

            uint256 balanceWlBox = WL_BOX.balanceOf(msg.sender);
            if(isWhitelistFreePurchaseUserMintedOnce[account] == false && balanceWlBox > 0){
                return true;
            }
        }

        return MerkleProof.verify(
            whitelistMerkleProof,
            whitelistFreePurchaseRoot,
            leaf
        );
    }

    function isUserEarlyAccessWhitelist(
        bytes32[] calldata whitelistMerkleProof,
        address account
    ) public view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(account));

        if(getMintCountForEarlyAccessUser[account] >= 2) {
            return false;
        }

        return MerkleProof.verify(
            whitelistMerkleProof,
            whitelistEarlyAccessRoot,
            leaf
        );
    }

    function setTokenRarityByIds(
        uint256[] calldata tokenIds,
        Type rarity
    ) external onlyOwner
    {
        for(uint256 i = 0; i < tokenIds.length;)
        {
            _idToType[tokenIds[i]] = rarity;
            unchecked { ++i; }
        }
    }

    function activatePublicSale() external onlyOwner
    {
        isPublicSaleActive = true;
    }

    function deactivatePublicSale() external onlyOwner
    {
        isPublicSaleActive = false;
    }

    // withdraw method
    function withdrawBalance()
        external
        onlyOwner
        returns (bool) {
        uint256 balance = address(this).balance;
        require(balance > 0, "CNRS-2: zero balance");
        
        (bool sent, bytes memory data) = teamWallet.call{value: balance}("");
        require(sent, "CNRS-2: Failed to send Ether");
        
        return sent;
    }
}