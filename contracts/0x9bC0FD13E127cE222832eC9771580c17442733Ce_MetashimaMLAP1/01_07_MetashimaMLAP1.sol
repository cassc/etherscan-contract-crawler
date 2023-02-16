// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0; 

import "enefte/ERC721AUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "operator-filter-registry/src/upgradeable/DefaultOperatorFiltererUpgradeable.sol";

/*
* @title Metashima Accessory Pack 1
* @author lileddie.eth / Enefte Studio
*/
contract MetashimaMLAP1 is Initializable, ERC721AUpgradeable, DefaultOperatorFiltererUpgradeable {

    uint public TOKEN_PRICE;

    uint public saleOpens;
    uint public saleCloses;   

    string public BASE_URI;
    mapping(uint => bool) public claimedTokenIds; 
    uint[] public allClaimedTokens; 
      
    mapping(address => bool) private _dev;  
    address private _owner;

    ERC721AUpgradeable public MetashimaContract;


    
    /**
    * @notice minting process for the main sale
    *
    * @param _tokenIds IDs of tokens to claim against
    */
    function mint(uint[] calldata _tokenIds) external payable  {
        require(block.timestamp >= saleOpens && block.timestamp <= saleCloses, "Public sale closed");

        uint tokensToMint = 0;
        uint _numberOfTokens = _tokenIds.length;
        require(TOKEN_PRICE * _numberOfTokens <= msg.value, 'Missing eth');

        for (uint256 i = 0; i < _numberOfTokens; i++) {
            if(msg.sender == MetashimaContract.ownerOf(_tokenIds[i])){
                require(!hasBeenClaimed(_tokenIds[i]), "Token has been claimed already");
                claimedTokenIds[_tokenIds[i]] = true;
                allClaimedTokens.push(_tokenIds[i]);
                tokensToMint += 1;
            }
        }

        _safeMint(msg.sender, tokensToMint);
    }

    /**
    * @notice read the mints made by a specified wallet address.
    *
    * @param _tokenId token ID to check
    */
    function hasBeenClaimed(uint _tokenId) public view returns (bool) {
        return claimedTokenIds[_tokenId];
    }


    /**
    * @notice set the timestamp of when the main sale should begin
    *
    * @param _openTime the unix timestamp the sale opens
    * @param _closeTime the unix timestamp the sale closes
    */
    function setSaleTimes(uint64 _openTime, uint64 _closeTime) external onlyDevOrOwner {
        saleOpens = _openTime;
        saleCloses = _closeTime;
    }

    /**
    * @notice return an array of Metashima token IDs owned by the given wallet address.
    *
    * @param tokenOwner the wallet address of the owner to check
    */
    function metashimaTokensOfOwner(address tokenOwner) external view returns(uint[] memory ) {
        uint256 tokenCount = MetashimaContract.balanceOf(tokenOwner);
        uint256 totalTokens = MetashimaContract.totalSupply();
        if (tokenCount == 0) {
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 index = 0;
            for (uint256 tokenid = 1; tokenid <= totalTokens; tokenid++) {
                if(tokenOwner == MetashimaContract.ownerOf(tokenid)){
                    result[index] = tokenid;
                    index+=1;
                }
            }
            return result;
        }
    }

    
    /**
    * @notice return an array of Metashima token IDs owned by the given wallet address.
    *
    * @param tokenOwner the wallet address of the owner to check
    */
    function tokensOfOwner(address tokenOwner) external view returns(uint[] memory ) {
        uint256 tokenCount = balanceOf(tokenOwner);
        uint256 totalTokens = totalSupply();
        if (tokenCount == 0) {
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 index = 0;
            for (uint256 tokenid = 1; tokenid <= totalTokens; tokenid++) {
                if(tokenOwner == ownerOf(tokenid)){
                    result[index] = tokenid;
                    index+=1;
                }
            }
            return result;
        }
    }

    
    /**
    * @notice return an array of Metashima token IDs that have been claimed already
    *
    */
    function getAllClaimedTokens() external view returns(uint[] memory ) {
        return allClaimedTokens;
    }
    

    /**
    * @notice sets the URI of where metadata will be hosted, gets appended with the token id
    *
    * @param _uri the amount URI address
    */
    function setBaseURI(string memory _uri) external onlyDevOrOwner {
        BASE_URI = _uri;
    }

    function setPrice(uint _price) external onlyDevOrOwner {
        TOKEN_PRICE = _price;
    }
    
    /**
    * @notice returns the URI that is used for the metadata
    */
    function _baseURI() internal view override returns (string memory) {
        return BASE_URI;
    }
    
    function tokenURI(uint tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _baseURI();
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, _toString(tokenId))) : '';
    }

    /**
    * @notice withdraw the funds from the contract to a specificed address. 
    */
    function withdrawBalance() external onlyOwner {
        uint256 balance = address(this).balance;
        (bool sent, bytes memory data) = _owner.call{value: balance}("");
        require(sent, "Failed to send Ether to Wallet");
    }

    
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }
    
    /**
     * @dev notice if called by any account other than the dev or owner.
     */
    modifier onlyDevOrOwner() {
        require(owner() == msg.sender || _dev[msg.sender], "Ownable: caller is not the owner or dev");
        _;
    }  

    /**
     * @notice Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    /**
     * @notice Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @notice Adds a new dev role user
     */
    function addDev(address _newDev) external onlyOwner {
        _dev[_newDev] = true;
    }

    /**
     * @notice Removes address from dev role
     */
    function removeDev(address _removeDev) external onlyOwner {
        delete _dev[_removeDev];
    }

    /**
     * @notice Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _owner = newOwner;
    }

    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    /**
    * @notice Initialize the contract and it's inherited contracts, data is then stored on the proxy for future use/changes
    *
    * @param name_ the name of the contract
    * @param symbol_ the symbol of the contract
    */
    function initialize(string memory name_, string memory symbol_) public initializer {   
        __ERC721A_init(name_, symbol_);
        TOKEN_PRICE = 0.03 ether;
        BASE_URI = "https://www.metashima.com/mintedMLAP1/";
        saleOpens = 1676491200;
        saleCloses = 99999999999999;
        _dev[msg.sender] = true;
        _owner = msg.sender;
        _safeMint(address(0x88493c8a0F0f0Ef46667E9918AF5874ca5C78bd4), 118);
        MetashimaContract = ERC721AUpgradeable(0x223EF06367b89458df762cfa633fb53F403cb9c9);    
    }

}