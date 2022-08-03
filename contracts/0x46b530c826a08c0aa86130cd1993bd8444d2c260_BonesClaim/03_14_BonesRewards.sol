// SPDX-License-Identifier: MIT
/*
██████╗░░██████╗░███╗░░░██╗███████╗███████╗░░░░██████╗░███████╗██╗░░░░██╗░█████╗░██████╗░██████╗░███████╗
██╔══██╗██╔═══██╗████╗░░██║██╔════╝██╔════╝░░░░██╔══██╗██╔════╝██║░░░░██║██╔══██╗██╔══██╗██╔══██╗██╔════╝
██████╔╝██║░░░██║██╔██╗░██║█████╗░░███████╗░░░░██████╔╝█████╗░░██║░█╗░██║███████║██████╔╝██║░░██║███████╗
██╔══██╗██║░░░██║██║╚██╗██║██╔══╝░░╚════██║░░░░██╔══██╗██╔══╝░░██║███╗██║██╔══██║██╔══██╗██║░░██║╚════██║
██████╔╝╚██████╔╝██║░╚████║███████╗███████║░░░░██║░░██║███████╗╚███╔███╔╝██║░░██║██║░░██║██████╔╝███████║
╚═════╝░░╚═════╝░╚═╝░░╚═══╝╚══════╝╚══════╝░░░░╚═╝░░╚═╝╚══════╝░╚══╝╚══╝░╚═╝░░╚═╝╚═╝░░╚═╝╚═════╝░╚══════╝
*/
pragma solidity >=0.8.9 <0.9.0;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol';
import 'erc721a/contracts/extensions/ERC721AQueryable.sol';


contract BonesRewards is ERC20, ERC20Burnable, Ownable {

    struct Vault {
        ERC721AQueryable nft;
        string name;
        uint allocation;
        uint specialAllocation;
        uint[] specialTokens;
    }

    mapping(address => bool) public controllers;
    mapping(address => Vault) public vault;
    mapping(address => mapping(uint => bool)) public claimedTokens;

    constructor(
        string memory _tokenName,
        string memory _tokenSymbol
    ) ERC20(_tokenName, _tokenSymbol) {}

    function mint(address _to, uint _amount) external {
        require(controllers[_msgSender()], 'Not authorized');
        _mint(_to, _amount);
    }

    function burnFrom(address _account, uint _amount) public override {
        if (controllers[_msgSender()]) {
            _burn(_account, _amount);
        } else {
            super.burnFrom(_account, _amount);
        }
    }

    function addController(address _newController) external onlyOwner {
        controllers[_newController] = true;
    }

    function removeController(address _controller) external onlyOwner {
        controllers[_controller] = false;
    }

    function airdrop(address _address, uint _amount) external onlyOwner {
        uint amount = _amount * (10 ** 18); 
        _mint(_address, amount);
    }

    function createVault(ERC721AQueryable _nft, string memory _name, uint _allocation, uint _specialAllocation, uint[] calldata _specialTokens) public onlyOwner {
        Vault memory newVault = Vault(
            _nft,
            _name,
            _allocation,
            _specialAllocation,
            _specialTokens
        );

        vault[address(_nft)] = newVault;
    }

    function setClaimed(ERC721AQueryable _nft, uint[] calldata _tokenIds, bool _state) public onlyOwner {
        for (uint i = 0; i < _tokenIds.length; i++) {
            uint tokenId = _tokenIds[i];
            claimedTokens[address(_nft)][tokenId] = _state;
        }
    }

    function initialClaim(ERC721AQueryable _nft, uint[] calldata _tokenIDs) external { 
        Vault memory vaultInfo = vault[address(_nft)];
        require(_tokenIDs.length > 0, "Token array cannot be empty");
        uint amount;
        uint specialDiff = vaultInfo.specialAllocation - vaultInfo.allocation;
        for (uint i = 0; i < _tokenIDs.length; i++) {
            uint tokenId = _tokenIDs[i];
            require(ERC721AQueryable(_nft).ownerOf(tokenId) == _msgSender(), "You do not own this token");
            require(!claimedTokens[address(_nft)][tokenId], "This tokens rewards have already been claimed");
            if (vaultInfo.specialTokens.length > 0) {
                for (uint j = 0; j < vaultInfo.specialTokens.length; j++) {
                    if (tokenId == vaultInfo.specialTokens[j]) {
                        // amount += vaultInfo.specialAllocation;
                        amount += specialDiff;
                    }
                }
            }
            amount += vaultInfo.allocation;
            claimedTokens[address(_nft)][tokenId] = true;
        }

        if (amount > 0) {
            _mint(_msgSender(), amount * (10 ** 18));
        }
    }

    function ownerTokens(ERC721AQueryable _nft, address _user) public view returns (uint[] memory) {
        address NFT = address(_nft);
        return ERC721AQueryable(NFT).tokensOfOwner(_user);
    }
/*__            __    __                     
 /\ \          /\ \__/\ \              __    
 \_\ \     __  \ \ ,_\ \ \____    ___ /\_\   
 /'_` \  /'__`\ \ \ \/\ \ '__`\  / __`\/\ \  
/\ \L\ \/\ \L\.\_\ \ \_\ \ \L\ \/\ \L\ \ \ \ 
\ \___,_\ \__/.\_\\ \__\\ \_,__/\ \____/\ \_\
 \/__,_ /\/__/\/_/ \/__/ \/___/  \/___/  \/_/
*/
}