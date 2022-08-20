// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


contract NowlyCollection is ERC721, Ownable {
    /**
        *   @dev Initializes the contract by setting a 
        *   `totalSupply`, `baseUri`, and a `extension` to the collection.
        *   @param totalSupply_ The initial value of the totalSupply.
        *   @param baseUri_ The initial value of the _baseUri.
        *   @param extension_ The initial value of the _extension.
        */
    constructor(uint256 totalSupply_, string memory baseUri_, string memory extension_)
        ERC721("Project Nowly", "ProjectNowly")
    {
        totalSupply = totalSupply_;
        authorizedAddress[msg.sender] = true;
        mint(msg.sender, 1);
        _baseUri = baseUri_;
        _extension = extension_;
    }

    // using SafeMath to prevent overflow
    using SafeMath for uint256;

    // Total minted NFT
    uint256 public minted;
    
    // Mintable amount of NFTs
    uint256 public totalSupply;
    
    // NFTs revealed baseUri
    string private _baseUri;
    
    // NFTs revealed baseUri extension
    string private _extension;

    /**
        * Mapping of address authorized to interact on functions with `onlyOwnerOrAuthorized` modifier.
        */ 
    mapping(address => bool) private authorizedAddress;

    /**
        * Mapping of the tokenIds thats metadata are revealed.
        */ 
    mapping(uint256 => bool) private reveal;

    /**
        *   Checks if the `_address` provided is {Authorized} to interact with sensitive data.
        *   @param _address The address that is being checked for authorization.
        *   @return bool If the address is `authorized` or not.
        */
    function isAddressAuthorized(address _address) 
        public 
        view 
        returns (bool) 
    {
        return authorizedAddress[_address];
    }

    /**
        *   Checks if the `tokenId` is `revealed`.
        *   @param tokenId The tokenId that is checked if it is `revealed` or not.
        *   @return bool If the tokenId is `revealed` or not. 
        */
    function isRevealed(uint256 tokenId)
        public
        view
        returns (bool)
    {
        return reveal[tokenId];
    }

    /**
        *   Fetches the Metadata origin for every `tokenId`.
        *   @param tokenId The NFTs tokenId.
        *   @return string The URI to where to take the NFTs metadata.
        */
    function tokenURI(uint256 tokenId) 
        override
        view
        public
        returns (string memory) 
    {
        return string(abi.encodePacked(
            _baseUri,
            Strings.toString(tokenId),
            _extension
        ));
    }

    /**
        *   Fetches the `_extension` of the baseURI.
        *   @notice Can only be executed by the Owner or an Authorized Address. 
        *   @return string The URI extension of the baseUri.
        */
    function getExtension()
        view
        public
        onlyOwnerOrAuthorized
        returns (string memory)
    {
        return _extension;
    }

    /**
        *   Fetches the `_baseUri` of the NFT.
        *   @notice Can only be executed by the Owner or an Authorized Address. 
        *   @return string The baseURI to where the NFT's metadata is stored.
        */
    function getBaseUri()
        view
        public
        onlyOwnerOrAuthorized
        returns (string memory)
    {
        return _baseUri;
    }

    /**
        *   Updates the `reveal` mapping for the tokenId.
        *   @param tokenId The tokenId that will be revealed.
        *   @param _reveal The new value of reveal.
        *   @notice Can only be executed by the Owner or an Authorized Address.
        */
    function revealTokenId(uint256 tokenId, bool _reveal)
        public
        onlyOwnerOrAuthorized
    {
        reveal[tokenId] = _reveal;
    }

    /**
        *   Updates the `reveal` mapping for a range of tokenIds.
        *   @param start The starting tokenId to be updated.
        *   @param end The last tokenId to be updated.
        *   @param _reveal The new value of reveal.
        *   @notice Can only be executed by the Owner or an Authorized Address.
        */
    function revealRange(uint256 start, uint256 end, bool _reveal)
        public
        onlyOwnerOrAuthorized
    {
        require(start < end, "Start must be lesser End.");
        for (uint256 startingIndex = start; startingIndex <= end; ++startingIndex) {
            reveal[startingIndex] = _reveal;
        }
    }

    /**
        *   Updates the `totalSupply` amount.
        *   @param _amount The new value of totalSupply.
        *   @notice Can only be executed by the Owner.
        */
    function setTotalSupply(uint256 _amount) 
        public
        onlyOwner
    {
        require(minted <= _amount, "New amount must not be lower than the current minted amount");
        totalSupply = _amount;
    }

    /**
        *   Authorizes an `address`.
        *   @param _address The Address that is being Authorized.
        *   @notice Can only be executed by the Owner.
        */
    function authorizeAddress(address _address) 
        public 
        onlyOwner 
    {
        authorizedAddress[_address] = true;
    }

    /**
        *   Unauthorizes an `address`.
        *   @param _address The Address that is being Unathorized.
        *   @notice Can only be executed by the Owner.
        */
    function unauthorizeAddress(address _address)
        public
        onlyOwner
    {
        authorizedAddress[_address] = false;
    }

    /**
        *   Mint the NFT supply to an address.
        *   @param account The owner of the assets that will be minted. 
        *   @param amount The amount of NFT assets that will be minted. 
        *   @notice Can only be executed by the Owner or an Authorized Address.
        */
    function mint(address account, uint256 amount)
        public
        onlyOwnerOrAuthorized
    {
        uint total = amount + minted;
        require(total <= totalSupply, "Not enough NFTs to mint");
        uint256 totalMinted = 0;
        do {
            ++minted;
            if(!_exists(minted)) {
                _safeMint(account, minted);
                ++totalMinted;
            }
        } while(totalMinted < amount);
        require(minted <= totalSupply, "Not enough NFTs to mint");
    }

    /**
        *   Mint a specific `tokenId` to a designated `account`.
        *   @param account The owner of the asset that will be minted. 
        *   @param tokenId The tokenId that will be minted. 
        *   @notice Can only be executed by the Owner.
        */
    function mintTokenId(address account, uint256 tokenId) 
        public
        onlyOwner
    {
        _safeMint(account, tokenId);
    }

    /**
        *   Update the `extension` of the baseURI.
        *   @param extension_ The new value of _extension.
        *   @notice Can only be executed by the Owner.
        */
    function setExtension(string memory extension_)
        onlyOwner
        public
    {
        _extension = extension_;
    }

    /**
        *   Update the `baseUri` value.
        *   @param baseUri_ The new value of _baseUri.
        *   @notice Can only be executed by the Owner.
        */
    function setBaseUri(string memory baseUri_)
        onlyOwner
        public
    {
        _baseUri = baseUri_;
    }

    /**
        *   Updates the minted index.
        *   @param _amount The new value of minted. 
        *   @notice Can only be executed by the Owner or an Authorized Address.
        */
    function setMinted(uint256 _amount) 
        onlyOwner
        public
    {
        require(_amount > minted, "Amount must not be lower than the current minted amount.");
        minted = _amount;
    }

    /**
        *   @notice A function modifier to guard functions with sensitive data
        *   that must only be executed by the Owner or an Authorized address.
        */
    modifier onlyOwnerOrAuthorized() {
        require(
            isAddressAuthorized(msg.sender) == true || owner() == msg.sender, "Caller is not the Owner or Authorized");
        _;
    }
}