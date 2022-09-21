// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./IERC721Burnable.sol";

// must be granted burner role by access token
contract ERC20Claim is Ownable {
    address public accessToken;
    address public erc20Token;
    uint public baseAllocation;

    bool public claimStarted;
    mapping(uint => uint) public rank;
    mapping(uint => bool) public claimed;

    /// @notice Constructor for the ONFT
    /// @param _accessToken address for the nft used to claim
    /// @param _baseAllocation allocation amount for base rank
    constructor(address _accessToken, uint _baseAllocation) {
        accessToken = _accessToken;
        baseAllocation = _baseAllocation;
    }

    function claim(uint _tokenId) public {
        require(claimStarted, "Claim period has not begun");
        address owner = IERC721Burnable(accessToken).ownerOf(_tokenId);
        require(owner == msg.sender, "Must be access token owner");
        IERC721Burnable(accessToken).burn(_tokenId);
        issueToken(owner, _tokenId);
    }

    function claimBatch(uint[] memory _tokenIds) public {
        for (uint i = 0; i < _tokenIds.length; i++) {
            claim(_tokenIds[i]);
        }
    }

    function issueToken(address _owner, uint _tokenId) internal {
        uint issuance = viewAllocation(_tokenId);
        require(issuance > 0, "no tokens to claim");
        IERC20(erc20Token).transfer(_owner, issuance);
        // SafeERC20.safeTransfer(IERC20(erc20Token), _owner, issuance);
    }

    function viewAllocation(uint _tokenId) public view returns (uint) {
        uint rankLevel = rank[_tokenId];
        return baseAllocation * rankLevel;
    }

    function setAccessRankings(uint[] memory _tokenIds, uint _rank) public onlyOwner {
        for (uint i = 0; i < _tokenIds.length; i++) {
            rank[_tokenIds[i]] = _rank;
        }
    }

    function setBaseAllocation(uint _allocation) public onlyOwner {
        baseAllocation = _allocation;
    }

    function setClaimStart(bool _isStarted) public onlyOwner {
        claimStarted = _isStarted;
    }

    function setERC20(address _erc20Token) public onlyOwner {
        erc20Token = _erc20Token;
    }

    function setAccessToken(address _accessToken) public onlyOwner {
        accessToken = _accessToken;
    }

    function withdrawERC20(IERC20 _erc20Token, address _to, uint _value) public onlyOwner {
        SafeERC20.safeTransfer(_erc20Token, _to, _value);
    }

    function withdrawAllERC20(IERC20 _erc20Token, address _to) public onlyOwner {
        uint balance = _erc20Token.balanceOf(address(this));
        SafeERC20.safeTransfer(_erc20Token, _to, balance);
    }
}