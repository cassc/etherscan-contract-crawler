// SPDX-License-Identifier: MIT
// Authentic Artists 2022
pragma solidity ^0.8.9;

import "./ERC721U.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./IERC20.sol";

interface WarpSoundAPI {
    function ownerOf(uint256) external returns(address);
}

contract WarpSynthNFT is
Initializable,
ERC721Upgradeable,
ReentrancyGuardUpgradeable,
OwnableUpgradeable
{
    using StringsUpgradeable for uint256;
    mapping(uint256 => bool) private tokensConsumed;
    mapping(uint256 => uint256) private variants;

    string public baseURI;
    mapping(uint256 => bool) validTokens;
    mapping(address => bool) adminWallets;
    bool public mintingEnabled;
    address warpSoundContract;

    function initialize(string memory name, string memory symbol, string memory _initBaseURI) public initializer {
        __ERC721_init(name, symbol);
        __ReentrancyGuard_init();
        __Ownable_init();
        baseURI = _initBaseURI;
        adminWallets[0xed9Fe6a99ACc9FAC0EF90d1719B54BC9cD2d5b48] = true;
        warpSoundContract = 0xcBC67Ea382F8a006d46EEEb7255876BeB7d7f14d;
        mintingEnabled = false;
    }

    /* Guards */

    modifier onlyAdmin() {
        require(
            owner() == msg.sender || adminWallets[msg.sender],
            "Only an admin can perform this operation"
        );
        _;
    }

    /* Minting */

    function toggleMinting() public onlyOwner {
        require(
            msg.sender == tx.origin,
            "smart contract sender is not allowed"
        );
        mintingEnabled = !mintingEnabled;
    }

    function setValidTokens(uint256[] memory tokensToEnable) public onlyAdmin {
        require(
            msg.sender == tx.origin,
            "smart contract sender is not allowed"
        );
        require(
            tokensToEnable.length < 51,
            "Cannot add more than 50 tokens in one transaction"
        );
        //++i instead of i++
        for (uint i=0; i < tokensToEnable.length; i++){
            validTokens[tokensToEnable[i]] = true;
        }
    }

    function getVariantID(uint256 token) public view returns (uint256) {
        return variants[token];
    }

    function addAdmin(address user) public onlyOwner {
        adminWallets[user] = true;
    }

    function removeAdmin(address admin) public onlyOwner {
        adminWallets[admin] = false;
    }
    
    function isAdmin(address maybeAdmin) public view onlyOwner returns (bool) {
        return adminWallets[maybeAdmin];
    }

    function clearTokenConsumedStatus(uint256 tokenId) public onlyAdmin {
        tokensConsumed[tokenId] = false;
    }

    function getTokenNumber(uint256 token) public view returns (bool) {
        return tokensConsumed[token];
    }

    function isTokenValid(uint256 token) public view returns (bool) {
        return validTokens[token];
    }


    function mint(uint256 token, uint32 variant_id)
    public
    nonReentrant
    {
        WarpSoundAPI api = WarpSoundAPI(warpSoundContract);
        address base_token_owner = api.ownerOf(token);
        require(
            msg.sender == tx.origin,
            "Minting from a smart contract is not allowed"
        );
        require(
            mintingEnabled == true,
            "Minting isn't enabled"
        );
        require(
            base_token_owner == msg.sender,
            "You are not the owner of this token."
        );
        require(
            tokensConsumed[token] == false,
            "This token's ability to mint has already been consumed."
        );
        require(
            validTokens[token] == true,
            "The token you suggested doesn't have sufficient generative ability"
        );
        require(
            variant_id > 0,
            "you have provided an invalid variant id"
        );

        _mint(msg.sender);
        tokensConsumed[token] = true;
        variants[token] = variant_id;
    }

    // owner only function for minting
    function magicMint(uint256 token, uint32 variant_id, address to)
    public
    nonReentrant
    onlyAdmin
    {
        require(
            msg.sender == tx.origin,
            "Minting from a smart contract is not allowed"
        );
        require(
            tokensConsumed[token] == false,
            "This token's ability to mint has already been consumed."
        );
        require(
            variant_id > 0,
            "you have provided an invalid variant id"
        );
        _mint(to);
        tokensConsumed[token] = true;
        variants[token] = variant_id;
    }


    function mintTest(uint256 token, uint32 variant_id)
    public
    nonReentrant
    onlyAdmin
    {
        require(
            tokensConsumed[token] == false,
            "This token's ability to mint has already been consumed."
        );
        require(
            validTokens[token] == true,
            "The token you suggested doesn't have sufficient generative ability"
        );
        require(
            variant_id > 0,
            "you have provided an invalid variant id"
        );

        _safeMint(msg.sender);
        tokensConsumed[token] = true;
        variants[token] = variant_id;
    }

    /* URL Utility */

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory _baseTokenURI) external onlyAdmin {
        baseURI = _baseTokenURI;
    }

    function withdraw() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function withdrawERC20(IERC20Upgradeable token) public onlyOwner {
        require(
            token.transfer(msg.sender, token.balanceOf(address(this))),
            "Transfer failed"
        );
    }
}