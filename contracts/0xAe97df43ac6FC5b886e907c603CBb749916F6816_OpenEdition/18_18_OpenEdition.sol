// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155SupplyUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155URIStorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/MerkleProofUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract OpenEdition is OwnableUpgradeable, ERC1155BurnableUpgradeable, ERC1155SupplyUpgradeable, ERC1155URIStorageUpgradeable {

    enum MintPhase{
        WHITELIST,
        PUBLIC
    }

    struct Token{
        uint256 maxSupply;
        bool status;
        MintPhase currPhase;
    }

    struct User{
        uint256 publicMintCount;
        uint256 whitelistMintCount;
        uint256 burnCount;
    }

    struct Mint{
        uint256 maxWallet;
        uint256 maxSupply;
        uint256 price;
        bytes32 merkleRoot;
    }

    mapping(uint256 => Token) public tokenData; // Every Token ID has a Token Struct
    mapping(uint256 => mapping(MintPhase => Mint)) public mintData; // For every Token ID, it contains Mint Phases, and Mint Phases has a Mint Struct
    mapping(uint256 => mapping(address => User)) public userData;   // For every Token ID, it has user address, and user address has User struct
    address public treasuryAddress;
    string public contractURI;

    event TokenMinted(address minter, uint256 tokenID, uint256 qty, uint256 timestamp);
    event StatusChanged(bool status, string reason, uint256 timestamp);

    modifier MintSettings(uint256 _tokenID, uint256 _qty){
        require(tokenData[_tokenID].status, "OpenEdition :: Token Minting Freezed!");   // status must be true to mint
        
        if((mintData[_tokenID][tokenData[_tokenID].currPhase].price > 0)){ // check if tokendID has price, some token is free.
            require((mintData[_tokenID][tokenData[_tokenID].currPhase].price * _qty) > msg.value, "OpenEdition :: Not enough payment!");  // price must be equal to quantity they bought
        }
        
        if(tokenData[_tokenID].currPhase == MintPhase.PUBLIC){  // Check if user is minting beyond max allocated mint per user
            require((userData[_tokenID][msg.sender].publicMintCount + _qty) <= mintData[_tokenID][tokenData[_tokenID].currPhase].maxWallet, " OpenEdition :: Wallet Mint Maxed Out!");
        }
        else{
            require((userData[_tokenID][msg.sender].whitelistMintCount + _qty) <= mintData[_tokenID][tokenData[_tokenID].currPhase].maxWallet, " OpenEdition :: Wallet Mint Maxed Out!");
        }

        if(mintData[_tokenID][tokenData[_tokenID].currPhase].maxSupply > 0){ // Check if user is minting beyond max supply per Mint Phase
            require((totalSupply(_tokenID) + _qty) >= mintData[_tokenID][tokenData[_tokenID].currPhase].maxSupply, " OpenEdition :: Beyond Mint Phase Supply");
        }
        
        if(tokenData[_tokenID].maxSupply > 0){ // if max supply is set to 0, then supply is infinite
            require((totalSupply(_tokenID) + _qty) <= tokenData[_tokenID].maxSupply, "OpenEdition :: Beyond Max Supply!");  // cannot mint beyond max supply
        }
        _;
    }
    
    function initialize(string memory _contractURI, address _treasuryAddress) initializer external{
        __ERC1155_init("");
        __ERC1155Burnable_init();
        __ERC1155Supply_init();
        __ERC1155URIStorage_init();
        __Ownable_init();

        contractURI = _contractURI;
        treasuryAddress = _treasuryAddress;
    }

    /**
     * Public Function
     */
    function mint(uint256 _tokenID, uint256 _qty) external payable MintSettings(_tokenID, _qty) {
        require(tokenData[_tokenID].currPhase == MintPhase.PUBLIC, "OpenEdition :: Public Sale not Enabled");   // currPhase must be PUBLIC to use this function
        payable(treasuryAddress).transfer(msg.value);

        userData[_tokenID][msg.sender].publicMintCount += _qty; // adds mint qty to user's mint count, per TokenID
        _mint(msg.sender, _tokenID, _qty, "");
        emit TokenMinted(msg.sender, _tokenID, _qty, block.timestamp);
    }

    function whitelistMint(bytes32[] memory _merkleProof, uint256 _tokenID, uint256 _qty) external payable MintSettings(_tokenID, _qty){
        require(tokenData[_tokenID].currPhase == MintPhase.WHITELIST, "OpenEdition :: Whitelist Sale not Enabled");   // currPhase must be WHITELIST to use this function
        bytes32 sender = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProofUpgradeable.verify(_merkleProof, mintData[_tokenID][MintPhase.WHITELIST].merkleRoot, sender), "OpenEdition :: You're not in the list!");


        userData[_tokenID][msg.sender].whitelistMintCount += _qty;  // / adds mint qty to user's mint count, per TokenID
        _mint(msg.sender, _tokenID, _qty, "");
        emit TokenMinted(msg.sender, _tokenID, _qty, block.timestamp);
    }       

    /**
     * Administrative Function
     */
    function setURI(uint256 _tokenID, string memory _tokenUri) external onlyOwner{
        _setURI(_tokenID, _tokenUri);
    }

    function setTreasuryAddress(address _treasuryAddress) external onlyOwner{
        treasuryAddress = _treasuryAddress;
    }

    function setUpTokenData(uint256 _tokenID, uint256 _maxSupply) external onlyOwner{
        tokenData[_tokenID].maxSupply = _maxSupply;
    }

    function setContractStatus(uint256 _tokenID, string memory _reason) external onlyOwner{
        tokenData[_tokenID].status = !tokenData[_tokenID].status;
        emit StatusChanged(tokenData[_tokenID].status, _reason, block.timestamp);
    }

    function setMerkleRoot(uint256 _tokenID, bytes32 _merkleRoot) external onlyOwner{
        mintData[_tokenID][MintPhase.WHITELIST].merkleRoot = _merkleRoot;
    }

    function setMintPhase(uint256 _tokenID) external onlyOwner{
        if(tokenData[_tokenID].currPhase == MintPhase.PUBLIC){
            tokenData[_tokenID].currPhase = MintPhase.WHITELIST;
        }
        else{
            tokenData[_tokenID].currPhase = MintPhase.PUBLIC;
        }
    }

    function setUpMintData(uint256 _tokenID, MintPhase _mintPhase, uint256 _maxWallet, uint256 _maxSupply, uint256 _price, bytes32 _merkleRoot) external onlyOwner{
        mintData[_tokenID][_mintPhase].maxWallet = _maxWallet;
        mintData[_tokenID][_mintPhase].maxSupply = _maxSupply;
        mintData[_tokenID][_mintPhase].price = _price;
        mintData[_tokenID][_mintPhase].merkleRoot = _merkleRoot;
    }

    /**
     * Overrides
     */
    function _beforeTokenTransfer(
		address operator,
		address from,
		address to,
		uint256[] memory ids,
		uint256[] memory amounts,
		bytes memory data
	) internal override(ERC1155Upgradeable, ERC1155SupplyUpgradeable) {
		super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
	}

    function uri(uint256 tokenId) public view virtual override(ERC1155Upgradeable, ERC1155URIStorageUpgradeable) returns (string memory) {

        return super.uri(tokenId);
    }

    function burn(
        address account,
        uint256 id,
        uint256 value
    ) public virtual override {
        require(
            account == _msgSender() || isApprovedForAll(account, _msgSender()),
            "ERC1155: caller is not token owner or approved"
        );

        userData[id][msg.sender].burnCount += value;

        _burn(account, id, value);
    }

    function burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory values
    ) public virtual override {
        require(
            account == _msgSender() || isApprovedForAll(account, _msgSender()),
            "ERC1155: caller is not token owner or approved"
        );

        for(uint256 index = 0; index < ids.length; index++){
            userData[ids[index]][msg.sender].burnCount += values[index];
        }

        _burnBatch(account, ids, values);
    }

}