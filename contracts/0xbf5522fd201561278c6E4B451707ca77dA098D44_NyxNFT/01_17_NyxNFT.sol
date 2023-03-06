// SPDX-License-Identifier: MIT

// @title NyxNFT for Nyx DAO
// @author TheV

//  ________       ___    ___ ___    ___      ________  ________  ________     
// |\   ___  \    |\  \  /  /|\  \  /  /|    |\   ___ \|\   __  \|\   __  \    
// \ \  \\ \  \   \ \  \/  / | \  \/  / /    \ \  \_|\ \ \  \|\  \ \  \|\  \   
//  \ \  \\ \  \   \ \    / / \ \    / /      \ \  \ \\ \ \   __  \ \  \\\  \  
//   \ \  \\ \  \   \/  /  /   /     \/        \ \  \_\\ \ \  \ \  \ \  \\\  \ 
//    \ \__\\ \__\__/  / /    /  /\   \         \ \_______\ \__\ \__\ \_______\
//     \|__| \|__|\___/ /    /__/ /\ __\         \|_______|\|__|\|__|\|_______|
//               \|___|/     |__|/ \|__|                       

pragma solidity >=0.7.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Checkpoints.sol";
import "operator_filter/OperatorFilterer.sol";
import {CANONICAL_CORI_SUBSCRIPTION} from "operator_filter/lib/Constants.sol";


contract NyxNFT is ERC1155Supply, Ownable, OperatorFilterer
{
    //////////////////////////////////////////////////////////////////
    // Attributes
    //////////////////////////////////////////////////////////////////

    using Checkpoints for Checkpoints.History;

    string public constant name = "Nyx DAO NFT";
    string public constant symbol = "NYX";
    uint256 public constant MAX_SUPPLY = 10000;
    uint256 public constant BASE_VOTING_POWER = 10000;
    uint256 public constant BASE_REDEEM_RATIO = 10000;
    uint256 public max_holding = 2;
    uint256 public max_holding_whitelist = 20;
    
    address public vault_address;
    address public main_address;
    address public signer_address;
    bool public isMinting = false;
    uint256 public currentTokenId = 0;
    mapping(uint256 => string) public tokenIdURI;
    mapping(uint256 => uint256) public wavePrice;
    mapping(uint256 => uint256) public waveCurrentSupply;
    mapping(uint256 => uint256) public waveMaxSupply;
    mapping(uint256 => uint256) public waveMintableSupply;
    mapping(uint256 => uint256) public waveWithdrawl;
    mapping(uint256 => uint256) public waveTokenId;
    mapping(uint256 => uint256) public waveBalance;
    mapping(uint256 => uint256) public waveVotingPower;
    mapping(uint256 => uint256) public waveRedeemPower;
    mapping(uint256 => uint256) public waveTeamMintPct;
    mapping(uint256 => uint256) public waveTeamFeePct;
    mapping(uint256 => mapping(address => uint256)) public waveMints;
    mapping(uint256 => bool) public waveIsRunning;
    mapping(address => bool) public approved;

    mapping(uint256 => mapping(address => Checkpoints.History)) private balanceHistory;
    mapping(uint256 => Checkpoints.History) private supplyHistory;

    //////////////////////////////////////////////////////////////////
    // Modifiers
    //////////////////////////////////////////////////////////////////

    /**
    * * @notice Modifer for functions that can be only be called by approved contracts
    */
    modifier onlyApproved
    {
        require(approved[msg.sender] || msg.sender == owner(), "not approved");
        _;
    }

    //////////////////////////////////////////////////////////////////
    // Constructor
    //////////////////////////////////////////////////////////////////

    /**
    * @notice Construuctor intialize the various needed addresses, metadata url, and first token ID informations
        It also calls the parent contract constructors : ERC1155 (for metadata URL) and OperatorFilterer 
        (for the registry address to copy the filtered operators from)
    */
    constructor(address _vault_address, address _main_address, address _signer_address,
        string memory metadata_url, uint256 _wavePrice, uint256 _waveMintableSupply,
        uint256 teamMintPct, uint256 teamFeePct)
    ERC1155(metadata_url)
    OperatorFilterer(CANONICAL_CORI_SUBSCRIPTION, false)
    {
        vault_address = _vault_address;
        main_address = _main_address;
        signer_address = _signer_address;

        tokenIdURI[currentTokenId] = metadata_url;
        
        // Setting up first wave
        initWave(currentTokenId, _wavePrice, _waveMintableSupply, BASE_VOTING_POWER, BASE_REDEEM_RATIO, teamMintPct, teamFeePct);
    }

    //////////////////////////////////////////////////////////////////
    // Overrided Functions
    //////////////////////////////////////////////////////////////////

    /**
    * @notice Overriding ERC1155.setApprovalForAll to integrate OperatorFilter modifier 
        onlyAllowedOperatorApproval
    */
    function setApprovalForAll(address operator, bool isApproved)
    public override
    onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, isApproved);
    }

    /**
    * @notice Overriding ERC1155.safeBatchTransferFrom to update balanceHistory and integrate
        OperatorFilter modifier onlyAllowedOperatorApproval
    */
    function safeBatchTransferFrom(address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        public
        override
        onlyAllowedOperator(from)
    {
        for (uint256 idx = 0; idx < ids.length; idx++)
        {
            uint256 id = ids[idx];
            balanceHistory[id][from].push(balanceOf(from, id) - amounts[idx]);
            balanceHistory[id][to].push(balanceOf(to, id) + amounts[idx]);
        }
        super.safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /**
    * @notice Overriding ERC1155.safeTransferFrom to update balanceHistory and integrate
        OperatorFilter modifier onlyAllowedOperatorApproval
    */
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes memory data)
        public
        override
        onlyAllowedOperator(from)
    {
        balanceHistory[id][from].push(balanceOf(from, id) - amount);
        balanceHistory[id][to].push(balanceOf(to, id) + amount);
        super.safeTransferFrom(from, to, id, amount, data);
    }

    /**
    * @notice Overriding ERC1155.supportsInterface as advised for OperatorFilterRegistry 
        smart contract
    */
    function supportsInterface(bytes4 interfaceId)
        public view virtual
        override
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    //////////////////////////////////////////////////////////////////
    // OperatorFilter functions
    //////////////////////////////////////////////////////////////////

    /**
     * @notice Registers self with the operator filter registry
    */
    function register()
        external onlyOwner
    {
        OPERATOR_FILTER_REGISTRY.register(address(this));
    }

    /**
     * @notice Unregisters self from the operator filter registry
    */
    function unregister()
        external onlyOwner
    {
        OPERATOR_FILTER_REGISTRY.unregister(address(this));
    }

    /**
     * @notice Registers self with the operator filter registry, and susbscribe to 
        the filtered operators of the given subscription 
    */
    function registerAndSubscribe(address subscription)
        external onlyOwner
    {
        OPERATOR_FILTER_REGISTRY.registerAndSubscribe(address(this), subscription);
    }

    /**
     * @notice Registers self with the operator filter registry, and copy
        the filtered operators of the given subscription 
    */
    function registerAndCopyEntries(address registrantToCopy)
        external onlyOwner
    {
        OPERATOR_FILTER_REGISTRY.registerAndCopyEntries(address(this), registrantToCopy);
    }

    /**
     * @notice Update given operator address to filtered/unfiltered state
    */
    function updateOperator(address operator, bool filtered)
        external onlyOwner
    {
        OPERATOR_FILTER_REGISTRY.updateOperator(address(this), operator, filtered);
    }

    /**
     * @notice Update given operator smart contract code hash to filtered/unfiltered state
    */
    function updateCodeHash(bytes32 codeHash, bool filtered)
        external onlyOwner
    {
        OPERATOR_FILTER_REGISTRY.updateCodeHash(address(this), codeHash, filtered);
    }

    /**
     * @notice Batch function for updateOperator
    */
    function updateOperators(address[] calldata operators, bool filtered)
        external onlyOwner
    {
        OPERATOR_FILTER_REGISTRY.updateOperators(address(this), operators, filtered);
    }

    /**
     * @notice Batch function for updateCodeHash
    */
    function updateCodeHashes(bytes32[] calldata codeHashes, bool filtered)
        external onlyOwner
    {
        OPERATOR_FILTER_REGISTRY.updateCodeHashes(address(this), codeHashes, filtered);
    }

    /**
     * @notice Check if a given operator address is currently filtered
    */
    function isOperatorAllowed(address operator)
        external view
        returns (bool)
    {
        return OPERATOR_FILTER_REGISTRY.isOperatorAllowed(address(this), operator);
    }

    /**
     * @notice Subscribe to OperatorFilterRegistry contract : activate modifiers
    */
    function subscribe(address subscription)
        external onlyOwner
    {
        return OPERATOR_FILTER_REGISTRY.subscribe(address(this), subscription);
    }

    /**
     * @notice Unsubscribe to OperatorFilterRegistry contract : deactivate modifiers
    */
    function unsubscribe(bool copyExistingEntries)
        external onlyOwner
    {
        return OPERATOR_FILTER_REGISTRY.unsubscribe(address(this), copyExistingEntries);
    }

    /**
     * @notice Copy filtered operators of a given OperatorFilterRegistry
        registered smart contract
    */
    function copyEntriesOf(address registrantToCopy)
        external onlyOwner
    {
        return OPERATOR_FILTER_REGISTRY.copyEntriesOf(address(this), registrantToCopy);
    }

    /**
     * @notice Returns the list of filtered operators
    */
    function filteredOperators()
        external
        returns (address[] memory)
    {
        return OPERATOR_FILTER_REGISTRY.filteredOperators(address(this));
    }

    //////////////////////////////////////////////////////////////////
    // Balance of functions
    //////////////////////////////////////////////////////////////////

    /**
    * @notice Get current NyxDao NFT's balance of an address for all token IDs
    */
    function balanceOfLatest(address from)
        public view
        returns (uint256)
    {
        uint256 balance = 0;
        for (uint256 tokenId = 0; tokenId <= currentTokenId; tokenId++)
        {
            balance += balanceHistory[tokenId][from].latest();
        }
        return balance;
    }

    /**
    * @notice Get current NyxDao NFT's balance of an address for a given token ID
    */
    function balanceOfLatest(address from, uint256 id)
        public view
        returns (uint256)
    {
        return balanceHistory[id][from].latest();
    }

    /**
    * @notice Get NyxDao NFT's balance of an address at a given block number, for all token IDs
    */
    function balanceOfAtBlock(address from, uint256 _blockNumber)
        public view
        returns (uint256)
    {
        uint256 balance = 0;
        for (uint256 tokenId = 0; tokenId <= currentTokenId; tokenId++)
        {
            balance += balanceHistory[tokenId][from].getAtBlock(_blockNumber);
        }
        return balance;
    }

    /**
    * @notice Get NyxDao NFT's balance of an address at a given block number, for a given token ID
    */
    function balanceOfAtBlock(address from, uint256 id, uint256 _blockNumber)
        public view
        returns (uint256)
    {
        return balanceHistory[id][from].getAtBlock(_blockNumber);
    }

    /**
    * @notice Get NyxDao NFT's balance of an address around a given block number, for all token IDs
    */
    function balanceOfAtProbablyRecentBlock(address from, uint256 _blockNumber)
        public view
        returns (uint256)
    {
        uint256 balance = 0;
        for (uint256 tokenId = 0; tokenId <= currentTokenId; tokenId++)
        {
            balance += balanceHistory[tokenId][from].getAtProbablyRecentBlock(_blockNumber);
        }
        return balance;
    }

    /**
    * @notice Get NyxDao NFT's balance of an address around a given block number, for given token ID
    */
    function balanceOfAtProbablyRecentBlock(address from, uint256 id, uint256 _blockNumber)
        public view
        returns (uint256)
    {
        return balanceHistory[id][from].getAtProbablyRecentBlock(_blockNumber);
    }

    //////////////////////////////////////////////////////////////////
    // Attribute getters
    //////////////////////////////////////////////////////////////////

    /**
    * @notice Get ETH balance of a given address
    */
    function getETHBalance(address addr)
        public view
        returns (uint)
    {
        return addr.balance;
    }

    /**
    * @notice Get ETH balance of Nyx DAO NFT's contract
    */
    function getContractBalance()
        public view
        returns (uint256)
    {
        return address(this).balance;
    }

    /**
    * @notice Get current supply of a given token ID
    */
    function getCurrentSupply(uint256 tokenId)
        public view
        returns (uint256)
    {
        return totalSupply(tokenId);
    }

    /**
    * @notice Get total current supply for all token IDs
    */
    function getTotalCurrentSupply()
        public view
        returns (uint256)
    {
        uint256 totalCurrentSupply = 0;
        for (uint256 tid = 0; tid <= currentTokenId; tid++)
        {
            totalCurrentSupply += totalSupply(tid);
        }
        return totalCurrentSupply;
    }

    /**
    * @notice Get metadata URI for a given token ID
    */
    function uri(uint256 tokenId)
        public view
        override
        returns (string memory)
    {
        return tokenIdURI[tokenId];
    }

    //////////////////////////////////////////////////////////////////
    // Attribute setters
    //////////////////////////////////////////////////////////////////

    /**
    * @notice If public mint is closed, open it. Otherwise, close public mint.
    */
    function toggleMintingState()
        public onlyApproved
    {
        if (!isMinting)
        {
            isMinting = true;
        }
        else
        {
            isMinting = false;
        }
    }

    /**
    * @notice Set the address of NYX's Vault
    */
    function setVaultAddress(address addr)
        external onlyOwner
    {
        vault_address = addr;
    }

    /**
    * @notice Set the address of NYX's team
    */
    function setMainAddress(address addr)
        external onlyOwner
    {
        main_address = addr;
    }

    /**
    * @notice Set the address of the signer
    */
    function setSignerAddress(address addr)
        external onlyOwner
    {
        signer_address = addr;
    }

    /**
    * @notice Set the metadata URI for a given token ID
    */
    function setTokenIdURI(uint256 tokenId, string memory _uri)
        public onlyOwner
    {
        tokenIdURI[tokenId] = _uri;
    }

    /**
    * @notice Set the max mintable for public mint
    */
    function setMaxHolding(uint256 _max_holding)
        public onlyOwner
    {
        max_holding = _max_holding;
    }
    
    /**
    * @notice Set the max mint for whitelist mint
    */
    function setMaxHoldingWhitelist(uint256 _max_holding_whitelist)
        public onlyOwner
    {
        max_holding_whitelist = _max_holding_whitelist;
    }

    /**
    * @notice If the given address is an approved caller, remove its role.
        Otherwise, add it to the approved callers
    */
    function toggleApproved(address addr)
        external onlyOwner
    {
        if (approved[addr])
        {
            approved[addr] = false;
        }
        else
        {
            approved[addr] = true;
        }
    }

    //////////////////////////////////////////////////////////////////
    // Wave functions
    //////////////////////////////////////////////////////////////////

    /**
    * @notice Get total supply given a supply and a token ID
        (and hence the team mint percentage associated with it)
        The difference of the output and the given supply is the team supply
    */
    function getMaxSupplyFromMintable(uint256 supply, uint256 tokenId)
        public view
        returns (uint256)
    {
        if (waveTeamMintPct[tokenId] > 0)
        {
            return supply + supply / waveTeamMintPct[tokenId];
        }
        else
        {
            return supply;
        }
        
    }

    /**
    * @notice Private helper function to initialize a new token ID
    */
    function initWave(uint256 wave, uint256 _wavePrice, uint256 _waveMintableSupply, uint256 votingPower, uint256 redeemPower,
        uint256 teamMintPct, uint256 teamFeePct)
        private
    {
        wavePrice[wave] = _wavePrice;
        waveCurrentSupply[wave] = 0;
        waveWithdrawl[wave] = 0;
        waveTokenId[wave] = currentTokenId;
        waveVotingPower[wave] = votingPower;
        waveRedeemPower[wave] = redeemPower;
        waveTeamMintPct[wave] = teamMintPct;
        waveTeamFeePct[wave] = teamFeePct;
        waveIsRunning[wave] = true;

        require(getMaxSupplyFromMintable(_waveMintableSupply, wave) <= MAX_SUPPLY, "Mintable supply is too high");

        waveMintableSupply[wave] = _waveMintableSupply;
        waveMaxSupply[wave] = getMaxSupplyFromMintable(_waveMintableSupply, wave);
    }

    /**
    * @notice Definitely close the mint of a given token ID
    */
    function endWave(uint256 wave)
        public onlyApproved
    {
        require(waveIsRunning[wave], "Wave has already ended");
        require(currentTokenId == wave, "Wave has already ended");
        require(waveCurrentSupply[wave] >= 0, "Wave have no mint yet");
        
        uint256 mint_amount = getMaxSupplyFromMintable(waveCurrentSupply[wave], wave) - waveCurrentSupply[wave];
        if (mint_amount > 0)
        {
            _mintNFT(mint_amount, main_address);
        }
        waveIsRunning[wave] = false;
        isMinting = false;
    }

    /**
    * @notice External function to initialize a new token ID
    */
    function createNewTokenId(uint256 _wavePrice, uint256 _waveMintableSupply, uint256 votingPower, uint256 redeemPower,
        uint256 teamMintPct, uint256 teamFeePct)
        external onlyApproved
    {
        require(_waveMintableSupply > 0, "Can't start a new wave with a max supply <= 0");
        if (waveIsRunning[currentTokenId])
        {
            endWave(currentTokenId);
        }
        currentTokenId += 1;
        initWave(currentTokenId, _wavePrice, _waveMintableSupply, votingPower, redeemPower, teamMintPct, teamFeePct);
        isMinting = false;
    }

    //////////////////////////////////////////////////////////////////
    // Mint Functions
    //////////////////////////////////////////////////////////////////

    /**
    * @notice Internal helper function to mint a Nyx DAO's NFT
    */
    function _mintNFT(uint256 nMint, address recipient)
        internal
    {
        // require(tx.origin == msg.sender, "No bots allowed");
        require(totalSupply(currentTokenId) + nMint <= MAX_SUPPLY, "No more NFT to mint");
        require(waveIsRunning[currentTokenId], "Wave has ended");
        waveBalance[currentTokenId] += msg.value;
        waveCurrentSupply[currentTokenId] += nMint;
        waveMints[currentTokenId][recipient] += nMint;
        balanceHistory[currentTokenId][recipient].push(balanceOf(recipient, currentTokenId) + nMint);
        _mint(recipient, currentTokenId, nMint, "");
    }
 
    /**
    * @notice Mint logic for public mint
    */
    function mintNFT(uint256 nMint, address recipient)
        public payable
    {
        require(isMinting, "Mint period have not started yet");
        require(waveMints[currentTokenId][recipient] + nMint <= max_holding, "Max minted NFTs is reached");
        require(msg.value >= wavePrice[currentTokenId] * nMint, "Not enough ETH to mint");
        require(waveCurrentSupply[currentTokenId] + nMint <= waveMintableSupply[currentTokenId], "No more NFT to mint for this wave");
        return _mintNFT(nMint, recipient);
    }

    /**
    * @notice Mint logic for whitelist mint
    */
    function mintNFTWithSignature(uint256 nMint, address recipient, uint8 v, bytes32 r, bytes32 s, string calldata nonce, uint256 deadline)
        public payable
    {
        require(isWhitelist(v, r, s, nonce, deadline), "You are not Whitelisted");
        require(waveMints[currentTokenId][recipient] + nMint <= max_holding_whitelist, "Max minted NFTs is reached");
        require(msg.value >= wavePrice[currentTokenId] * nMint, "Not enough ETH to mint");
        require(waveCurrentSupply[currentTokenId] + nMint <= waveMintableSupply[currentTokenId], "No more NFT to mint for this wave");
        return _mintNFT(nMint, recipient);
    }

    /**
    * @notice Mint logic for free mint
    */
    function giveaway(uint256 nMint, address recipient)
        public onlyApproved
    {
        require(waveCurrentSupply[currentTokenId] + nMint <= waveMintableSupply[currentTokenId], "No more NFT to mint for this wave");
        return _mintNFT(nMint, recipient);
    }

    /**
    * @notice Burn logic to burn your NFT.
        Should only be called by Nyx DAO's contract when calling the redeem function
    */
    function burnNFT(address fromAddress, uint256 amount, uint256 tokenId)
        public
    {
        require(msg.sender == fromAddress, "Not allowed to burn");
        require(balanceOf(fromAddress, tokenId) >= amount, "Not enough balance to burn this amount");
        waveCurrentSupply[tokenId] -= amount;
        balanceHistory[tokenId][fromAddress].push(balanceOf(fromAddress, tokenId) - amount);
        _burn(fromAddress, tokenId, amount);
    }

    //////////////////////////////////////////////////////////////////
    // Verify-role functions
    //////////////////////////////////////////////////////////////////

    /**
    * @notice Check the given address is holder of a given token ID
    */
    function isHolder(address addr, uint256 tokenId)
        public view
        returns (bool)
    {
        return balanceOf(addr, tokenId) > 0;
    }

    /**
    * @notice Check the given address is holder of any token IDs
    */
    function isHolder(address addr)
        public view
        returns (bool)
    {
        for (uint256 tid = 0; tid <= currentTokenId; tid++)
        {
            if (balanceOf(addr, tid) > 0)
            {
                return true;
            }
        }
        return false;
    }

    /**
    * @notice Check the given signature params against signer address
        Used to verify signature validity
    */
    function isWhitelist(uint8 v, bytes32 r, bytes32 s, string calldata nonce, uint256 deadline)
        internal view
        returns (bool)
    {
        require(block.timestamp <= deadline, "Signing too late");
        require(
            recoverSigner(msg.sender, v, r, s, nonce, deadline) == signer_address,
            "Wrong signer"
        );
        return true;
    }

    /**
    * @notice Retrieve the signer address induced by the given signature params
    */
    function recoverSigner(address addr, uint8 v, bytes32 r, bytes32 s, string memory nonce, uint256 deadline)
        internal pure
        returns (address)
    {
        return ecrecover(sha256(abi.encodePacked(addr, nonce, deadline)), v, r, s);
    }

    //////////////////////////////////////////////////////////////////
    // Withdraw functions
    //////////////////////////////////////////////////////////////////

    /**
    * @notice Emergency withdraw function to send all smart contract funds to NYX's Vault
    */
    function withdraw()
        external onlyOwner
    {
        uint256 amount = address(this).balance;
        for (uint256 wave = 0; wave <= currentTokenId; wave++)
        {
            waveBalance[wave] = 0;
        }
        // Use call instead of send so that no gas limitation 
        // bool success = payable(vault_address).send(amount);
        (bool success, ) = payable(vault_address).call{value: amount}("");
        require(success, "Failed to withdraw");
    }
    
    /**
    * @notice Helper function to get the amount to withdraw for the team, and for the vault, given a token ID
    */
    function getAmountToWithdraw(uint256 wave)
        public view
        returns (uint256, uint256)
    {
        uint256 allowedWithdraw;
        uint256 restWithdraw;
        if (waveBalance[wave] > 0)
        {
            allowedWithdraw = waveBalance[wave] * waveTeamFeePct[wave]/100;
            restWithdraw = waveBalance[wave] - allowedWithdraw;
        }
        else
        {
            allowedWithdraw = 0;
            restWithdraw = 0;
        }

        return (allowedWithdraw, restWithdraw);
    }

    /**
    * @notice Main withdraw function,
        that will withdraw the percentage fee of a given token id mint funds
        to the team address, and the remaining balance to NYX's Vault
    */
    function withdrawOnce(uint256 wave)
        external onlyOwner
    {
        (uint256 allowedWithdraw, uint256 restWithdraw) = getAmountToWithdraw(wave);

        waveWithdrawl[wave] = allowedWithdraw;
        waveBalance[wave] = 0;

        require(allowedWithdraw != 0 || restWithdraw != 0, "Nothing to withdraw");

        bool succes_nyx = true;
        if (allowedWithdraw > 0)
        {
            // succes_nyx = payable(main_address).send(allowedWithdraw);
            (succes_nyx, ) = payable(main_address).call{value: allowedWithdraw}("");
        }
        bool succes_vault = true;
        if (restWithdraw > 0)
        {
            // succes_vault = payable(vault_address).send(restWithdraw);
            (succes_vault, ) = payable(vault_address).call{value: restWithdraw}("");
        }
        require(succes_nyx && succes_vault, "Failed to withdraw");
    }

    //////////////////////////////////////////////////////////////////
    // Receive & fallback
    //////////////////////////////////////////////////////////////////

    receive()
        external payable
    {
    }

    fallback()
        external
    {
    }
}