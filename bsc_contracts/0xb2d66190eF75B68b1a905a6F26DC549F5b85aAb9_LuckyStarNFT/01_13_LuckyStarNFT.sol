// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./ERC721A.sol";
import "./libraries/UniversalERC20.sol";
import "./interfaces/IAdmin.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/**
 *
 *  /$$                           /$$                  /$$$$$$   /$$
 * | $$                          | $$                 /$$__  $$ | $$
 * | $$       /$$   /$$  /$$$$$$$| $$   /$$ /$$   /$$| $$  \__//$$$$$$    /$$$$$$   /$$$$$$
 * | $$      | $$  | $$ /$$_____/| $$  /$$/| $$  | $$|  $$$$$$|_  $$_/   |____  $$ /$$__  $$
 * | $$      | $$  | $$| $$      | $$$$$$/ | $$  | $$ \____  $$ | $$      /$$$$$$$| $$  \__/
 * | $$      | $$  | $$| $$      | $$_  $$ | $$  | $$ /$$  \ $$ | $$ /$$ /$$__  $$| $$
 * | $$$$$$$$|  $$$$$$/|  $$$$$$$| $$ \  $$|  $$$$$$$|  $$$$$$/ |  $$$$/|  $$$$$$$| $$
 * |________/ \______/  \_______/|__/  \__/ \____  $$ \______/   \___/   \_______/|__/
 *                                          /$$  | $$
 *                                         |  $$$$$$/
 *                                          \______/
 */

contract LuckyStarNFT is ERC721A, Ownable {
    using Strings for uint256;
    using UniversalERC20 for IERC20;

    uint256 public phase;
    IAdmin public admin;
    string private _BaseURI;
    mapping(address => uint256) private _nonces;
    mapping(uint256 => uint8) private _levels;

    event Upgrade(address user, uint256 tokenId, uint8 level);

    constructor(
        string memory name_,
        string memory symbol_,
        string memory baseURI_,
        address admin_
    ) ERC721A(name_, symbol_) {
        _BaseURI = baseURI_;
        admin = IAdmin(admin_);
    }

    function mint(bytes calldata signature_) public {
        require(phase == 1, "Not in active time for mint");
        unchecked {
            _nonces[msg.sender] += 1;
        }
        bytes32 hash_ = keccak256(
            abi.encodePacked(msg.sender, _nonces[msg.sender], this)
        );
        require(checkSignature(signature_, hash_), "Invalid mint signature");

        _safeMint(msg.sender, 1);
        unchecked {
            uint256 mintedId_ = _nextTokenId() - 1;
            _levels[mintedId_] = 1;
        }
    }

    function batchMint(address[] memory addresses_) public onlyOwner {
        require(addresses_.length > 0, "Addresses should not be empty");
        for (uint256 i = 0; i < addresses_.length; i++) {
            _safeMint(addresses_[i], 1);
            unchecked {
                uint256 mintedId_ = _nextTokenId() - 1;
                _levels[mintedId_] = 1;
            }
        }
    }

    function upgrade(uint256 tokenId_, bytes calldata signature_) public {
        require(ownerOf(tokenId_) == msg.sender, "Only upgrade your own");
        unchecked {
            _levels[tokenId_] += 1;
        }
        bytes32 hash_ = keccak256(
            abi.encodePacked(msg.sender, tokenId_, _levels[tokenId_], this)
        );
        require(checkSignature(signature_, hash_), "Invalid upgrade signature");

        emit Upgrade(msg.sender, tokenId_, _levels[tokenId_]);
    }

    function tokensOfOwner(address owner_)
        public
        view
        returns (uint256[] memory)
    {
        uint256 balance = balanceOf(owner_);
        uint256[] memory tokens = new uint256[](balance);
        uint256 index;
        unchecked {
            uint256 totalSupply = totalSupply();
            for (uint256 i = 1; i <= totalSupply; i++) {
                if (ownerOf(i) == owner_) {
                    tokens[index] = uint256(i);
                    index++;
                }
            }
        }
        return tokens;
    }

    function tokenURI(uint256 tokenId_)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId_), "URI query for nonexistent token");

        return
            bytes(_BaseURI).length > 0
                ? string(
                    abi.encodePacked(_BaseURI, tokenId_.toString(), ".json")
                )
                : "";
    }

    function baseURI() public view returns (string memory) {
        return _BaseURI;
    }

    function getLevel(uint256 tokenId_) public view returns (uint8) {
        return _levels[tokenId_];
    }

    function getNonce(address user_) public view returns (uint256) {
        return _nonces[user_];
    }

    function setBaseURI(string memory baseUri_) external onlyOwner {
        _BaseURI = baseUri_;
    }

    function setPhase(uint256 phase_) external onlyOwner {
        phase = phase_;
    }

    function rescueFunds(IERC20 token_, uint256 amount_) external onlyOwner {
        token_.universalTransfer(payable(msg.sender), amount_);
    }

    function checkSignature(bytes calldata signature_, bytes32 hash_)
        public
        view
        returns (bool)
    {
        bytes32 message = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", hash_)
        );
        return admin.isAdmin(_validate(message, signature_));
    }

    /// @dev validate signature msg
    function _validate(bytes32 message, bytes memory signature_)
        internal
        view
        returns (address)
    {
        require(address(admin) != address(0) && signature_.length == 65);

        bytes32 r;
        bytes32 s;
        uint8 v;
        assembly {
            // first 32 bytes, after the length prefix.
            r := mload(add(signature_, 32))
            // second 32 bytes.
            s := mload(add(signature_, 64))
            // final byte (first byte of the next 32 bytes).
            v := byte(0, mload(add(signature_, 96)))
        }
        return ecrecover(message, v, r, s);
    }
}