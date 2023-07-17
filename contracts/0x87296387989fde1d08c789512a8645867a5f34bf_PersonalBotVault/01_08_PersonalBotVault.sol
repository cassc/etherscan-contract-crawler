// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/interfaces/IERC1271.sol";

interface IWrappedEther {
    function approve(address spender, uint256 amount) external returns (bool);
    function transfer(address to, uint256 amount) external returns (bool);
    function balanceOf(address owner) external view returns (uint256);
}

contract PersonalBotVault is ERC721Holder, IERC1271 {
    using ECDSA for bytes32;

    IWrappedEther immutable public wrappedEther;
    address public openSeaConduit;
    address immutable public owner;
    address public signer;

    constructor(
        address owner_,
        address signer_,
        address wrappedEtherAddress_,
        address openSeaConduit_
    ) {
        require(openSeaConduit_ != address(0), "Vault: OpenSea Conduit address can not be null");
        require(wrappedEtherAddress_ != address(0), "Vault: WETH address can not be null");
        require(owner_ != address(0), "Vault: owner can not be null");
        require(signer_ != address(0), "Vault: signer can not be null");
        owner = owner_;
        signer = signer_;
        wrappedEther = IWrappedEther(wrappedEtherAddress_);
        openSeaConduit = openSeaConduit_;
        require(IWrappedEther(wrappedEtherAddress_).approve(openSeaConduit_, type(uint).max), "Pool: error approving WETH");
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function updateOpenSeaData(address openSeaConduit_) external onlyOwner {
        require(openSeaConduit_ != address(0), "Vault: OpenSea Conduit not set");
        openSeaConduit = openSeaConduit_;
        require(wrappedEther.approve(openSeaConduit_, type(uint).max), "Pool: error approving WETH");
    }

    function exchangeOpenSea(address openSeaExchange, bytes calldata _calldata, uint256 value) external onlyOwner {
        require(openSeaExchange != address(0), "Vault: OpenSea exchange can not be null");
        (bool _success,) = openSeaExchange.call{value : value}(_calldata);
        require(_success, "Vault: error sending data to exchange");
    }

    function withdraw() external onlyOwner {
        uint256 balance = wrappedEther.balanceOf(address(this));
        require(balance > 0, "Vault: no WETH to withdraw");
        wrappedEther.transfer(owner, balance);
    }

    function withdrawAsset(address contractAddress_, uint256 tokenId_) external onlyOwner {
        IERC721(contractAddress_).safeTransferFrom(address(this), owner, tokenId_);
    }

    function isValidSignature(bytes32 hash_, bytes calldata signature_) external override view returns (bytes4) {
        address signer_ = hash_.recover(signature_);
        if (signer_ == signer) {
            return 0x1626ba7e;
        }
        return 0x00000000;
    }
}

contract PersonalBotVaultFactory {
    mapping(address => address) public vaults;
    address immutable wrappedEtherAddress;

    constructor(address wrappedEtherAddress_) {
        wrappedEtherAddress = wrappedEtherAddress_;
    }

    function create(
        address signer_,
        address openSeaConduit_
    ) public {
        require(vaults[msg.sender] == address(0));
        PersonalBotVault vault = new PersonalBotVault(
            msg.sender,
            signer_,
            wrappedEtherAddress,
            openSeaConduit_
        );
        vaults[msg.sender] = address(vault);
    }
}