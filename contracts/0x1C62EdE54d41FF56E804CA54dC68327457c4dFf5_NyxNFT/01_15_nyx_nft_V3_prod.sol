//Contract based on https://docs.openzeppelin.com/contracts/3.x/erc721
// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

import "../utils_smart_contract/verify_signature_contract.sol" as VerifySign;


//  ________       ___    ___ ___    ___      ________  ________  ________  ___  _________  ________  ___               ________  ___       ___  ___  ________
// |\   ___  \    |\  \  /  /|\  \  /  /|    |\   ____\|\   __  \|\   __  \|\  \|\___   ___\\   __  \|\  \             |\   ____\|\  \     |\  \|\  \|\   __  \
// \ \  \\ \  \   \ \  \/  / | \  \/  / /    \ \  \___|\ \  \|\  \ \  \|\  \ \  \|___ \  \_\ \  \|\  \ \  \            \ \  \___|\ \  \    \ \  \\\  \ \  \|\ /_
//  \ \  \\ \  \   \ \    / / \ \    / /      \ \  \    \ \   __  \ \   ____\ \  \   \ \  \ \ \   __  \ \  \            \ \  \    \ \  \    \ \  \\\  \ \   __  \
//   \ \  \\ \  \   \/  /  /   /     \/        \ \  \____\ \  \ \  \ \  \___|\ \  \   \ \  \ \ \  \ \  \ \  \____        \ \  \____\ \  \____\ \  \\\  \ \  \|\  \
//    \ \__\\ \__\__/  / /    /  /\   \         \ \_______\ \__\ \__\ \__\    \ \__\   \ \__\ \ \__\ \__\ \_______\       \ \_______\ \_______\ \_______\ \_______\
//     \|__| \|__|\___/ /    /__/ /\ __\         \|_______|\|__|\|__|\|__|     \|__|    \|__|  \|__|\|__|\|_______|        \|_______|\|_______|\|_______|\|_______|
//               \|___|/     |__|/ \|__|


/// @title ERC115 for Nyx Capital Club
/// @author @TheV

contract NyxNFT is ERC1155Supply, Ownable
{
    string public name = "Nyx Capital Club";
    string public symbol = "NYX";
    uint256 public constant MAX_SUPPLY = 10000;
    uint256 public nyx_mint_fee_pct = 10;
    uint256 public nyx_premint_pct = 10;
    uint256 public max_holding = 2;
    uint256 public max_holding_whitelist = 20;
    
    address public vault_address;
    address public main_address;
    address public signer_address;
    mapping(address => bool) public teamAddressesDict;
    bool public _isMinting = false;
    mapping(address => uint) private balance;
    uint256 public currentTokenId = 0;
    uint256 public currentWave = 0;
    mapping(uint256 => string) public tokenIdURI;
    mapping(uint256 => uint256) public wavePrice;
    mapping(uint256 => uint256) public waveCurrentSupply;
    mapping(uint256 => uint256) public waveMaxSupply;
    mapping(uint256 => uint256) public waveWithdrawl;
    mapping(uint256 => uint256) public waveTokenId;
    mapping(uint256 => uint256) public waveBalance;
    mapping(uint256 => bool) public waveIsRunning;

    constructor(address _vault_address, address _main_address, address _signer_address,
        string memory metadata_url, uint256 _wavePrice, uint256 _waveMaxSupply,
        address[] memory teamAddresses) ERC1155(metadata_url)
    {
        vault_address = _vault_address;
        main_address = _main_address;
        signer_address = _signer_address;

        tokenIdURI[currentTokenId] = metadata_url;

        for (uint256 idx; idx < teamAddresses.length; idx++)
        {
            teamAddressesDict[teamAddresses[idx]] = true;
        }
        
        // Setting up first wave
        initWave(currentWave, _wavePrice, _waveMaxSupply);
    }

    function toggleMintingState()
        public onlyOwner
    {
        if (!_isMinting)
        {
            _isMinting = true;
        }
        else
        {
            _isMinting = false;
        }
    }

    function initWave(uint256 wave, uint256 _wavePrice, uint256 _waveMaxSupply)
        private
    {
        wavePrice[wave] = _wavePrice;
        waveCurrentSupply[wave] = 0;
        waveMaxSupply[wave] = _waveMaxSupply;
        waveWithdrawl[wave] = 0;
        waveTokenId[wave] = currentTokenId;
        waveIsRunning[wave] = true;

        uint256 premint_amount = _waveMaxSupply * nyx_premint_pct / 100;
        _mintNFT(premint_amount, main_address);
    }

    function endWave(uint256 wave)
        public onlyOwner
    {
        require(waveIsRunning[wave], "Wave has already ended");
        require(currentWave == wave, "Wave has already ended");
        require(waveCurrentSupply[wave] >= 0, "Wave have no mint yet");
        
        uint256 waveMinted = waveCurrentSupply[wave];
        uint256 currentWaveMaxSupply = waveMaxSupply[wave];
        uint256 premint_amount_init = currentWaveMaxSupply * nyx_premint_pct / 100;
        uint256 premint_amount_final = waveMinted * nyx_premint_pct / 100;
        uint256 burn_amount = premint_amount_init - premint_amount_final;

        if (burn_amount > 0)
        {
            burnNFT(main_address, burn_amount, currentTokenId, wave);
            waveIsRunning[wave] = false;
            _isMinting = false;
        }
    }

    function startNewWave(uint256 _wavePrice, uint256 _waveMaxSupply)
        public onlyOwner
    {
        require(_waveMaxSupply > 0, "Can't start a new wave with a max supply <= 0");
        if (waveIsRunning[currentWave])
        {
            endWave(currentWave);
        }
        currentWave += 1;
        initWave(currentWave, _wavePrice, _waveMaxSupply);
        _isMinting = false;
    }

    function createNewTokenId(uint256 _wavePrice, uint256 _waveMaxSupply)
        external onlyOwner
    {
        if (waveIsRunning[currentWave])
        {
            endWave(currentWave);
        }
        currentTokenId += 1;
        startNewWave(_wavePrice, _waveMaxSupply);
        // waveTokenId[currentWave] = currentTokenId;
    }

    // Mint Logic
    function _mintNFT(uint256 nMint, address recipient)
        private
    {
        require(totalSupply(currentTokenId) + nMint <= MAX_SUPPLY, "No more NFT to mint");
        require(waveCurrentSupply[currentWave] + nMint <= waveMaxSupply[currentWave], "No more NFT to mint for this wave");
        require(waveIsRunning[currentWave], "Wave has ended");
        waveCurrentSupply[currentWave] += nMint;
        _mint(recipient, currentTokenId, nMint, "");
    }
 
    // Normal Mint
    function mintNFT(uint256 nMint, address recipient)
        public payable
    {
        require(_isMinting, "Mint period have not started yet");
        require(balanceOf(recipient, currentTokenId) + nMint <= max_holding ||
                teamAddressesDict[recipient],
                "Max holded NFTs is reached");
        require(msg.value >= wavePrice[currentWave] * nMint, "Not enough ETH to mint");
        waveBalance[currentWave] += msg.value;
        return _mintNFT(nMint, recipient);
    }

    // Normal Mint (with secret key)
    function mintNFTWithSignature(uint256 nMint, address recipient, uint8 v, bytes32 r, bytes32 s, string memory nonce, uint256 deadline)
        public payable
    {
        // require(VerifySign.getSignerSha256WithDeadline(v, r, s, message, nonce, deadline) == signer_address, "Wrong signer");
        require(_isMinting || isWhitelist(v, r, s, nonce, deadline), "Mint period have not started yet and you are not Whitelisted");
        require(balanceOf(recipient, currentTokenId) + nMint <= max_holding ||
                teamAddressesDict[recipient] ||
                isWhitelist(v, r, s, nonce, deadline) && balanceOf(recipient, currentTokenId) + nMint <= max_holding_whitelist,
                "Max holded NFTs is reached");
        require(msg.value >= wavePrice[currentWave] * nMint, "Not enough ETH to mint");
        waveBalance[currentWave] += msg.value;
        return _mintNFT(nMint, recipient);
    }

    // Free Mint
    function giveaway(uint256 nMint, address recipient)
        public onlyOwner
    {
        return _mintNFT(nMint, recipient);
    }

    function burnNFT(address fromAddress, uint256 amount, uint256 tokenId, uint256 wave)
        public onlyOwner
    {   
        require(balanceOf(fromAddress, currentTokenId) >= amount, "Not enough balance to burn this amount");
        waveCurrentSupply[wave] -= amount;
        _burn(fromAddress, tokenId, amount);
    }

    function setVaultAddress(address addr)
        external onlyOwner
    {
        vault_address = addr;
    }

    function setMainAddress(address addr)
        external onlyOwner
    {
        main_address = addr;
    }

    function setSignerAddress(address addr)
        external onlyOwner
    {
        signer_address = addr;
    }

    function setTokenIdURI(uint256 tokenId, string memory _uri)
        public onlyOwner
    {
        tokenIdURI[tokenId] = _uri;
    }

    function setNyxMintFeePct(uint256 _nyx_mint_fee_pct)
        public onlyOwner
    {
        nyx_mint_fee_pct = _nyx_mint_fee_pct;
    }
    
    function setNyxPremintPct(uint256 _nyx_premint_pct)
        public onlyOwner
    {
        nyx_premint_pct = _nyx_premint_pct;
    }

    function setMaxHolding(uint256 _max_holding)
        public onlyOwner
    {
        max_holding = _max_holding;
    }
    
    function setMaxHoldingWhitelist(uint256 _max_holding_whitelist)
        public onlyOwner
    {
        max_holding_whitelist = _max_holding_whitelist;
    }

    function addTeamAddress(address addr)
        external onlyOwner
    {
        teamAddressesDict[addr] = true;
    }

    function removeTeamAddress(address addr)
        external onlyOwner
    {
        teamAddressesDict[addr] = false;
    }

    function isTeamAddress(address addr)
        public view
        returns (bool)
    {
        return teamAddressesDict[addr];
    }

    function isHolder(address addr, uint256 tokenId)
        public view
        returns (bool)
    {
        return balanceOf(addr, tokenId) > 0;
    }

    function isWhitelist(uint8 v, bytes32 r, bytes32 s, string memory nonce, uint256 deadline)
        public view
        returns (bool)
    {
        require(block.timestamp <= deadline, "Signing too late");
        require(
            recoverSigner(v, r, s, nonce, deadline) == signer_address,
            "Wrong signer"
        );
        return true;
    }

    function recoverSigner(uint8 v, bytes32 r, bytes32 s, string memory nonce, uint256 deadline)
        public view
        returns (address)
    {
        return ecrecover(sha256(abi.encodePacked(msg.sender, nonce, deadline)), v, r, s);
    }

    function getETHBalance(address addr)
        public view
        returns (uint)
    {
        return addr.balance;
    }

    function getContractBalance()
        public view
        returns (uint256)
    {
        return address(this).balance;
    }

    function getCurrentSupply(uint256 tokenId)
        public view
        returns (uint256)
    {
        return totalSupply(tokenId);
    }

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

    function withdraw()
        external onlyOwner
        payable
    {
        uint256 amount = address(this).balance;
        bool success = payable(vault_address).send(amount);
        require(success, "Failed to withdraw");
        for (uint256 wave = 0; wave <= currentWave; wave++)
        {
            waveBalance[wave] = 0;
        }
    }
    
    function getAmountToWithdraw(uint256 wave)
        public view
        returns (uint256, uint256)
    {
        uint256 allowedWithdraw;
        uint256 restWithdraw;
        if (waveBalance[wave] > 0)
        {
            // M1
            // uint256 totalWithdraw = waveBalance[wave] * nyx_mint_fee_pct/100;
            // uint256 alreadyWithdraw = waveWithdrawl[wave];
            // allowedWithdraw = totalWithdraw - alreadyWithdraw;
            // // restWithdraw = address(this).balance - allowedWithdraw;
            // restWithdraw = waveBalance[wave] - allowedWithdraw;
            allowedWithdraw = waveBalance[wave] * nyx_mint_fee_pct/100;
            restWithdraw = waveBalance[wave] - allowedWithdraw;
        }
        else
        {
            allowedWithdraw = 0;
            restWithdraw = 0;
        }

        return (allowedWithdraw, restWithdraw);
    }

    function withdrawOnce(uint256 wave)
        external onlyOwner
        payable
    {
        (uint256 allowedWithdraw, uint256 restWithdraw) = getAmountToWithdraw(wave);

        waveWithdrawl[wave] = allowedWithdraw;
        waveBalance[wave] = 0;

        require(allowedWithdraw != 0 && restWithdraw != 0, "Nothing to withdraw");

        bool succes_nyx = payable(main_address).send(allowedWithdraw);
        bool succes_vault = payable(vault_address).send(restWithdraw);
        require(succes_nyx && succes_vault, "Failed to withdraw");
    }
    
    function uri(uint256 tokenId)
        public view
        override
        returns (string memory)
    {
        return tokenIdURI[tokenId];
    }

    receive()
        external payable
    {
        balance[msg.sender] += msg.value;
    }

    fallback()
        external
    {
    }
}