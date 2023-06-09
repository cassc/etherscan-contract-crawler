// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "openzeppelin-contracts/access/Ownable.sol";
import "openzeppelin-contracts/security/Pausable.sol";
import "openzeppelin-contracts/token/ERC20/ERC20.sol";
import "openzeppelin-contracts/interfaces/IERC721Receiver.sol";
import "./interfaces/IBeefyVault.sol";
import "./interfaces/ICrossChainStablecoin.sol";
import "./interfaces/IPerfToken.sol";

contract ThreeStepQiZappah is Ownable, Pausable, IERC721Receiver{
    struct AssetChain {
        IERC20 asset;
        IPerfToken perfToken;
        ICrossChainStablecoin mooTokenVault;
        /*
        WSTETH -> @ 0x1F32b1c2345538c0c6f582fCB022739c4A194Ebb
        Call enter on PerfToken @ 0x77965B3282DFdeB258B7ad77e833ad7Ee508B878
        Call depositCollateral @ 0xdB5D7086C5198e8A4da5BD2972c8584309c3759e
        */
       
    }
    mapping (bytes32 => AssetChain) private _chainWhiteList;
    
    event AssetZapped(address indexed asset, uint256 indexed amount, uint256 vaultId);
    event AssetUnZapped(address indexed asset, uint256 indexed amount, uint256 vaultId);

    function _beefyZapToVault(uint256 amount, uint256 vaultId, AssetChain memory chain) internal whenNotPaused returns (uint256) {
        require(amount > 0, "You need to deposit at least some tokens");

        uint256 allowance = chain.asset.allowance(msg.sender, address(this));
        require(allowance >= amount, "Check the token allowance");
        require(chain.mooTokenVault.exists(vaultId), "VaultId provided doesn't exist");

        chain.asset.transferFrom(msg.sender, address(this), amount);
        chain.asset.approve(address(chain.perfToken), amount);
        chain.perfToken.enter(amount);
        uint256 perfTokenBalToZap = chain.perfToken.balanceOf(address(this));

        chain.perfToken.approve(address(chain.mooTokenVault), perfTokenBalToZap);
        chain.mooTokenVault.depositCollateral(vaultId, perfTokenBalToZap);
        emit AssetZapped(address(chain.asset), amount, vaultId);
        return chain.perfToken.balanceOf(msg.sender);
    }

    function _beefyZapFromVault(uint256 amount, uint256 vaultId, AssetChain memory chain) internal whenNotPaused returns (uint256) {
        require(amount > 0, "You need to withdraw at least some tokens");
        require(chain.mooTokenVault.getApproved(vaultId) == address(this), "Need to have approval");
        require(chain.mooTokenVault.ownerOf(vaultId) == msg.sender, "You can only zap out of vaults you own");

        //Transfer vault to this contract
        chain.perfToken.approve(address(chain.mooTokenVault), amount);
        chain.mooTokenVault.safeTransferFrom(msg.sender, address(this), vaultId);

        //Withdraw funds from vault
        uint256 perfTokenBalanceBeforeWithdraw = chain.perfToken.balanceOf(address(this));
        chain.mooTokenVault.withdrawCollateral(vaultId, amount);
        uint256 perfTokenBalanceToUnzap = chain.perfToken.balanceOf(address(this)) - perfTokenBalanceBeforeWithdraw;
        
        //Return vault to user
        chain.mooTokenVault.approve(msg.sender, vaultId);
        chain.mooTokenVault.safeTransferFrom(address(this), msg.sender, vaultId);

        //Exit from the perfToken to mooToken
        uint256 tokenBalanceBeforeWithdraw = chain.asset.balanceOf(address(this));
        chain.perfToken.leave(perfTokenBalanceToUnzap);
        uint256 tokenBalanceToTransfer = chain.asset.balanceOf(address(this)) - tokenBalanceBeforeWithdraw;

        //Transfer tokens to user
        chain.asset.approve(address(this), tokenBalanceToTransfer);
        chain.asset.transfer(msg.sender, tokenBalanceToTransfer);

        emit AssetUnZapped(address(chain.asset), amount, vaultId);
        return tokenBalanceToTransfer;
    }

    function _buildAssetChain(address _asset, address perfToken, address _mooAssetVault) pure internal returns (AssetChain memory) {
        AssetChain memory chain;
        chain.asset = IERC20(_asset);
        chain.perfToken = IPerfToken(perfToken);
        chain.mooTokenVault = ICrossChainStablecoin(_mooAssetVault);
        return chain;
    }

    function _hashAssetChain(AssetChain memory chain) pure internal returns (bytes32){
        return keccak256(
            abi.encodePacked(address(chain.asset), address(chain.perfToken), address(chain.mooTokenVault)));
    }

    function isWhiteListed(AssetChain memory chain) view public returns (bool){
        return address(_chainWhiteList[_hashAssetChain(chain)].asset) != address(0x0);
    }

    function addChainToWhiteList(address _asset, address _perfToken, address _mooAssetVault) public onlyOwner {
        AssetChain memory chain = _buildAssetChain(_asset, _perfToken, _mooAssetVault);
        if(!isWhiteListed(chain)){
            _chainWhiteList[_hashAssetChain(chain)] = chain;
        } else {
            revert("Chain already in White List");
        }
    }

    function removeChainFromWhiteList(address _asset, address _perfToken, address _mooAssetVault) public onlyOwner {
        AssetChain memory chain = _buildAssetChain(_asset, _perfToken, _mooAssetVault);
        if(isWhiteListed(chain)){
            delete _chainWhiteList[_hashAssetChain(chain)];
        } else {
            revert("Chain not in white List");
        }
    }

    function pauseZapping() public onlyOwner {
        _pause();
    }

    function resumeZapping() public onlyOwner {
        _unpause();
    }

    function beefyZapToVault(uint256 amount, uint256 vaultId, address _asset, address _perfToken, address _mooAssetVault) public whenNotPaused returns (uint256) {
        AssetChain memory chain = _buildAssetChain(_asset, _perfToken, _mooAssetVault);
        require(isWhiteListed(chain), "mooToken chain not in on allowable list");
        return _beefyZapToVault(amount, vaultId, chain);
    }

    function beefyZapFromVault(uint256 amount, uint256 vaultId, address _asset, address _perfToken, address _mooAssetVault) public whenNotPaused returns (uint256) {
        AssetChain memory chain = _buildAssetChain(_asset, _perfToken, _mooAssetVault);
        require(isWhiteListed(chain), "mooToken chain not in on allowable list");
        return _beefyZapFromVault(amount, vaultId, chain);
    }

    function onERC721Received(address, address, uint256, bytes memory) public pure returns (bytes4) {
        return this.onERC721Received.selector;
    }
}