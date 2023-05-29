// SPDX-License-Identifier: agpl-3.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

interface IS16Presale {
    function getPresaleRegisterUserList()
        external
        view
        returns (address[] memory);

    function getPresaleTime() external view returns (uint);
}

contract S16Token is Ownable, ERC20, ERC20Burnable, AccessControl {
    uint256 maxTokenSupply = 10000000000e18; //10 billion max token supply
    bytes32 public constant S16DIST_ROLE = keccak256("S16DIST_ROLE");

    bool public _airdropMintingPaused = false;

    address private s16PresaleAddress;
    address private s16DistAddress;

    constructor() ERC20("S16", "S16") {}

    function configureS16Presale(address _s16PresaleAddress)
        external
        onlyOwner
    {
        require(_s16PresaleAddress != address(0), "S16TOKEN: null address");
        s16PresaleAddress = _s16PresaleAddress;
    }

    function configureS16Dist(address _s16DistAddress) external onlyOwner {
        require(_s16DistAddress != address(0), "S16TOKEN: null address");
        s16DistAddress = _s16DistAddress;
    }

    function setRoleS16Dist() external onlyOwner {
        require(s16DistAddress != address(0), "S16TOKEN: null address");
        _setupRole(S16DIST_ROLE, s16DistAddress);
    }

    function mint(address account, uint256 amount) external onlyOwner {
        require(
            totalSupply() + amount <= maxTokenSupply,
            "S16TOKEN: cap exceeded"
        );
        super._mint(account, amount);
    }

    function airdropTokenbyAdmin() external onlyOwner {

        require(s16PresaleAddress != address(0), "S16TOKEN: s16 presale not configured");
        require(block.timestamp > IS16Presale(s16PresaleAddress).getPresaleTime());
        address[] memory preSaleUsers = IS16Presale(s16PresaleAddress).getPresaleRegisterUserList();
        for (uint256 i = 0; i < preSaleUsers.length; i++) {
            require(
                totalSupply() + 1600e18 <= maxTokenSupply,
                "S16TOKEN: cap exceeded"
            );
            super._mint(preSaleUsers[i], 1600e18);
        }
    }

    function airdropTokenUser(address account, uint256 amount) external {
        
        require(!_airdropMintingPaused, "S16TOKEN");
        require(s16DistAddress != address(0), "S16Token: s16 dist not configured yet");
        require(
            hasRole(S16DIST_ROLE, s16DistAddress),
            "S16Token: callet is not S16Dist"
        );
        require(
            totalSupply() + amount <= maxTokenSupply,
            "S16TOKEN: cap exceeded"
        );
        super._mint(account, amount);
    }

    function pauseAirdrop(bool _pause) external onlyOwner{
        require(_airdropMintingPaused != _pause, "Already in desired pause state");
        _airdropMintingPaused = _pause;
        
    }
}