// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract FlyFrogsTadpoles is ERC1155, Ownable {
    using Counters for Counters.Counter;
    using Strings for uint256;
    using ECDSA for bytes32;

    string public name;
    string public symbol;
    string private baseURI;
    address private signerAddress;
    mapping (address => bool) private burnerAddresses;
    mapping (address => bool) private teamAddresses;
    bool private _paused = true;
    mapping(string => bool) private _usedNonces;
    Counters.Counter private _tokenIds;

    constructor(
      address _signer,
      string memory _uri,
      address _firstMinter
    ) ERC1155(_uri) {
        baseURI = _uri;
        name = "Fly Frogs Tadpoles";
        symbol = "FLYTADS";
        signerAddress = _signer;
        _mint(_firstMinter, 0, 1, "");
    }

    function hatch(
      address account,
      string memory nonce,
      bytes memory signature
    ) external returns (uint256) {
      if(!teamAddresses[account]) {
        require(!_paused, "Breeding Paused");
      }
      require(_verify(_hash(account, 1, nonce), signature), "Invalid signature");
      require(!_usedNonces[nonce], "Hash used");
      
      _tokenIds.increment();
      _mint(account, _tokenIds.current(), 1, "");
      _usedNonces[nonce] = true;
      return _tokenIds.current();
    }

    function multiHatch(
      address account,
      uint256 count,
      string memory nonce,
      bytes memory signature
    ) external returns (uint256[] memory) {
      if(!teamAddresses[account]) {
        require(!_paused, "Breeding Paused");
      }
      require(_verify(_hash(account, count, nonce), signature), "Invalid signature");
      require(!_usedNonces[nonce], "Hash used");
      
      uint256[] memory ids = new uint256[](count);
      uint256[] memory amounts = new uint256[](count);
      
      for(uint i = 0; i < count; i++) {
        _tokenIds.increment();
        ids[i]= _tokenIds.current();
        amounts[i] = 1;
      }

      _mintBatch(account, ids, amounts, "");
      _usedNonces[nonce] = true;
      return ids;
    }

    /**
     * @dev Set signer address
     */
    function setSignerAddress(address _signer) external onlyOwner {
        signerAddress = _signer;
    }

    /**
     * @dev Add address to list of contracts that can burn tadpoles
     */
    function addBurnerAddress(address burnerAddress) external onlyOwner {
        burnerAddresses[burnerAddress]=true;
    }

    /**
     * @dev Burn tadpole for holder address
     */
    function burnForAddress(address burnTokenAddress, uint256 tokenId) external {
        require(burnerAddresses[msg.sender], "Invalid burner address");
        _burn(burnTokenAddress, tokenId, 1);
    }

    function setURI(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    function uri(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        return string(abi.encodePacked(baseURI, tokenId.toString()));
    }

    function isPaused() public view returns(bool) {
        return _paused;
    }

    function pause(bool val) public onlyOwner {
        _paused = val;
    }

    function setTeamAddress(address teamMember, bool val) external onlyOwner {
        teamAddresses[teamMember]=val;
    }

    function _hash(address account, uint256 count, string memory nonce)
    internal pure returns (bytes32)
    {
        return ECDSA.toEthSignedMessageHash(keccak256(abi.encodePacked(account, count, nonce)));
    }

    function _verify(bytes32 hash, bytes memory signature)
    internal view returns (bool)
    {
        return hash.recover(signature) == signerAddress;
    }
}