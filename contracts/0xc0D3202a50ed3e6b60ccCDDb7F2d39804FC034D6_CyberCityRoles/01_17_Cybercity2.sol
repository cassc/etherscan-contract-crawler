// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "../omnium-library/contracts/OmniumStakeableERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

contract OwnableDelegateProxy {}

/**
 * Used to delegate ownership of a contract to another address, to save on unneeded transactions to approve contract use for users
 */

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

contract CyberCityRoles is OmniumStakeableERC1155Upgradeable {
    using SafeMathUpgradeable for uint256;
    using StringsUpgradeable for uint256;    

    event debug(address _from, uint256 _tokenId, uint256 _amount);
    // Constants

    address private constant _withdrawWallet = address(0xb6B35D3263832338f883Be9373d18f7809F21e3b);
    uint256 private constant _maxNFTSupply = 40;
    string private constant  _metaDataUri = "ipfs://QmX5fMXxpgUemVxdJivpZ9cL6QLEQnZAwcBd5L6ErjyiC5/";
    string private constant _contractURI = "ipfs://QmbNX9QGGi4ZpS6w31NrbbKwJrvJbp1hvZ8uPNTSgvPaPn";    

    // Custom data types

    struct tokenData {
        uint256 _maxSupply;
        uint256 _currentSupply;
    }

    struct tierData {
        uint256 _upgradePrice;
        uint256 _stakeCoefficient;
    }

    // State Variables

    string public name;
    string public symbol;
    bool private _paused;
    address private _proxyRegistryAddress; // OpenSea proxy registry address
    mapping ( uint256 => tokenData) private _mintedTokens;
    mapping ( uint256 => tierData) private _tiers;    
    bool[_maxNFTSupply] private _nftAvailabilityMap;    
    uint randNonce;
    mapping ( address => uint256 ) private claimedRoles;
    address private _cybercityContractAddress;
    address private _omniumTokenAddress;
    address private _rolePromotionAddress;    
    uint256[49] private __gap;
    
    function initialize( address __proxyRegistryAddress ) initializer public {
        __OmniumStakeableERC1155Upgradeable_init(_metaDataUri);        
        _paused = false;
        name = "CyberCity Roles";
        symbol = "CCR";
        _proxyRegistryAddress = __proxyRegistryAddress;
        randNonce = 0;
       
        for (uint i=0;i<_maxNFTSupply;i++) {
            _nftAvailabilityMap[i] = true;
        }        
        _mint(msg.sender, 26, 1, "");        
    }


    /**
     * @dev Pauses / Resume contract operation.
     *
     */

    function Pause() public onlyOwner {
        _paused = !_paused;
    }

    /**
     * @dev Randomly Mints NFT tokens 
     */
     
    function claimRole() public returns ( uint256 ){
        require(!_paused,"P");    
        address _to = msg.sender;
        uint256 residentBalance = IERC1155Upgradeable(_cybercityContractAddress).balanceOf(_to, 2);
        require(residentBalance > 0 && claimedRoles[_to].add(1) <= residentBalance, "NR");
        uint256 tokenId = _getNFtoMint();
        require( tokenId > 0,"NT");
        require( _mintedTokens[tokenId]._currentSupply.add(1) <= _mintedTokens[tokenId]._maxSupply,tokenId.toString());
        // updates current supply
        _mintedTokens[tokenId]._currentSupply++;
        // updates nft avilability MAP for random minting
        _nftAvailabilityMap[tokenId-1] = (_mintedTokens[tokenId]._currentSupply != _mintedTokens[tokenId]._maxSupply);
        // mints NFT
        _mint(_to, tokenId, 1, "");
        claimedRoles[_to]++;

        return tokenId;
    }

    function stakeRole( uint256 tokenID ) public {
        require(!_paused,"P");
        require( tokenID > 0,"NTID");        
        
        _safeTransferFrom(msg.sender, _omniumTokenAddress, tokenID, 1, "");

    }

    /**
     * @dev Empty receive function.
     *
     * Requirements:
     *   
     * - Cannot send plain ether to this contract
     */

      receive () external payable { revert(); }


    /**
     * @dev Set token staking, mint and upgrade data 

     */

   function setTokenData( 
        uint256 _fromTokenID,
        uint256 _toTokenID,        
        uint256 _maxSupply
    ) public onlyOwner() {
        require(!_paused,"P");  
        require(_fromTokenID <= _maxNFTSupply && _toTokenID <= _maxNFTSupply);
        require(_fromTokenID <= _toTokenID);        
        for (uint256 i=_fromTokenID; i <= _toTokenID; i++) {
            _mintedTokens[_getBaseTokenId(i)]._maxSupply = _maxSupply; 
        }
    }    

    function setTierData( 
        uint256 _tierID,
        uint256 _upgradePrice,
        uint256 _stakeCoefficient
    ) public onlyOwner() {
        require(!_paused,"P");    
        require(_tierID >= 1 && _tierID <= 3);
        _tiers[_tierID]._upgradePrice = _upgradePrice;
        _tiers[_tierID]._stakeCoefficient = _stakeCoefficient;
    }

    function setContractAddress( address _CC, address _OT, address _RP ) public onlyOwner {
        require(!_paused,"P");      
        _cybercityContractAddress = address(_CC);
        _omniumTokenAddress = address(_OT);        
        _rolePromotionAddress = address(_RP);        
    }

    function getContractAddress() public view onlyOwner returns (address,address,address) {
        return (_cybercityContractAddress,_omniumTokenAddress,_rolePromotionAddress);
    }

    /**
     * @dev Get token staking, mint and upgrade data 
     * Returns:
     * Token Max Supply
     * First Upgrade Price in omnium coins
     * Second Upgrade price in omnium coins
     * Stake coefficient
     */

    function getTokenData( uint256 _tokenID) public returns (uint256,uint256,uint256,uint256) {
        uint256 _baseTokenId = _getBaseTokenId(_tokenID);
        uint256 _tokenTier = _getTokenTier(_tokenID);
        return (
            _mintedTokens[_baseTokenId]._maxSupply,         
            _mintedTokens[_tokenID]._currentSupply,                     
            _tiers[_tokenTier]._upgradePrice,
            getTokenStakeCoeficient(_tokenID)
        );
    }

    function getTierData( uint256 _tierID) public view onlyOwner() returns (uint256,uint256) {
        require(_tierID >= 1 && _tierID <= 3);
        return( 
            _tiers[_tierID]._upgradePrice,
            _tiers[_tierID]._stakeCoefficient
        );
    }

    function getTokenStakeCoeficient( uint256 _tokenId) public virtual override returns (uint256) {
        require(_tokenId <= _maxNFTSupply.mul(3));
        uint256 _tokenTier = _getTokenTier(_tokenId);

        return _tiers[_tokenTier]._stakeCoefficient;
    }

    /**
     * @dev uri: Returns metada file URI for the selected NFT
     *   
     */    

    function uri(uint id) public view virtual override returns (string memory) {
        return string(abi.encodePacked(_metaDataUri, StringsUpgradeable.toString(id)));
    }    
    
    /**
     * @dev baseTokenURI: Returns contract base URI for metadata files
     *   
     */    

    function baseTokenURI() external pure  returns (string memory) {
        return _metaDataUri;
    }  

    function contractURI() public pure returns (string memory) {
        return _contractURI;
    }
    /**
     * @dev paused: Returns contract pause status
     *   
     */        

    function paused() external view  returns (bool) {
        return _paused;
    }  

    /**
     * @dev isApprovedForAll: Returns isApprovedForAll standar ERC1155 method modified to return
     * always true for Opensea proxy contract. (frictionless opensea integration)  
     * See Opensea tradable token.
     */        

    function isApprovedForAll(
        address account, 
        address operator
        ) 
        public 
        view 
        virtual 
        override returns (bool) {  
            // Whitelist OpenSea proxy contract for easy trading.
            ProxyRegistry proxyRegistry = ProxyRegistry(_proxyRegistryAddress);
            if (address(proxyRegistry.proxies(account)) == operator || address(this) == operator || address(_omniumTokenAddress) == operator ) {
                return true;
            }          

            return super.isApprovedForAll(account,operator);
    }

    /**
     * @dev _beforeTokenTransfer: Modified _safeTransfer trigger to implement RESIDENT PASS FREE MINT.
     * After successfull transfer of REDEMPTION Tokens from user wallet to contract address, this function mints 
     * one RESIDENT PASS TOKEN for each REDEMPTION TOKEN received.
     *
     */        

    function _beforeTokenTransfer(
        address,
        address _from,
        address _to,
        uint256[] memory,
        uint256[] memory,
        bytes memory 
    ) internal virtual override {
        require(!_paused,"P");    
        if ( _from != address(0) && _from.code.length == 0 && _to.code.length == 0 && _to != address(0)) {
            uint256 residentBalance = IERC1155Upgradeable(_cybercityContractAddress).balanceOf(_to, 2);
            require(residentBalance > 0, "NR");
            claimedRoles[_from] = claimedRoles[_from].sub(1);
            if ( claimedRoles[_from] == 0) {
                delete claimedRoles[_from];
            }
            claimedRoles[_to] = claimedRoles[_to].add(1);
        }
    }    

    function onERC1155Received(
        address,
        address _from,
        uint256 _sourceTokenId,
        uint256 _qty,
        bytes memory data 
    ) public virtual override returns (bytes4) {
        if (msg.sender == address(_rolePromotionAddress)) {
            require(!_paused && _sourceTokenId == 1,"EG");    
            uint256 _tokenId = toUint256(data);
            require(balanceOf(_from, _tokenId) >= _qty,"NBLC");
            require( _tokenId <= _maxNFTSupply.mul(2),"NUPG");
            uint256 _tokenToMint = _tokenId.add(_maxNFTSupply);                
            //uint256 _baseTokenToMint = _getBaseTokenId(_tokenToMint);
            uint256 _tokenIdTier = _getTokenTier(_tokenId);
            uint256 _mintPrice = _tiers[_tokenIdTier]._upgradePrice;
            require( _qty >= _mintPrice,"IQ");
            // updates current supply for upgraded role token
            _mintedTokens[_tokenToMint]._currentSupply = _mintedTokens[_tokenToMint]._currentSupply.add(1);
            // mints upgraded NFT
            _mint(_from, _tokenToMint, 1, "");
            // Burn Original Token
            _burn(_from, _tokenId, 1);
        }

        return this.onERC1155Received.selector;
    }

    /**
     * @dev Get base token ID
     * Returns the token ID for accessing configuration parameters, taking care that 
     * TokenIds between 1 and MaxSupply are base token ID
     * TokenID between MaxSupply + 1 and MaxSupple * 2 ar 1st upgrade role token
     * TokenID between MaxSupply*2 + 1 and MaxSupple * 3 ar 2st upgrade role token     
     */

    function _getBaseTokenId( uint256 _tokenId ) private pure returns (uint256) {
        uint256 _baseTokenId;
        if (_tokenId <= _maxNFTSupply) {
            _baseTokenId = _tokenId;
        } else {            
            _baseTokenId = _tokenId <= _maxNFTSupply.mul(2) ? _tokenId.sub(_maxNFTSupply) : _tokenId.sub(_maxNFTSupply.mul(2));
        }

        return (_baseTokenId <= _maxNFTSupply.mul(3)) ? _baseTokenId : 0;
    }

   /**
     * @dev Returns available NFTs for random minting
     * Since each NFT has his own max supply, it's possible than some NFTs get out of stock
     * before another, in an effort to evict long loops finding random NFTs ID for mint, we use randomness 
     * to find the firs available slot in teh NFTs availability map
     */

    function _getAvailableNFTs() private view returns ( uint16 ) {
        uint16 _totalAvailableSlots = 0;
        for (uint16 i=0; i<_maxNFTSupply; i++) {
            if (_nftAvailabilityMap[i] == true) {
                _totalAvailableSlots++;
            }
        }

        return _totalAvailableSlots;
    }

    function _getNFtoMint() private returns (uint256) {
        require(!_paused,"P"); 
        uint256 _nftId = 0;
        uint16 _NFTStock = _getAvailableNFTs();
        uint _rndIndex;
        uint256 _nftIndex = 0;
        if (_NFTStock > 0) {
            randNonce++; 
            _rndIndex = (uint(keccak256(abi.encodePacked(block.timestamp,blockhash(block.number),randNonce))).mod(_NFTStock)) + 1;
            for (uint i=0;i < _maxNFTSupply; i++) {
                if (_nftAvailabilityMap[i] == true) {
                    _nftId++;
                    if (_nftId == _rndIndex) {
                        _nftIndex = i+1;
                        break;
                    }
                }
            }
        }
        return _nftIndex;
    }

    function toUint256(bytes memory _bytes) internal pure returns (uint256 value) {

        assembly {
        value := mload(add(_bytes, 0x20))
        }
    }

    function _getTokenTier( uint256 tokenId) private pure returns (uint256) {
        require(tokenId <= _maxNFTSupply.mul(3));        
        uint256 _ret = 0;
        if (tokenId <= _maxNFTSupply) {
            _ret = 1;
        } else {
            _ret = tokenId <= _maxNFTSupply.mul(2) ? 2 : 3;
        }

        return _ret;
    }
}