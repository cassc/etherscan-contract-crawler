// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";


/// @title Smart Contract for managing Continent Key NFT
/// @author Hernan Abeldaño
/// @notice Implements ERC1155 Standard with specific mint.


contract CKNFT is ERC1155, Ownable, Pausable {

    event WhiteListedMint (address indexed wlminter, uint256 indexed _id, uint256 _amount);
    event Mint (address indexed minter, uint256 indexed _id, uint256 _amount);
    
    string public name = "Continent Key";
    string public symbol = "CKEY";
    string public contractUri;

    uint256 public constant CKNFT_PRICE = 0 ether;
    uint256 public constant MAX_TOKEN_ID_PLUS_ONE = 1; 
    uint256 public AL_TIMER;
    uint256 public MAX_MINT = 1;
    uint256 public max_mint_wl = 1;
    uint256 public MAX_AL_MINT = 1;   

    
    
    mapping(uint256 => uint256) public tokenIdToExistingSupply;
    mapping(uint256 => uint256) public tokenIdToMaxSupplyPlusOne; // set in the constructor
    mapping(address => bool) public allowlistsAddresses;
    mapping(address => uint256) public allowlistsPermit;
    mapping(address => uint256) public mintPermit;

    bool private _reentrant = false;
    bool public isAllowlistsActive = false;

    modifier nonReentrant() {
        require(!_reentrant, "No reentrancy");
        _reentrant = true;
        _;
        _reentrant = false;
    }

    address public companyTreasuryWallet = 0x672AFf8Baa1735C16D99f669E246A272191F1C6c;


    constructor()
        ERC1155(
            "https://continent-key.mypinata.cloud/ipfs/QmP6Cyyx7caHDXFowVEiwSTWw3Xx9ZB4eX6zeA2mXphzzE/{id}.json"
        )
    {
        contractUri = "https://continent-opensea.mypinata.cloud/ipfs/QmXmjP9gudWvnodR9DY1eWQ4UkygFNSQUQ9DhBJKhw2yNo"; // json contract metadata file for OpenSea

        tokenIdToMaxSupplyPlusOne[0] = 10000;        
        
        Pausable._pause();
        uint256[] memory _ids = new uint256[](1);
        uint256[] memory _amounts = new uint256[](1);
        for (uint256 i = 0; i < MAX_TOKEN_ID_PLUS_ONE; ++i) {
            _ids[i] = i;
            _amounts[i] = 384;
            tokenIdToExistingSupply[i] = 384;
        }
        _mintBatch(companyTreasuryWallet, _ids, _amounts, "");
    }
     
    /// @dev function for OpenSea that returns the total quantity of a token ID currently in existence
    function totalSupply(uint256 _id) external view returns (uint256) {
        require(_id < MAX_TOKEN_ID_PLUS_ONE, "id must be < 1");
        return tokenIdToExistingSupply[_id];
    }

    /// @dev function for OpenSea that returns uri of the contract metadata
    function contractURI() public view returns (string memory) {
        return contractUri; // OpenSea
    }

    // SETTERS

    function setContractURI(string calldata _newURI) external onlyOwner {
        contractUri = _newURI; // updatable in order to change general project info for marketplaces like OpenSea
    }

    function setPaused(bool _paused) external onlyOwner {
        if (_paused) _pause();
        else _unpause();
    }

    function setAllowlistsActive(bool _wlEnd) external onlyOwner {
        AL_TIMER = block.timestamp + 1 minutes; // 3 days (72h)
        isAllowlistsActive = _wlEnd;
    }

    function allowlistsUsers(address[] calldata _users) public onlyOwner {
        for (uint256 i = 0; i < _users.length; i++) {
            allowlistsAddresses[_users[i]] = true;
        }
    }

    function setMaxALMint(uint256 _max) public onlyOwner {
        MAX_AL_MINT = _max;
    }

    // PUBLIC FUNCTIONS

    // @notice Mints one o more NFTs for the selected amount.
    // @dev There is a limit on minting amount.
    // @param id NFT to be minted.
    // @param amount The amount of NFT to be minted. 

    function allowlistsMint(uint256 _id, uint256 _amount)
        external
        payable
        nonReentrant
    {
        require(
            (isAllowlistsActive),
            "Allowlists is not active"
        );

        // AL_Timer is here to lock access for AL only under 24h
        require(
            (AL_TIMER > block.timestamp),
            "Allowlists is finish"
        );
        require(
            allowlistsAddresses[msg.sender] == true,
            "You'r not allowlists !"
        );
        
        require(
            allowlistsPermit[msg.sender] + _amount <= MAX_AL_MINT,
            "Only 1 Nfts by allowlists address."
        );
        require(_id < MAX_TOKEN_ID_PLUS_ONE, "id must be < 1");
        require(tokenIdToExistingSupply[_id] + _amount <= 1, "Allowlists supply exceeded");
        require(_amount > 0 && _amount <= max_mint_wl, "Invalid mint amount");                

        uint256 existingSupply = tokenIdToExistingSupply[_id];

        require(msg.value == _amount * CKNFT_PRICE, "Incorrect ETH");
        require(msg.sender == tx.origin, "No Smart Contracts");

        payable(companyTreasuryWallet).transfer(_amount * CKNFT_PRICE);    

        unchecked {
            existingSupply += _amount;
        }
        tokenIdToExistingSupply[_id] = existingSupply;      
        
        for (uint256 i = 0; i < _amount; i++) {
                        
            allowlistsPermit[msg.sender]++;   
        }
        _mint(msg.sender, _id, _amount, "");
    }

    // PUBLIC FUNCTIONS

    // @notice Mints one o more NFTs for the selected amount.
    // @dev There is a limit on minting amount.
    // @param id NFT to be minted.
    // @param amount The amount of NFT to be minted. 

    function publicMint(uint256 _id, uint256 _amount) external payable {
        require(
            (AL_TIMER != 0),
            "Allowlists has not started"
        );
        require(
            (AL_TIMER < block.timestamp),
            "Allowlists has not finish"
        );        
        require(_id < MAX_TOKEN_ID_PLUS_ONE, "id must be < 1");

        require(
            allowlistsPermit[msg.sender] + _amount <= MAX_MINT,
            "Only 1 Nfts by address. "
        );

        uint256 existingSupply = tokenIdToExistingSupply[_id];
        require(
            existingSupply + _amount <= tokenIdToMaxSupplyPlusOne[_id],
            "Total supply exceeded"
        );

        require(msg.value == _amount * CKNFT_PRICE, "Incorrect ETH");
        require(msg.sender == tx.origin, "No Smart Contracts");

        payable(companyTreasuryWallet).transfer(_amount * CKNFT_PRICE);
        
        unchecked {
            existingSupply += _amount;
        }
        tokenIdToExistingSupply[_id] = existingSupply;
        for (uint256 i = 0; i < _amount; i++) {
                        
           allowlistsPermit[msg.sender]++;   
        }
        _mint(msg.sender, _id, _amount, "");
    }

    function ownerMint(
        address _to,
        uint256 _id,
        uint256 _amount
    ) external onlyOwner {
        require(_id < MAX_TOKEN_ID_PLUS_ONE, "id must be < 1");

        uint256 existingSupply = tokenIdToExistingSupply[_id];
        require(
            existingSupply + _amount < tokenIdToMaxSupplyPlusOne[_id],
            "Supply exceeded"
        );
        unchecked {
            existingSupply += _amount;
        }
        tokenIdToExistingSupply[_id] = existingSupply;
        _mint(_to, _id, _amount, "");
    }

    function mintBatch(uint256[] calldata _ids, uint256[] calldata _amounts)
        external
        payable whenNotPaused
    {
        uint256 sumAmounts;
        uint256 arrayLength = _ids.length;
        for (uint256 i = 0; i < arrayLength; ++i) {
            sumAmounts += _amounts[i];
        }

        require(msg.value == sumAmounts * CKNFT_PRICE, "Incorrect ETH");

        for (uint256 i = 0; i < arrayLength; ++i) {
            uint256 _id = _ids[i];
            uint256 _amount = _amounts[i];
            uint256 existingSupply = tokenIdToExistingSupply[_id];
            
            require(
                existingSupply + _amount < tokenIdToMaxSupplyPlusOne[_id],
                "Supply exceeded"
            );
            require(msg.sender == tx.origin, "No Smart Contracts");

            unchecked {
                existingSupply += _amount;
            }
            tokenIdToExistingSupply[_id] = existingSupply;
        }
        _mintBatch(msg.sender, _ids, _amounts, "");
    }    

    function ownerMintBatch(
        uint256[] calldata _ids,
        uint256[] calldata _amounts
    ) external whenNotPaused onlyOwner {
        uint256 arrayLength = _ids.length;

        for (uint256 i = 0; i < arrayLength; ++i) {
            uint256 existingSupply = tokenIdToExistingSupply[_ids[i]];
            uint256 _id = _ids[i];
            uint256 _amount = _amounts[i];

            require(_id < MAX_TOKEN_ID_PLUS_ONE, "id must be < 1");
            require(
                existingSupply + _amount < tokenIdToMaxSupplyPlusOne[_id],
                "Supply exceeded"
            );
            require(msg.sender == tx.origin, "No Smart Contracts");

            unchecked {
                existingSupply += _amount;
            }
            tokenIdToExistingSupply[_id] = existingSupply;
        }
        _mintBatch(msg.sender, _ids, _amounts, "");
    }       

    // ARRAYS

    function addToArray(uint256[] storage list, uint256 value) private {
        uint256 index = find(list, value);
        if (index == list.length) {
            list.push(value);
        }
    }

    function removeFromArray(uint256[] storage list, uint256 value) private {
        uint256 index = find(list, value);
        if (index < list.length) {
            list[index] = list[list.length - 1];
            list.pop();
        }
    }

    function find(uint256[] memory list, uint256 value) private pure returns(uint)  {
        for (uint i=0;i<list.length;i++) {
            if (list[i] == value) {
               return i;
            }
        }
        return list.length;
    }
    
}