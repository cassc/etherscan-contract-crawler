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

contract SimpleVault is Ownable, ERC721Holder, IERC1271 {
    using ECDSA for bytes32;

    IWrappedEther immutable public wrappedEther;
    IVaultManager immutable public vaultManager;
    IERC20 immutable public landDao;
    uint256 public tokenId;
    address public exchange;
    address public openSeaConduit;

    modifier onlyOwnerOrManager() {
        require(owner() == msg.sender || address(vaultManager) == msg.sender, "Vault: caller is not the owner or manager");
        _;
    }

    constructor(
        address vaultManager_,
        address wrappedEther_,
        address landDao_,
        address exchange_,
        address openSeaConduit_
    ) {
        vaultManager = IVaultManager(vaultManager_);
        wrappedEther = IWrappedEther(wrappedEther_);
        landDao = IERC20(landDao_);
        exchange = exchange_;
        openSeaConduit = openSeaConduit_;
    }

    function updateExchangeData(address exchange_, address openSeaConduit_) external onlyOwner {
        exchange = exchange_;
        openSeaConduit = openSeaConduit_;
    }

    function prepareOpenSea(address[] memory contracts) public onlyOwnerOrManager {
        for (uint i = 0; i < contracts.length; i++) {
            IERC721(contracts[i]).setApprovalForAll(openSeaConduit, true);
        }
        require(wrappedEther.approve(openSeaConduit, type(uint).max), "Vault: error approving WETH");
    }

    function exchangeAsset(bytes calldata _calldata, uint256 value) external onlyOwner {
        (bool _success,) = exchange.call{value : value}(_calldata);
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