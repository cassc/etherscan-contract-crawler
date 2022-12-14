//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "contracts/MetaproMetaAsset.sol";

contract MetaproAirdrop is Ownable, ERC1155Holder, ReentrancyGuard  {
    using SafeMath for uint256;

    MetaproMetaAsset public token;

    struct AirdropConfiguration {
        address creator;
        uint256 tokenId;
        uint256 startBlock;
        uint256 endBlock;
        uint256 amount;
        bool valid;
    }

    struct AirdropWhitelistEntry {
        address user;
        bool exists;
    }

    event ClaimTransfer(uint256 tokenId, address target, uint256 amount);
    event WhitelistAddressAdd(uint256 tokenId, address target);
    event WhitelistAddressRemove(uint256 tokenId, address target);
    event TokenAddressUpdated(address _address);
    event AirdropCreated(uint256 tokenId, uint256 amount, uint256 startBlock, uint256 endBlock);

    mapping(uint256 => AirdropConfiguration) public airdrops;

    mapping(uint256 => AirdropWhitelistEntry[]) public whitelists;

    mapping(uint256 => address[]) private claimed;
    
    uint256[] private createdAirdropTokenIds;

    constructor(address _tokenAddress) {
        token = MetaproMetaAsset(_tokenAddress);
    }

    function createAirdrop(uint256 _tokenId, uint256 _startBlock, uint256 _endBlock, uint256 _amount, bytes memory _data) external onlyOwner nonReentrant {
        require(_tokenId > 0, "MetaproAirdrop: tokenId must be greater than 0");

        require(
            token.balanceOf(msg.sender, _tokenId) != 0,
            "MetaproAirdrop: Insufficient balance"
        );

        require(
            _startBlock < _endBlock,
            "MetaproAirdrop: startBlock must be less than endBlock"
        );

        require(airdrops[_tokenId].valid != true, "MetaproAirdrop: Airdrop already exists");

        token.safeTransferFrom(
            msg.sender,
            address(this),
            _tokenId,
            _amount,
            _data
        );

        AirdropConfiguration memory configuration = AirdropConfiguration(
            msg.sender,
            _tokenId,
            _startBlock,
            _endBlock,
            _amount,
            true
        );
        
        airdrops[_tokenId] = configuration;
        createdAirdropTokenIds.push(_tokenId);
        
        emit AirdropCreated(
            _tokenId,
            _amount,
            _startBlock,
            _endBlock
        );

        return;
    }

    function createdAirdrops() public view returns (uint256[] memory) {
        return createdAirdropTokenIds;
    }

    function addAddresses(uint256 _tokenId, address[] memory _addresses) external onlyOwner {
        require(_tokenId > 0, "MetaproAirdrop: token id cannot be 0");

        for (uint256 i; i < _addresses.length; i++) {
            bool userWhitelisted = false;
            for (uint256 j = 0; j < whitelists[_tokenId].length; ++j) {
                if (whitelists[_tokenId][j].user == _addresses[i]) {
                    userWhitelisted = true;
                }
            }

            if (!userWhitelisted) {
                AirdropWhitelistEntry memory whitelistEntry = AirdropWhitelistEntry(_addresses[i], true);
                whitelists[_tokenId].push(whitelistEntry);
                emit WhitelistAddressAdd(_tokenId, _addresses[i]);
            }
        }
    }

    function addAddress(uint256 _tokenId, address _address) external onlyOwner {
        require(_tokenId > 0, "MetaproAirdrop: token id cannot be 0");

        bool userWhitelisted = false;
        for (uint256 i = 0; i < whitelists[_tokenId].length; ++i) {
            if (whitelists[_tokenId][i].user == _address) {
                userWhitelisted = true;
            }
        }

        if (!userWhitelisted) {
            AirdropWhitelistEntry memory whitelistEntry = AirdropWhitelistEntry(_address, true);
            whitelists[_tokenId].push(whitelistEntry);
            emit WhitelistAddressAdd(_tokenId, _address);
        }
    }

    function removeAddress(uint256 _tokenId, address _address) external onlyOwner {
        for (uint256 i = 0; i < whitelists[_tokenId].length; ++i) {
            if (whitelists[_tokenId][i].user == _address) {
                delete whitelists[_tokenId][i];
            }
        }
    }

    function whitelisted(address _address) public view returns (AirdropConfiguration[] memory) {
        uint256 entriesResultsCount;

        for (uint256 i = 0; i < createdAirdropTokenIds.length; ++i) {
            AirdropWhitelistEntry[] memory whitelistsEntries = whitelists[createdAirdropTokenIds[i]];
            for (uint256 j = 0; j < whitelistsEntries.length; ++j) {
                if (whitelistsEntries[j].user == _address) {
                    entriesResultsCount++;
                }
            }
        }

        uint256 entryAdded;
        AirdropConfiguration[] memory userAirdrops = new AirdropConfiguration[](entriesResultsCount);
        for (uint256 i = 0; i < createdAirdropTokenIds.length; ++i) {
            AirdropConfiguration memory configuration = airdrops[createdAirdropTokenIds[i]];
            AirdropWhitelistEntry[] memory whitelistsEntries = whitelists[createdAirdropTokenIds[i]];
            for (uint256 j = 0; j < whitelistsEntries.length; ++j) {
                if (whitelistsEntries[j].user == _address) {
                    userAirdrops[entryAdded] = configuration;
                    entryAdded++;
                }
            }
        }
        return userAirdrops;
    }  

    function claim(uint256 _tokenId, bytes memory _data) public {        
        require(_tokenId > 0, "MetaproAirdrop: token id cannot be 0");
        address claimer = _msgSender();
        
        AirdropConfiguration memory configuration = airdrops[_tokenId];
        require(configuration.valid, "MetaproAirdrop: Aidrop invalid");

        require(token.balanceOf(address(this), _tokenId) > 0, "MetaproAirdrop: balance cannot be 0");
        require(block.number >= configuration.startBlock && block.number <= configuration.endBlock, "MetaproAirdrop: Airdrop not active");

        bool userWhitelisted = false;
        for (uint256 i = 0; i < whitelists[_tokenId].length; ++i) {
            if (whitelists[_tokenId][i].user == claimer) {
                userWhitelisted = true;
            }
        }

        require(userWhitelisted, "MetaproAirdrop: User not in whitelist");

        bool userClimed = false;
        for (uint256 i = 0; i < claimed[_tokenId].length; ++i) {
            if (claimed[_tokenId][i] == claimer) {
                userClimed = true;
            }
        }

        require(userClimed == false, "MetaproAirdrop: looks you have already claimed this token");

        token.safeTransferFrom(address(this), claimer, _tokenId, 1, _data);
        claimed[_tokenId].push(claimer);

        for (uint256 i = 0; i < whitelists[_tokenId].length; ++i) {
            if (whitelists[_tokenId][i].user == claimer) {
                delete whitelists[_tokenId][i];
            }
        }

        emit ClaimTransfer(_tokenId, claimer, 1);
    }

    function setTokenAddress(address _newAddress) external onlyOwner {
        token = MetaproMetaAsset(_newAddress);
        emit TokenAddressUpdated(_newAddress);
    }

    function withdrawUnclaimedTokens(uint256 _tokenId, bytes memory _data) external onlyOwner {
        AirdropConfiguration storage configuration = airdrops[_tokenId];

        require(configuration.valid, "MetaproAirdrop: Aidrop invalid");
        require(block.number > configuration.endBlock, "Airdrop not finished yet");

        uint256 balance = token.balanceOf(address(this), _tokenId);
        if (balance != 0) {
            token.safeTransferFrom(address(this), msg.sender, _tokenId, balance, _data);
        }

        configuration.valid = false;

        for (uint256 i = 0; i < createdAirdropTokenIds.length; ++i) {
            if (createdAirdropTokenIds[i] == _tokenId) {
                delete createdAirdropTokenIds[i];
            }
        }

        delete claimed[_tokenId];
        delete whitelists[_tokenId];
        
        return;
    }
}