// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interface/ISmartWallet.sol";
import "./interface/IAlphaWhitelist.sol";
import "./interface/ISmartWalletFactory.sol";

contract AlphaWhitelist is Ownable, IAlphaWhitelist {
    event Whitelisted(address indexed user, bool whitelist);

    IERC721 public immutable alphaNft;
    ISmartWalletFactory public immutable smartWalletFactory;
    mapping(address => bool) private _whitelisted;

    constructor(address _alphaNft, address _smartWalletFactory) {
        require(
            _alphaNft != address(0) && _smartWalletFactory != address(0),
            "AlphaWhitelist: zero address"
        );
        alphaNft = IERC721(_alphaNft);
        smartWalletFactory = ISmartWalletFactory(_smartWalletFactory);
    }

    function setWhitelist(address[] calldata users, bool whitelist)
        external
        onlyOwner
    {
        uint256 len = users.length;
        for (uint256 i; i < len; i += 1) {
            address user = users[i];
            _whitelisted[user] = whitelist;
            emit Whitelisted(user, whitelist);
        }
    }

    function isWhitelisted(address user) external view override returns (bool) {
        if (_whitelisted[user] || alphaNft.balanceOf(user) != 0) {
            return true;
        }

        (bool success, bytes memory data) = user.staticcall(
            abi.encodeWithSignature("owner()")
        );
        if (!success || data.length == 0) {
            return false;
        }
        address owner = abi.decode(data, (address));
        return
            smartWalletFactory.getSmartWallet(owner) == user &&
            alphaNft.balanceOf(owner) != 0;
    }
}