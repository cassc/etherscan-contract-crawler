// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0; 

import "enefte/ERC721AUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "operator-filter-registry/src/upgradeable/DefaultOperatorFiltererUpgradeable.sol";

/*
* @title D8a Dao Silver
* @author lileddie.eth / Enefte Studio
*/
contract D8aDaoSilverV2 is Initializable, ERC721AUpgradeable, DefaultOperatorFiltererUpgradeable {

    uint64 public MAX_SUPPLY;
    uint64 public TOKEN_PRICE;
    uint64 public MAX_TOKENS_PER_WALLET;

    uint64 public saleOpens;
    uint64 public saleCloses;   

    string public BASE_URI;
      
    mapping(address => bool) private _dev;  
    address private _owner;
    address private wallet1;
    address private wallet2;
    address private wallet3;
    address private wallet4;
    address private wallet5;
    address private wallet6;
    address private wallet7;
    
    /**
    * @notice minting process for the main sale
    *
    * @param _numberOfTokens number of tokens to be minted
    */
    function mint(uint64 _numberOfTokens) external payable  {
        require(block.timestamp >= saleOpens && block.timestamp <= saleCloses, "Public sale closed");
        require(totalSupply() + _numberOfTokens <= MAX_SUPPLY, "Not enough left");

        uint64 mintsForThisWallet = mintsForWallet(msg.sender);
        mintsForThisWallet += _numberOfTokens;
        require(mintsForThisWallet <= MAX_TOKENS_PER_WALLET, "Max tokens reached per wallet");

        require(TOKEN_PRICE * _numberOfTokens <= msg.value, 'Missing eth');

        _safeMint(msg.sender, _numberOfTokens);
        _setAux(msg.sender,mintsForThisWallet);
    }

    /**
    * @notice read the mints made by a specified wallet address.
    *
    * @param _wallet the wallet address
    */
    function mintsForWallet(address _wallet) public view returns (uint64) {
        return _getAux(_wallet);
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
    * @notice set the maximum number of tokens that can be bought by a single wallet
    *
    * @param _quantity the amount that can be bought
    */
    function setMaxPerWallet(uint64 _quantity) external onlyDevOrOwner {
        MAX_TOKENS_PER_WALLET = _quantity;
    }

    /**
    * @notice sets the URI of where metadata will be hosted, gets appended with the token id
    *
    * @param _uri the amount URI address
    */
    function setBaseURI(string memory _uri) external onlyDevOrOwner {
        BASE_URI = _uri;
    }

    function setFounderWallet(address _address) external onlyDevOrOwner {
        wallet1 = _address;
    }
    function setMarketingWallet(address _address) external onlyDevOrOwner {
        wallet2 = _address;
    }
    function setDaoCommunityWallet(address _address) external onlyDevOrOwner {
        wallet3 = _address;
    }
    function setDaoAcquisitionWallet(address _address) external onlyDevOrOwner {
        wallet4 = _address;
    }
    function setDaoRewardsWallet(address _address) external onlyDevOrOwner {
        wallet5 = _address;
    }
    function setDaoDevWallet(address _address) external onlyDevOrOwner {
        wallet6 = _address;
    }
    function setTechnologyWallet(address _address) external onlyDevOrOwner {
        wallet7 = _address;
    }
    
    /**
    * @notice returns the URI that is used for the metadata
    */
    function _baseURI() internal view override returns (string memory) {
        return BASE_URI;
    }
    
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _baseURI();
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, _toString(tokenId))) : '';
    }

    /**
    * @notice withdraw the funds from the contract to a specificed address. 
    */
    function withdrawBalance() external onlyOwner {
        uint256 balance = address(this).balance;
        uint256 halfBalance = balance/2;

        uint256 wallet1Share = (halfBalance / 100) * 14;
        uint256 wallet2Share = (halfBalance / 100) * 8;
        uint256 wallet3Share = (halfBalance / 100) * 16;
        uint256 wallet4Share = (halfBalance / 100) * 18;
        uint256 wallet5Share = (halfBalance / 100) * 7;
        uint256 wallet6Share = (halfBalance / 100) * 15;
        uint256 wallet7Share = (halfBalance / 100) * 22;
        uint256 wallet7Extra = halfBalance;

        wallet1.call{value: wallet1Share}("");
        wallet2.call{value: wallet2Share}("");
        wallet3.call{value: wallet3Share}("");
        wallet4.call{value: wallet4Share}("");
        wallet5.call{value: wallet5Share}("");
        wallet6.call{value: wallet6Share}("");
        wallet7.call{value: wallet7Share}("");
        
        (bool sent7extra, bytes memory data7extra) = wallet7.call{value: wallet7Extra}("");
        require(sent7extra, "Failed to send Ether to Wallet 7 Extra");

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

    function _startTokenId() internal override view virtual returns (uint256) {
        return 1;
    }


}