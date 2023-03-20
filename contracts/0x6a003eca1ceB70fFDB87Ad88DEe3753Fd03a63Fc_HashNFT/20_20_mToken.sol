// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

struct NFTInfo {
    address nft;
    uint256 tokenId;
}

contract mToken is Context, Ownable {
    event mTokenReceived(address from, uint256 amount);
    event FundsClaimed(IERC20 indexed token, address to, uint256 amount);
    event PayeeAdded(address nft, uint256 tokenId, uint256 shares);

    IERC20 public immutable funds;

    uint256 private _totalShares;
    uint256 private _fundsTotalClaimed;
    mapping(string => uint256) private _fundsClaimed;

    mapping(string => uint256) private _shares;
    NFTInfo[] private _payees;

    /**
     * @dev Creates an instance of `mToken`
     */
    constructor(address funds_) {
        funds = IERC20(funds_);
    }

    function totalShares() public view returns (uint256) {
        return _totalShares;
    }

    function totalClaimed() public view returns (uint256) {
        return _fundsTotalClaimed;
    }

    function addPayee(uint256 tokenId, uint256 shares_) public onlyOwner {
        address nft = msg.sender;
        require(
            IERC721(nft).ownerOf(tokenId) != address(0),
            "mToken: account is the zero address"
        );
        require(shares_ > 0, "mToken: shares are 0");

        _payees.push(NFTInfo(nft, tokenId));
        _shares[_toString(nft, tokenId)] += shares_;
        _totalShares = _totalShares + shares_;
        emit PayeeAdded(nft, tokenId, shares_);
    }

    function shares(address nft, uint256 tokenId)
        public
        view
        returns (uint256)
    {
        return _shares[_toString(nft, tokenId)];
    }

    function claimed(address nft, uint256 tokenId)
        public
        view
        returns (uint256)
    {
        return _fundsClaimed[_toString(nft, tokenId)];
    }

    function payee(uint256 index) public view returns (address, uint256) {
        return (_payees[index].nft, _payees[index].tokenId);
    }

    function claims(address nft, uint256 tokenId) public {
        require(
            _shares[_toString(nft, tokenId)] > 0,
            "mToken: tokenId has no shares"
        );
        address to = IERC721(nft).ownerOf(tokenId);
        uint256 totalReceived = funds.balanceOf(address(this)) + _fundsTotalClaimed;
        uint256 payment = _pending(
            nft,
            tokenId,
            totalReceived,
            claimed(nft, tokenId)
        );
        require(payment != 0, "mToken: tokenId is not due payment");
        _fundsClaimed[_toString(nft, tokenId)] += payment;
        _fundsTotalClaimed += payment;
        SafeERC20.safeTransfer(funds, to, payment);
        emit FundsClaimed(funds, to, payment);
    }

    function _pending(
        address nft,
        uint256 tokenId,
        uint256 totalReceived,
        uint256 alreadyClaimed
    ) private view returns (uint256) {
        return
            (totalReceived * _shares[_toString(nft, tokenId)]) /
            _totalShares -
            alreadyClaimed;
    }

    function _toString(address nft, uint256 tokenId)
        private
        pure
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    toAsciiString(nft),
                    ":",
                    Strings.toString(tokenId)
                )
            );
    }

    function toAsciiString(address x) internal pure returns (string memory) {
        bytes memory s = new bytes(40);
        for (uint256 i = 0; i < 20; i++) {
            bytes1 b = bytes1(uint8(uint256(uint160(x)) / (2**(8 * (19 - i)))));
            bytes1 hi = bytes1(uint8(b) / 16);
            bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
            s[2 * i] = char(hi);
            s[2 * i + 1] = char(lo);
        }
        return string(s);
    }

    function char(bytes1 b) internal pure returns (bytes1 c) {
        if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
        else return bytes1(uint8(b) + 0x57);
    }
}