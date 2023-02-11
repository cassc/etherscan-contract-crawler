// SPDX-License-Identifier: MIT
// ERC721A Contracts v4.2.3
// Creator: Elie Kassis

pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./extensions/ERC721AURIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
// Dev imports
import "hardhat/console.sol";

contract HodlerMiamiFCMember is ERC721A, ERC721AURIStorage,  Ownable {
    using Counters for Counters.Counter;
    
    Counters.Counter _tokenIdCounter;
    address contractOwner;
    
    mapping(address => bool) nft2023MembersWL; // whitelist for NFT mint.
    
    mapping(address => bool) nft2022MembersWL; // Checking if wallet has a permission to mint 2022 player NFT.
    mapping(address => bool) nft2022And2023MembersWL; // Checking if wallet has a permission to mint 2022 player NFT.
    mapping(address => bool) nftStaffsWL; // Checking if wallet has a permission to mint staff NFT.

    mapping(address => bool) isCheckStaffMint; // Checking if wallet has minted staff NFT already.
    mapping(address => bool) isCheck2022PlayerMint; // Checking if wallet has minted 2022 player NFT already.
    mapping(address => bool) isCheck2023PlayerMint; // Checking if wallet has minted 2023 player NFT already.
    
    constructor() ERC721A("Hodler Miami FC Member", "HMFM") {
        contractOwner = msg.sender;
    }

    modifier isAddressInWL (address _address) {
        require(
            nft2023MembersWL[_address] == false && 
            nft2022And2023MembersWL[_address] == false &&
            nftStaffsWL[_address] == false && 
            nft2022MembersWL[_address] == false,
            "You are in the whitelist already!"
        );
        _;
    }

    // _nftType : 1 => 2023 member NFT, 2 => 2022 Member NFT, 3 => Staff
    function safeMint(
        string memory _tokenURI,  
        uint256 _nftType, 
        uint256 _price
    ) public virtual payable {
        require (msg.value >= _price, "Not enough Balance sent; check price!");

        if(_nftType == 1) {
            require(nftStaffsWL[msg.sender] == false, "You can only mint Staff NFT!");
            require(nft2022MembersWL[msg.sender] == false, "You can only mint 2022 Member NFT!");
            require(
                nft2023MembersWL[msg.sender] == true || nft2022And2023MembersWL[msg.sender] == true, 
                "You have no premission to mint 2023 Member NFT!"
            );

            if(nft2022And2023MembersWL[msg.sender] == true) {
                require(isCheck2022PlayerMint[msg.sender] == true, "You should mint 2022 member NFT at first!");
            }
            require(isCheck2023PlayerMint[msg.sender] == false, "You minted 2023 player NFT already!");
        }

        if(_nftType == 2) {
            require(nftStaffsWL[msg.sender] == false, "You can only mint Staff NFT!");
            require(nft2023MembersWL[msg.sender] == false, "You can only mint 2023 Member NFT!");
            
            require(
                nft2022MembersWL[msg.sender] == true || nft2022And2023MembersWL[msg.sender] == true, 
                "You have no premission to mint 2023 Member NFT!"
            );
            require(isCheck2022PlayerMint[msg.sender] == false, "You minted 2023 player NFT already!");
        }

        if(_nftType == 3) {
            require(nftStaffsWL[msg.sender] == true, "You have no permission to mint Staff NFT!");

            require(nft2022And2023MembersWL[msg.sender] == false, "You can only mint 2022/2023 Member NFTs!");
            require(nft2022MembersWL[msg.sender] == false, "You can only mint 2022 Member NFT!");
            require(nft2023MembersWL[msg.sender] == false, "You can only mint 2023 Member NFT!");

            require(isCheckStaffMint[msg.sender] == false, "You minted Staff NFT already!");
        }

        // Current counter value will be the minted token's token ID.
        uint256 tokenId = _tokenIdCounter.current();

        // Mint the token
        _safeMint(msg.sender, 1);

        // set Token URI
        _setTokenURI(tokenId, _tokenURI);

        // Increment it so next time it's correct when we call .current()
        _tokenIdCounter.increment();

        if(_nftType == 1) {
             isCheck2023PlayerMint[msg.sender] = true;
        } else if(_nftType == 2) {
            isCheck2022PlayerMint[msg.sender] = true;
        } else if(_nftType == 3) {
            isCheckStaffMint[msg.sender] = true;
        }
    }

    function getContractOwner () public view returns (address) {
        return contractOwner;
    }

    // Get lastest token id minted.
    function getLatestTokenId () public view returns (uint256) {
        return _tokenIdCounter.current();
    }

    // add wallet to 2022 Member whitelist to mint
    function addToNft2022MembersWL (address _address) external isAddressInWL(_address) onlyOwner {
        nft2022MembersWL[_address] = true;
    }

    // add wallet to 2023 Member whitelist to mint
    function addToNft2023MembersWL (address _address) external isAddressInWL(_address) onlyOwner {
        nft2023MembersWL[_address] = true;
    }

    // add wallet to whitelist to mint 2022/2023 Player NFT
    function addToNft2022And2023MembersWL (address _address) external isAddressInWL(_address) onlyOwner {
        nft2022And2023MembersWL[_address] = true;
    }

    // add wallet to whitelist to mint Staff NFT
    function addToNftStaffsWL (address _address) external isAddressInWL(_address) onlyOwner {
        nftStaffsWL[_address] = true;
    }

    // Set single token URI
    function setTokenURI (uint256 _tokenId, string memory _tokenURI) external onlyOwner {
        _setTokenURI(_tokenId, _tokenURI);
    }

    /*
     * User Types
     * 0 => No Permission
     * 1 => 2023 Members WL
     * 2 => 2022 Members WL
     * 3 => 2022/2023 Members WL
     * 4 => Staffs WL
     */
    function getUserType (address _wallet) external view returns(uint256) {
        if(nft2023MembersWL[_wallet] == true) {
            return 1;
        } else if(nft2022MembersWL[_wallet] == true) {
            return 2;
        } else if(nft2022And2023MembersWL[_wallet] == true) {
            return 3;
        } else if (nftStaffsWL[_wallet] == true) {
            return 4;
        }

        return 0;
    }

    function isCheckMint2022 (address _wallet) public view returns (bool) {
        return isCheck2022PlayerMint[_wallet];
    }

    function isCheckMint2023 (address _wallet) public view returns (bool) {
        return isCheck2023PlayerMint[_wallet];
    }

    function isCheckMintStaff (address _wallet) public view returns (bool) {
        return isCheckStaffMint[_wallet];
    }

    // Set Multi tokens' URIs
    function setMultiTokensURI (
        uint256[] memory _tokenIds, 
        string[] memory _tokenURIs, 
        uint256 _length
    ) external onlyOwner {
        for (uint i = 0 ; i < _length; i ++) {
            _setTokenURI(_tokenIds[i], _tokenURIs[i]);
        }
    }

    // Withdraw ETH from token contract
    function withdrawETH () public onlyOwner {
        payable(contractOwner).transfer(address(this).balance);
    }

    // get Balance of msgSender
    function getBalanceOfMsgSender () public view returns (uint256) {
        return msg.sender.balance;
    }
    
    // overrite TokenURI
    function tokenURI (uint256 tokenId) public view override(ERC721A, ERC721AURIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    // override burn
    function _burn(uint256 tokenId) internal override(ERC721A, ERC721AURIStorage) {
        super._burn(tokenId);
    }

}