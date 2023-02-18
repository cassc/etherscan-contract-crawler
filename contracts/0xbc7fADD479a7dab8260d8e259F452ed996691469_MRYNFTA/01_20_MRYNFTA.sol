// SPDX-License-Identifier: MIT
//
// Smart-contract MIU group access NFT for
// Mry.vc

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

contract MRYNFTA is ERC721Enumerable, ReentrancyGuard, Ownable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    struct MintConfig {
      address nft_minter;
      uint256 minted_at;
    }
    //
    // Vars
    string public baseURI;
    address internal wallet;
    IERC20 public sell_token;
    uint256 public sell_price;

    mapping(uint256 => MintConfig) mint_info;
    //

    constructor(address _wallet, address _sell_token, uint256 _sell_price) ERC721 ("MRY CAPITAL", "MRYC") {
        wallet = _wallet;
        sell_token = IERC20(_sell_token);
        sell_price = _sell_price;
    }

    //
    // View, pure helpers functions
    // Base URI
    function tokenURI(uint256 _id) public view virtual override returns (string memory) {
        require(_id > 0 && _id <= totalSupply(), 'Token id not corrrect');
        return string(abi.encodePacked(
            "data:application/json;base64,",
            Base64.encode(bytes('{"name": "MRY Member", "description": "MRY Capital NFT collection for private access", "image": "https://mry.vc/images/nft/main.png"}'))
        ));
    }
    // Check wallet address
    function getWallet() public view returns(address _wallet) {
        _wallet = wallet;
    }
    // Get nimber of available NFT for mint
    function availableNFT() public view returns (uint256) {
        return (10000 - totalSupply());
    }
    // Check minter info by token_id
    function getMinterInfo(uint256 _id) public view returns(MintConfig memory _minter) {
        _minter = mint_info[_id];
    }

    //
    // Mint new ERC721
    function buyNFT() external nonReentrant {
        require(totalSupply() < 10000, "All NFT minted");
        _stake(sell_token, sell_price);
        _safeMint(_msgSender(), totalSupply().add(1));
        _setMintInfo(_msgSender());
    }
    //
    //
    // Admin mint
    function adminMint() external nonReentrant onlyOwner {
        require(totalSupply() < 10000, "All NFT minted");
        _safeMint(_msgSender(), totalSupply().add(1));
        _setMintInfo(_msgSender());
    }
    //
    // Admin change mint price
    function changePrice(IERC20 _token, uint256 _amnt) external nonReentrant onlyOwner {
        _setPrice(_token, _amnt);
    }
    //

    //
    // Internal functions
        // Request payment
    function _stake(IERC20 token, uint256 amount) internal {
        require(amount > 0, "Amount too low");
        require(IERC20(token).balanceOf(_msgSender()) >= amount, "User not enought token");
        uint256 allow_amount = IERC20(token).allowance(_msgSender(), address(this));
        require(amount <= allow_amount, "Not approved amount");

        SafeERC20.safeTransferFrom(token, _msgSender(), wallet, amount);
    }

    function _setMintInfo(address _minter) internal {
        mint_info[totalSupply().add(1)] = MintConfig(_minter, block.timestamp);
    }

    function _setPrice(IERC20 _token, uint256 _amnt) internal {
        sell_token = _token;
        sell_price = _amnt;
    }
    //
}