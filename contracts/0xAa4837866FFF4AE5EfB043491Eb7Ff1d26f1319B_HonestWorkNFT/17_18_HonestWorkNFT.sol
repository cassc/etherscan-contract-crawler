// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./utils/Base64.sol";

/// @title HonestWork Genesis NFT
/// @author @takez0_o, @ReddKidd
/// @notice Genesis Membership NFT's to be used in the platform
/// @notice Cap is initially set to 1001, but can be increased by the owner
/// @dev NFT's are standalone, revenue is updated via off-chain metadata service
contract HonestWorkNFT is ERC721, ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter public _tokenIds;
    bytes32 public whitelistRoot;
    string public baseUri;
    uint256 public tokenCap = 1001;
    uint256 public tierOneFee = 100e18;
    uint256 public tierTwoFee = 250e18;
    uint256 public tierThreeFee = 300e18;

    mapping(address => bool) public whitelistedTokens;
    mapping(address => bool) public whitelistCap;
    mapping(uint256 => uint256) public tier;
    
    bool public isPaused = false;

    event Upgrade(uint256 id, uint256 tier);
    event Mint(uint256 id, address user);

    constructor(
        string memory _baseUri,
        address[] memory _whitelistedTokens
    ) ERC721("HonestWork Genesis", "HWG") {
        baseUri = _baseUri;
        for (uint256 i = 0; i < _whitelistedTokens.length; i++) {
            whitelistedTokens[_whitelistedTokens[i]] = true;
        }
    }

    //-----------------//
    //  admin methods  //
    //-----------------//

    function setTiers(
        uint256 _tierOneFee,
        uint256 _tierTwoFee,
        uint256 _tierThreeFee
    ) external onlyOwner {
        tierOneFee = _tierOneFee;
        tierTwoFee = _tierTwoFee;
        tierThreeFee = _tierThreeFee;
    }

    function setBaseUri(string memory _baseUri) external onlyOwner {
        baseUri = _baseUri;
    }

    function setTokenCap(uint256 _tokenCap) external onlyOwner {
        tokenCap = _tokenCap;
    }

    function whitelistToken(address _token) external onlyOwner {
        whitelistedTokens[_token] = true;
    }

    function setWhitelistRoot(bytes32 _root) external onlyOwner {
        whitelistRoot = _root;
    }

    function withdraw(address _token, uint256 _amount) external onlyOwner {
        IERC20(_token).transfer(msg.sender, _amount);
    }

    function pause() external onlyOwner {
        isPaused = true;
    }

    function unpause() external onlyOwner {
        isPaused = false;
    }

    function removeWhitelistToken(address _token) external onlyOwner {
        whitelistedTokens[_token] = false;
    }
    

    function adminMint(address _to, uint256 _tier) external onlyOwner {
        require(_tokenIds.current() < tokenCap, "Token cap reached");
        _tokenIds.increment();
        uint256 newTokenId = _tokenIds.current();
        _mint(_to, newTokenId);
        tier[newTokenId] = _tier;
        emit Mint(newTokenId, _to);
    }

    //--------------------//
    //  internal methods  //
    //--------------------//

    function _whitelistLeaf(address _address) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_address));
    }

    function _verify(
        bytes32 _leaf,
        bytes32 _root,
        bytes32[] memory _proof
    ) internal pure returns (bool) {
        return MerkleProof.verify(_proof, _root, _leaf);
    }

    function _beforeTokenTransfer(
        address _from,
        address _to,
        uint256 _tokenId,
        uint256 _batchSize
    ) internal whenNotPaused override(ERC721, ERC721Enumerable) {
        if(_to != owner()) {
        require(balanceOf(_to) == 0, "only one nft at a time");
        }
        super._beforeTokenTransfer(_from, _to, _tokenId, _batchSize);
    }

    function _toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    //--------------------//
    //  mutative methods  //
    //--------------------//

    function publicMint(address _token) whenNotPaused external {
        require(whitelistedTokens[_token], "token not whitelisted");
        IERC20(_token).transferFrom(msg.sender, address(this), tierOneFee);
        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();
        require(newItemId < tokenCap, "all the nfts are claimed");
        _mint(msg.sender, newItemId);
        tier[newItemId] = 1;
        emit Mint(newItemId, msg.sender);
    }

    function whitelistMint(bytes32[] calldata _proof) whenNotPaused external {
        require(!whitelistCap[msg.sender], "whitelist cap reached");
        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();
        require(newItemId < tokenCap, "all the nfts are claimed");
        require(
            _verify(_whitelistLeaf(msg.sender), whitelistRoot, _proof),
            "Invalid merkle proof"
        );

        whitelistCap[msg.sender] = true;
        _mint(msg.sender, newItemId);
        tier[newItemId] = 1;
        emit Mint(newItemId, msg.sender);
    }

    function upgradeToken(address _token, uint256 _levels) external {
        require(_levels > 0 && _levels < 3);
        require(balanceOf(msg.sender) == 1);
        uint256 _tokenId = tokenOfOwnerByIndex(msg.sender, 0);
        require(tier[_tokenId] < 3);
        require(whitelistedTokens[_token], "token not whitelisted");
        if (_levels == 2) {
            require(tier[_tokenId] == 1);
            IERC20(_token).transferFrom(msg.sender, address(this), tierThreeFee - tierOneFee);
            tier[_tokenId] += 2;
        } else {
            if (tier[_tokenId] == 1) {
              IERC20(_token).transferFrom(msg.sender, address(this), tierTwoFee - tierOneFee);
            } else {
              IERC20(_token).transferFrom(msg.sender, address(this), tierThreeFee - tierTwoFee);
            }
            tier[_tokenId]++;
        }
        emit Upgrade(_tokenId, tier[_tokenId]);
    }

    //----------------//
    //  view methods  //
    //----------------//

    function getTokenTier(uint256 _tokenId) external view returns (uint256) {
        return tier[_tokenId];
    }

    function getUserTier(address _user) external view returns (uint256) {
        if (balanceOf(_user) == 0) {
            return 0;
        }
        uint256 _tokenId = tokenOfOwnerByIndex(_user, 0);
        return tier[_tokenId];
    }

    function supportsInterface(
        bytes4 _interfaceId
    ) public view override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(_interfaceId);
    }

    function tokenURI(
        uint256 _tokenId
    ) public view override returns (string memory) {
        return string(abi.encodePacked(baseUri, _toString(_tokenId)));
    }

    function getWhitelistToken(address _token) external view returns (bool) {
        return whitelistedTokens[_token];
    }

    //----------------//
    //   modifiers    //
    //----------------//
 
    modifier whenNotPaused() {
        require(!isPaused, "Contract is paused");
        _;
    }
}