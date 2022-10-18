// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/// @title ERC115 for Cosmo Gang Items
/// @author @TheV

enum Faction {None, Jahjahrion, Breedorok, Foodrak, Pimpmyridian,
        Muskarion, Lamborgardoz, Schumarian, Creatron}

abstract contract Cosmog is ERC20, Ownable
{    
}

contract CosmoGangItems is ERC1155Supply, Ownable {
    string public name = "CosmoGangItems";
    string public symbol = "CGI";
    uint256 public constant PRICE = 0 ether;
    address public main_address;
    address public token_address;
    address public signer_address;
    uint256 public daysBetweenMints = 30;
    uint256 public cosmog_price = 150000000000000000000;
    Cosmog public token_contract;
    bool public isMinting = false;
    mapping(Faction => string) faction_metadata_url_mapping;
    mapping(uint256 => uint256) tokenIdLastMint;
    mapping(address => bool) public approvedAddresses;
    mapping(Faction => uint256) public factionSuccessProbability;

    constructor(address _main_address, address _token_address, address _signer_address) ERC1155("")
    {
        main_address = _main_address;

        token_address = _token_address;
        token_contract = Cosmog(token_address);

        factionSuccessProbability[Faction.None] = 0;
        factionSuccessProbability[Faction.Jahjahrion] = 100;
        factionSuccessProbability[Faction.Breedorok] = 10;
        factionSuccessProbability[Faction.Foodrak] = 100;
        factionSuccessProbability[Faction.Pimpmyridian] = 100;
        factionSuccessProbability[Faction.Muskarion] = 100;
        factionSuccessProbability[Faction.Lamborgardoz] = 100;
        factionSuccessProbability[Faction.Schumarian] = 100;
        factionSuccessProbability[Faction.Creatron] = 100;

        signer_address = _signer_address;
    }

    modifier onlyApproved()
    {
        require(msg.sender == owner() || approvedAddresses[msg.sender], "caller is not approved");
        _;
    }

    function toggleMintState()
        external onlyOwner
    {
        if (isMinting)
        {
            isMinting = false;
        }
        else
        {
            isMinting = true;
        }
    }

    function getFaction(uint256[] calldata tokenIds, uint8 v, bytes32 r, bytes32 s, uint256 deadline)
        private view
        returns (Faction)
    {
        if (ecrecover(sha256(abi.encodePacked(msg.sender, tokenIds, uint(Faction.None), deadline)), v, r, s) == signer_address)
        {
            return Faction.None;
        }
        else if (ecrecover(sha256(abi.encodePacked(msg.sender, tokenIds, uint(Faction.Jahjahrion), deadline)), v, r, s) == signer_address)
        {
            return Faction.Jahjahrion;
        }
        else if (ecrecover(sha256(abi.encodePacked(msg.sender, tokenIds, uint(Faction.Breedorok), deadline)), v, r, s) == signer_address)
        {
            return Faction.Breedorok;
        }
        else if (ecrecover(sha256(abi.encodePacked(msg.sender, tokenIds, uint(Faction.Foodrak), deadline)), v, r, s) == signer_address)
        {
            return Faction.Foodrak;
        }
        else if (ecrecover(sha256(abi.encodePacked(msg.sender, tokenIds, uint(Faction.Pimpmyridian), deadline)), v, r, s) == signer_address)
        {
            return Faction.Pimpmyridian;
        }
        else if (ecrecover(sha256(abi.encodePacked(msg.sender, tokenIds, uint(Faction.Muskarion), deadline)), v, r, s) == signer_address)
        {
            return Faction.Muskarion;
        }
        else if (ecrecover(sha256(abi.encodePacked(msg.sender, tokenIds, uint(Faction.Lamborgardoz), deadline)), v, r, s) == signer_address)
        {
            return Faction.Lamborgardoz;
        }
        else if (ecrecover(sha256(abi.encodePacked(msg.sender, tokenIds, uint(Faction.Schumarian), deadline)), v, r, s) == signer_address)
        {
            return Faction.Schumarian;
        }
        else if (ecrecover(sha256(abi.encodePacked(msg.sender, tokenIds, uint(Faction.Creatron), deadline)), v, r, s) == signer_address)
        {
            return Faction.Creatron;
        }
        else
        {
            return Faction.None;
        }
    }

    function canMint(uint256 tokenId)
        public view
        returns (bool)
    {
        // Ideally we would like to check msg.sender is owner of tokenId
        // but this makes multi mint far too expensive.
        // We so prefer to rely on backend to do this
        // return nft_contract.ownerOf(tokenId) == msg.sender & (block.timestamp >= tokenIdLastMint[tokenId] + 60 * 60 * 24 * daysBetweenMints);
        return block.timestamp >= tokenIdLastMint[tokenId] + 60 * 60 * 24 * daysBetweenMints;
    }

    function canMintBatch(uint256[] calldata tokenIds)
        public view
        returns (bool)
    {
        for (uint256 idx = 0; idx < tokenIds.length; idx++)
        {
            if (!canMint(tokenIds[idx]))
            {
                return false;
            }
        }
        return true;
    }

    function canMintMany(uint256[] calldata tokenIds)
        external view
        returns (bool[] memory)
    {
        bool[] memory canMintArray = new bool[](tokenIds.length);
        for (uint256 idx = 0; idx < tokenIds.length; idx++)
        {
            uint tid = tokenIds[idx];
            bool _canMint = canMint(tid);
            canMintArray[idx] = _canMint;
        }
        return canMintArray;
    }

    function successMint(Faction faction)
        private view
        returns (bool)
    {
        uint256 random;
        random = randomBetween(0, 100);

        if (random > (100 - factionSuccessProbability[faction]))
        {
            return true;
        }
        return false;
    }

    // Mint Logic Batch
    function _mintNFT(address recipient, uint8 v, bytes32 r, bytes32 s, uint256[] calldata fromTokenIds, uint256 deadline, bool useProba)
        private
        returns (bool)
    {
        Faction faction = getFaction(fromTokenIds, v, r, s, deadline);
        require(canMintBatch(fromTokenIds), "tokenId already minted his periodic Cosmo Gang Item");
        for (uint256 idx = 0; idx < fromTokenIds.length; idx++)
        {
            uint tokenId = fromTokenIds[idx];
            tokenIdLastMint[tokenId] = block.timestamp;
        } 
        require(faction != Faction.None, "No faction found with these parameters");
        uint256 nMint = fromTokenIds.length;
        if (useProba)
        {
            if (successMint(faction))
            {
                _mint(recipient, uint256(faction), nMint, "");
                return true;
            }
            else
            {
                return false;
            }
        }
        else
        {
            _mint(recipient, uint256(faction), nMint, "");
            return true;
        }
    }

    // Normal Mint Batch
    function mintNFT(address recipient, uint8 v, bytes32 r, bytes32 s, uint256[] calldata fromTokenIds, uint256 deadline)
        external payable
        returns (bool)
    {
        uint256 nMint = fromTokenIds.length;

        require(token_contract.allowance(msg.sender, address(this)) >= nMint * cosmog_price, "Inssuficient allowance for CosmoGangItems on your Cosmog");
        require(isMinting, "Mint period have not started yet and you are not Whitelisted");
        require(msg.value >= PRICE * nMint, "Not enough ETH to mint");
        require(token_contract.balanceOf(msg.sender) >= nMint * cosmog_price, "Not enough Cosmogs to mint");
        require(nMint > 0, "You have to mint more than 0");
        
        if (cosmog_price != 0)
        {
            token_contract.transferFrom(msg.sender, address(token_contract), nMint * cosmog_price);
        }
        
       return _mintNFT(recipient, v, r, s, fromTokenIds, deadline, true);
    }

    function giveaway(uint256 nMint, address recipient, Faction faction)
        public onlyApproved
        returns (bool)
    {
        _mint(recipient, uint256(faction), nMint, "");
        return true;
    }

    function burnNFT(address fromAddress, uint256 amount, Faction _faction)
        public
    {   
        require(msg.sender == fromAddress || msg.sender == owner() || approvedAddresses[msg.sender], "Must be called by owner of address or approved of contract");
        require(balanceOf(fromAddress, uint256(_faction)) >= amount, "Not enough balance to burn this amount");
        _burn(fromAddress, uint256(_faction), amount);
    }

    function setTokenAddress(address _token_address)
        external onlyOwner
    {
        token_address = _token_address;
        token_contract =  Cosmog(token_address);
    }

    function setSignerAddress(address _signer_address)
        external onlyOwner
    {
        signer_address =  _signer_address;
    }

    function setMainAddress(address _main_address)
        external onlyOwner
    {
        main_address = _main_address;
    }

    function setDaysBetweenMints(uint256 _days)
        external onlyOwner
    {
        daysBetweenMints = _days;
    }

    function setCosmogPrice(uint256 _days)
        external onlyOwner
    {
        cosmog_price = _days;
    }

    function setFactionMetadata(Faction faction, string memory metadataUri)
        external onlyApproved
    {
        faction_metadata_url_mapping[faction] = metadataUri;
    }

    function setFactionSuccessProbability(Faction faction, uint256 proba)
        external onlyApproved
    {
        factionSuccessProbability[faction] = proba;
    }

    function uri(uint256 tokenId)
        public view
        override
        returns (string memory)
    {
        return faction_metadata_url_mapping[Faction(tokenId)];
    }

    function withdraw()
        external onlyOwner
        payable
    {
        uint256 amount = address(this).balance;
        require(amount > 0, "Nothing to withdraw");
        bool success = payable(main_address).send(amount);
        require(success, "Failed to withdraw");
    }

    function transferCosmogs(address addr, uint256 amount)
        external onlyApproved
    {
        require(token_contract.balanceOf(address(this)) > 0, "Not enough Cosmogs in the contract to send");
        token_contract.transfer(addr, amount);
    }

    function addApprovedAddress(address addr)
        external onlyOwner
    {
        approvedAddresses[addr] = true;
    }

    function removeApprovedAddress(address addr)
        external onlyOwner
    {
        approvedAddresses[addr] = false;
    }

    function randomBetween(uint256 min, uint256 max)
        internal view
        returns (uint)
    {
        require (max > min, "max have to be > min");
        string memory difficulty = Strings.toString(block.difficulty);
        string memory timestamp = Strings.toString(block.timestamp);

        // abi.encodePacked is used to concatenate strings and get the result in bytes
        bytes memory key = abi.encodePacked(difficulty, timestamp, msg.sender);
        uint random = uint(keccak256(key)) % (max - min);
        random += min;
        return random;
    }

    receive()
        external payable
    {
    }

    fallback()
        external
    {
    }
}