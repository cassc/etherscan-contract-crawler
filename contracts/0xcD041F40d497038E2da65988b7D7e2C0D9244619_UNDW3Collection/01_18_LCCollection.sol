// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

/// @title Lacoste UNDW3 Collection
/// @author UNBLOCKED (https://unblocked-group.com/) 
/// @Reviewed by Pinky and the Brain

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
//the rarible dependency files are needed to setup sales royalties on LooksRare
import "./rarible/royalties/contracts/impl/RoyaltiesV2Impl.sol";
import "./rarible/royalties/contracts/LibPart.sol";
import "./rarible/royalties/contracts/LibRoyaltiesV2.sol";

contract UNDW3Collection is ERC721Enumerable, Ownable, RoyaltiesV2Impl {
    using Strings for uint256;

    // Epochs details for Lacoste UNDW3 sales
    struct EpochDetails {
        uint8 maxPerWallet;
        uint256 maxTotal;
        uint256 supply;
        uint256 startDate;
        uint256 endDate;
    }
    
    // Base URI before for metadata
    string public baseURI;
    // Blind URI before reveal
    string public blindURI;
    // Max NFTs to mint
    uint256 public constant MAX_NFT = 11212;  
    // NFT price
    uint256 public NFTPrice = 0.08 ether;   
    // Reveal enable/disable
    bool public reveal;
    // Freeze the mint 
    bool public freeze; 
    // Royalties interface
    bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a; 
    // Root of the whitelist
    bytes32 public root;
    // Mapping to store the number of claims per epoch 
    mapping (address => mapping (uint256 => uint256)) nftClaimed;
    // Mapping to store epochs 
    mapping(uint256 => EpochDetails) epochs;
    // To claim ethers
    address payable public escrow = payable(0x826FE181baAf7464ee58ccFA2a2514D0F86a96b6);
    // To get royalties
    address payable public secondary = payable(0xDC4bCa7958000EF99e8C3dC5A63707D3c2a1C39e);


    /********************/
    /**    MODIFIERS   **/
    /********************/
    // This means that if the smart contract is frozen by the owner, the
    // function is executed an exception is thrown
    modifier onlyWhenNotFreeze() {
        require(!freeze, 'UNDW3 Lacoste: frozen !');
        _;
    }

    /********************/
    /**  CONSTRUCTOR   **/
    /********************/
    constructor(
        string memory _blindURI
    ) ERC721("UNDW3 Lacoste", "UNDW3") {
        blindURI = _blindURI;

        // Init epochs 
        // TODO check epochs 
        epochs[1] = EpochDetails(2,4924,0,1655201520,1655283600);
        epochs[2] = EpochDetails(1,5838,0,1655302320,1655373600); 
        epochs[3] = EpochDetails(3,11212,0,1655400780,0); 
        epochs[4] = EpochDetails(1,450,0,1655287920,0); 
    }

    /******************************/
    /**    ONLYOWNER Functions   **/
    /******************************/
    /// @notice reveal now, called only by owner 
    /// @dev reveal metadata for NFTs
    function revealNow() 
        external 
        onlyOwner 
    {
        reveal = true;
    }

    /// @notice freeze now, called only by owner 
    /// @dev freeze minting 
    function freezeNow() 
        external 
        onlyOwner 
        onlyWhenNotFreeze
    {
        freeze = true;
    }

    /// @notice setURIs, called only by owner 
    /// @dev set Base and Blind URI
    function setURIs(
        string memory _URI
    ) 
        external 
        onlyOwner 
    {
        baseURI = _URI;
    }

    /// @notice updateEpochs, called only by owner and when smart contract is activated 
    /// @dev update epochs
    /// @param _index, index of the epoch (1 : Lacoste List, 2: Premint, 3: Public, 4: FreeMint)
    /// @param _start, starting date of the epoch
    /// @param _end, ending date of the epoch
    function updateEpochs(uint256 _index, uint256 _start, uint256 _end)
        external 
        onlyOwner
        onlyWhenNotFreeze
    {
        epochs[_index].startDate = _start;
        epochs[_index].endDate = _end;
    }

    /// @notice updateRemainingSupplyByEpoch, called only by owner and when smart contract is activated
    /// @dev to update the remaining supply for a specidic epoch
    /// @param _index, index of the epoch (1 : Lacoste List, 2: Premint, 3: Public, 4: FreeMint)
    /// @param _supply, remaining supply
    function updateRemainingSupplyByEpoch(uint256 _index, uint256 _supply)
        external 
        onlyOwner
        onlyWhenNotFreeze
    {
        epochs[_index].maxTotal = _supply;
    }
    
    /// @notice mintByOwner, called only by owner 
    /// @dev mint one NFT for a given address (for giveaway and partnerships)
    /// @param _to, address to mint NFT
    function mintByOwner(
        address _to
    ) 
        external 
        onlyOwner
    {
        require(block.timestamp >= epochs[4].startDate, "UNDW3 Lacoste: not active yet");
        require(totalSupply() + 1 <= MAX_NFT, "UNDW3 Lacoste: Tokens number to mint cannot exceed number of MAX tokens");
        require(epochs[4].supply + 1 <= epochs[4].maxTotal, "UNDW3 Lacoste: giveway number cannot exceed the MAX_GIVEWAY");

        _setRoyalties(totalSupply(), secondary, 400);
        _safeMint(_to, totalSupply());
        epochs[4].supply += 1;
    }
    
    /// @notice mintByOwner, called only by owner 
    /// @dev mint multiple NFTs for a set of addresses (for giveaway and partnerships)
    /// @param _to, list of addresses to mint NFT
    function mintMultipleByOwner(
        address[] memory _to
    ) 
        external 
        onlyOwner
    {
        require(block.timestamp >= epochs[4].startDate, "UNDW3 Lacoste: not active yet");
        require(totalSupply() + _to.length <= MAX_NFT, "UNDW3 Lacoste: Tokens number to mint cannot exceed number of MAX tokens");
        require(epochs[4].supply + _to.length <= epochs[4].maxTotal, "UNDW3 Lacoste: giveway number cannot exceed the MAX_GIVEWAY");

        for(uint256 i = 0; i < _to.length; i++){
            _setRoyalties(totalSupply(), secondary, 400);
            _safeMint(_to[i], totalSupply());
            epochs[4].supply += 1;
        }
    }

    /// @notice setRoot, called only by owner 
    /// @dev set the root of merkle tree to check the whitelist
    /// @param _root, root of merkle tree
    function setRoot(uint256 _root) 
        onlyOwner 
        public 
    {
        root = bytes32(_root);
        if(block.timestamp > epochs[1].endDate && block.timestamp < epochs[2].startDate){
            epochs[2].maxTotal += epochs[1].maxTotal - epochs[1].supply;
        }
    }

    /// @notice claim, called only by owner 
    /// @dev claim the raised funds and send it to the escrow wallet
    // https://solidity-by-example.org/sending-ether
    function claim()
        external 
        onlyOwner
    {
        // Send returns a boolean value indicating success or failure.
        (bool sent, ) = escrow.call{value: address(this).balance}("");
        require(sent, "UNDW3 Lacoste: Failed to send Ether");
    }

    /******************************/
    /**      Public Functions    **/
    /******************************/
    /// @notice mintNFT, called only by owner 
    /// @dev mint new NFTs, it is payable. Amount is caulated as per (NFTPrice.mul(_numOfTokens))
    /// @param _numOfTokens, number of NFT a mint 
    /// @param _proof, proof of whitelisting 
    function mintNFT(
        uint256 _numOfTokens,
        bytes32[] memory _proof
    ) 
        public 
        payable
        onlyWhenNotFreeze
    {
        require(block.timestamp >= epochs[1].startDate, "UNDW3 Lacoste: too early");
        require(totalSupply() + _numOfTokens <= MAX_NFT - epochs[4].maxTotal, "UNDW3 Lacoste: Tokens number to mint cannot exceed number of MAX tokens");
        // Epoch 1 
        if (block.timestamp >= epochs[1].startDate && block.timestamp <= epochs[1].endDate) _mintNFT(_numOfTokens, _proof, 1, msg.sender);
        // Epoch 2
        else if (block.timestamp >= epochs[2].startDate  && block.timestamp <= epochs[2].endDate) {
            _mintNFT(_numOfTokens, _proof, 2, msg.sender);
        }
        // Epoch 3
        else if (block.timestamp >= epochs[3].startDate) { 
            epochs[3].maxTotal = MAX_NFT - epochs[1].supply - epochs[2].supply - epochs[4].maxTotal;
            _mintNFT(_numOfTokens, _proof, 3, msg.sender);
        }

        else if((block.timestamp > epochs[1].endDate && block.timestamp < epochs[2].startDate) 
        || block.timestamp > epochs[2].endDate && block.timestamp < epochs[3].startDate) {
            revert("UNDW3 Lacoste: smart contract disabled !");
        }
    }

    /// @notice tokenURI
    /// @dev get token URI of given token ID. URI will be blank untill totalSupply reaches MAX_NFT_PUBLIC
    /// @param _tokenId, token ID NFT
    /// @return URI
    function tokenURI(
        uint256 _tokenId
    ) 
        public 
        view 
        virtual 
        override 
        returns (string memory) 
    {
        require(_exists(_tokenId), "UNDW3 Lacoste: URI query for nonexistent token");
        if (!reveal) {
            return blindURI;
        } else {
            return baseURI;
        }
    }

    /// @notice verify (openzeppelin)
    /// @dev get token URI of given token ID. URI will be blank untill totalSupply reaches MAX_NFT_PUBLIC
    /// @param proof, proof of whitelisting
    /// @param leaf, leaf of merkle tree
    /// @return boolean, true or false
    function verify(bytes32[] memory proof, bytes32 leaf) 
    public 
    view 
    returns (bool) 
    {
        bytes32 computedHash = leaf;

        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];
            
            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = sha256(abi.encodePacked(computedHash, proofElement));
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = sha256(abi.encodePacked(proofElement, computedHash));
            }
        }

        // Check if the computed hash (root) is equal to the provided root
        return computedHash == root;
    }

    /// @notice getEpochsInfo
    /// @dev get epochs details
    /// @param _index, index of the epoch (1 : Lacoste List, 2: Premint, 3: Public, 4: FreeMint)
    /// @return epochs details
    function getEpochsInfo(uint256 _index) 
        public 
        view 
        returns (EpochDetails memory) {
        return epochs[_index];
    }

    /// @notice royaltyInfo
    /// @dev get royalties for Mintable using the ERC2981 standard
    /// @param _tokenId, token ID NFT
    /// returns receiver address, address (secondary wallet)
    /// returns royaltyAmount, royality amount to send to the owner
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount)
    {
        //use the same royalties that were saved for LooksRare
        LibPart.Part[] memory _royalties = royalties[_tokenId];
        if (_royalties.length > 0) {
            return (
                _royalties[0].account,
                (_salePrice * _royalties[0].value) / 10000
            );
        }
        return (address(0), 0);
    }

    /// @notice supportsInterface
    /// @dev used to use the ERC2981 standard
    /// @param interfaceId, ERC2981 interface
    /// @return bool, true or false
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721Enumerable)
        returns (bool)
    {
        if (interfaceId == LibRoyaltiesV2._INTERFACE_ID_ROYALTIES) {
            return true;
        }
        if (interfaceId == _INTERFACE_ID_ERC2981) {
            return true;
        }
        return super.supportsInterface(interfaceId);
    }

    /******************************/
    /**     Internal Functions   **/
    /******************************/
    
    // Standard functions to be overridden (openzeppelin)
    function _beforeTokenTransfer(
        address _from, 
        address _to, 
        uint256 _tokenId
    ) 
        internal 
        override(ERC721Enumerable) 
    {
        super._beforeTokenTransfer(_from, _to, _tokenId);
    }

    /// @notice _mintNFT, internal function
    /// @dev mint new NFTs and verify all epochs and conditions
    /// @param _numOfTokens, number of NFT a mint 
    /// @param _proof, proof of whitelisting 
    /// @param _index, index of the epoch (1 : Lacoste List, 2: Premint, 3: Public, 4: FreeMint)
    /// @param _claimer, connected wallet
    function _mintNFT(
        uint256 _numOfTokens,
        bytes32[] memory _proof,
        uint256 _index,
        address _claimer
    ) 
        internal 
    {
        require(block.timestamp >= epochs[_index].startDate, "UNDW3 Lacoste: too early");
        if(_index == 1 || _index == 2) require(verify(_proof, bytes32(uint256(uint160(_claimer)))), "UNDW3 Lacoste: Not whitelisted");
        require(_numOfTokens <= epochs[_index].maxPerWallet  , "UNDW3 Lacoste: Cannot mint above limit");
        require(_getClaimedNFT(_index, _claimer) + _numOfTokens<= epochs[_index].maxPerWallet  , "UNDW3 Lacoste: Cannot mint above limit for one address");
        require(epochs[_index].supply + _numOfTokens <= epochs[_index].maxTotal, "UNDW3 Lacoste: Purchase would exceed max public supply of NFTs");
        require(msg.value >= NFTPrice * _numOfTokens, "UNDW3 Lacoste: Ether value sent is not correct");

        for (uint256 i = 0; i < _numOfTokens; i++) {
            _setRoyalties(totalSupply(), secondary, 400);
            _safeMint(_claimer, totalSupply());
        }

        _updateClaimedNFT(_index, _claimer, _numOfTokens);
    }

    /// @notice _getClaimedNFT, internal function
    /// @dev get the number of NFT minted by a specific address by epoch
    /// @param _claimer, connected wallet
    function _getClaimedNFT(
        uint256 _index, 
        address _claimer
    ) 
        internal 
        view
        returns (uint256 _num)
    {
        return nftClaimed [_claimer][_index];
    }
    
    /// @notice _updateClaimedNFT, internal function
    /// @dev update the supply and the claimed NFTs after minting (for each epoch/claimer)
    /// @param _numOfTokens,  number of NFT a mint 
    function _updateClaimedNFT(
        uint256 _index, 
        address _claimer,
        uint256 _numOfTokens
    ) 
        internal 
    {
        nftClaimed [_claimer][_index] += _numOfTokens; 
        epochs[_index].supply += _numOfTokens;
    }

    /// @notice _setRoyalties, internal function
    /// @dev configure royalties details for each NFT minted (secondary market)
    /// @param _tokenId,  token ID 
    /// @param _royaltiesRecipientAddress, the secondary wallet to collect royalities (secondary wallet)
    /// @param _percentageBasisPoints, percentage for the secondary wallet
    function _setRoyalties(
        uint256 _tokenId,
        address payable _royaltiesRecipientAddress,
        uint96 _percentageBasisPoints) 
        internal 
    {
        LibPart.Part[] memory _royalties = new LibPart.Part[](1);
        _royalties[0].value = _percentageBasisPoints;
        _royalties[0].account = _royaltiesRecipientAddress;
        _saveRoyalties(_tokenId, _royalties);
    }
}