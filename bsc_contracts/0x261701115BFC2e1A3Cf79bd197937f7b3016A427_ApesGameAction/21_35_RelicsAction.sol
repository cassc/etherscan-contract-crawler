// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./lib/Verify.sol";

interface MintNfter {
    function adminMintTo(address to, uint256 tokenId) external;
}

contract FreeMintAction is OwnableUpgradeable, Verify {
    MintNfter public nftContract;
    struct Config {
        uint128 nonce;
        uint128 price;
    }

    Config public cfg;

    mapping(bytes32 => bool) public claimed;
    event Claimed(
        address to,
        uint256 serverId,
        uint256 payerId,
        uint256 relicsId,
        uint256 tokenId
    );

    function initialize(MintNfter _impl, Config memory _cfg)
        public
        initializer
    {
        nftContract = _impl;
        __Ownable_init();
        setConfig(_cfg);
    }

    /// @dev TokenId for mint nft
    /// @dev Each mint nft, nonce will add 1
    /// @dev mint nft is mint nonce
    /// @dev price: 1000 = 1 ether, 1 = 0.001 ether
    function setConfig(Config memory _cfg) public onlyOwner {
        require(
            _cfg.nonce > cfg.nonce,
            "_nonce must be greater than origin nonce"
        );
        cfg.nonce = _cfg.nonce;
        cfg.price = _cfg.price;
    }

    function setNft(MintNfter _impl) external onlyOwner {
        nftContract = _impl;
    }

    /// @notice Entrance of user mint art nft
    /// @param _data sign data, keccak256(abi.encodePacked(msg.sender, _serverId, _payerId, _relicsId));
    function claim(
        uint256 _serverId,
        uint256 _payerId,
        uint256 _relicsId,
        bytes memory _data
    ) external payable {
        address sender = _msgSender();
        bytes32 _hash = keccak256(
            abi.encodePacked(sender, _serverId, _payerId, _relicsId)
        );
        bytes32 _onlyHash = keccak256(
            abi.encodePacked(_serverId, _payerId, _relicsId)
        );

        require(verify(_hash, _data), "Authentication failed");
        require(!claimed[_onlyHash], "Already minted");
        require(msg.value == cfg.price * 1e15, "Invalid amount");

        nftContract.adminMintTo(sender, cfg.nonce);
        claimed[_onlyHash] = true;
        emit Claimed(sender, _serverId, _payerId, _relicsId, cfg.nonce);
        cfg.nonce++;
    }

    /// @notice Withdraw the balance of the contract
    /// @param _to Withdraw the balance of the contract to `_to`
    function withdraw(address _to) external onlyOwner {
        payable(_to).transfer(address(this).balance);
    }
}