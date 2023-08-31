// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol';
import "./Duckz.sol";

contract TempHaven is Ownable, IERC721Receiver {
    // reference to the Duckz NFT contract
    Duckz duckz;

    // maps tokenId to owner
    mapping(uint256 => address) public stakeOwner;
    bool public active = false;

    uint256 public constant NUM_DUCKZ = 555;

    constructor(address _duckz) { 
        duckz = Duckz(_duckz);
    }

    //Staking
    function stakeDuckz(address _address, uint256[] calldata _tokenIds) external {
        require (msg.sender == _address, "Bad address");
        require (active, "Contract no longer active for staking");
        for (uint256 i; i < _tokenIds.length; i++) {
            require(duckz.ownerOf(_tokenIds[i]) == _address, "Must be duck owner");
            duckz.safeTransferFrom(_address, address(this), _tokenIds[i], "");
            stakeOwner[_tokenIds[i]] = _address;
        }
    }

    function unstakeDuckz(address _address, uint256[] calldata _tokenIds) external {
        require (msg.sender == _address, "Bad address");
        require (active, "Contract no longer active for staking");
        for (uint256 i; i < _tokenIds.length; i++) {
            require(stakeOwner[_tokenIds[i]] == _address, "Must be duck owner");
            duckz.safeTransferFrom(address(this), stakeOwner[_tokenIds[i]], _tokenIds[i], "");
            stakeOwner[_tokenIds[i]] = address(0);
        }
    }
    //

    function flipActive() external onlyOwner {
        active = !active;
    }

    function evict(uint256[] calldata _tokenIds) external onlyOwner {
        for (uint256 i; i < _tokenIds.length; i++) {
            require(stakeOwner[_tokenIds[i]] != address(0), "No duck staked");
            duckz.safeTransferFrom(address(this), stakeOwner[_tokenIds[i]], _tokenIds[i], "");
            stakeOwner[_tokenIds[i]] = address(0);
        }
    }

    function rescue(address _address, uint256[] calldata _tokenIds) external {
        require (msg.sender == _address, "Bad address");
        require (!active, "Only for emergencies");
        for (uint256 i; i < _tokenIds.length; i++) {
            require(stakeOwner[_tokenIds[i]] == _address, "Must be duck owner");
            duckz.safeTransferFrom(address(this), stakeOwner[_tokenIds[i]], _tokenIds[i], "");
            stakeOwner[_tokenIds[i]] = address(0);
        }
    }

    //Reads
    function balanceOf(address _address) public view returns(uint256) {
        uint256 balance = 0;
        for (uint256 i; i < NUM_DUCKZ; i++) {
            if (stakeOwner[i] == _address) {
                balance++;
            }
        }
        return balance;
    }

    function walletOfOwner(address _address) external view returns(uint256[] memory) {
        uint256[] memory tokenIds = new uint256[](balanceOf(_address));
        uint256 count = 0;
        for (uint256 i; i < NUM_DUCKZ; i++) {
            if (stakeOwner[i] == _address) {
                tokenIds[count] = i;
                count++;
            }
        }
        return tokenIds;
    }

    function totalDuckz() public view returns(uint256) {
        uint256 total = 0;
        for (uint256 i; i < NUM_DUCKZ; i++) {
            if (stakeOwner[i] != address(0)) {
                total++;
            }
        }
        return total;
    }

    function stakedDuckz() external view returns(uint256[] memory) {
        uint256[] memory tokenIds = new uint256[](totalDuckz());
        uint256 count = 0;
        for (uint256 i; i < NUM_DUCKZ; i++) {
            if (stakeOwner[i] != address(0)) {
                tokenIds[count] = i;
                count++;
            }
        }
        return tokenIds;
    }
    //

    function onERC721Received(address,address,uint256,bytes calldata) external pure override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }
}