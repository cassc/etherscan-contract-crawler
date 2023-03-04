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

contract CybercityRolePromotion is OmniumStakeableERC1155Upgradeable {
    using SafeMathUpgradeable for uint256;
    using StringsUpgradeable for uint256;    

    // Constants

    address private constant _withdrawWallet = address(0xb6B35D3263832338f883Be9373d18f7809F21e3b);
    string private constant  _metaDataUri = "ipfs://QmW8fa34fRU97ZLBsWprFQezKNvbBXZpkHLzp8rzsicyr7/";
    string private constant _contractURI = "ipfs://QmUTco9TJkVw8QvHQ2r8R3fShh1GNXwC85N5Kp5egKB2Ze";    
    
    // State Variables

    string public name;
    string public symbol;
    bool private _paused;
    address private _proxyRegistryAddress; // OpenSea proxy registry address
    mapping(uint256 => uint256) private _mintPacks;
    address private _cybercityContractAddress;
    address private _omniumTokenAddress;
    address private _cybercityRolesAddress;    
    uint256 private _supply;
    uint256[49] private __gap;
    
    function initialize( address __proxyRegistryAddress ) initializer public {
        __OmniumStakeableERC1155Upgradeable_init(_metaDataUri);        
        _paused = false;
        name = "Cyber City Role Promotion Ticket";
        symbol = "CCRP";
        _proxyRegistryAddress = __proxyRegistryAddress;
        _supply = 0;
        _mint(_msgSender(), 1, 1, "");        
    }


    /**
     * @dev Pauses / Resume contract operation.
     *
     */

    function Pause() public onlyOwner {
        _paused = !_paused;
    }

    /**
     * @dev Mints NFT Tokens with omiun
     */
     
    function mintPack( uint256 _amount ) public  {
        require(!_paused,"Paused");    
        require( _amount > 0,"invalid amount");
        require( _mintPacks[_amount] > 0,"Invalid pack");        

        address _to = msg.sender;
        uint256 _mintPrice = _mintPacks[_amount];        
        uint256 residentBalance = IERC1155Upgradeable(_cybercityContractAddress).balanceOf(_to, 2);
        require(residentBalance > 0, "No resident");
        uint256 _allowance = IERC20Upgradeable(_omniumTokenAddress).allowance(_to, address(this));
        require (_allowance >= _mintPrice,"Need allowance");

        try  IERC20Upgradeable(_omniumTokenAddress).transferFrom(_to, address(this),_mintPrice) {
            // mints NFT
            _supply = _supply.add(_amount);
            _mint(_to, 1, _amount, "");
        } catch Error(string memory reason) {
            revert(reason);
        } catch {
            revert("Error during upgrade");
        }                            
    }


    function freeMint( uint256 _amount, address _to ) public onlyOwner  {
        require(!_paused,"Paused");    
        require( _amount > 0,"invalid amount");
        // mints NFT
        _supply = _supply.add(_amount);
        _mint(_to, 1, _amount, "");
    }

    /**
        * @dev Empty receive function.
        *
        * Requirements:
        *   
        * - Cannot send plain ether to this contract
    */

    receive () external payable { revert(); }

    function setMintPack(uint256 _qty, uint256 _value ) public onlyOwner {
        require(!_paused,"Paused");            
        require(_qty > 0 && _value > 0,'Invalid values');
        _mintPacks[_qty] = _value;
    }

    function getMintPack( uint256 _qty) public view returns ( uint256 ) {
        return _mintPacks[_qty];
    }

    function setCybercityContractAddress( address _contractAddress ) public onlyOwner {
        require(!_paused,"Paused");      
        _cybercityContractAddress = address(_contractAddress);
    }

    function getCybercityContractAddress() public view onlyOwner returns (address) {
        return _cybercityContractAddress;
    }

    function setOmniumTokenContractAddress( address _contractAddress ) public onlyOwner {
        require(!_paused,"Paused");      
        _omniumTokenAddress = address(_contractAddress);
    }

    function getOmniumTokenContractAddress() public view onlyOwner returns ( address ){
        return _omniumTokenAddress;
    }

    function setRolesContractAddress( address _contractAddress ) public onlyOwner {
        require(!_paused,"Paused");      
        _cybercityRolesAddress = address(_contractAddress);
    }

    function getRolesContractAddress() public view onlyOwner returns ( address ){
        return _cybercityRolesAddress;
    }

    function supply() public view returns (uint256) {
        return _supply;
    }

    /**
     * @dev uri: Returns metada file URI for the selected NFT
     *   
     */    

    function uri(uint id) public view virtual override returns (string memory) {
        require(!_paused,"Paused");
        return string(abi.encodePacked(_metaDataUri, StringsUpgradeable.toString(id)));
    }    
    
    /**
     * @dev baseTokenURI: Returns contract base URI for metadata files
     *   
     */    

    function baseTokenURI() external view  returns (string memory) {
        require(!_paused,"Paused");        
        return _metaDataUri;
    }  

    function ContractURI() public view virtual returns (string memory) {
        return string(abi.encodePacked(_contractURI));
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
            if (address(proxyRegistry.proxies(account)) == operator || operator == _cybercityRolesAddress ) {
                return true;
            }          

            return super.isApprovedForAll(account,operator);
    }

    /**
     * @dev withDrawOT: withdraws omnium token from contract to withdraw wallet.
     *   
     * - Contract not paused.
     * - Only contract owner can whitelist wallets
     * - Uses allowance mechanism to contract owner account, so backend should do transferFrom after executing withDrawOT method
     */

    function withdrawOT( uint256 __amount) external onlyOwner {
        require(! _paused );
        uint256 _OTBalance = IERC20Upgradeable(_omniumTokenAddress).balanceOf(address(this));
        require(__amount <= _OTBalance,"No balance");
        IERC20Upgradeable(_omniumTokenAddress).transfer(_withdrawWallet, __amount);
    }

    /**
     * @dev _beforeTokenTransfer: Modified _safeTransfer.
     *
     */        

    function _beforeTokenTransfer(
        address,
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory 
    ) internal virtual override {
        require(!_paused,"Paused");    
    }    

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory 
    ) public virtual override returns (bytes4) {
        require(!_paused,"Paused");    
        return this.onERC1155Received.selector;
    }

}