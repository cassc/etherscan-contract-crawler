//Contract based on https://docs.openzeppelin.com/contracts/3.x/erc721
// SPDX-License-Identifier: MIT
// Creator : TheV

//  _______ __   __ _______    _______ _______ _______ __   __ _______    _______ _______ __    _ _______ 
// |       |  | |  |       |  |       |       |       |  |_|  |       |  |       |       |  |  | |       |
// |_     _|  |_|  |    ___|  |       |   _   |  _____|       |   _   |  |    ___|   _   |   |_| |    ___|
//   |   | |       |   |___   |      _|  | |  | |_____|       |  | |  |  |   | __|  |_|  |       |   | __ 
//   |   | |       |    ___|  |     | |  |_|  |_____  |       |  |_|  |  |   ||  |       |  _    |   ||  |
//   |   | |   _   |   |___   |     |_|       |_____| | ||_|| |       |  |   |_| |   _   | | |   |   |_| |
//   |___| |__| |__|_______|  |_______|_______|_______|_|   |_|_______|  |_______|__| |__|_|  |__|_______|

pragma solidity >=0.7.0;

import "https://github.com/chiru-labs/ERC721A/contracts/ERC721A.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";


contract CosmoGang is ERC721A, Ownable {
    enum Faction {None, Jahjahrion, Breedorok, Foodrak, Pimpmyridian,
        Muskarion, Lamborgardoz, Schumarian, Creatron}
    
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    uint256 public constant MAX_SUPPLY = 10000;
    mapping (uint256 => string) public tokenURIs;
    mapping (uint256 => Faction) public tokenFactions;
    uint256 public max_per_wallet = 5;
    uint256 public max_per_wallet_owner = 5;
    address public main_address = 0x9C21c877B44eBac7F0E8Ee99dB4ebFD4A9Ac5000;
    string public placeholder_uri = "https://bafybeih6b2d4aqvcsw6sv3cu2pi3doldwa4lq42w34ismwvfrictsod5nu.ipfs.infura-ipfs.io/";
    string public base_uri;
    bool public isMinting = false;
    bool public isRevealed = false;
    bool public isBaseUri = false;
    bool public isOnlyHolder = false;
    bool public isOnlyOwner = false;
    uint256 public price = 0 ether;
    uint256 public current_supply = 2000;

    constructor() ERC721A("TheCosmoGang", "CG")
    {
        // Minting for availability on OpenSea before any mint
        _safeMint(address(this), 1);
        _burn(0);
    }

    function toggleMintState()
        public onlyOwner
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

    function toggleRevealState()
        public onlyOwner
    {
        if (isRevealed)
        {
            isRevealed = false;
        }
        else
        {
            isRevealed = true;
        }
    }

    function toggleBaseUriState()
        public onlyOwner
    {
        if (isBaseUri)
        {
            isBaseUri = false;
        }
        else
        {
            isBaseUri = true;
        }
    }

    function toggleOnlyHolderState()
        public onlyOwner
    {
        if (isOnlyHolder)
        {
            isOnlyHolder = false;
        }
        else
        {
            isOnlyHolder = true;
        }
    }

    function toggleOnlyOwnerState()
        public onlyOwner
    {
        if (isOnlyOwner)
        {
            isOnlyOwner = false;
        }
        else
        {
            isOnlyOwner = true;
        }
    }

    function mintManyNFTs(uint256[] memory nMints, address[] memory recipients)
        external onlyOwner
    {
        require(!isOnlyOwner || (isOnlyOwner && msg.sender == owner()), "isOnlyOwner is setted up and you're not the owner");   
        require(nMints.length == recipients.length, "nMints and recipients have to be the same length");

        uint256 totalMint = 0;

        for (uint256 i = 0; i < nMints.length; i++)
        {
            uint256 nMint = nMints[i];
            address recipient = recipients[i];

            require((balanceOf(recipient) + nMint <= max_per_wallet) ||
                    (msg.sender == main_address && balanceOf(recipient) + nMint <= max_per_wallet_owner), "Too much NFT minted");

            totalMint += nMint;

            require(!isOnlyHolder || (isOnlyHolder && isHolder(recipient)), "isOnlyHolder is setted up and you're not a holder");
            _tokenIds.increment();
            _safeMint(recipient, nMint);
            // _mint(recipient, nMint);
        }
        require(_tokenIds.current() + totalMint <= MAX_SUPPLY, "No more NFT to mint");
        require(_tokenIds.current() + totalMint <= current_supply, "No more NFT to mint currently");
    }

    // Mint Logic
    function _mintNFT(uint256 nMint, address recipient)
        private
    {
        require(_tokenIds.current() + nMint <= MAX_SUPPLY, "No more NFT to mint");
        require(_tokenIds.current() + nMint <= current_supply, "No more NFT to mint currently");
        require((balanceOf(recipient) + nMint <= max_per_wallet) ||
                (msg.sender == main_address && balanceOf(recipient) + nMint <= max_per_wallet_owner), "Too much NFT minted");
        require(!isOnlyHolder || (isOnlyHolder && isHolder(recipient)), "isOnlyHolder is setted up and you're not a holder");
        require(!isOnlyOwner || (isOnlyOwner && msg.sender == owner()), "isOnlyOwner is setted up and you're not the owner");        

        for (uint256 i = 0; i < nMint; i++)
        {
            _tokenIds.increment();
        }
        _safeMint(recipient, nMint);
        // _mint(recipient, nMint);
    }

    // Normal Mint
    function mintNFT(uint256 nMint, address recipient)
        external payable
    {
        require(isMinting, "Mint period have not started yet");
        require(msg.value >= price * nMint, "Not enough ETH to mint");

        return _mintNFT(nMint, recipient);
    }

    // Free Mint
    function giveaway(uint256 nMint, address recipient)
        external onlyOwner
    {
        return _mintNFT(nMint, recipient);
    }

    function burnNFT(uint256 tokenId)
        external onlyOwner
    {
        _burn(tokenId);
        delete tokenURIs[tokenId];
    }

    function setCurrentSupply(uint256 supply)
        external onlyOwner
    {
        require(getCurrentSupply() + supply <= MAX_SUPPLY, "Too much supply");
        current_supply = supply;
    }

    function transferFrom(address from, address to, uint256 tokenId)
        public
        override
    {
        require(balanceOf(from) >= 1, "Not enough NFT to send one");
        super.transferFrom(from, to, tokenId);
    }

    function transferFromBatch(address from, address[] memory to, uint256[] memory tokenId)
        external 
    {
        require(balanceOf(from) >= to.length, "Not enough NFT to send this batch");
        require(to.length >= tokenId.length, "to and tokenId arrays have to be same length");
        for (uint256 idx = 0; idx < to.length; idx++)
        {
            address t = to[idx];
            uint256 tId = tokenId[idx];

            super.transferFrom(from, t, tId);
        }   
    }

    function tokenURI(uint256 tokenId)
        public view
        override
        returns (string memory)
    {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        if (isRevealed)
        {
            if (isBaseUri)
            {
                return string(abi.encodePacked(abi.encodePacked(abi.encodePacked(base_uri, "/"), Strings.toString(tokenId)), ".json"));
            }
            else
            {
                return tokenURIs[tokenId];
            }
            
        }
        else
        {
            return placeholder_uri;
        }
    }

    function setTokenURI(uint256 tokenId, string memory _tokenURI, Faction faction)
        private
        // override(ERC721)
    {
        require(_exists(tokenId), "ERC721URIStorage: URI set of nonexistent token");
        tokenURIs[tokenId] = _tokenURI;
        tokenFactions[tokenId] = faction;
    }

    function updateTokenURI(uint256 tokenId, string memory _tokenURI, Faction faction)
        external onlyOwner
        // override(ERC721A)
    {
        require(_exists(tokenId), "ERC721URIStorage: URI set of nonexistent token");
        tokenURIs[tokenId] = _tokenURI;
        tokenFactions[tokenId] = faction;
    }

    function updateAllTokenURIs(uint256[] memory tokenIds, string[] memory _tokenURIs, Faction[] memory factions)
        external onlyOwner
        // override(ERC721A)
    {
        mapping(uint256 => string) storage tempTokenURIs = tokenURIs;
        mapping(uint256 => Faction) storage tempTokenFactions = tokenFactions;
        for (uint256 idx = 0; idx <= tokenIds.length; idx++)
        {
            uint256 tokenId = tokenIds[idx];
            string memory _tokenURI = _tokenURIs[idx];
            Faction tokenFaction = factions[idx];
            require(_exists(tokenId), "ERC721URIStorage: URI set of nonexistent token");
            tempTokenURIs[tokenId] = _tokenURI;
            tempTokenFactions[tokenId] = tokenFaction;
        }
    }

    function setFaction(uint256 tokenId, Faction _faction)
        external onlyOwner
    {
        tokenFactions[tokenId] = _faction;
    }
    
    function setPrice(uint256 priceGwei)
        external onlyOwner
    {
        price = priceGwei * 10**9;
    }

    function setPlaceholderUri(string memory _placeholder_uri)
        external onlyOwner
    {
        placeholder_uri = _placeholder_uri;
    }

    function setBaseUri(string memory _base_uri)
        external onlyOwner
    {
        base_uri = _base_uri;
    }

    function setMaxPerWallet(uint256 _max_per_wallet)
        external onlyOwner
    {
        max_per_wallet = _max_per_wallet;
    }

    function setMaxPerWalletOwner(uint256 _max_per_wallet_owner)
        external onlyOwner
    {
        max_per_wallet_owner = _max_per_wallet_owner;
    }

    function setMainAddress(address _main_address)
        external onlyOwner
    {
        main_address = _main_address;
    }

    function getCurrentSupply()
        public view
        returns (uint256)
    {
        return totalSupply();
    }

    function isHolder(address addr)
        public view
        returns (bool)
    {
        return balanceOf(addr) > 0;
    }

    function tokenIdExists(uint256 tokenId)
        external view
        returns (bool)
    {
        return _exists(tokenId);
    } 

    function withdraw()
        public 
        payable
    {
        uint256 amount = address(this).balance;
        require(amount > 0, "Nothing to withdraw");
        bool success = payable(main_address).send(amount);
        require(success, "Failed to withdraw");
    }

    receive()
        external payable
    {
        // balance[msg.sender] += msg.value;
    }

    fallback()
        external
    {

    }
}