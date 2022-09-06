// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/interfaces/IERC1271.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

interface IWrappedEther {
    function deposit() external payable;

    function withdraw(uint wad) external;

    function balanceOf(address account) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);
}

interface IVaultManager {
    function close(uint256 tokenId) external payable;
}

interface IOpenSeaProxy {
    function registerProxy() external returns (address);
}

contract PartnerVault is Ownable, ERC721Holder, IERC1271 {
    using ECDSA for bytes32;

    address immutable public tokenContract;
    IWrappedEther immutable public wrappedEther;
    IVaultManager immutable public vaultManager;
    IERC20 immutable public landDao;
    uint256 public tokenId;
    address public openSeaExchange;
    address public openSeaConduit;

    address public updateManager;
    mapping(address => mapping(uint256 => address)) public updateOperator;

    event UpdateOperatorSet(address, uint256, address);

    modifier onlyOwnerOrManager() {
        require(owner() == msg.sender || address(vaultManager) == msg.sender, "Vault: caller is not the owner or manager");
        _;
    }

    modifier onlyUpdateManager() {
        require(updateManager == msg.sender, "Vault: caller is not the update manager");
        _;
    }

    constructor(
        address vaultManager_,
        address tokenContract_,
        address wrappedEther_,
        address landDao_,
        address openSeaExchange_,
        address openSeaConduit_
    ) {
        vaultManager = IVaultManager(vaultManager_);
        tokenContract = tokenContract_;
        wrappedEther = IWrappedEther(wrappedEther_);
        landDao = IERC20(landDao_);
        openSeaExchange = openSeaExchange_;
        openSeaConduit = openSeaConduit_;
    }

    function setUpdateManager(address updateManager_) external onlyOwner {
        require(updateManager_ != address(0));
        updateManager = updateManager_;
    }

    function setUpdateOperator(uint256 assetId, address operator) external onlyUpdateManager {
        updateOperator[tokenContract][assetId] = operator;
        emit UpdateOperatorSet(tokenContract, assetId, operator);
    }

    function updateOpenSeaData(address openSeaExchange_, address openSeaConduit_) external onlyOwner {
        openSeaExchange = openSeaExchange_;
        openSeaConduit = openSeaConduit_;
    }

    function prepareOpenSea() public onlyOwnerOrManager {
        IERC721(tokenContract).setApprovalForAll(openSeaConduit, true);
        require(wrappedEther.approve(openSeaConduit, type(uint).max), "Vault: error approving WETH");
    }

    function exchangeOpenSea(bytes calldata _calldata, uint256 value) external onlyOwner {
        (bool _success,) = openSeaExchange.call{value : value}(_calldata);
        require(_success, "Vault: error sending data to exchange");
    }

    receive() external payable {
    }

    function start(uint256 tokenId_) external payable {
        require(tokenId_ > 0, "Vault: tokenId can not be 0");
        require(tokenId == 0, "Vault: tokenId is already set");
        require(msg.value > 0, "Vault: can not be started without funds");
        require(msg.sender == address(vaultManager), "Vault: manager should start");
        tokenId = tokenId_;
        wrap();
        prepareOpenSea();
    }

    function wrap() public onlyOwnerOrManager {
        wrappedEther.deposit{value : address(this).balance}();
    }

    function unWrap() public onlyOwnerOrManager {
        uint256 balance = wrappedEther.balanceOf(address(this));
        if (balance > 0) {
            wrappedEther.withdraw(balance);
        }
    }

    function finish() external onlyOwnerOrManager {
        require(tokenId > 0, "Vault: tokenId not set");
        require(IERC721(tokenContract).balanceOf(address(this)) == 0, "Vault: not all tokens sold");
        unWrap();
        vaultManager.close{value : address(this).balance}(tokenId);
    }

    function isValidSignature(bytes32 _hash, bytes calldata _signature) external override view returns (bytes4) {
        address signer = _hash.recover(_signature);
        if (signer == owner()) {
            return 0x1626ba7e;
        }
        return 0x00000000;
    }

    function distributeRewards(address account, uint256 balance, uint256 totalSupply) external {
        require(msg.sender == address(vaultManager));
        uint256 landBalance = landDao.balanceOf(address(this));
        if (landBalance > 0) {
            uint256 rewards = (landBalance * balance) / totalSupply;
            landDao.transfer(account, rewards);
        }
    }

}