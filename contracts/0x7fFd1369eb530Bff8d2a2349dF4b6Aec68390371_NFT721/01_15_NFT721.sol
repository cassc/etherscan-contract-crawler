// SPDX-License-Identifier: None
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "./OwnPause.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

error NotAuthorizedNorOwner();

contract NFT721 is OwnPause, ERC721Enumerable {
    using Strings for uint256;

    uint256 public currentTokenID;
    uint256 public currentLuckyTokenID;
    string public baseURI;

    event Mint(address indexed to, uint256 indexed tokenID);
    event MintBatch(address[] beneficiaries, uint256 fromID, uint256 toID);

    constructor(
        string memory _name,
        string memory _symbol,
        string memory baseURI_
    ) Ownable() ERC721(_name, _symbol) {
        baseURI = baseURI_;
        currentTokenID = 1;
        currentLuckyTokenID = 100000000000;
    }

    /**
       	@notice Update new Base URI
       	@dev  Caller must be Owner
		@param	baseURI_				New Base URI
    */
    function updateBaseURI(string calldata baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    /**
       	@notice Mint NFT to `_beneficiary`
       	@dev  Caller must be Authorized
		@param	_beneficiary				Address of Beneficiary
    */
    function mint(address _beneficiary) external isAuthorized {
        uint256 _currentTokenID = currentTokenID;
        _safeMint(_beneficiary, _currentTokenID, "");

        emit Mint(_beneficiary, _currentTokenID);
        currentTokenID++;
    }

    /**
       	@notice Lucky Mint NFT to `_beneficiary`
       	@dev  Caller must be Authorized
		@param	_beneficiary				Address of Beneficiary
    */
    function luckyMint(address _beneficiary) external isAuthorized {
        uint256 _currentLuckyTokenID = currentLuckyTokenID;
        _safeMint(_beneficiary, _currentLuckyTokenID, "");

        emit Mint(_beneficiary, _currentLuckyTokenID);
        currentLuckyTokenID++;
    }

    /**
       	@notice Mint a batch of NFT to `_beneficiaries`
       	@dev  Caller must be Owner
		@param	_beneficiaries				A list of Beneficiaries
    */
    function mintBatch(address[] calldata _beneficiaries) external isAuthorized {
        uint256 _amount = _beneficiaries.length;
        uint256 _currentTokenID = currentTokenID;
        for (uint256 i; i < _amount; i++)
            _safeMint(_beneficiaries[i], _currentTokenID + i, "");

        emit MintBatch(_beneficiaries, _currentTokenID, _currentTokenID + _amount - 1);
        currentTokenID += _amount;
    }

    /**
       	@notice Burn a batch of `_tokenIds`
       	@dev  Caller must be Owner
		@param	_tokenIds		        A list of burning `_tokenIds`
    */
    function burn(uint256[] calldata _tokenIds) external {
        bool authorized;
        address _caller = msg.sender;
        uint256 _len = _tokenIds.length;
        if (_caller == owner()) authorized = true;
        
        uint256 _id;
        for (uint256 i; i < _len; i++) {
            _id = _tokenIds[i];
            if (!authorized && ownerOf(_id) != _caller) revert NotAuthorizedNorOwner();

            _burn(_id);
        }
    }

    /**
       	@notice Query a list of `_tokenIds` that owned by `_account`
       	@dev  Caller can be ANY
		@param	_account			Account's address to query
		@param	_fromIdx		    Starting index
		@param	_toIdx			    Ending index
    */
	function tokensByOwner(address _account, uint256 _fromIdx, uint256 _toIdx) external view returns (uint256[] memory _tokens) {
		uint256 _len = _toIdx - _fromIdx + 1;
		_tokens = new uint256[](_len);

		for(uint256 i; i < _len; i++) 
			_tokens[i] = tokenOfOwnerByIndex(_account, _fromIdx + i);
	}

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireMinted(tokenId);

        string memory baseURI_ = _baseURI();

        if(tokenId >= currentLuckyTokenID){
            return bytes(baseURI_).length > 0 ? string(abi.encodePacked(baseURI_, "box", ".json")) : "";
        }
        return bytes(baseURI_).length > 0 ? string(abi.encodePacked(baseURI_, tokenId.toString(), ".json")) : "";
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

}