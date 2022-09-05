// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './jupiter/JupiterNFT.sol';
import './jupiter/MintOptions.sol';
import './jupiter/MintPayable.sol';
import './jupiter/AllowList.sol';
import './jupiter/JupiterApproved.sol';
import './jupiter/AddressMintCap.sol';

import './IBarrelX.sol';

/**
 * @dev BARRELX ERC721 token
 * is JupiterNFT: tradeable ERC721 with Jupiter operators, burnable and pausable.
 * MintOptions: allows BARRELX to define different minting options per barrel type and mashbill
 * MintPayable: allows Jupiter to withdrawn payments
 * AllowList: allows BARRELX to define and activate a preMint phase with an allow list.
 * JupiterApproved: allows Jupiter to claim non redeemed bottled barrels.
 * AddresMintCap: allows BARRELX to limit the amount of barrels to mint.
 */
contract BarrelX is JupiterNFT, MintOptions,  MintPayable, IBarrelX, AllowList, JupiterApproved, AddressMintCap {
    event MintBarrel(address indexed to, uint8 option, uint256 indexed tokenId);
    
    constructor(
        // opensea proxy to override isApproved for all and reduce trading transactions.
		address proxyRegistryAddress,
        // BARRELX token Name
		string memory name,
        // BARRELX token symbol
		string memory symbol,
        // Metadata uri        
		string memory baseTokenURI,
        // Jupiter operators
        address[] memory operators
	) JupiterNFT(proxyRegistryAddress, name, symbol, baseTokenURI, operators){}

    
    /**
     * @dev internal function to mint BarrelX token
     * @param _to new to be owner 
     * @param _option to be minted
     */
    function _barrelXMint (address _to, uint8 _option) internal {
        // we increase the tokenId
        currentTokenId++;		
        
        // the amount of minted tokens for this address
        _addressCap[_to]++;

        // we reduce the amount of items for this option
        options[_option].remaining--;
        
        _safeMint(_to, currentTokenId);
            
        emit MintBarrel(_to, _option, currentTokenId);
    }

    /**
     * @dev BARRELX mint function.
     * @param _option a valid MintOptions option
     * @param _amount number of tokens to mint for the caller
    */
    function mintBatchBarrel (uint8 _option, uint256 _amount) payable external override{
        // we only allow between 1 and 10 tokens per transaction
        require(_amount > 0, 'Invalid amount');
        require(_amount < 11, 'Invalid amount');

        // has to be a valid option
        require(options[_option].enabled, 'Invalid option');
        // and option must not be exhausted
        require(options[_option].remaining > _amount, 'No barrels remaining for option');
        // we verify payment is correct for the selected option
        require(msg.value >= options[_option].price * _amount, 'Not enough ETH sent, check price!');
        
        // if we are enforcing allow list, sender must be allowed to mint.
        if (isAllowListActive()){
            require(isAllowed[msg.sender], 'Sender not in allow list.');
        }

        // we don't allowe more that 10 barrels per address
        require((_addressCap[msg.sender] + _amount) < 11, 'Max barrels per wallet exceeded');
        
        // we are ready to mint
        for (uint8 i=0; i < _amount; i++){
            _barrelXMint(msg.sender, _option);
        }
    }

    /**
     * @dev crossMint minting option.
     * Similar to mintBatchBarrel but only if sender is CrossMint and specifies the owner.
     * @param _to the owner of the token to be minted.
     * @param _option a valid option to mint
     * @param _amount the number of tokens to mint
     */
    function crossmintBarrel(address _to, uint8 _option, uint256 _amount) payable external{
        // we only allow between 1 and 10 tokens per transaction
        require(_amount > 0, 'Invalid amount');
        require(_amount < 11, 'Invalid amount');

        // has to be a valid option
        require(options[_option].enabled, 'Invalid option');
        // and option must not be exhausted
        require(options[_option].remaining > _amount, 'No barrels remaining for option');
        
        // we verify payment is correct for the selected option
        require(msg.value >= options[_option].price * _amount, 'Not enough ETH sent, check price!');

        // has to be called by Crossmint contract
        require(msg.sender == 0xdAb1a1854214684acE522439684a145E62505233, "This function is for Crossmint only.");

        // we don't allowe more that 10 barrels per address
        require((_addressCap[_to] + _amount) < 11, 'Max barrels per wallet exceeded');
        
        // we are ready to mint
        for (uint8 i=0; i < _amount; i++){
            _barrelXMint(_to, _option);
        }
    }

    /**
     * @dev admin only function to overpass restrictions and mint
     */
    function adminMintBatchBarrel (uint8 _option, uint256 _amount) external override {
        require(operators[msg.sender], "only operators");
        require(options[_option].enabled, 'Invalid option');
        
        for (uint8 i=0; i < _amount; i++){
            _barrelXMint(msg.sender, _option);
        }
    }

    function isApprovedForAll(address owner, address operator)
        override(JupiterNFT, JupiterApproved)
        public
        virtual
        view
        returns (bool)
    {
        return JupiterApproved.isApprovedForAll(owner, operator);
    }
}